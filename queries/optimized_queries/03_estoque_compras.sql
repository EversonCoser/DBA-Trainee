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
ORDER BY qtd_comprada DESC, valor_gasto DESC, pc.id_produto ASC; 

-- Valor gasto por fornecedor

WITH gasto_fornecedor AS (
    SELECT
        c.id_fornecedor,
        SUM(c.valor_total) AS total_gasto
    FROM compras c
    GROUP BY c.id_fornecedor
)
SELECT
    p.nome,
    gf.total_gasto
FROM gasto_fornecedor gf
JOIN pessoas p
    ON p.id_pessoa = gf.id_fornecedor
WHERE p.ativo = true
ORDER BY gf.total_gasto DESC
LIMIT 10;