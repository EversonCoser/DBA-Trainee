-- Query para análise de vendas no ano de 2024, considerando apenas os pedidos com status 'Pago'.

EXPLAIN ANALYZE
SELECT 
    COUNT(*) AS total_vendas,
    SUM(valor_total) AS faturamento_total,
    ROUND(AVG(valor_total), 2) AS ticket_medio
FROM vendas
    WHERE status_pedido = 'Pago' 
    AND data_venda BETWEEN '2024-01-01' AND '2024-12-31';
