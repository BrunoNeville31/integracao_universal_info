require_relative 'base_is'
require 'time'
require 'active_support/time'
require 'byebug'
require "uri"
require "net/http"
require "json"
require 'dotenv/load'

class Produtos < BaseIs

    FILIAL = ENV.fetch('COD_FILIAL')
    URL_SHOP9 = ENV.fetch('URL_SHOP9')
    SENHA = ENV.fetch('SENHA_SHOP9') #"31011996"

    def pagina_produtos(npagina)
        time = (Time.now + 3.hours).to_i.to_s
        metodo = "get"
       
        @signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SENHA, "#{metodo}#{time}"))

        url = URI("#{URL_SHOP9}/produtos/#{npagina}")

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
            return JSON.parse(response.read_body)['dados']
        rescue => exception
            puts exception
            return false
        end
    end

    def consulta_produto(nproduto)
        time = (Time.now + 3.hours).to_i.to_s
        metodo = "get"
       
        @signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SENHA, "#{metodo}#{time}"))

        url = URI("#{URL_SHOP9}/produtos/detalhes/#{nproduto}")

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
            return JSON.parse(response.read_body)['dados']
        rescue => exception
            puts exception
            return false
        end
    end

    
    def foto_posicao(idprod, posicao)
        time = (Time.now + 3.hours).to_i.to_s
        metodo = "get"
       
        @signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SENHA, "#{metodo}#{time}"))

        url = URI("#{URL_SHOP9}/fotos/#{idprod}/#{posicao}")
        
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
            
            return response.read_body
           
        rescue => exception
            puts exception
            return false
        end
    end

    def estoque(idprod)
        time = (Time.now + 3.hours).to_i.to_s
        metodo = "get"
       
        @signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SENHA, "#{metodo}#{time}"))

        url = URI("#{URL_SHOP9}/estoque/#{idprod}")
        
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
            return JSON.parse(response.read_body)['dados']['estoqueFiliais'].select{|f| f['codigoFilial'] == 3}[0]['estoqueAtual']
        rescue => exception
            puts "Produto não cadastro na Filial 3"
            return 0
        end
    end


    def foto_produto(idprod)
        time = (Time.now + 3.hours).to_i.to_s
        metodo = "get"
       
        @signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SENHA, "#{metodo}#{time}"))

        url = URI("#{URL_SHOP9}/fotos/#{idprod}")
        
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
            fotos = JSON.parse(response.read_body)['dados']
            if fotos['fotos'].empty?
                return false
            else
                return fotos['fotos']
            end
        rescue => exception
            puts exception
            return false
        end
    end
end