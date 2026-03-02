-- Porcentagem de pessoas ativas

SELECT 
    COUNT(*) FILTER (WHERE ativo = true) AS pessoas_ativas,
    COUNT(*) FILTER (WHERE ativo = false) AS pessoas_inativas,
    ROUND(
        (COUNT(*) FILTER (WHERE ativo = true)::DECIMAL 
        / NULLIF(COUNT(*),0)) * 100, 
    2) AS percentual_ativos
FROM pessoas;

-- Porcentagem de pessoas físicas

SELECT
    COUNT(*) FILTER (WHERE fisica_juridica = 'F') AS clientes_fisicos,
    COUNT(*) FILTER (WHERE fisica_juridica = 'J') AS clientes_juridicos,
    ROUND(
        (COUNT(*) FILTER (WHERE fisica_juridica = 'F')::DECIMAL
        / NULLIF(COUNT(*),0)) * 100,
    2) AS percentual_fisicos 
FROM pessoas;

-- Quantidade de pessoas cadastradas por mês

SELECT
    DATE_TRUNC('month', data_cadastro) AS mes,
    COUNT(*) AS total_cadastros
FROM pessoas
WHERE data_cadastro BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY mes
ORDER BY mes;

-- Distribuição de idade dos clientes

SELECT 
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(c.data_nascimento)) BETWEEN 18 AND 25 THEN '18-25'
        WHEN EXTRACT(YEAR FROM AGE(c.data_nascimento)) BETWEEN 26 AND 35 THEN '26-35'
        WHEN EXTRACT(YEAR FROM AGE(c.data_nascimento)) BETWEEN 36 AND 50 THEN '36-50'
        ELSE '50+'
    END AS faixa_etaria,
    COUNT(*) AS total
FROM clientes c
JOIN pessoas p ON p.id_pessoa = c.id_cliente
WHERE p.ativo = true
GROUP BY faixa_etaria
ORDER BY total DESC;

-- Top 15 clientes por pontos de fidelidade

SELECT 
    p.nome AS nome_cliente,
    c.pontos_fidelidade AS pontos
FROM pessoas p
JOIN clientes c ON c.id_cliente = p.id_pessoa
ORDER BY c.pontos_fidelidade DESC, p.id_pessoa ASC
LIMIT 15;

-- Salário total e médio por cargo

SELECT
    f.cargo,
    COUNT(*) AS total_funcionarios,
    SUM(f.salario) AS folha_total,
    AVG(f.salario) AS salario_medio
FROM funcionarios f
JOIN pessoas p 
    ON p.id_pessoa = f.id_funcionario
    AND p.ativo = true
GROUP BY f.cargo
ORDER BY folha_total DESC;

-- 10 funcionários com mais tempo de empresa

SELECT
    p.nome,
    f.cargo,
    AGE(CURRENT_DATE, f.data_contratacao) AS tempo_casa
FROM pessoas p
JOIN funcionarios f 
    ON f.id_funcionario = p.id_pessoa
WHERE p.ativo = true
ORDER BY tempo_casa DESC
LIMIT 10;

-- Fornecedores com prazo de entrega acima da média

SELECT
    f.id_fornecedor,
    p.nome,
    f.prazo_entrega
FROM fornecedores f
JOIN pessoas p 
    ON p.id_pessoa = f.id_fornecedor
WHERE p.ativo = true
  AND f.prazo_entrega > (
        SELECT AVG(f2.prazo_entrega)
        FROM fornecedores f2
        JOIN pessoas p2
            ON p2.id_pessoa = f2.id_fornecedor
        WHERE p2.ativo = true
    )
ORDER BY f.prazo_entrega DESC, f.id_fornecedor ASC
LIMIT 10;