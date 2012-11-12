require File.dirname(__FILE__) + "/../test_helper.rb"

class LoggersTest < Test::Unit::TestCase

    context "a new gateway" do

      setup do
        @gateway = Trademe::Gateway.new

        Net::HTTP.expects(:get).with("api.trademe.co.nz", "/v1/Search/Property/Residential.json?search_string=nice").returns(open_mock("listing_search.json"))
      end

      context "and a File Logger" do
        setup do
          @filename       = "trademe_test.log"
          @gateway.logger = Trademe::Loggers::FileLogger.new(@filename)
        end

        should "log API calls to a file" do
          @gateway.search("property/residential", :search_string => "nice")

          assert File.open(@filename).read.include?("TradeMe API Call: /v1/Search/Property/Residential.json?search_string=nice")
        end

        teardown do
          FileUtils.rm(@filename) if File.exists?(@filename)
        end
      end

      context "and a Redis Count Logger" do
        setup do
          @redis = mock
          @gateway.logger = Trademe::Loggers::RedisCountLogger.new(@redis, "test_key")
        end

        should "count API calls in Redis keys" do
          @redis.expects(:incr).with("test_key:#{Time.now.strftime("%Y-%m-%d:%H")}")
          @gateway.search("property/residential", :search_string => "nice")
        end
      end

      context "and multiple loggers" do
        setup do
          @redis          = mock
          @filename       = "trademe_test.log"
          redis_logger    = Trademe::Loggers::RedisCountLogger.new(@redis, "test_key")
          file_logger     = Trademe::Loggers::FileLogger.new(@filename)
          @gateway.logger = Trademe::Loggers::MultipleLogger.new(redis_logger, file_logger)
        end

        should "log to both loggers" do
          @redis.expects(:incr).with("test_key:#{Time.now.strftime("%Y-%m-%d:%H")}")
          @gateway.search("property/residential", :search_string => "nice")

          assert File.open(@filename).read.include?("TradeMe API Call: /v1/Search/Property/Residential.json?search_string=nice")
        end

        teardown do
          FileUtils.rm(@filename) if File.exists?(@filename)
        end
      end

    end

end