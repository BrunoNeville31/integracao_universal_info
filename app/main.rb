require 'rufus-scheduler'
require 'byebug'
require 'time'
require 'active_support/time'
require_relative 'service/ideal_soft/produtos'
require_relative 'service/woocommerce/produtos'
require_relative 'service/woocommerce/vendas'
require_relative 'service/ideal_soft/cliente'
require_relative 'service/ideal_soft/detalhes'


woocommerce = ProdutosWoocommerce.new
shop = Produtos.new

scheduler = Rufus::Scheduler.new

scheduler.in '60m' do#cron '* * * * *' do 
    puts 'INICIANDO SINCRONISMO'
    initial = 1

    while initial > -1 do
        produtos = Produtos.new.pagina_produtos(initial)
        puts "==================="
        puts "PAGINA = #{initial}"
        det = Detalhes.new
        unless produtos.nil?           
            
            produtos.each do |produto|

                consulta_produto = woocommerce.consulta_produto(produto['codigo'])
                puts "PRODUTO #{produto['codigo']}"               
              
                if consulta_produto == false
                    #Cadastrar Produto
                    puts "PRODUTO TIPO = #{produto['tipo']}"
                    if produto['tipo'] == 0

                        payload = woocommerce.payload(produto)
                        if payload != false
                            puts "QUANTIDADE DO PRODUTO = #{payload[:stock_quantity]}"
                            
                            if payload[:stock_quantity] >= 5
                                woocommerce.cadastro(payload)
                                puts "Cadastrado Produto #{produto['codigo']} - #{produto['nome']}"
                            else
                                puts "Sem estoque"
                                unless payload[:images].empty?
                                    payload[:images].each do |image|
                                        woocommerce.deleta_imagem(image[:id].to_s)
                                    end
                                end                                
                            end

                            unless payload[:images].empty?
                                payload[:images].each do |image|
                                    woocommerce.deleta_imagem(image[:id].to_s)
                                end
                            end 
                        end
                        
                        #Produto Unico

                    elsif produto['tipo'] == 2
                        puts "produto grade #{produto['codigo']}"
                        
                        payload = woocommerce.payload(produto)

                        if payload != false
                            if payload[:stock_quantity] >= 5
                                id_produto = woocommerce.cadastro(payload)
                                puts "Cadastrado Produto #{produto['codigo']} - #{produto['nome']}"
                            end
                        else
                            next
                        end
                        next
                        series = det.produto_series(produto['urlDetalhe'])                        
                        
                        series['lista'].each do |serie|
                            data = {
                                regular_price: payload[:regular_price],
                                sku: serie['serie']
                            }
                            woocommerce.cadastra_variacao(id_produto, data)
                        end

                    end
                else
                    #Atualizar Produto

                    if produto['tipo'] == 0
                        dados_produtos = JSON.parse(consulta_produto)[0]

                        dados_produtos['images'].each do |dado_produto|
                            woocommerce.deleta_imagem(dado_produto)                            
                        end                        

                        data = woocommerce.payload(produto)                        
                        
                        begin
                            if data[:stock_quantity] >= 1
                                woocommerce.atualiza(dados_produtos['id'], data)
                                puts "Atualizado Produto #{produto['codigo']} - #{produto['nome']}"
                            else
                                woocommerce.deleta_produto(dados_produtos['id'])
                            end

                            data[:images].each do |image|
                                woocommerce.deleta_imagem(image[:id].to_s) 
                            end
                        rescue StandardError => e                           
                            puts "SEM ATUALIZAÇÂO PARA PRODUTO #{produto['codigo']}"
                           
                        end
                       
                        #Produto Unico

                    elsif produto['tipo'] == 2

                        dados_produtos = JSON.parse(consulta_produto)[0]

                        dados_produtos['images'].each do |dado_produto|
                            woocommerce.deleta_imagem(dado_produto)                            
                        end                        

                        data = woocommerce.payload(produto)                        
                        
                        begin
                            if data[:stock_quantity] >= 1
                                woocommerce.atualiza(dados_produtos['id'], data)
                                puts "Atualizado Produto #{produto['codigo']} - #{produto['nome']}"
                            else
                                woocommerce.deleta_produto(dados_produtos['id'])
                            end

                            data[:images].each do |image|
                                woocommerce.deleta_imagem(image[:id].to_s) 
                            end
                        rescue StandardError => e                           
                            puts "SEM ATUALIZAÇÂO PARA PRODUTO #{produto['codigo']}"
                           
                        end

                    end
                end
            end    
            initial += 1
        else 
            initial = -1
        end
        puts "^^^^^^^^^^FIM^^^^^^^^^^"
    end
end

scheduler.in '1s' do
    vendas = VendasWoocommerce.new
    cliente = Cliente.new
    todas_vendas = vendas.consulta_vendas
    puts 'Iniciando vendas'

    todas_vendas.each do |venda|
        status_next = ['processing', 'on-hold', 'completed', 'cancelled', 'refunded', 'failed', 'trash']
        
        next if venda['line_items'].empty?
        next if status_next.include? venda['status']
        
        codigo_cliente = cliente.consulta_cliente(venda['billing'])

        produtos = []
        venda['line_items'].each do |produto|
            dados_prod = Produtos.new.consulta_produto(produto['sku'])
            
            produtos.append({
                "Codigo": dados_prod['codigo'],
                "CodigoCor": nil,
                "CodigoTamanho": nil,
                "Quantidade": produto['quantity'],
                "PrecoUnitario": (produto['total'].to_f / produto['quantity']),
                "DescontoUnitario": 0.00
            })
        end
        

        recebimentos = []
        
        qtd_parcelas = venda['meta_data'].select{|a| a['key'] == 'Parcelas'}[0]['value'].to_i
        valor_parcela = venda['total'].to_f / qtd_parcelas

        for index in 1..qtd_parcelas do 
            recebimentos.append({
                "ValorParcelas": valor_parcela,
                "CodigoAdministradora": nil,
                "Vencimento": nil,
                "Nsu": "#{Time.now.to_i}",
                "QuantidadeParcelas": qtd_parcelas,
                "Tipo": "C" 
            })
        end
        

        payload = {
            "CpfCnpj": venda['billing']['cpf'],
            "CodigoOperacao": "500",
            "Data": "#{Time.now}",
            "Produtos": produtos,
            "Recebimentos": recebimentos,
            "DadosEntrega": {
                "Valor": venda['total'].to_f,
                "OpcoesFretePagoPor": "O",
                "PesoBruto": 0.0,
                "PesoLiquido": 0.0,
                "Volume": 0.0,
                "NaoSomarFreteTotalNota": true,
                "OutroEndereco": {
                "Cep": venda['shipping']['postcode'].delete("-"),
                "Endereco": venda['shipping']['address_1'],
                "Numero": venda['shipping']['number'],
                "Bairro": venda['shipping']['neighborhood'],
                "Cidade":venda['shipping']['city'],
                "Uf": venda['shipping']['state']
                }
            }
        }

        
        realiza_venda = cliente.realiza_venda(payload)
        if realiza_venda == true
            vendas.atualiza_venda(venda['id'], 'processing')
        else
            puts "VENDA NÂO REALIZADA"
        end
    end

    puts "FIM"
end


scheduler.join

# Consumer key 
#ck_07d5b2dbdfe10ad5d310550fb2d63942247b0f4a

#Consumer secret 
#cs_281974aeb46a503e265b777dad505cd6f425602e