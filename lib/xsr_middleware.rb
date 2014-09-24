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

    if request.env['X-TrackingId']
      XsrMiddleware::RequestContext.set_tracking_id(request.env['X-TrackingId'])
    else
      XsrMiddleware::RequestContext.set_tracking_id(encode_string(request.session_options.fetch(:id, '')))
    end

    XsrMiddleware::RequestContext.request_id = encode_string("#{$$}#{request.path}#{Time.now.to_s}")
    XsrMiddleware::RequestContext.set_default_operator if Module.constants.include? :MdpBackoffice

    status, headers, body = @app.call(env)

    # TODO : Do not set X-RequestId header
    # X-Request-id header would typically be generated by a firewall, load balancer, or the web server, or,
    # if this header is not available, a random uuid. header already set by web server.
    headers['X-RequestId']  = XsrMiddleware::RequestContext.request_id
    headers['X-TrackingId'] = XsrMiddleware::RequestContext.tracking_id

    XsrMiddleware::RequestContext.reset

    [status, headers, body]
  end

  private

    def encode_string(string)
      Digest::MD5.new.hexdigest(string)
    end
end
