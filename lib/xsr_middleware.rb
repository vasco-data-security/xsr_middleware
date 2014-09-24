require 'xsr_middleware/request_context'
require 'digest'

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

    # Rails.logger.info("Request #{request.request_method.to_s.upcase} #{request.path} from #{request.ip}")

    status, headers, body = @app.call(env)

    headers['X-RequestId']  = XsrMiddleware::RequestContext.request_id
    headers['X-TrackingId'] = XsrMiddleware::RequestContext.tracking_id

    # Rails.logger.info("Response #{status} #{headers['Content-Type']} #{headers['Content-Length']}")

    XsrMiddleware::RequestContext.reset

    [status, headers, body]
  end

  private

    def encode_string(string)
      Digest::MD5.new.hexdigest(string)
    end
end
