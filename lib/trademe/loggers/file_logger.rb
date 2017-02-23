module Trademe
  module Loggers
    class FileLogger

      require 'logger'

      attr_accessor :logger

      def initialize(filename)
        @logger = Logger.new(filename)
      end

      def log_api_call(path, response)
        @logger.info("==== TradeMe API Call: #{path}")
        @logger.info("Response:\n")
        @logger.info(response)
        @logger.info("====\n\n\n\n")
      end

    end
  end
end