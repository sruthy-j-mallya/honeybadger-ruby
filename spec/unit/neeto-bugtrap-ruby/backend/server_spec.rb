require 'logger'
require 'neeto-bugtrap-ruby/backend/server'
require 'neeto-bugtrap-ruby/config'

describe NeetoBugtrap::Backend::Server do
  let(:config) { NeetoBugtrap::Config.new(logger: NULL_LOGGER, api_key: 'abc123') }
  let(:logger) { config.logger }
  let(:payload) { double('Notice', to_json: '{}') }

  subject { described_class.new(config) }

  it { should respond_to :notify }
  it { should respond_to :check_in }

  describe "#check_in" do
    it "returns a response" do
      stub_http
      expect(subject.check_in('foobar')).to be_a NeetoBugtrap::Backend::Response
    end
  end

  describe "#notify" do
    it "returns the response" do
      stub_http
      expect(notify_backend).to be_a NeetoBugtrap::Backend::Response
    end

    context "when payload has an api key" do
      before do
        allow(payload).to receive(:api_key).and_return('bugtraps')
      end

      it "passes the payload api key in extra headers" do
        http = stub_http
        expect(http).to receive(:post).with(anything, anything, hash_including({ 'X-API-Key' => 'bugtraps'}))
        notify_backend
      end
    end

    context "when payload doesn't have an api key" do
      it "doesn't pass extra headers" do
        http = stub_http
        expect(http).to receive(:post).with(anything, anything, hash_including({ 'X-API-Key' => 'abc123'}))
        notify_backend
      end
    end

    context "when encountering exceptions" do
      context "HTTP connection setup problems" do
        it "should not be rescued" do
          proxy = double()
          allow(proxy).to receive(:new).and_raise(NoMemoryError)
          allow(Net::HTTP).to receive(:Proxy).and_return(proxy)
          expect { notify_backend }.to raise_error(NoMemoryError)
        end
      end

      context "connection errors" do
        it "returns Response" do
          http = stub_http
          NeetoBugtrap::Backend::Server::HTTP_ERRORS.each do |error|
            allow(http).to receive(:post).and_raise(error)
            result = notify_backend
            expect(result).to be_a NeetoBugtrap::Backend::Response
            expect(result.code).to eq :error
          end
        end

        it "doesn't fail when posting an http exception occurs" do
          http = stub_http
          NeetoBugtrap::Backend::Server::HTTP_ERRORS.each do |error|
            allow(http).to receive(:post).and_raise(error)
            expect { notify_backend }.not_to raise_error
          end
        end
      end
    end

    def notify_backend
      subject.notify(:notices, payload)
    end

  end
end
