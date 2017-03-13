module Trademe
  class Gateway
    if Rails.env.production?
      DOMAIN = "api.trademe.co.nz"
    else
      DOMAIN = "api.tmsandbox.co.nz"
    end
    VERSION = "v1"
    FORMAT = "json"

    include Authentication
    include MyTrademe

    attr_accessor :logger

    def initialize(opts={})
      @domain = opts[:domain] || DOMAIN
      @version = opts[:version] || VERSION
      @format = FORMAT # format must be json

      self.logger = opts.delete(:logger)
      if Rails.env.production?
        if (consumer_key = opts.delete(:consumer_key)) && (consumer_secret = opts.delete(:consumer_secret))
            @consumer = OAuth::Consumer.new(consumer_key, consumer_secret, {
            :site               => "https://#{DOMAIN}/#{VERSION}",
            :request_token_url  => "https://secure.trademe.co.nz/Oauth/RequestToken",
            :access_token_url   => "https://secure.trademe.co.nz/Oauth/AccessToken",
            :authorize_url      => "https://secure.trademe.co.nz/Oauth/Authorize",
            :scheme             => :query_string,
            :signature_method => "PLAINTEXT"
          })
        end
       else
        if (consumer_key = opts.delete(:consumer_key)) && (consumer_secret = opts.delete(:consumer_secret))
          @consumer = OAuth::Consumer.new(consumer_key, consumer_secret, {
            :site               => "https://#{DOMAIN}/#{VERSION}",
            :request_token_url  => "https://secure.tmsandbox.co.nz/Oauth/RequestToken",
            :access_token_url   => "https://secure.tmsandbox.co.nz/Oauth/AccessToken",
            :authorize_url      => "https://secure.tmsandbox.co.nz/Oauth/Authorize",
            :scheme             => :query_string,
            :signature_method => "PLAINTEXT"
          })
       end 
      end
    end

    def search(term, filters = {})
      term = term.split("/").map{|t| t.capitalize }.join("/")

      url = "#{base_url}/Search/#{term}.#{@format}"
      url << "?#{urlize(filters)}" unless filters.empty?

      send_request(url)
    end

    def open_homes(term, filters = {})
      term = term.split("/").map{|t| t.capitalize }.join("/")

      url = "#{base_url}/Search/Property/OpenHomes.#{@format}"
      url << "?#{urlize(filters)}" unless filters.empty?

      send_request(url)
    end

   def get_listing(listing_id)
      url = "#{base_url}/Listings/#{listing_id}.#{@format}"
      send_request(url)
   end

    def post_listing(listing_id)
      url = "#{base_url}/Listings/#{listing_id}.#{@format}"
      send_request(url)
    end

    private

      def urlize(params)
        params.map{|k,v|
          value = if v.respond_to?(:utc) && v.respond_to?(:iso8601)
            v.utc.iso8601 # time format trademe API accepts
          else
            v.to_s
          end

          "#{k}=#{CGI::escape(value)}"
        }.join("&")
      end

      def send_request(path)
        response = if !authorized?
          uri = URI.parse("#{protocol}://#{@domain}")
          Net::HTTP.get uri.host, path
        else
          res = self.access_token.get(path)
          res.body
        end

        logger.log_api_call(path, response) if self.logger

        json = ::Yajl::Parser.new.parse(response)
        raise ApiError.new "#{json["ErrorDescription"]}" if !json.is_a?(Array) && json["ErrorDescription"]
        json
      rescue ::Yajl::ParseError => e
        raise ApiError.new "Bad JSON response #{response.inspect}"
      end

      def post_request(path, params)
        response = if !authorized?
          uri = URI.parse("#{protocol}://#{@domain}")
          Net::HTTP.post uri.host, path, params
        else
          res = self.access_token.post(path)
          res.body
        end

        logger.log_api_call(path, response) if self.logger

        json = ::Yajl::Parser.new.parse(response)
        raise ApiError.new "#{json["ErrorDescription"]}" if !json.is_a?(Array) && json["ErrorDescription"]
        json
      rescue ::Yajl::ParseError => e
        raise ApiError.new "Bad JSON response #{response.inspect}"
      end

      def protocol
        authorized? ? "https" : "http"
      end

      def base_url
        "/#{@version}"
      end

      def check_authentication
        raise MustBeAuthenticated.new unless authorized?
      end

  end

  class ApiError < StandardError; end
  class MustBeAuthenticated < StandardError; end
end