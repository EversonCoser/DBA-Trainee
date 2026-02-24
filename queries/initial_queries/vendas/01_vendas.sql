-- Query para análise de vendas no ano de 2024, considerando apenas os pedidos com status 'Pago'.

EXPLAIN ANALYZE
SELECT 
    COUNT(*) AS total_vendas,
    SUM(valor_total) AS faturamento_total,
    ROUND(AVG(valor_total), 2) AS ticket_medio
FROM vendas
    WHERE status_pedido = 'Pago' 
    AND data_venda BETWEEN '2024-01-01' AND '2024-12-31';

-- Faturamento por mês, quantidade de vendas e ticket médio, considerando apenas os pedidos 
-- com status 'Pago' no ano de 2024, ordenamento pelo faturamento.

EXPLAIN ANALYZE
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

EXPLAIN ANALYZE
SELECT
    fp.nome AS forma_pagamento,
    SUM(v.valor_total) AS faturamento,
    COUNT(*) AS total_vendas
FROM vendas v
    JOIN formas_pagamento fp ON fp.id_forma_pagamento = v.id_forma_pagamento
        WHERE v.status_pedido = 'Pago'
        AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
        GROUP BY fp.nome
        ORDER BY faturamento DESC;

-- Performance por funcionário

SELECT
    f.id_funcionario,
    p.nome,
    SUM(v.valor_total) AS valor_total,
    COUNT(*) AS total_vendas
FROM vendas v
JOIN funcionarios f 
    ON f.id_funcionario = v.id_funcionario
JOIN pessoas p 
    ON p.id_pessoa = f.id_funcionario
    AND p.ativo = true
WHERE v.status_pedido = 'Pago'
    AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY f.id_funcionario, p.nome
ORDER BY valor_total DESC
LIMIT 10;

-- 10 produtos mais vendidos e sua categoria

SELECT
    p.descricao,
    p.categoria,
    SUM(iv.quantidade) AS total_vendido
FROM itens_venda iv
JOIN produtos p 
    ON p.id_produto = iv.id_produto
JOIN vendas v 
    ON v.id_venda = iv.id_venda
WHERE v.status_pedido = 'Pago'
    AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'    
GROUP BY p.descricao, p.categoria
ORDER BY total_vendido DESC
LIMIT 10;

-- 10 produtos com maior faturamento 

WITH produtos_maiores_faturamentos AS (
    SELECT 
        v.id_venda
    FROM vendas v
        WHERE v.status_pedido = 'Pago'
            AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
),
maior_faturamento AS (
    SELECT 
        iv.id_produto,
        SUM(iv.quantidade * iv.preco_unitario_venda) AS faturamento
    FROM itens_venda iv
    JOIN produtos_maiores_faturamentos pmf ON pmf.id_venda = iv.id_venda
    GROUP BY iv.id_produto
)
SELECT 
    p.descricao AS produto,
    mf.faturamento AS faturamento
FROM maior_faturamento mf
JOIN produtos p ON p.id_produto = mf.id_produto
ORDER BY mf.faturamento DESC
LIMIT 10;