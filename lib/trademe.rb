require 'net/http'
require 'cgi'
require 'time' # needed in 1.9.2-p180

require 'yajl'
require 'oauth'

module Trademe
  VERSION = "0.2.1"
end

require "trademe/gateway/authentication"
require "trademe/gateway/my_trademe"
require "trademe/gateway"
require "trademe/loggers"