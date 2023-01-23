require 'neeto-bugtrap-ruby/breadcrumbs/logging'

describe NeetoBugtrap::Breadcrumbs::LogSubscriberInjector do
  LOGGING_LEVELS = %w(info debug warn error fatal unknown)

  let(:logger) do
    Class.new do
      prepend NeetoBugtrap::Breadcrumbs::LogSubscriberInjector

      LOGGING_LEVELS.each do |level|
        define_method(level) do |message = nil, &block|
          # That's what a typical logger (e.g. Syslog::Logger) does to evaluate
          # the message string
          message || block.call
        end
      end
    end
  end

  subject { logger.new }

  it "resets __nb_within_log_subscriber to false" do
    subject.info "test"
    expect(Thread.current[:__nb_within_log_subscriber]).to eq(false)
  end

  it "works when message is a string" do
    expect { subject.info "test" }.not_to raise_error
  end

  it "works when message is generated by a block" do
    expect { subject.info { "test" } }.not_to raise_error
  end
end
