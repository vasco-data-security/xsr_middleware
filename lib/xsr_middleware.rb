require 'xsr_middleware/request_context'
require 'digest'

##
# This middleware helps with tracking users accross multiple requests and services (anonymously),
# by using an MD5-encoded session_id as tracking_id.
#
# It will also add the tracking_id to a header (X-TrackingId) so the services can use it as well.

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

    XsrMiddleware::RequestContext.request_id = encode_string("#{$$}#{request.path}#{Time.now.to_s}")
    XsrMiddleware::RequestContext.set_default_operator if Module.constants.include? :MdpBackoffice

    status, headers, body = @app.call(env)

    # Set the X-Requist-Id header which would be otherwise set by the web server or rails.
    headers['X-Request-Id'] = XsrMiddleware::RequestContext.request_id
    headers['X-Tracking-Id'] = XsrMiddleware::RequestContext.tracking_id

    XsrMiddleware::RequestContext.reset

    [status, headers, body]
  end

  private

    def encode_string(string)
      Digest::MD5.new.hexdigest(string)
    end
end
