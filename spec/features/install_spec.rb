require 'neeto-bugtrap-ruby/config'
require 'pathname'

feature "Installing neetobugtrap via the cli" do
  shared_examples_for "cli installer" do |rails|
    let(:config) { NeetoBugtrap::Config.new(:api_key => 'asdf', :'config.path' => config_file) }

    before { set_environment_variable('NEETOBUGTRAP_BACKEND', 'debug') }

    it "outputs successful result" do
      expect(run_command('neetobugtrap install asdf')).to be_successfully_executed
      expect(all_output).to match /Writing configuration/i
      expect(all_output).to match /Happy 'bugtraping/i
      expect(all_output).not_to match /heroku/i
      expect(all_output).not_to match /Starting NeetoBugtrap/i
      if rails
        expect(all_output).to match /Detected Rails/i
      else
        expect(all_output).not_to match /Detected Rails/i
      end
    end

    it "creates the configuration file" do
      expect {
        run_command_and_stop('neetobugtrap install asdf', fail_on_error: true)
      }.to change { config_file.exist? }.from(false).to(true)
    end

    it "sends a test notification" do
      set_environment_variable('NEETOBUGTRAP_LOGGING_LEVEL', '1')
      expect(run_command('neetobugtrap install asdf')).to be_successfully_executed
      assert_notification('error' => {'class' => 'NeetoBugtrapTestingException'})
    end

    context "with the --no-test option" do
      it "skips the test notification" do
        set_environment_variable('NEETOBUGTRAP_LOGGING_LEVEL', '1')
        expect(run_command('neetobugtrap install asdf --no-test')).to be_successfully_executed
        assert_no_notification
      end
    end

    scenario "when the configuration file already exists" do
      before { File.write(config_file, <<-YML) }
---
api_key: 'asdf'
YML

      it "does not overwrite existing configuration" do
        expect(run_command('neetobugtrap install asdf')).to be_successfully_executed
        expect {
          run_command_and_stop('neetobugtrap install asdf', fail_on_error: true)
        }.not_to change { config_file.mtime }
      end

      it "outputs successful result" do
        expect(run_command('neetobugtrap install asdf')).to be_successfully_executed
        expect(all_output).to match /Happy 'bugtraping/i
      end
    end

## 
# TODO: Capistrano us not supported
#
#     scenario "when capistrano is detected" do
#       let(:capfile) { Pathname(current_dir).join('Capfile') }

#       before { File.write(capfile, <<-YML) }
# if respond_to?(:namespace) # cap2 differentiator
#   load 'deploy'
# else
#   require 'capistrano/setup'
#   require 'capistrano/deploy'
# end
# YML

#       it "installs capistrano command" do
#         expect(run_command('neetobugtrap install asdf')).to be_successfully_executed
#         expect(run_command('bundle exec cap -T')).to be_successfully_executed
#         expect(all_output).to match(/neetobugtrap\:deploy/i)
#       end
#     end
  end

  scenario "in a plain ruby project" do
    let(:config_file) { Pathname(current_dir).join('neetobugtrap.yml') }

    it_behaves_like "cli installer", false
  end

  scenario "in a Rails project", framework: :rails do
    let(:config_file) { Pathname(current_dir).join('config', 'neetobugtrap.yml') }

    it_behaves_like "cli installer", true
  end
end
