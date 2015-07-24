module ContentGateway
  class Gateway
    def initialize(label, config, url_generator = nil, default_params = {})
      @label = label
      @config = config
      @url_generator = url_generator
      @default_params = default_params
    end

    def get(resource_path, params = {})
      aux_params = remove_aux_parameters! params
      headers = aux_params.delete :headers

      url = self.generate_url(resource_path, params)

      measure("GET - #{url}") do
        data = { method: :get, url: url }.tap do |h|
          h[:headers] = headers if headers.present?
        end

        request_params = aux_params.merge(params)
        send_request(data, request_params)
      end
    end

    def post(resource_path, params = {})
      aux_params = remove_aux_parameters! params
      headers = aux_params.delete :headers
      payload = aux_params.delete :payload
      timeout = aux_params.delete :timeout
      ssl_certificate = aux_params.delete :ssl_certificate

      url = self.generate_url(resource_path, params)

      measure("POST - #{url}") do
        data = { method: :post, url: url, payload: payload }.tap do |h|
          h[:headers] = headers if headers.present?
        end

        request_params = { timeout: timeout }.merge(params).tap do |h|
          h[:ssl_certificate] = ssl_certificate unless ssl_certificate.nil?
        end
        send_request(data, request_params)
      end
    end

    def put(resource_path, params = {})
      aux_params = remove_aux_parameters! params
      headers = aux_params.delete :headers
      payload = aux_params.delete :payload
      timeout = aux_params.delete :timeout
      ssl_certificate = aux_params.delete :ssl_certificate

      url = self.generate_url(resource_path, params)

      measure("PUT - #{url}") do
        data = { method: :put, url: url, payload: payload }.tap do |h|
          h[:headers] = headers if headers.present?
        end

        request_params = { timeout: timeout }.merge(params).tap do |h|
          h[:ssl_certificate] = ssl_certificate unless ssl_certificate.nil?
        end

        send_request(data, request_params)
      end
    end

    def delete(resource_path, params = {})
      aux_params = remove_aux_parameters! params
      headers = aux_params.delete :headers
      timeout = aux_params.delete :timeout
      ssl_certificate = aux_params.delete :ssl_certificate

      url = self.generate_url(resource_path, params)

      measure("DELETE - #{url}") do
        data = { method: :delete, url: url }.tap do |h|
          h[:headers] = headers if headers.present?
        end

        request_params = { timeout: timeout }.tap do |h|
          h[:ssl_certificate] = ssl_certificate unless ssl_certificate.nil?
        end

        send_request(data, request_params)
      end
    end

    def get_json(resource_path, params = {})
      JSON.parse get(resource_path, params)
    rescue JSON::ParserError => e
      url = generate_url(resource_path, params) rescue resource_path
      raise ContentGateway::ParserError.new(url, e)
    end

    def post_json(resource_path, params = {})
      JSON.parse post(resource_path, params)
    rescue JSON::ParserError => e
      url = generate_url(resource_path, params) rescue resource_path
      raise ContentGateway::ParserError.new(url, e)
    end

    def put_json(resource_path, params = {})
      JSON.parse put(resource_path, params)
    rescue JSON::ParserError => e
      url = generate_url(resource_path, params) rescue resource_path
      raise ContentGateway::ParserError.new(url, e)
    end

    def delete_json(resource_path, params = {})
      JSON.parse delete(resource_path, params)
    rescue JSON::ParserError => e
      url = generate_url(resource_path, params) rescue resource_path
      raise ContentGateway::ParserError.new(url, e)
    end

    def generate_url(resource_path, params = {})
      if @url_generator.respond_to? :generate
        @url_generator.generate(resource_path, params)
      else
        resource_path
      end
    end

    private

    def remove_aux_parameters! params
      aux_params = params.select do |k, v|
        [:timeout, :expires_in, :stale_expires_in, :skip_cache, :headers, :payload, :ssl_certificate].include? k
      end

      aux_params.tap do |p|
        p[:headers] = p[:headers] || @default_params[:headers]
      end

      params.delete_if do |k,v|
        aux_params.keys.include? k
      end

      aux_params
    end

    def send_request(request_data, params = {})
      method  = request_data[:method] || :get
      url     = request_data[:url]
      headers = request_data[:headers]
      payload = request_data[:payload]

      @cache = ContentGateway::Cache.new(@config, url, method, params)
      @request = ContentGateway::Request.new(method, url, headers, payload, @config.try(:proxy), params)

      begin
        do_request(params)

      rescue ContentGateway::BaseError => e
        message = "#{prefix(e.status_code)} :: #{color_message(e.resource_url)}"
        message << " - #{e.info}" if e.info
        logger.info message

        raise e
      end
    end

    def do_request(params = {})
      if @cache.use?
        @cache.fetch(@request, timeout: params[:timeout], expires_in: params[:expires_in], stale_expires_in: params[:stale_expires_in])
      else
        @request.execute
      end
    end

    def do_json_request()
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
