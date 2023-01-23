require_relative '../rails_helper'

describe "Rails integration", if: RAILS_PRESENT, type: :request do
  load_rails_hooks(self)

  it "inserts the middleware" do
    expect(RailsApp.middleware).to include(NeetoBugtrap::Rack::ErrorNotifier)
  end

  it "reports exceptions" do
    NeetoBugtrap.flush do
      get "/runtime_error"
      expect(response.status).to eq(500)
    end

    expect(NeetoBugtrap::Backend::Test.notifications[:notices].size).to eq(1)
  end

  it "sets the root from the Rails root" do
    expect(NeetoBugtrap.config.get(:root)).to eq(Rails.root.to_s)
  end

  it "sets the env from the Rails env" do
    expect(NeetoBugtrap.config.get(:env)).to eq(Rails.env)
  end

  context "default ignored exceptions" do
    it "doesn't report exception" do
      NeetoBugtrap.flush { get "/record_not_found" }

      expect(NeetoBugtrap::Backend::Test.notifications[:notices]).to be_empty
    end
  end
end
