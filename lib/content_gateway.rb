require "ostruct"
require "logger"
require "timeout"
require "benchmark"
require "json"
require "rest-client"
require "active_support/cache"
require "active_support/notifications"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/date_time/calculations"
require "active_support/core_ext/hash/indifferent_access"

module ContentGateway
  extend self

  def logger
  end
end

require "content_gateway/version"
require "content_gateway/exceptions"
require "content_gateway/cache"
require "content_gateway/request"
require "content_gateway/gateway"
