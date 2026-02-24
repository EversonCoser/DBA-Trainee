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

-- Faturamento e quantidade de vendas por forma de pagamento

WITH vendas_agrupadas AS (
    SELECT 
        id_forma_pagamento,
        SUM(valor_total) AS faturamento,
        COUNT(*) AS total_vendas
    FROM vendas
    WHERE status_pedido = 'Pago'
      AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY id_forma_pagamento
)
SELECT 
    fp.nome AS forma_pagamento,
    v.faturamento,
    v.total_vendas
FROM vendas_agrupadas v
JOIN formas_pagamento fp
    ON fp.id_forma_pagamento = v.id_forma_pagamento
ORDER BY v.faturamento DESC;

-- Performance por funcionário

WITH performance_funcionario AS (
    SELECT
        id_funcionario,
        SUM(valor_total) AS valor_total,
        COUNT(*) AS total_vendas
    FROM vendas
    WHERE status_pedido = 'Pago'
      AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY id_funcionario
)
SELECT
    pf.id_funcionario,
    p.nome,
    pf.valor_total,
    pf.total_vendas
FROM performance_funcionario pf
JOIN pessoas p
    ON p.id_pessoa = pf.id_funcionario
   AND p.ativo = true
ORDER BY pf.valor_total DESC
LIMIT 10;