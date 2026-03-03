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