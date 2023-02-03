require 'forwardable'
require 'rack/request'

require 'neeto-bugtrap-ruby/ruby'

module NeetoBugtrap
  module Rack
    # Middleware for Rack applications. Any errors raised by the upstream
    # application will be delivered to NeetoBugtrap and re-raised.
    #
    # @example
    #   require 'neeto-bugtrap-ruby/rack/error_notifier'
    #
    #   app = Rack::Builder.app do
    #     run lambda { |env| raise "Rack down" }
    #   end
    #
    #   use NeetoBugtrap::Rack::ErrorNotifier
    #
    #   run app
    class ErrorNotifier
      extend Forwardable

      def initialize(app, agent = nil)
        @app = app
        @agent = agent.kind_of?(Agent) && agent
      end

      def call(env)
        agent.with_rack_env(env) do
          begin
            env['neetobugtrap.config'] = config
            response = @app.call(env)
          rescue Exception => raised
            env['neetobugtrap.error_id'] = notify_neetobugtrap(raised, env)
            raise
          end

          framework_exception = framework_exception(env)
          if framework_exception
            env['neetobugtrap.error_id'] = notify_neetobugtrap(framework_exception, env)
          end

          response
        end
      ensure
        agent.clear!
      end

      private

      def_delegator :agent, :config
      def_delegator :config, :logger

      def agent
        @agent || NeetoBugtrap::Agent.instance
      end

      def ignored_user_agent?(env)
        true if config[:'exceptions.ignored_user_agents'].
          flatten.
          any? { |ua| ua === env['HTTP_USER_AGENT'] }
      end

      def notify_neetobugtrap(exception, env)
        return if ignored_user_agent?(env)

        if config[:'breadcrumbs.enabled']
          # Drop the last breadcrumb only if the message contains the error class name
          agent.breadcrumbs.drop_previous_breadcrumb_if do |bc|
            bc.category == "log" && bc.message.include?(exception.class.to_s)
          end

          agent.add_breadcrumb(
            exception.class,
            metadata: {
              message: exception.message
            },
            category: "error"
          )
        end

        agent.notify(exception)
      end

      def framework_exception(env)
        env['action_dispatch.exception'] || env['rack.exception'] ||
          env['sinatra.error'] || env['neetobugtrap.exception']
      end
    end
  end
end