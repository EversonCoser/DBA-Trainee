-- Os 10 produtos ativos com menor estoque

SELECT
    descricao,
    estoque
FROM produtos
WHERE ativo = TRUE
ORDER BY estoque ASC
LIMIT 10;

-- Produtos mais comprados e valor gasto

WITH produtos_comprados AS (
	SELECT
		ic.id_produto,
		SUM(ic.quantidade) AS qtd_comprada,
		SUM(ic.valor_unitario * ic.quantidade) AS valor_gasto
	FROM compras c
	JOIN itens_compra ic 
		ON c.id_compra = ic.id_compra
	WHERE data_compra BETWEEN '2025-01-01' AND '2025-12-31'
	GROUP BY ic.id_produto
	ORDER BY qtd_comprada DESC, valor_gasto DESC, ic.id_produto ASC 
	LIMIT 10
)
SELECT
	p.descricao,
	p.estoque,
	pc.qtd_comprada,
	pc.valor_gasto
FROM produtos p 
JOIN produtos_comprados pc
	ON p.id_produto = pc.id_produto 
ORDER BY qtd_comprada DESC, valor_gasto DESC, pc.id_produto ASC 