require 'xsr_middleware/request_context'

class XsrMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    XsrMiddleware::RequestContext.session_id = request.session_options[:id]
    XsrMiddleware::RequestContext.request_id = SaltyHash.hexdigest("#{$$}#{request.path}#{Time.now.to_s}")
    XsrMiddleware::RequestContext.set_default_operator

    Rails.logger.info("Request #{request.method.to_s.upcase} #{request.path} from #{request.remote_ip}")

    status, headers, body = @app.call(env)

    headers['X-RequestId'] = XsrMiddleware::RequestContext.request_id

    Rails.logger.info("Response #{status} #{headers['Content-Type']} #{headers['Content-Length']}")

    XsrMiddleware::RequestContext.reset

    [status, headers, body]
  end

end
