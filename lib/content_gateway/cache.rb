module ContentGateway
  class Cache
    def initialize(url, method, params = {})
      @url = url
      @method = method.to_sym
      @skip_cache = params[:skip_cache] || false
    end

    def use?
      !@skip_cache && [:get, :head].include?(@method)
    end

    def stale_key
      @stale_key ||= "stale:#{@url}"
    end
  end
end
