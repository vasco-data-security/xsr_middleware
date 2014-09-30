require 'singleton'

module Xsr

  ##
  # The main responsability of the RequestContext class is to take care of the tracking_id
  # which is being added or removed from the current Thread.

  class RequestContext
    include Singleton

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

    ##
    # Adds the mdp request id to the current Thread
    # and passes it to the logger
    #
    # - mdp_request_id = an encoded string

    def set_mdp_request_id(mdp_request_id)
      Thread.current['ctx_mdp_request_id'] = mdp_request_id
      ::Log4r::MDC.put('request', mdp_request_id)
    end

    def mdp_request_id
      Thread.current['ctx_mdp_request_id']
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
      self.operator   = nil if Xsr::RequestContext.method_defined? :operator=
      self.controller = nil
      reset_tracking_id!
      reset_mdp_request_id!
    end

    def self.method_missing(method,*args,&block)
      self.instance.send(method,*args,&block)
    end

    private

      def reset_tracking_id!
        Thread.current['ctx_tracking_id'] = nil
        ::Log4r::MDC.remove('tracking')
      end

      def reset_mdp_request_id!
        Thread.current['ctx_mdp_request_id'] = nil
        ::Log4r::MDC.remove('request')
      end
  end
end
