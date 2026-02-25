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

-- 10 produtos mais vendidos por categoria

WITH produtos_mais_vendidos_por_categoria AS (
    SELECT 
        v.id_venda
    FROM vendas v
        WHERE v.status_pedido = 'Pago'
            AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
),
itens_agrupados AS (
    SELECT 
        iv.id_produto,
        SUM(iv.quantidade) AS total_vendido
    FROM itens_venda iv
    JOIN produtos_mais_vendidos_por_categoria pmv
        ON iv.id_venda = pmv.id_venda
    GROUP BY iv.id_produto
)
SELECT
    p.descricao,
    p.categoria,
    ia.total_vendido
FROM itens_agrupados ia
JOIN produtos p ON p.id_produto = ia.id_produto
ORDER BY ia.total_vendido DESC
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

-- Faturamento por categoria

SELECT 
    pr.categoria,
    SUM(iv.quantidade * iv.preco_unitario_venda) AS faturamento_total
FROM vendas v
JOIN itens_venda iv 
    ON iv.id_venda = v.id_venda
JOIN produtos pr 
    ON pr.id_produto = iv.id_produto
WHERE v.status_pedido = 'Pago'
  AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY pr.categoria
ORDER BY faturamento_total DESC;

-- Os 10 clientes com maior valor total gasto

WITH ranking AS (
    SELECT 
        v.id_cliente,
        SUM(v.valor_total) AS total_gasto
    FROM vendas v
    WHERE v.status_pedido = 'Pago'
      AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY v.id_cliente
    ORDER BY total_gasto DESC
    LIMIT 10
)
SELECT p.nome, r.total_gasto
FROM ranking r
JOIN pessoas p ON p.id_pessoa = r.id_cliente
ORDER BY r.total_gasto DESC;

-- Porcentagem de vendas canceladas

SELECT 
    COUNT(*) AS total_vendas,
    COUNT(*) FILTER (WHERE status_pedido = 'Cancelado') AS canceladas,
    ROUND(
        (COUNT(*) FILTER (WHERE status_pedido = 'Cancelado')::DECIMAL 
        / NULLIF(COUNT(*),0)) * 100, 
    2) AS percentual_cancelado
FROM vendas;