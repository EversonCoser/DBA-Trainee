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