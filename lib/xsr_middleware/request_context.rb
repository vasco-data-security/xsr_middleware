class XsrMiddleware
  class RequestContext
    include Singleton

    def set_default_operator
      self.operator = default_operator
    end

    def default_operator
      @@vasco_operator ||= MdpBackoffice::Operator.find_by_login('vasco_federation_portal')
    end

    def operator=( given_operator )
      given_operator = default_operator if given_operator.nil?

      Thread.current['ctx_operator'] = given_operator

      EnAble::Stamped.current_stamper = given_operator && given_operator.id

      if given_operator
        Log4r::MDC.put('operator',given_operator.login)
      else
        Log4r::MDC.remove('operator')
      end
    end

    def operator
      Thread.current['ctx_operator']
    end

    def session_id=( session_id )
      Thread.current['ctx_session_id'] = session_id

      if session_id
        session_id = SaltyHash.hexdigest("#{$$}#{session_id}#{Time.now.to_s}")
        Log4r::MDC.put('session', session_id)
      else
        Log4r::MDC.remove('session')
      end
    end

    def session_id
      Thread.current['ctx_session_id']
    end

    def request_id=( request_id )
      Thread.current['ctx_request_id'] = request_id

      if request_id
        Log4r::MDC.put('request', request_id)
      else
        Log4r::MDC.remove('request')
      end
    end

    def request_id
      Thread.current['ctx_request_id']
    end

    def controller=( controller )
      Thread.current['ctx_controller'] = controller
    end

    def controller
      Thread.current['ctx_controller']
    end

    def reset
      self.operator   = nil
      self.request_id = nil
      self.session_id = nil
      self.controller = nil
    end

    def self.method_missing(method,*args,&block)
      self.instance.send(method,*args,&block)
    end
  end
end
