-- vendas

CREATE INDEX idx_vendas_data_venda 
ON vendas (data_venda);

CREATE INDEX idx_vendas_status_data 
ON vendas (status_pedido, data_venda);

CREATE INDEX idx_vendas_covering
ON vendas (status_pedido, data_venda)
INCLUDE (valor_total);

CREATE INDEX idx_vendas_pago_cover
ON vendas (data_venda, id_funcionario)
INCLUDE (valor_total)
WHERE status_pedido = 'Pago';

CREATE INDEX idx_vendas_pago_data_id
ON vendas (data_venda, id_venda)
WHERE status_pedido = 'Pago';

-- pessoas

CREATE INDEX idx_pessoas_ativas
ON pessoas (id_pessoa)
WHERE ativo = true;

CREATE INDEX idx_pessoas_data_cadastro
ON pessoas (data_cadastro);

-- itens_venda

CREATE INDEX idx_itens_venda_produto
ON itens_venda (id_produto);

CREATE INDEX idx_itens_venda_idvenda
ON itens_venda (id_venda);

CREATE INDEX idx_itens_venda_idvenda_produto
ON itens_venda (id_venda, id_produto)
INCLUDE (quantidade);

-- clientes

CREATE INDEX idx_clientes_id_cliente
ON clientes (id_cliente);

CREATE INDEX idx_clientes_data_nascimento
ON clientes (data_nascimento);

CREATE INDEX idx_clientes_pontos_id
ON clientes (pontos_fidelidade DESC, id_cliente ASC);

-- funcionarios

CREATE INDEX idx_funcionarios_data
ON funcionarios (data_contratacao);

-- fornecedores

CREATE INDEX idx_fornecedores_prazo_id
ON fornecedores (prazo_entrega DESC, id_fornecedor ASC);

-- produtos

CREATE INDEX idx_produtos_ativo_estoque
ON produtos (estoque)
WHERE ativo = TRUE;

-- compras

CREATE INDEX idx_compras_data_id
ON compras (data_compra, id_compra);

CREATE INDEX idx_compras_id_fornecedor
ON compras (id_fornecedor);

-- itens_compra

CREATE INDEX idx_itens_compra_id_compra_produto
ON itens_compra (id_compra, id_produto);

-- fornecimento

CREATE INDEX idx_fornecimento_produto_prioridade
ON fornecimento (id_produto, id_fornecedor)
WHERE prioridade = 'Primaria';