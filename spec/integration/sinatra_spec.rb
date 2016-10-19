begin
  require 'sinatra/base'
  SINATRA_PRESENT = true
rescue LoadError
  SINATRA_PRESENT = false
  puts 'Skipping Sinatra integration specs.'
end

if SINATRA_PRESENT
  require_relative 'sinatra/app'
  require 'honeybadger/init/sinatra'
  require 'rack/test'

  describe 'Sinatra integration' do
    include Rack::Test::Methods

    def app
      SinatraApp
    end

    before(:each) do
      Honeybadger.configure do |config|
        config.backend = 'test'
      end
    end

    after(:each) do
      Honeybadger::Backend::Test.notifications[:notices].clear
    end

    it "reports exceptions" do
      Honeybadger.flush do
        get '/runtime_error'
        expect(last_response.status).to eq(500)
      end

      expect(Honeybadger::Backend::Test.notifications[:notices].size).to eq(1)
    end

    it "configures the api key from sinatra config" do
      get '/' # Initialize app
      expect(Honeybadger.config.get(:api_key)).to eq('gem testing')
    end
  end
end
