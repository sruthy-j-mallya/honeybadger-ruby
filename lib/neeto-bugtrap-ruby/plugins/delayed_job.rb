require 'neeto-bugtrap-ruby/plugin'

module NeetoBugtrapRuby
  Plugin.register do
    requirement { defined?(::Delayed::Plugin) }
    requirement { defined?(::Delayed::Worker.plugins) }
    requirement do
      if delayed_job_honeybadger = defined?(::Delayed::Plugins::NeetoBugtrapRuby)
        logger.warn("Support for Delayed Job has been moved " \
                    "to the honeybadger gem. Please remove " \
                    "delayed_job_honeybadger from your " \
                    "Gemfile.")
      end
      !delayed_job_honeybadger
    end

    execution do
      require 'neeto-bugtrap-ruby/plugins/delayed_job/plugin'
      ::Delayed::Worker.plugins << Plugins::DelayedJob::Plugin
    end
  end
end
