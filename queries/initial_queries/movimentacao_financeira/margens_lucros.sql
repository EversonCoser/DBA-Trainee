-- Margem de lucro por produto para vendas realizadas entre 01/01/2025 e 01/02/2025, 
-- considerando apenas pedidos pagos. A consulta retorna os 10 produtos com maior margem 
-- de lucro e os 10 produtos com menor margem de lucro, ordenados por lucro.

WITH vendas_filtradas AS (
    SELECT id_venda
    FROM vendas
    WHERE data_venda BETWEEN '2025-01-01' AND '2025-02-01'
      AND status_pedido = 'Pago'
),
compras_filtradas AS (
    SELECT id_compra
    FROM compras
    WHERE data_compra BETWEEN '2025-01-01' AND '2025-02-01'
),
receita AS (
    SELECT
        iv.id_produto,
        SUM(iv.preco_unitario_venda * iv.quantidade) AS receita_total
    FROM itens_venda iv
    JOIN vendas_filtradas vf
        ON vf.id_venda = iv.id_venda
    GROUP BY iv.id_produto
),
gastos AS (
    SELECT
        ic.id_produto,
        SUM(ic.valor_unitario * ic.quantidade) AS gasto_total
    FROM itens_compra ic
    JOIN compras_filtradas cf
        ON cf.id_compra = ic.id_compra
    GROUP BY ic.id_produto
),
lucro AS (
    SELECT
        g.id_produto,
        (r.receita_total - g.gasto_total) AS lucro
    FROM gastos g
    JOIN receita r
        ON r.id_produto = g.id_produto
)
(
SELECT
    p.descricao,
    l.lucro
FROM lucro l
JOIN produtos p
    ON p.id_produto = l.id_produto
ORDER BY l.lucro DESC
LIMIT 10
)

UNION ALL

(
SELECT *
FROM (
    SELECT
        p.descricao,
        l.lucro
    FROM lucro l
    JOIN produtos p
        ON p.id_produto = l.id_produto
    ORDER BY l.lucro ASC
    LIMIT 10
) menores
ORDER BY lucro DESC
);

-- Movimentação financeira da empresa

WITH receitas_gerais AS (
	SELECT 
		sum(v.valor_total) AS receita_total 
	FROM vendas v
	WHERE v.data_venda BETWEEN '2025-01-01' AND '2025-02-01'
		AND v.status_pedido = 'Pago'
),
gastos_totais AS (
	SELECT 
		sum(c.valor_total) AS gastos_totais
	FROM compras c
	WHERE c.data_compra  BETWEEN '2025-01-01' AND '2025-02-01'
)
SELECT 
	rg.receita_total,
	gt.gastos_totais,
	(rg.receita_total - gt.gastos_totais) AS lucro
FROM receitas_gerais rg, gastos_totais gt