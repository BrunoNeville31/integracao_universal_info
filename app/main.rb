require 'rufus-scheduler'
require 'byebug'
require_relative 'service/ideal_soft/produtos'
require_relative 'service/woocommerce/produtos'


woocommerce = ProdutosWoocommerce.new
shop = Produtos.new

scheduler = Rufus::Scheduler.new

scheduler.in '2s' do#cron '* * * * *' do 
    puts 'INICIANDO SINCRONISMO'
    initial = 1

    while initial > -1 do
        produtos = Produtos.new.pagina_produtos(initial)
        unless produtos.nil?
            puts produtos[0]
            
            produtos.each do |produto|

                if produto['codigo'] != "2"
                    next
                end

                consulta_produto = woocommerce.consulta_produto(produto['codigo'])
                
                if consulta_produto == false
                    #Cadastrar Produto
                    
                    if produto['tipo'] == 0
                        payload = woocommerce.payload(produto)
                        if payload != false
                            if payload[:stock_quantity] >= 5
                                woocommerce.cadastro(payload)
                                puts "Cadastrado Produto #{produto['codigo']} - #{produto['nome']}"
                            end
                        end
                        #Produto Unico

                    elsif produto['tipo'] == 1

                        #Produto Grade

                    end
                else
                    #Atualizar Produto

                    if produto['tipo'] == 0
                        dados_produtos = JSON.parse(consulta_produto)[0]

                        dados_produtos['images'].each do |dado_produto|
                            woocommerce.deleta_imagem(dado_produto)                            
                        end                        

                        data = woocommerce.payload(produto)
                        if data[:stock_quantity] >= 5
                            woocommerce.atualiza(dados_produtos['id'], data)
                            puts "Atualizado Produto #{produto['codigo']} - #{produto['nome']}"
                        else
                            woocommerce.deleta_produto(dados_produtos['id'])
                        end

                        data[:images].each do |image|
                            woocommerce.deleta_imagem(image[:id].to_s) 
                        end
                       
                        #Produto Unico

                    elsif produto['tipo'] == 1

                        #Produto Grade

                    end
                end
            end    
            initial += 1
        else 
            initial = -1
        end
    end
end


scheduler.join

# Consumer key 
#ck_07d5b2dbdfe10ad5d310550fb2d63942247b0f4a

#Consumer secret 
#cs_281974aeb46a503e265b777dad505cd6f425602e