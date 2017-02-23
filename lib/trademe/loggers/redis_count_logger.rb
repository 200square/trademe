module Trademe
  module Loggers
    class RedisCountLogger

      attr_accessor :redis, :key

      def initialize(redis, key)
        @redis = redis
        @key   = key || "trademe_gateway_api_calls"
      end

      def log_api_call(*args)
        # log calls by hour - TradeMe rate limits on an hourly basis
        full_datetime_key = "#{@key}:#{Time.now.strftime("%Y-%m-%d:%H")}"
        self.redis.incr(full_datetime_key)
      end

    end
  end
end