require_relative 'base_wc'
require "uri"
require "net/http"
require "json"
require 'dotenv/load'
require "securerandom"

require_relative '../ideal_soft/produtos'
require_relative 'categorias'

require 'byebug'
class ProdutosWoocommerce < BaseWc
    URL = ENV.fetch('URL_UNIVERSAL')

    def cadastrar_categoria(name)
        url = URI("#{URL}/wp-json/wc/v3/products/categories")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        payload = {
            "name": "#{name}",
            "slug": "#{name}"
        }
        
        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        request.body = payload.to_json
        response = https.request(request)        
       
        if response.code.to_i == 201 || response.code.to_i == 201
            return JSON.parse(response.read_body)['id']  
        else
            return JSON.parse(response.read_body)['data']['resource_id']
        end 
    end

    def categorias
        url = URI("#{URL}/wp-json/wc/v3/products/categories")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        
        request = Net::HTTP::Get.new(url)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        response = https.request(request)
        
        if response.code.to_i == 200           
            resp = JSON.parse(response.read_body)            
            return resp
        else
            puts response.read_body
            return false
            
        end
    end

    def cadastra_variacao(id_produto, data)
        puts "CADASTRANDO DETALHES DO PRODUTO #{id_produto}"
        puts "DATA = #{data}"
        url = URI("#{URL}/wp-json/wc/v3/products/#{id_produto}/variations")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        
        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        request.body = data.to_json
        response = https.request(request)

        if response.code == "201" || response.code == "200"
            return true
        else
            return false
            puts response.read_body
        end 
    end

    def payload(data)
        produtos_shop = Produtos.new 
       
        estoque = produtos_shop.estoque(data['codigo'])

        return false if estoque <= 5

        
      
        categories = categorias()  #categorias Woocommerce
        categories_shop = Grupo.new.grupo_cadastrado(data['codigoClasse']) #categoria Shop9
        
        tipo = data['tipo'] == 2 ? "variable" : "simple"

        id_categoria = false

        begin
            categories.each do |category|
               
               if category['name'] == categories_shop
                    id_categoria = category['id']
               end

            end
            
            if id_categoria == false
                id_categoria = cadastrar_categoria(categories_shop)
            end
        rescue StandardError => e
            puts "Categorias"
            puts e
        end


        produtos_img = produtos_shop.foto_produto(data['codigo'])

        cadastro_foto = []

        if produtos_img == false
            puts "Sem Imagem"
            return false
        else
            produtos_img.each do |produto_img|
                foto = produtos_shop.foto_posicao(data['codigo'], produto_img['posicao'] )
                filename = "#{data['codigo']}_#{produto_img['posicao']}.jpg"
                f = File.new(filename, "wb")
                f.write(foto)
                f.binmode
                f.close               
                
                cad_foto = cadastrar_foto(filename,"publish")
                
                if cad_foto
                    cadastro_foto.append({
                        src: cad_foto[:url],
                        id: cad_foto[:id]
                    })
                end               
            end            
        end
        

        return {
            name: data['nome'],
            sku: data['codigo'],
            type: tipo,
            regular_price: data['precos'][0]['preco'].to_s,
            description: data['observacao1'],
            short_description: data['observacao2'],
            manage_stock: true,
            stock_quantity: estoque.to_i,
            dimensions: {
                length: data['comprimento'],
                width: data['largura'],
                height: data['altura']
            },
            categories: [
              {
                id: id_categoria
              }              
            ],
            images: cadastro_foto
        }

    end

    def deleta_imagem(produto)
        url = URI("#{URL}/wp-json/wp/v2/media/#{produto['id']}?force=true")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        
        request = Net::HTTP::Delete.new(url)
        request["Content-Disposition"] = "attachment;filename=#{produto['name']}"
        request["Authorization"] = "Bearer #{@token}"
        form_data = []
        request.set_form form_data, 'multipart/form-data'
        response = https.request(request)
        if response.code.to_i == 201 || response.code.to_i == 200
            return true
        else
            return false
        end
    end


    def deleta_produto(produto)
        url = URI("#{URL}/wp-json/wc/v3/products/#{produto}?force=true")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        
        request = Net::HTTP::Delete.new(url)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        
        response = https.request(request)
        if response.code.to_i == 201 || response.code.to_i == 200
            return true
        else
            return false
        end
    end


    def cadastrar_foto(filename, data)
        url = URI("#{URL}/wp-json/wp/v2/media")
        puts "AQUI"

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(url)
        request["Content-Disposition"] = "attachment; filename=teste.jpeg"
        request["Authorization"] = "Bearer #{@token}"
        form_data = [['file', File.open(filename)],['title', filename],['status', data]]
        request.set_form form_data, 'multipart/form-data'
        response = https.request(request)
        
        if response.code.to_i == 201 || response.code.to_i == 200
            body = JSON.parse(response.read_body)
            return {
                'url': body['guid']['rendered'],
                'id': body['id']
            }
        else
            return false
        end

    end

    def consulta_produto(produto)
        begin
            url = URI("#{URL}/wp-json/wc/v3/products/?sku=#{produto}")

            https = Net::HTTP.new(url.host, url.port)
            https.use_ssl = true
            
            request = Net::HTTP::Get.new(url)
            request["Authorization"] = "Bearer #{@token}"
            request["Content-Type"] = "application/json"
            response = https.request(request)
            puts "Consultando produto = #{produto}"

            puts response.code
            if response.read_body == "[]" && response.code.to_i == 200
                return false
            else
                return response.read_body
            end
        rescue => exception            
            puts exception
            return false
        end
    end

    def cadastro(payload)

        url = URI("#{URL}/wp-json/wc/v3/products")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        
        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        request.body = payload.to_json
        response = https.request(request)

        if response.code == "201" || response.code == "200"
            return JSON.parse(response.read_body)['id']
        else
            return false
            puts response.read_body
        end       
        
    end

    def atualiza(id, data)

        url = URI("#{URL}/wp-json/wc/v3/products/#{id}")

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        
        request = Net::HTTP::Put.new(url)
        request["Authorization"] = "Bearer #{@token}"
        request["Content-Type"] = "application/json"
        request.body = data.to_json
        response = https.request(request)

        if response.code == "201" || response.code == "200"
            return true
        else
            return false
            puts response.read_body
        end       
        
    end


end