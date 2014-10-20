module ContentGateway
  class Gateway
    def initialize(label, config, url_generator, default_params = {})
      @label = label
      @config = config
      @url_generator = url_generator
      @default_params = default_params
    end

    def get(resource_path, params = {})
      timeout = params.delete :timeout
      expires_in = params.delete :expires_in
      stale_expires_in = params.delete :stale_expires_in
      skip_cache = params.delete :skip_cache
      headers = (params.delete :headers) || @default_params[:headers]

      url = self.generate_url(resource_path, params)

      measure("GET - #{url}") do
        data = { method: :get, url: url }.tap do |h|
          h[:headers] = headers if headers.present?
        end
        send_request(data, skip_cache: skip_cache, expires_in: expires_in, stale_expires_in: stale_expires_in, timeout: timeout)
      end
    end

    def post(resource_path, params = {})
      payload = params.delete :payload
      url = self.generate_url(resource_path, params)

      measure("POST - #{url}") do
        send_request({ method: :post, url: url, payload: payload }, params)
      end
    end

    def put(resource_path, params = {})
      payload = params.delete :payload
      url = self.generate_url(resource_path, params)

      measure("PUT - #{url}") do
        send_request({ method: :put, url: url, payload: payload }, params)
      end
    end

    def delete(resource_path, params = {})
      payload = params.delete :payload
      url = self.generate_url(resource_path, params)

      measure("DELETE - #{url}") do
        send_request({ method: :delete, url: url, payload: payload }, params)
      end
    end

    def get_json(resource_path, params = {})
      JSON.parse get(resource_path, params)
    end

    def post_json(resource_path, params = {})
      JSON.parse post(resource_path, params)
    end

    def put_json(resource_path, params = {})
      JSON.parse put(resource_path, params)
    end

    def generate_url(resource_path, params = {})
      @url_generator.generate(resource_path, params)
    end

    private

    def send_request(request_data, params = {})
      method  = request_data[:method] || :get
      url     = request_data[:url]
      headers = request_data[:headers]
      payload = request_data[:payload]

      @cache = Cache.new(@config, url, method, params)
      @request = Request.new(method, url, headers, payload, @config.try(:proxy))

      begin
        if @cache.use?
          do_request_with_cache(params)
        else
          do_request_without_cache
        end

      rescue ContentGateway::BaseError => e
        message = "#{prefix(e.status_code)} :: #{color_message(e.resource_url)}"
        message << " - #{e.info}" if e.info
        logger.info message

        raise e
      end
    end

    def do_request_with_cache(params = {})
      @cache.fetch(@request, timeout: params[:timeout], expires_in: params[:expires_in], stale_expires_in: params[:stale_expires_in])
    end

    def do_request_without_cache
      @request.execute
    end

    def measure(message)
      result = nil
      time_elapsed = Benchmark.measure { result = yield }
      sufix = "finished in #{humanize_elapsed_time(time_elapsed.real)}. "
      cache_log = (@cache.status || "HIT").to_s.ljust(4, " ")
      log_message = "#{prefix(code(result))} :: #{cache_log} #{color_message(message)} #{sufix}"

      logger.info log_message
      result
    end

    def code(result)
      result.respond_to?(:code) ? result.code : ""
    end

    def humanize_elapsed_time(time_elapsed)
      time_elapsed >= 1 ? "%.3f secs" % time_elapsed : "#{(time_elapsed * 1000).to_i} ms"
    end

    def prefix(code = nil)
      "[#{@label}] #{color_code(code)}"
    end

    def color_message(message)
      "\033[1;33m#{message}\033[0m"
    end

    def color_code(code)
      color = code == 200 ? "32" : "31"
      code_message = code.to_s.ljust(3, " ")
      "\033[#{color}m#{code_message}\033[0m"
    end

    def logger
      @logger || lambda do
        if defined?(Rails)
          Rails.logger
        else
          log = ::Logger.new STDOUT
          log.formatter = lambda {|severity, datetime, progname, msg|
            "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} #{severity.upcase} #{msg}\n"
          }

          log
        end
      end.yield
    end
  end
end
