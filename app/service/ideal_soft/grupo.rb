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

        url = URI("#{URL_SHOP9}/aux/classes")

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

            classes = JSON.parse(response.read_body)['dados']
            
            #classes.each do |classe|
            #    debugger
            #    x = 1
            #    if classe['codigo'] == tipo
            #       return classe['nome']
            #   end
            #end
            classe = classes.select{|a| a['codigo'] == tipo.to_s}
            return classe[0]['nome']
            #return "outros"
        rescue => exception
            puts exception
            return "outros"
        end
    end


    
end