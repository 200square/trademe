module Trademe
  module Loggers
    class MultipleLogger

      attr_accessor :loggers

      def initialize(*loggers)
        @loggers = loggers.flatten # allow specifying as args or as an array
      end

      def log_api_call(*args)
        loggers.each do |l|
          l.log_api_call(*args)
        end
      end

    end
  end
end