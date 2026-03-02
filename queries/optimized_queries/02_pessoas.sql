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

WITH cadastros AS (
    SELECT 
        DATE_TRUNC('month', data_cadastro) AS mes,
        COUNT(*) AS total
    FROM pessoas
    WHERE data_cadastro BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY mes
)
SELECT *
FROM cadastros

-- Distribuição de idade dos clientes

SELECT 
    CASE 
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '25 years' 
                                 AND CURRENT_DATE - INTERVAL '18 years' THEN '18-25'
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '35 years' 
                                 AND CURRENT_DATE - INTERVAL '26 years' THEN '26-35'
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '50 years' 
                                 AND CURRENT_DATE - INTERVAL '36 years' THEN '36-50'
        ELSE '50+'
    END AS faixa_etaria,
    COUNT(*) AS total
FROM clientes
JOIN pessoas ON pessoas.id_pessoa = clientes.id_cliente
WHERE pessoas.ativo = true
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