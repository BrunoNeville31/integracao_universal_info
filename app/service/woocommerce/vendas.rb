require 'byebug'
require_relative 'base_wc'
require "uri"
require "net/http"
require "json"
require 'dotenv/load'
require "securerandom"

class VendasWoocommerce < BaseWc

    def consulta_vendas
        begin
            url = URI("#{URL}/wp-json/wc/v3/orders")

            https = Net::HTTP.new(url.host, url.port)
            https.use_ssl = true
            
            request = Net::HTTP::Get.new(url)
            request["Authorization"] = "Bearer #{@token}"
            request["Content-Type"] = "application/json"
            response = https.request(request)
            
            puts response.code           

            if response.read_body == "[]" && response.code.to_i == 200
                return false
            else
                return JSON.parse(response.read_body)
            end
        rescue => exception            
            puts exception
            return false
        end
    end
end