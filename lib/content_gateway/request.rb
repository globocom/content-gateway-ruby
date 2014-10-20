module ContentGateway
  class Request
    def initialize(method, url, headers, payload, proxy)
      data = { method: method, url: url, proxy: proxy || :none }.tap do |h|
        h[:payload] = payload if payload.present?
        h[:headers] = headers if headers.present?
      end

      @request = RestClient::Request.new(data)
    end

    def execute
      @request.execute

    rescue RestClient::ResourceNotFound => e1
      raise ContentGateway::ResourceNotFound.new url, e1

    rescue RestClient::Unauthorized => e2
      raise ContentGateway::UnauthorizedError.new url, e2

    rescue RestClient::UnprocessableEntity => e3
      raise ContentGateway::ValidationError.new url, e3

    rescue RestClient::Forbidden => e4
      raise ContentGateway::Forbidden.new url, e4

    rescue RestClient::Conflict => e5
      raise ContentGateway::ConflictError.new url, e5

    rescue RestClient::Exception => e6
      status_code = e6.http_code
      if status_code < 500
        raise e6
      else
        raise ContentGateway::ServerError.new url, e6, status_code
      end

    rescue StandardError => e7
      raise ContentGateway::ConnectionFailure.new url, e7
    end

    private

    def url
      @request.url
    end
  end
end
