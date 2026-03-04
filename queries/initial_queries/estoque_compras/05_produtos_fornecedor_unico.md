# Produtos com fornecedor único

## Query versão 1

````sql
EXPLAIN ANALYZE 
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
````

### Query plan 1

````sql
Nested Loop  (cost=290.59..341.47 rows=2 width=25) (actual time=3.054..5.112 rows=196 loops=1)
  ->  GroupAggregate  (cost=290.32..324.85 rows=2 width=4) (actual time=2.976..4.326 rows=239 loops=1)
        Group Key: f.id_produto
        Filter: (count(DISTINCT f.id_fornecedor) = 1)
        Rows Removed by Filter: 202
        ->  Sort  (cost=290.32..299.99 rows=3870 width=8) (actual time=2.965..3.276 rows=3870 loops=1)
              Sort Key: f.id_produto, f.id_fornecedor
              Sort Method: quicksort  Memory: 187kB
              ->  Seq Scan on fornecimento f  (cost=0.00..59.70 rows=3870 width=8) (actual time=0.029..0.693 rows=3870 loops=1)
  ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..8.29 rows=1 width=25) (actual time=0.003..0.003 rows=1 loops=239)
        Index Cond: (id_produto = f.id_produto)
        Filter: ativo
        Rows Removed by Filter: 0
Planning Time: 0.359 ms
Execution Time: 5.213 ms
````

- Tempo de execução de 5.213 ms com a utilização do índice pk_produtos_id_produto em produtos, Seq Scan em fornecimento.
- Índice criado nos atributos id_produto e id_funcionario na tabela fornecimento e no atributo ativo na tabela produtos.

### Query plan 2

````sql
Sort  (cost=150.18..150.18 rows=2 width=25) (actual time=1.734..1.749 rows=196 loops=1)
  Sort Key: p.id_produto
  Sort Method: quicksort  Memory: 33kB
  ->  Hash Join  (cost=135.22..150.17 rows=2 width=25) (actual time=1.486..1.685 rows=196 loops=1)
        Hash Cond: (p.id_produto = f.id_produto)
        ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=549 width=25) (actual time=0.028..0.139 rows=549 loops=1)
              Filter: ativo
              Rows Removed by Filter: 101
        ->  Hash  (cost=135.19..135.19 rows=2 width=4) (actual time=1.438..1.438 rows=239 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 17kB
              ->  GroupAggregate  (cost=0.28..135.19 rows=2 width=4) (actual time=0.033..1.393 rows=239 loops=1)
                    Group Key: f.id_produto
                    Filter: (count(DISTINCT f.id_fornecedor) = 1)
                    Rows Removed by Filter: 202
                    ->  Index Only Scan using idx_fornecimento_produto_fornecedor on fornecimento f  (cost=0.28..110.33 rows=3870 width=8) (actual time=0.026..0.642 rows=3870 loops=1)
                          Heap Fetches: 0
Planning Time: 0.364 ms
Execution Time: 1.828 ms
````

- Tempo de execução de 1.828 ms com a utilização do índice idx_fornecimento_produto_fornecedor em fornecimento e Seq Scan em produtos. A agregação foi realizada antes, o que diminuiu a quantidade de dados na etapa seguinte.

## Query versão 2

````sql
EXPLAIN ANALYZE 
WITH prod_fornecedor AS (
	SELECT 
	    f.id_produto
	FROM fornecimento f 
	GROUP BY f.id_produto 
	HAVING COUNT(DISTINCT f.id_fornecedor) = 1
),
prod_ativos AS (
	SELECT 
		p.id_produto,
		p.descricao,
		p.categoria
	FROM produtos p 
	WHERE p.ativo = TRUE 
)
SELECT
	pa.descricao,
	pa.categoria
FROM prod_ativos pa
JOIN prod_fornecedor pf
	ON pa.id_produto = pf.id_produto
ORDER BY pa.id_produto 
````

### Query plan 1

````sql
Sort  (cost=150.18..150.18 rows=2 width=25) (actual time=1.682..1.698 rows=196 loops=1)
  Sort Key: p.id_produto
  Sort Method: quicksort  Memory: 33kB
  ->  Hash Join  (cost=135.22..150.17 rows=2 width=25) (actual time=1.389..1.632 rows=196 loops=1)
        Hash Cond: (p.id_produto = f.id_produto)
        ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=549 width=25) (actual time=0.039..0.184 rows=549 loops=1)
              Filter: ativo
              Rows Removed by Filter: 101
        ->  Hash  (cost=135.19..135.19 rows=2 width=4) (actual time=1.339..1.340 rows=239 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 17kB
              ->  GroupAggregate  (cost=0.28..135.19 rows=2 width=4) (actual time=0.031..1.299 rows=239 loops=1)
                    Group Key: f.id_produto
                    Filter: (count(DISTINCT f.id_fornecedor) = 1)
                    Rows Removed by Filter: 202
                    ->  Index Only Scan using idx_fornecimento_produto_fornecedor on fornecimento f  (cost=0.28..110.33 rows=3870 width=8) (actual time=0.024..0.641 rows=3870 loops=1)
                          Heap Fetches: 0
Planning Time: 0.442 ms
Execution Time: 1.772 ms
````

- Tempo de execução de 1.772 ms. Mesmo plano de consulta da consulta anterior, logo, são equivalentes.