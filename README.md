# Content Gateway

An easy way to get external content with two cache levels. The first is a performance cache and second is the stale.

Content Gateway lets you set a timeout for any request.
If the configured timeout is reached without response, it searches for cached data.
If cache is unavailable or expired, it returns the stale cache data.
Only then, if stale cache is also unavailable or expired, it raises an exception

## Dependencies

- Ruby >= 1.9
- ActiveSupport (for cache store)

## Installation

Add this line to your application's Gemfile:

    gem 'content_gateway'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install content_gateway

## Configuration

`ContentGateway::Gateway` class accepts a configuration object with the following parameters:

- `timeout`: request timeout in seconds
- `cache_expires_in`: cache data expiration time, in seconds
- `cache_stale_expires_in`: stale cache data expiration time, in seconds
- `stale_on_error`: if `true`, returns value from cache stale (if available) after a server error. Default value: `true`
- `cache`: cache store instance. This may be an instance of `ActiveSupport::Cache`
- `proxy`: proxy address, if needed

Configuration object example:

```ruby
config = OpenStruct.new(
  timeout: 2,
  cache_expires_in: 1800,
  cache_stale_expires_in: 86400,
  stale_on_error: false,
  cache: ActiveSupport::Cache.lookup_store(:memory_store),
  proxy: "http://proxy.example.com:3128"
)
```

## Usage

`ContentGateway::Gateway` expects four parameters:

- a label, which is used in the log messages
- a config object, just as described above
- an URL Generator object. This may be any object that responds to a `generate` method, like this:
- an optional hash with default params. Currently, it only supports default headers

```ruby
class UrlGenerator
  def generate(resource_path, params = {})
    args = ""
    args = "?#{params.map {|k, v| "#{k}=#{v}"}.join("&")}" if params.any?
    "http://example.com/#{resource_path}#{args}"
  end
end

default_params = { headers: { Accept: "application/json" } }

gateway = ContentGateway::Gateway.new("My API", config, UrlGenerator.new, default_params)
```

Every param may be overrided on each request.

This Gateway object supports the following methods:

### GET

To do a GET request, you may use the `get` or `get_json` methods. The second one parses the response as JSON.
Optional parameters are supported:

- `timeout`: overwrites the default timeout
- `expires_in`: overwrites the default cache expiration time
- `stale_expires_in`: overwrites the default stale cache expiration time
- `skip_cache`: if set to `true`, ignores cache and stale cache
- `headers`: a hash with request headers
- `ssl_certificate`: a hash with ssl cert, key, ssl version (see ssl support section below)

Every other parameter is passed to URLGenerator `generate` method (like query string parameters).

Examples:

```ruby
gateway.get("/path", timeout: 3)

gateway.get_json("/path.json", skip_cache: true)
```

### POST, PUT and DELETE

POST, PUT and DELETE verbs are also supported, but ignore cache and stale cache.
The gateway object offers the equivalent methods for these verbs (`post`, `post_json`, `put`, `put_json`, `delete` and `delete_json`).
The only optional parameters supported by these methods are `payload` and `ssl_certificate`.
Every other parameter is passed to URLGenerator `generate` method (like query string parameters).

Examples:

```ruby
gateway.post("/api/post_example", payload: { param1: "value" })

gateway.put_json("/api/put_example.json", query_string_param: "value")

gateway.delete("/api/delete_example", id: "100")
```

### SSL Support

You can use ssl certificates to run all supported requests (get, post, put, delete).

Just pass the path of cert file (x509 certificate) and key file (rsa key) to the request method. See exemple below:

```ruby
ssl = {
  ssl_client_cert: "path/client.cert",
  ssl_client_key: "path/client.key"
}

gateway.get("/path", timeout: 3, ssl_certificate: ssl)

gateway.get_json("/path.json", skip_cache: true, ssl_certificate: ssl)

gateway.post("/api/post_example", payload: { param1: "value" }, ssl_certificate: ssl)
```

You can use ssl_version to specify which version you need. (You can use with client cert and key or use it alone) See example below:

```ruby
ssl = {
  ssl_version: "SSLv23"
}

gateway.get("/path", timeout: 3, ssl_certificate: ssl)

gateway.get_json("/path.json", skip_cache: true, ssl_certificate: ssl)

gateway.post("/api/post_example", payload: { param1: "value" }, ssl_certificate: ssl)
```

## Authors

- [Túlio Ornelas](https://github.com/tulios)
- [Roberto Soares](https://github.com/roberto)
- [Emerson Macedo](https://github.com/emerleite)
- [Guilherme Garnier](https://github.com/ggarnier)
- [Daniel Martins](https://github.com/danielfm)
- [Rafael Biriba](https://github.com/rafaelbiriba)
- [Célio Latorraca](https://github.com/celiofonseca)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright (c) 2015 Globo.com - Webmedia. See [LICENSE.txt](https://github.com/globocom/content-gateway-ruby/blob/master/LICENSE.txt) for more details.
