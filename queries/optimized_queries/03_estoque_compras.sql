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

-- Produtos com mais de um fornecedor primário

WITH produtos_fornecimento_primario AS (
    SELECT 
        f.id_produto
    FROM fornecimento f
    WHERE f.prioridade = 'Primaria'
    GROUP BY f.id_produto
    HAVING COUNT(DISTINCT f.id_fornecedor) > 1
)
SELECT 
    p.descricao,
    p.categoria
FROM produtos p
WHERE p.ativo = true
  AND EXISTS (
      SELECT 1
      FROM produtos_fornecimento_primario pfp
      WHERE pfp.id_produto = p.id_produto
  )
ORDER BY p.id_produto;

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

-- Funcionários que mais realizaram compras e valor total gasto

WITH funcionario_compras AS (
	SELECT 
		c.id_funcionario,
		COUNT(*) AS qtd_compras,
		SUM(c.valor_total) AS valor_total_gasto
	FROM compras c 
	WHERE c.data_compra BETWEEN '2022-01-01' AND '2022-12-31'
	GROUP BY c.id_funcionario 
)
SELECT 
	p.nome,
	fc.qtd_compras,
	fc.valor_total_gasto
FROM pessoas p 
JOIN funcionario_compras fc
	ON fc.id_funcionario = p.id_pessoa 
WHERE p.ativo = TRUE 
ORDER BY p.id_pessoa;

-- Investimento mensal em compras

SELECT  
	date_trunc('month', data_compra) AS mes,
	count(*) AS total_compras,
	sum(c.valor_total) AS total_gasto
FROM compras c 
WHERE c.data_compra BETWEEN '2025-01-01' AND '2025-12-01'
GROUP BY mes
ORDER BY total_gasto; 