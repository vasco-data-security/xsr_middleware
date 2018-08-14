require 'xsr/request_context'
require 'digest'
require 'logger'
require 'singleton'

##
# This middleware helps with tracking users accross multiple services (anonymously)
# by setting a Correlation id to follow a request to multiple services (Log-Correlation-ID)
#
# Be aware that whenever you perform an actual call to a web server,
# Rack automatically prepends "HTTP_" to the header's key, replaces dashes by
# underscores and capitalizes word segments.
module Xsr
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.env['HTTP_LOG_CORRELATION_ID']
        Xsr::RequestContext.correlation_id  = request.env['HTTP_LOG_CORRELATION_ID']
      else
        session_id = request.session_options[:id] || ''
        Xsr::RequestContext.correlation_id = encode_string(session_id)
      end

      Xsr::RequestContext.set_default_operator if Xsr::RequestContext.method_defined?(:set_default_operator)

      status, headers, body = Xsr.logger.tagged(request_info) { @app.call(env) }

      # See the description at the top of this file.
      # Rack does some annoying magic!
      headers['Log-Correlation-ID'] = Xsr::RequestContext.correlation_id

      Xsr::RequestContext.reset

      [status, headers, body]
    end

    private

      def encode_string(string)
        Digest::MD5.new.hexdigest(string)
      end

      def request_info
        "#{$$}:#{Xsr::RequestContext.correlation_id}"
      end
  end

  class Configuration
    include Singleton

    def self.default_logger
      logger = Logger.new(STDOUT)
      logger.define_singleton_method(:tagged) { |request_info, &block| block.call }
      logger.progname = 'xsr'
      logger
    end

    def self.defaults
      @defaults ||= {
        logger: default_logger
      }
    end

    attr_accessor :logger

    def initialize
      self.class.defaults.each_pair { |k, v| send("#{k}=", v) }
    end
  end

  def self.config
    Configuration.instance
  end

  def self.configure
    yield config
  end

  def self.logger
    config.logger
  end
end
