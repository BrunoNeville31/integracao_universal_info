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

    def atualiza_venda(numero_venda, status)
        begin
            url = URI("#{URL}/wp-json/wc/v3/orders/#{numero_venda}")
            
            payload  = {
                "status": status
            }

            https = Net::HTTP.new(url.host, url.port)
            https.use_ssl = true
            
            request = Net::HTTP::Put.new(url)
            request["Authorization"] = "Bearer #{@token}"
            request["Content-Type"] = "application/json"
            request.body = payload.to_json
            response = https.request(request)
            
            puts response.code
            
        rescue => exception            
            puts exception
            return false
        end
    end
end