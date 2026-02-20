-- Query para análise de vendas no ano de 2024, considerando apenas os pedidos com status 'Pago'.

SELECT 
    COUNT(*) AS total_vendas,
    SUM(valor_total) AS faturamento_total,
    ROUND(AVG(valor_total), 2) AS ticket_medio
FROM vendas
    WHERE status_pedido = 'Pago' 
    AND data_venda BETWEEN '2024-01-01' AND '2024-12-31';

-- Faturamento por mês, quantidade de vendas e ticket médio, considerando apenas os pedidos 
-- com status 'Pago' no ano de 2024, ordenamento pelo faturamento.

SELECT 
    DATE_TRUNC('month', data_venda) AS mes,
    SUM(valor_total) AS faturamento,
    COUNT(*) AS total_vendas,
    ROUND(AVG(valor_total), 2) AS ticket_medio
FROM vendas
    WHERE status_pedido = 'Pago'
    AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY mes
    ORDER BY faturamento DESC;