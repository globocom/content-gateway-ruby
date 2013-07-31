# -*- coding: utf-8 -*-

module ContentGateway
  class Gateway
    def initialize config, url_generator #host = Config.host, access_token = nil
      @config = OpenStruct.new(config)
      @url_generator = url_generator
    end

    def get resource_path, params = {}
      timeout = params.delete :timeout
      expires_in = params.delete :expires_in
      stale_expires_in = params.delete :stale_expires_in
      skip_cache = params.delete :skip_cache

      url = self.generate_url resource_path, params

      measure("GET - #{url}") {
        send_request({method: :get, url: url}, {skip_cache: skip_cache, expires_in: expires_in, stale_expires_in: stale_expires_in, timeout: timeout})
      }
    end

    def post resource_path, params = {}
      payload = params.delete :payload
      url = self.generate_url resource_path, params

      measure("POST - #{url}") {
        send_request({method: :post, url: url, payload: payload}, params)
      }
    end

    def put resource_path, params = {}
      payload = params.delete :payload
      url = self.generate_url resource_path, params

      measure("PUT - #{url}") {
        send_request({method: :put, url: url, payload: payload}, params)
      }
    end

    def get_json resource_path, params = {}
      JSON.parse get(resource_path, params)
    end

    def post_json resource_path, params = {}
      JSON.parse post(resource_path, params)
    end

    def put_json resource_path, params = {}
      JSON.parse put(resource_path, params)
    end

    def generate_url resource_path, params = {}
      return @url_generator.generate(resource_path, params)

      # url = "#{@host}/api/#{resource_path}.json"
      # params.merge!(access_token: @access_token) if @access_token

      # query_string = params.keys.map {|key| "#{URI.escape(key.to_s)}=#{URI.escape(params[key].to_s)}"}.join("&")
      # query_string.empty? ? url : "#{url}?#{query_string}"
    end

    private
    def send_request request_data, params = {}
      method  = request_data[:method] || :get
      url     = request_data[:url]
      payload = request_data[:payload]
      stale_cache_key = "stale:#{url}"
      timeout_value = params[:timeout] || @config.timeout

      request = lambda {
        begin
          data = {method: method, url: url, proxy: :none}.tap do |h|
            h[:payload] = payload if payload.present?
          end

          request = RestClient::Request.new(data)
          request.execute

        rescue RestClient::ResourceNotFound => e1
          logger.info "#{prefix(404)} :: #{color_message(url)}"
          raise ContentGateway::ResourceNotFound.new url, e1

        rescue RestClient::UnprocessableEntity => e2
          logger.info "#{prefix(422)} :: #{color_message(url)}"
          raise ContentGateway::ValidationError.new url, e2

        rescue RestClient::Forbidden => e3
          logger.info "#{prefix(403)} :: #{color_message(url)}"
          raise ContentGateway::Forbidden.new url, e3

        rescue RestClient::InternalServerError => e4
          return @config.cache.read(stale_cache_key).tap do |cached|
            unless cached
              logger.info "#{prefix(500)} :: #{color_message(url)} - SERVER ERROR"
              raise ContentGateway::ServerError.new url, e4
            end
            @cache_status = "STALE"
          end
        rescue StandardError => e5
          logger.info "#{prefix(500)} :: #{color_message(url)}"
          raise ContentGateway::ConnectionFailure.new url, e5
        end
      }

      if !params[:skip_cache] && [:get, :head].include?(method)
        begin
          Timeout.timeout(timeout_value) do
            @config.cache.fetch(url, expires_in: params[:expires_in] || @config.cache_expires_in) do
              @cache_status = "MISS"
              response = request.call

              @config.cache.write(stale_cache_key, response, expires_in: params[:stale_expires_in] || @config.cache_stale_expires_in) if @cache_status == "MISS"
              response
            end
          end
        rescue Timeout::Error => e
          return @config.cache.read(stale_cache_key).tap do |cached|
            unless cached
              logger.info "#{prefix(500)} :: #{color_message(url)} - TIMEOUT (max #{timeout_value} secs)"
              raise ContentGateway::TimeoutError.new url, e
            end
            @cache_status = "STALE"
          end
        end
      else
        request.call
      end
    end

    def measure message
      result = nil
      time_elapsed = Benchmark.measure { result = yield }
      sufix = "finished in #{humanize_elapsed_time(time_elapsed.real)}. "
      cache_log = (@cache_status || "HIT").to_s.ljust(4, " ")
      log_message = "#{prefix(result.try(:code))} :: #{cache_log} #{color_message(message)} #{sufix}"

      logger.info log_message
      result
    end

    def humanize_elapsed_time time_elapsed
      time_elapsed >= 1 ? "%.3f secs" % time_elapsed : "#{(time_elapsed * 1000).to_i}ms"
    end

    def prefix code = nil
      "[GloboTV API] #{color_code(code)}"
    end

    def color_message message
      "\033[1;33m#{message}\033[0m"
    end

    def color_code code
      color = code == 200 ? "32" : "31"
      code_message = code.to_s.ljust(3, " ")
      "\033[#{color}m#{code_message}\033[0m"
    end

    def logger
      @logger || -> {
        if defined?(Rails)
          Rails.logger
        else
          log = ::Logger.new STDOUT
          log.formatter = lambda {|severity, datetime, progname, msg|
            "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} #{severity.upcase} #{msg}\n"
          }
          
          log
        end
      }.yield
    end
  end
end
