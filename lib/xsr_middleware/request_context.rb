require 'singleton'

class XsrMiddleware

  ##
  # The main responsability of the RequestContext class is to take care of the tracking_id
  # which is being added or removed from the current Thread.

  class RequestContext
    include Singleton

    # TODO : This class should not know anything about the operator.
    # This code belongs to dpplus and mdp_backoffice.
    def set_default_operator
      self.operator = default_operator
    end

    def default_operator
      @@vasco_operator ||= MdpBackoffice::Operator.find_by_login('vasco_federation_portal')
    end

    def operator=( given_operator )
      return unless Module.constants.include? :MdpBackoffice

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

    ##
    # Adds the tracking_id to the current Thread
    # and passes it to the logger.
    #
    # - tracking_id = an encoded string

    def set_tracking_id(tracking_id)
      Thread.current['ctx_tracking_id'] = tracking_id
      ::Log4r::MDC.put('tracking', tracking_id)
    end

    def tracking_id
      Thread.current['ctx_tracking_id']
    end

    def request_id=( request_id )
      Thread.current['ctx_request_id'] = request_id

      if request_id
        ::Log4r::MDC.put('request', request_id)
      else
        ::Log4r::MDC.remove('request')
      end
    end

    def request_id
      Thread.current['ctx_request_id']
    end

    # TODO : This class should not know anything about the controller.
    # This code belongs to dpplus and mdp_backoffice.
    def controller=( controller )
      Thread.current['ctx_controller'] = controller
    end

    def controller
      Thread.current['ctx_controller']
    end

    def reset
      self.operator   = nil
      self.request_id = nil
      self.controller = nil
      reset_tracking_id!
    end

    def self.method_missing(method,*args,&block)
      self.instance.send(method,*args,&block)
    end

    private

      def reset_tracking_id!
        Thread.current['ctx_tracking_id'] = nil
        ::Log4r::MDC.remove('tracking')
      end
  end
end
