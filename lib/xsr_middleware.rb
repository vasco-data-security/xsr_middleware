require 'xsr_middleware/request_context'
require 'digest'

##
# This middleware helps with tracking users accross multiple requests and services (anonymously):
#   - by setting a request id to follow a request to multiple services (X-MDP-Request-Id)
#   - by setting a tracking id to follow a user through multiple requests (X-Tracking-Id)
#

class XsrMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.env['X-Tracking-Id']
      XsrMiddleware::RequestContext.set_tracking_id(request.env['X-Tracking-Id'])
    else
      XsrMiddleware::RequestContext.set_tracking_id(encode_string(request.session_options.fetch(:id, '')))
    end

    if request.env['X-MDP-Request-Id']
      XsrMiddleware::RequestContext.set_mdp_request_id(request.env['X-MDP-Request-Id'])
    else
      XsrMiddleware::RequestContext.set_mdp_request_id(encode_string("#{$$}#{request.path}#{Time.now.to_s}"))
    end

    XsrMiddleware::RequestContext.set_default_operator if Module.constants.include? :MdpBackoffice

    status, headers, body = @app.call(env)

    headers['X-MDP-Request-Id'] = XsrMiddleware::RequestContext.mdp_request_id
    headers['X-Tracking-Id'] = XsrMiddleware::RequestContext.tracking_id

    XsrMiddleware::RequestContext.reset

    [status, headers, body]
  end

  private

    def encode_string(string)
      Digest::MD5.new.hexdigest(string)
    end
end
