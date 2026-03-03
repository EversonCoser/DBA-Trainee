-- Os 10 produtos ativos com menor estoque

SELECT
    descricao,
    estoque
FROM produtos
WHERE ativo = TRUE
ORDER BY estoque ASC
LIMIT 10;

