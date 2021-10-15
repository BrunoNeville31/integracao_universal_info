require_relative 'base_is'
require 'time'
require 'active_support/time'
require 'byebug'
require "uri"
require "net/http"
require "json"
require 'dotenv/load'

class Grupo < BaseIs

    FILIAL = ENV.fetch('COD_FILIAL')
    URL_SHOP9 = ENV.fetch('URL_SHOP9')
    SENHA = ENV.fetch('SENHA_SHOP9') #"31011996"

    def grupo_cadastrado(tipo)
        time = (Time.now + 3.hours).to_i.to_s
        metodo = "get"
       
        @signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SENHA, "#{metodo}#{time}"))

        url = URI("#{URL_SHOP9}/aux/grupos")

        http = Net::HTTP.new(url.host, url.port);

        request = Net::HTTP::Get.new(url)

        request["Authorization"] = "Token #{@token}"
        request["signature"] = @signature
        request["CodFilial"] = FILIAL
        request["Timestamp"] = time
        request["Accept"] = "application/json"
        request["Content-Type"] = "application/json"

        begin
            response = http.request(request)            

            grupos = JSON.parse(response.read_body)['dados']
            
            grupos.each do |grupo|
                
                if grupo['codigo'] == tipo
                    return grupo['nome']
                else
                    return 'outros'
                end
            end

        rescue => exception
            puts exception
            return false
        end
    end


    
end