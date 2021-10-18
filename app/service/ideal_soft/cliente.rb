require_relative 'base_is'
require 'time'
require 'active_support/time'
require 'byebug'
require "uri"
require "net/http"
require "json"
require 'dotenv/load'

require 'byebug'

class Cliente < BaseIs

    FILIAL = ENV.fetch('COD_FILIAL')
    URL_SHOP9 = ENV.fetch('URL_SHOP9')
    SENHA = ENV.fetch('SENHA_SHOP9') #"31011996"


    def consulta_cliente(data)
        time = (Time.now + 3.hours).to_i.to_s
        metodo = "get"
       
        @signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SENHA, "#{metodo}#{time}"))

        initial = 1
        nome_cliente = "#{data['first_name']} #{data['last_name']}"

        real_nome = false

        begin
            while initial > -1 do
                puts "Procurando Cliente na Pagina = #{initial}"
                url = URI("#{URL_SHOP9}/clientes/#{initial}")
            
                http = Net::HTTP.new(url.host, url.port);
    
                request = Net::HTTP::Get.new(url)
    
                request["Authorization"] = "Token #{@token}"
                request["signature"] = @signature
                request["CodFilial"] = FILIAL
                request["Timestamp"] = time
                request["Accept"] = "application/json"
                request["Content-Type"] = "application/json"
                response = http.request(request)
                clientes = JSON.parse(response.read_body)['dados']
    
                clientes.each do |cliente|
    
                    if cliente['nome'] == nome_cliente
                        real_nome = nome_cliente
                        return cliente['codigo']
                    end
                    
                end
                if real_nome == false
                    initial += 1
                end
            end
        rescue => exception
            initial = -1
            puts("Cadastrando Cliente #{data['first_name']}")
            return cadastro_cliente(payload_cliente(data))            
        end        
    end


    def payload_cliente(data)
        return {
            "Nome": "#{data['first_name']} #{data['last_name']}",
            "Fantasia": "#{data['company']}",
            "Tipo": "C",
            "FisicaJuridica": "F",
            "CpfCnpj": "",
            "Rg": "",            
            "Cep": data['postcode'],
            "Endereco": data['address_1'],
            "Numero": nil,
            "Complemento": "Bl 131",
            "Bairro": "Bacacheri",
            "Cidade": data['city'],
            "Uf": data['state'],
            "Pais": "",
            "Telefone1": "",
            "Telefone2": nil,
            "Fax": nil,
            "EntregaCep": nil,
            "EntregaEndereco": nil,
            "EntregaNumero": nil,
            "EntregaComplemento": nil,
            "EntregaBairro": nil,
            "EntregaCidade": nil,
            "EntregaUf": nil,
            "EntregaPais": nil,
            "EntregaPontoRef1": nil,
            "EntregaPontoRef2": nil,
            "FaturamentoCep": nil,
            "FaturamentoEndereco": nil,
            "FaturamentoNumero": nil,
            "FaturamentoComplemento": nil,
            "FaturamentoBairro": nil,
            "FaturamentoCidade": nil,
            "FaturamentoUf": nil,
            "FaturamentoPais": nil,
            "FaturamentoPontoRef1": nil,
            "FaturamentoPontoRef2": nil
          }
    end


    
    def cadastro_cliente(data)
        time = (Time.now + 3.hours).to_i.to_s
        metodo = "post"
        body = Base64.strict_encode64(data.to_json)
       
        @signature = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), SENHA, "#{metodo}#{time}#{body}"))

        url = URI("#{URL_SHOP9}/clientes/")
        
        http = Net::HTTP.new(url.host, url.port);

        request = Net::HTTP::Post.new(url)

        request["Authorization"] = "Token #{@token}"
        request["signature"] = @signature
        request["CodFilial"] = FILIAL
        request["Timestamp"] = time
        request["Accept"] = "application/json"
        request["Content-Type"] = "application/json"
        request.body = data.to_json        

        begin
            response = http.request(request)
            
            return JSON.parse(response.read_body)['dados']['codigoGerado']
           
        rescue => exception
            puts exception
            return false
        end
    end
end