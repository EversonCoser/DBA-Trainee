# Os 10 produtos ativos com menor estoque

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT
    descricao,
    estoque
FROM produtos
WHERE ativo = TRUE
ORDER BY estoque ASC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=25.36..25.39 rows=10 width=15) (actual time=0.507..0.511 rows=10 loops=1)
  ->  Sort  (cost=25.36..26.74 rows=549 width=15) (actual time=0.505..0.507 rows=10 loops=1)
        Sort Key: estoque
        Sort Method: top-N heapsort  Memory: 25kB
        ->  Seq Scan on produtos  (cost=0.00..13.50 rows=549 width=15) (actual time=0.045..0.283 rows=549 loops=1)
              Filter: ativo
              Rows Removed by Filter: 101
Planning Time: 0.225 ms
Execution Time: 0.556 ms
````

- Tempo de 0.556 com Seq Scan em produtos.
- Índice em estoque para produtos ativos favorece a consulta.

````sql
CREATE INDEX idx_produtos_ativo_estoque
ON produtos (estoque)
WHERE ativo = TRUE;
````

### Query plan 2

````sql
Limit  (cost=0.28..1.23 rows=10 width=15) (actual time=0.128..0.144 rows=10 loops=1)
  ->  Index Scan using idx_produtos_ativo_estoque on produtos  (cost=0.28..52.50 rows=549 width=15) (actual time=0.125..0.140 rows=10 loops=1)
Planning Time: 1.117 ms
Execution Time: 0.172 ms
````

- Tempo de execução de 0.172 ms com a utilização do índice idx_produtos_ativo_estoque na tabela produtos. Como a consulta é simples a utilização de CTE não apresenta ganho performático. 