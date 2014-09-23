require 'xsr_middleware/request_context'

class XsrMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.cookies['_dpplus_xsr_id']
      XsrMiddleware::RequestContext.set_tracking_id(request.cookies['_dpplus_xsr_id'], hashed: true)
    elsif request.env['X-TrackingId']
      XsrMiddleware::RequestContext.set_tracking_id(request.env['X-TrackingId'], hashed: true)
    else
      XsrMiddleware::RequestContext.set_tracking_id(request.session_options[:id], hashed: false)
    end

    XsrMiddleware::RequestContext.request_id = XsrMiddleware::RequestContext.generate_token
    XsrMiddleware::RequestContext.set_default_operator if Module.constants.include? :MdpBackoffice

    # Rails.logger.info("Request #{request.request_method.to_s.upcase} #{request.path} from #{request.ip}")

    status, headers, body = @app.call(env)

    headers['X-RequestId']  = XsrMiddleware::RequestContext.request_id
    headers['X-TrackingId'] = XsrMiddleware::RequestContext.tracking_id

    if XsrMiddleware::RequestContext.tracking_id
      Rack::Utils.set_cookie_header!(headers, "_dpplus_xsr_id", { value: XsrMiddleware::RequestContext.tracking_id,
                                                                  path: '/' })
    else
      Rack::Utils.delete_cookie_header!(headers, "_dpplus_xsr_id", { path: '/' })
    end

    # Rails.logger.info("Response #{status} #{headers['Content-Type']} #{headers['Content-Length']}")

    XsrMiddleware::RequestContext.reset

    [status, headers, body]
  end

end
