require 'singleton'

module Xsr
  ##
  # The main responsability of the RequestContext class is to take care of the correlation_id
  # which is being added or removed from the current Thread.
  class RequestContext
    include Singleton

    ##
    # Adds the correlation_id to the current Thread
    # and passes it to the logger.
    #
    # - correlation_id = an encoded string

    def correlation_id=(correlation_id)
      Thread.current['ctx_correlation_id'] = correlation_id
      ::Log4r::MDC.put('correlation', correlation_id) if defined? ::Log4r
    end

    def correlation_id
      Thread.current['ctx_correlation_id']
    end

    def reset
      self.operator = nil if Xsr::RequestContext.method_defined? :operator=
      reset_correlation_id!
    end

    def self.method_missing(method,*args,&block)
      self.instance.send(method,*args,&block)
    end

    private

    def reset_correlation_id!
      Thread.current['ctx_correlation_id'] = nil
      ::Log4r::MDC.remove('correlation') if defined? ::Log4r
    end
  end
end
