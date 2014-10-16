require 'xsr/request_context'
require 'digest'

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

      Xsr::RequestContext.set_default_operator if Module.constants.include? :MdpBackoffice

      status, headers, body = @app.call(env)

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

  end
end