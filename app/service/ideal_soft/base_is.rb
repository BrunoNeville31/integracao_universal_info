require "uri"
require "net/http"
require "json"
require 'dotenv/load'


class BaseIs
    URL = ENV.fetch('URL_SHOP9')
    AUTH = ENV.fetch('AUTH')

    def initialize
        url = URI("#{URL}/auth/?serie=HIEAPA-606254-UWVK&codfilial=3")

        http = Net::HTTP.new(url.host, url.port)
        request = Net::HTTP::Get.new(url)
        request["Authorization"] = "Basic #{AUTH}"
        request["Content-Type"] = "application/json"
    
        response = http.request(request)
        @token = JSON.parse(response.body)['dados']['token']    
    end
end