CREATE INDEX idx_vendas_data_venda 
ON vendas (data_venda);

CREATE INDEX idx_vendas_status_data 
ON vendas (status_pedido, data_venda);

CREATE INDEX idx_vendas_covering
ON vendas (status_pedido, data_venda)
INCLUDE (valor_total);
