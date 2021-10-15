require_relative 'base_wc'
require "uri"
require "net/http"
require "json"
require 'dotenv/load'

require_relative '../ideal_soft/grupo'

require 'byebug'
class CategoriaWoocommerce < BaseWc
    URL = ENV.fetch('URL_UNIVERSAL')   

    def cadastra_categoria(data)
        url = URI("#{URL}/wp-json/wc/v3/products/categories")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        grupo_cad = Grupo.new.grupo_cadastrado(data)

        payload = {
            "name": "#{grupo_cad}",
            "slug": "#{grupo_cad}"
        }
        
        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        request.body = payload.to_json
        response = https.request(request)
       
        if response.code == "201"
            return JSON.parse(response.read_body)['id']  
        else
            return false
        end 

    end

    def categorias(data)

        url = URI("#{URL}/wp-json/wc/v3/products/categories")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        
        request = Net::HTTP::Get.new(url)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        response = https.request(request)
        
        if response.code == "200"
           
            resp = JSON.parse(response.read_body)
            resp.each do |cat|                
               
                if cat['name'].to_i == data
                    return cat['id']
                else
                    return cadastra_categoria(data)
                end
            end
            return true
        else
            puts response.read_body
            return false
            
        end       
        
    end


end