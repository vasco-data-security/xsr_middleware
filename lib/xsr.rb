require 'xsr/request_context'
require 'digest'
require 'logger'
require 'singleton'

##
# This middleware helps with tracking users accross multiple requests and services (anonymously):
#   - by setting a request id to follow a request to multiple services (X-Mdp-Request-Id)
#   - by setting a tracking id to follow a user through multiple requests (X-Mdp-Tracking-Id)
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

      if request.env['HTTP_X_MDP_TRACKING_ID']
        Xsr::RequestContext.set_tracking_id(request.env['HTTP_X_MDP_TRACKING_ID'])
      else
        session_id = request.session_options[:id] || ''
        Xsr::RequestContext.set_tracking_id(encode_string(session_id))
      end

      if request.env['HTTP_X_MDP_REQUEST_ID']
        Xsr::RequestContext.set_mdp_request_id(request.env['HTTP_X_MDP_REQUEST_ID'])
      else
        Xsr::RequestContext.set_mdp_request_id(encode_string("#{$$}#{request.path}#{Time.now.to_s}"))
      end

      Xsr::RequestContext.set_default_operator if Xsr::RequestContext.method_defined?(:set_default_operator)

      status, headers, body = Xsr.logger.tagged(request_info) { @app.call(env) }

      # See the description at the top of this file.
      # Rack does some annoying magic!
      headers['X-Mdp-Request-Id'] = Xsr::RequestContext.mdp_request_id
      headers['X-Mdp-Tracking-Id'] = Xsr::RequestContext.tracking_id

      Xsr::RequestContext.reset

      [status, headers, body]
    end

    private

      def encode_string(string)
        Digest::MD5.new.hexdigest(string)
      end

      def request_info
        "#{$$}:#{Xsr::RequestContext.mdp_request_id}:#{Xsr::RequestContext.tracking_id}"
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
