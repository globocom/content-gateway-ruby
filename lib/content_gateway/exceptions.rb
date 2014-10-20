module ContentGateway
  class BaseError < StandardError
    attr_reader :wrapped_exception

    def initialize(resource_url, wrapped_exception)
      super "#{resource_url} - #{wrapped_exception.message}"
      @wrapped_exception = wrapped_exception
    end
  end

  class ResourceNotFound < BaseError; end
  class ConnectionFailure < BaseError; end
  class TimeoutError < BaseError; end
  class Forbidden < BaseError; end
  class ServerError < BaseError; end
  class UnauthorizedError < BaseError; end
  class ConflictError < BaseError; end

  class ValidationError < BaseError
    attr_reader :errors

    def initialize(resource_url, wrapped_exception)
      super resource_url, wrapped_exception

      response = wrapped_exception.response
      @errors = JSON.parse(response) if response.present?
    end
  end

  class StaleCacheNotAvailableError < StandardError
  end
end
