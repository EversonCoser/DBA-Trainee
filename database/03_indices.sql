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

-- pessoas

CREATE INDEX idx_pessoas_ativas
ON pessoas (id_pessoa)
WHERE ativo = true;