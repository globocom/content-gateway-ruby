module ContentGateway
  class BaseError < StandardError
    attr_reader :resource_url, :wrapped_exception, :status_code, :info

    def initialize(resource_url, wrapped_exception = nil, status_code = nil, info = nil)
      @resource_url = resource_url
      @wrapped_exception = wrapped_exception
      @status_code = status_code
      @info = info

      message = @resource_url.dup
      if @wrapped_exception
        message << " - #{@wrapped_exception.message}"
        message << " - #{@info}" if @info
      end

      super(message)
    end
  end

  class UnauthorizedError < BaseError
    def initialize(resource_url, wrapped_exception = nil)
      super(resource_url, wrapped_exception, 401)
    end
  end

  class Forbidden < BaseError
    def initialize(resource_url, wrapped_exception = nil)
      super(resource_url, wrapped_exception, 403)
    end
  end

  class ResourceNotFound < BaseError
    def initialize(resource_url, wrapped_exception = nil)
      super(resource_url, wrapped_exception, 404)
    end
  end

  class TimeoutError < BaseError
    def initialize(resource_url, wrapped_exception = nil, timeout = nil)
      info = "TIMEOUT (max #{timeout} s)" if timeout

      super(resource_url, wrapped_exception, 408, info)
    end
  end

  class ConflictError < BaseError
    def initialize(resource_url, wrapped_exception = nil)
      super(resource_url, wrapped_exception, 409)
    end
  end

  class ValidationError < BaseError
    attr_reader :errors

    def initialize(resource_url, wrapped_exception = nil)
      super(resource_url, wrapped_exception, 422)

      if wrapped_exception
        response = wrapped_exception.response
        @errors = JSON.parse(response) if response.present?
      end
    end
  end

  class ServerError < BaseError
    def initialize(resource_url, wrapped_exception = nil, status_code = nil)
      super(resource_url, wrapped_exception, status_code, "SERVER ERROR")
    end
  end

  class ConnectionFailure < BaseError
    def initialize(resource_url, wrapped_exception = nil)
      super(resource_url, wrapped_exception, 500)
    end
  end

  class OpenSSLFailure < BaseError
    def initialize(resource_url, wrapped_exception = nil, info=nil)
      super(resource_url, wrapped_exception, 406, info)
    end
  end

  class ParserError < BaseError; end

  class StaleCacheNotAvailableError < StandardError; end
end
