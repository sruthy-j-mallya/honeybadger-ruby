# frozen_string_literal: true

require 'forwardable'
require 'net/http'
require 'json'
require 'zlib'
require 'openssl'

require 'neeto-bugtrap-ruby/version'
require 'neeto-bugtrap-ruby/logging'

module NeetoBugtrap
  module Util
    class HTTP
      extend Forwardable

      include NeetoBugtrap::Logging::Helper

      HEADERS = {
        'Content-type' => 'application/json',
        'Content-Encoding' => 'deflate',
        'Accept' => 'text/json, application/json',
        'User-Agent' => "NB-Ruby #{VERSION}; #{RUBY_VERSION}; #{RUBY_PLATFORM}"
      }.freeze

      ERRORS = [Timeout::Error,
                Errno::EINVAL,
                Errno::ECONNRESET,
                Errno::ECONNREFUSED,
                Errno::ENETUNREACH,
                EOFError,
                Net::HTTPBadResponse,
                Net::HTTPHeaderSyntaxError,
                Net::ProtocolError,
                OpenSSL::SSL::SSLError,
                SocketError].freeze

      def initialize(config)
        @config = config
      end

      def get(endpoint)
        response = http_connection.get(endpoint)
        debug { format('http method=GET path=%s code=%d', endpoint.dump, response.code) }
        response
      end

      def post(endpoint, payload, headers = nil)
        response = http_connection.post(endpoint, { payload: payload.to_json }, http_headers(headers))
        debug { format('http method=POST path=%s code=%d', endpoint.dump, response.code) }
        response
      end

      private

      attr_reader :config

      def http_connection
        setup_http_connection
      end

      def http_headers(headers = nil)
        {}.tap do |hash|
          hash.merge!(HEADERS)
          hash.merge!({ 'X-API-Key' => config[:api_key].to_s })
          hash.merge!(headers) if headers
        end
      end

      def setup_http_connection
        http_class = Net::HTTP::Proxy(config[:'connection.proxy_host'], config[:'connection.proxy_port'],
                                      config[:'connection.proxy_user'], config[:'connection.proxy_pass'])
        http = http_class.new(config[:'connection.host'], config.connection_port)

        http.read_timeout = config[:'connection.http_read_timeout']
        http.open_timeout = config[:'connection.http_open_timeout']

        if config[:'connection.secure']
          http.use_ssl = true

          # TODO: Uncomment this later and fix the issue with the file
          # http.ca_file = config.ca_bundle_path
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
          http.use_ssl = false
        end

        http
      end

      def compress(string, level = Zlib::DEFAULT_COMPRESSION)
        Zlib::Deflate.deflate(string, level)
      end
    end
  end
end
