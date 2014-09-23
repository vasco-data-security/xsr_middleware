require 'xsr_middleware/request_context'

class XsrMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    if request.cookies['_dpplus_xsr_id']
      Rails.logger.debug "\n=====================\nhas cookie! mmm cookies\n====================="
      XsrMiddleware::RequestContext.set_tracking_id(request.cookies['_dpplus_xsr_id'], hashed: true)
    elsif request.headers['X-TrackingId']
      Rails.logger.debug "\n=====================\nhas X-TrackingId\n====================="
      XsrMiddleware::RequestContext.set_tracking_id(request.headers['X-TrackingId'], hashed: true)
    else
      Rails.logger.debug "\n=====================\nno has cookie or header!\n====================="
      Rails.logger.debug "\n=====================\nsession options: #{request.session_options.inspect}\n====================="
      XsrMiddleware::RequestContext.set_tracking_id(request.session_options[:id], hashed: false)
    end

    XsrMiddleware::RequestContext.request_id = SaltyHash.hexdigest("#{$$}#{request.path}#{Time.now.to_s}")
    XsrMiddleware::RequestContext.set_default_operator

    Rails.logger.info("Request #{request.method.to_s.upcase} #{request.path} from #{request.remote_ip}")

    status, headers, body = @app.call(env)

    Rails.logger.debug "\n=====================\nXSR tracking_id: #{XsrMiddleware::RequestContext.tracking_id}\n====================="

    headers['X-RequestId']  = XsrMiddleware::RequestContext.request_id
    headers['X-TrackingId'] = XsrMiddleware::RequestContext.tracking_id
    Rails.logger.debug "\n=====================\nheader: #{headers['X-RequestId']}\n====================="
    Rails.logger.debug "\n=====================\nheader: #{headers['X-TrackingId']}\n====================="

    if XsrMiddleware::RequestContext.tracking_id
      Rack::Utils.set_cookie_header!(headers, "_dpplus_xsr_id", { value: XsrMiddleware::RequestContext.tracking_id,
                                                                  path: '/' })
    else
      Rack::Utils.delete_cookie_header!(headers, "_dpplus_xsr_id", { path: '/' })
    end

    Rails.logger.info("Response #{status} #{headers['Content-Type']} #{headers['Content-Length']}")

    XsrMiddleware::RequestContext.reset

    [status, headers, body]
  end

end
