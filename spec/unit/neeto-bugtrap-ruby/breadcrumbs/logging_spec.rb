require 'neeto-bugtrap-ruby/breadcrumbs/logging'

describe NeetoBugtrap::Breadcrumbs::LogWrapper do
  let(:logger) do
    Class.new do
      prepend NeetoBugtrap::Breadcrumbs::LogWrapper

      attr_reader :severity, :message, :progname

      def add(severity, message, progname)
        @severity = severity
        @message = message
        @progname = progname
      end

      def format_severity(str)
        str
      end
    end
  end

  subject { logger.new }

  it 'adds a breadcrumb' do
    expect(subject).to receive(:format_severity).and_return("debug")
    expect(NeetoBugtrap).to receive(:add_breadcrumb).with("Message", hash_including(category: :log, metadata: hash_including(severity: "debug", progname: "none")))

    subject.add("test", "Message", "none")
  end

  it 'handles non-string objects' do
    expect(NeetoBugtrap).to receive(:add_breadcrumb).with("{}", anything)
    subject.add("DEBUG", {})
  end

  it 'does not mutate the message' do
    subject.add("DEBUG", {}, 'NeetoBugtrap')
    expect(subject.severity).to eq('DEBUG')
    expect(subject.message).to eq({})
    expect(subject.progname).to eq('NeetoBugtrap')
  end

  describe "ignores messages on" do
    before { expect(NeetoBugtrap).to_not receive(:add_breadcrumb) }

    it 'nil message' do
      subject.add("test", nil)
    end

    it 'empty string' do
      subject.add("test", "")
    end

    it 'neetobugtrap progname' do
      subject.add("test", "noop", "neetobugtrap")
    end

    it 'within log_subscriber call' do
      Thread.current[:__nb_within_log_subscriber] = true
      subject.add("test", "a message")
      Thread.current[:__nb_within_log_subscriber] = false
    end
  end
end
