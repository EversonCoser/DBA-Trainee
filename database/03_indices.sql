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

-- itens_venda

CREATE INDEX idx_itens_venda_produto
ON itens_venda (id_produto);

CREATE INDEX idx_itens_venda_idvenda
ON itens_venda (id_venda);

CREATE INDEX idx_itens_venda_idvenda_produto
ON itens_venda (id_venda, id_produto)
INCLUDE (quantidade);