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