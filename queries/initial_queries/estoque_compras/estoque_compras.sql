-- Os 10 produtos ativos com menor estoque

SELECT
    descricao,
    estoque
FROM produtos
WHERE ativo = TRUE
ORDER BY estoque ASC
LIMIT 10;

-- Produtos mais comprados e valor gasto

SELECT
	p.descricao,
	p.estoque,
	SUM(ic.quantidade) AS qtd_comprada,
	SUM(ic.valor_unitario * ic.quantidade ) AS total_gasto
FROM produtos p
JOIN (
    SELECT 
        c.id_compra,
        ic.id_produto,
        ic.quantidade,
        ic.valor_unitario
    FROM itens_compra ic
    JOIN compras c 
        ON c.id_compra = ic.id_compra
    WHERE data_compra BETWEEN '2024-01-01' AND '2024-12-31'
) ic 
	ON p.id_produto = ic.id_produto
GROUP BY p.descricao, p.estoque 
ORDER BY qtd_comprada DESC, total_gasto DESC
LIMIT 10; 

-- Valor gasto por fornecedor

SELECT
    p.nome,
    SUM(c.valor_total) AS total_gasto
FROM compras c
JOIN pessoas p 
    ON p.id_pessoa = c.id_fornecedor
GROUP BY p.nome
ORDER BY total_gasto DESC;

-- Produtos com mais de um fornecedor primário

SELECT 
    p.id_produto,
    p.descricao,
    p.categoria
FROM produtos p
JOIN fornecimento f 
    ON f.id_produto = p.id_produto
WHERE f.prioridade = 'Primaria'
GROUP BY p.id_produto, p.descricao
HAVING COUNT(DISTINCT f.id_fornecedor) > 1;

-- Produtos com apenas 1 fornecedor

WITH produtos_fornecedores_unicos AS (
	SELECT 
	    f.id_produto
	FROM fornecimento f 
	GROUP BY f.id_produto 
	HAVING COUNT(DISTINCT f.id_fornecedor) = 1
)
SELECT 
	p.descricao,
	p.categoria
FROM produtos p 
WHERE p.ativo = TRUE
AND EXISTS (
	SELECT 1
	FROM produtos_fornecedores_unicos pfu
	WHERE p.id_produto = pfu.id_produto 
)
ORDER BY p.id_produto;