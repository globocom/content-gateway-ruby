module ContentGateway
  class BaseError < StandardError
    attr_reader :resource_url, :wrapped_exception, :status_code

    def initialize(resource_url, wrapped_exception = nil, status_code = nil)
      if wrapped_exception
        super "#{resource_url} - #{wrapped_exception.message}"
        @wrapped_exception = wrapped_exception
      else
        super(resource_url)
      end

      @status_code = status_code
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
    def initialize(resource_url, wrapped_exception = nil)
      super(resource_url, wrapped_exception, 408)
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

  class ServerError < BaseError; end

  class ConnectionFailure < BaseError; end

  class StaleCacheNotAvailableError < StandardError; end
end
