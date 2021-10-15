require "uri"
require "net/http"
require "json"
require 'dotenv/load'

require 'byebug'


class BaseWc
    URL = ENV.fetch('URL_UNIVERSAL')

    def initialize
        payload = {
            "username": "integracao",
            "password": "BjcZgUH@txS6gHBviBdk%FfF"
        }

        url = URI("#{URL}/wp-json/jwt-auth/v1/token")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Post.new(url)
        request["Content-Type"] = "application/json"
        request.body = payload.to_json

        response = https.request(request)
        @token = JSON.parse(response.body)['token']
    end
end