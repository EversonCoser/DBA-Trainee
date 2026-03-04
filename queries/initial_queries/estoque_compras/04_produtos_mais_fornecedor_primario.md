# Produtos com mais de um fornecedor primário

## Query versão 1

````sql
EXPLAIN ANALYZE
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
````

### Query plan 1

````sql
GroupAggregate  (cost=140.23..155.47 rows=217 width=25) (actual time=3.068..3.513 rows=29 loops=1)
  Group Key: p.id_produto
  Filter: (count(DISTINCT f.id_fornecedor) > 1)
  Rows Removed by Filter: 139
  ->  Sort  (cost=140.23..142.60 rows=949 width=29) (actual time=3.044..3.147 rows=948 loops=1)
        Sort Key: p.id_produto, f.id_fornecedor
        Sort Method: quicksort  Memory: 71kB
        ->  Hash Join  (cost=21.62..93.30 rows=949 width=29) (actual time=0.380..1.602 rows=948 loops=1)
              Hash Cond: (f.id_produto = p.id_produto)
              ->  Seq Scan on fornecimento f  (cost=0.00..69.18 rows=949 width=8) (actual time=0.040..0.785 rows=948 loops=1)
                    Filter: (prioridade = 'Primaria'::prioridade_enum)
                    Rows Removed by Filter: 2922
              ->  Hash  (cost=13.50..13.50 rows=650 width=25) (actual time=0.327..0.328 rows=650 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 45kB
                    ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=650 width=25) (actual time=0.017..0.157 rows=650 loops=1)
Planning Time: 0.477 ms
Execution Time: 3.577 ms
````

- Tempo de execução de 3.577 ms. Seq Scan em produtos e fornecimento.
- Índice composto criado na tabela fornecimento nos atributos id_produto e id_fornecedor onde a prioridade é 'Primaria'.

### Query plan 2

````sql
GroupAggregate  (cost=0.61..96.86 rows=217 width=25) (actual time=0.112..1.436 rows=29 loops=1)
  Group Key: p.id_produto
  Filter: (count(DISTINCT f.id_fornecedor) > 1)
  Rows Removed by Filter: 139
  ->  Merge Join  (cost=0.61..84.00 rows=948 width=29) (actual time=0.063..1.073 rows=948 loops=1)
        Merge Cond: (f.id_produto = p.id_produto)
        ->  Index Only Scan using idx_fornecimento_produto_prioridade on fornecimento f  (cost=0.28..34.49 rows=948 width=8) (actual time=0.032..0.276 rows=948 loops=1)
              Heap Fetches: 0
        ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..36.02 rows=650 width=25) (actual time=0.021..0.279 rows=640 loops=1)
Planning Time: 0.720 ms
Execution Time: 1.525 ms
````

- Tempo de execução de 1.525 ms com a utilização do índice pk_produtos_id_produto em produtos e idx_fornecimento_produto_prioridade em fornecimento.

## Query versão 2

````sql
EXPLAIN ANALYZE 		
SELECT 
    p.id_produto,
    p.descricao,
    p.categoria
FROM produtos p
WHERE p.ativo = true
AND EXISTS (
    SELECT 1
    FROM fornecimento f
    WHERE f.id_produto = p.id_produto
      AND f.prioridade = 'Primaria'
    GROUP BY f.id_produto
    HAVING COUNT(DISTINCT f.id_fornecedor) > 1
);
````

### Query plan 1

````sql
Index Scan using idx_produtos_ativo_estoque on produtos p  (cost=0.28..2428.29 rows=275 width=25) (actual time=0.156..2.265 rows=24 loops=1)
  Filter: EXISTS(SubPlan 1)
  Rows Removed by Filter: 525
  SubPlan 1
    ->  GroupAggregate  (cost=0.28..4.33 rows=1 width=8) (actual time=0.003..0.003 rows=0 loops=549)
          Filter: (count(DISTINCT f.id_fornecedor) > 1)
          Rows Removed by Filter: 0
          ->  Index Only Scan using idx_fornecimento_produto_prioridade on fornecimento f  (cost=0.28..4.31 rows=2 width=8) (actual time=0.002..0.002 rows=1 loops=549)
                Index Cond: (id_produto = p.id_produto)
                Heap Fetches: 0
Planning Time: 0.334 ms
Execution Time: 2.327 ms
````

- Tempo de execução de 2.327 ms, superior em compração com a consulta anterior. Utilização do índice idx_fornecimento_produto_prioridade em fornecimento e idx_produtos_ativo_estoque em produtos.

## Query versão 3

````sql
EXPLAIN ANALYZE 
WITH produtos_fornecimento_primario AS (
	SELECT 
		f.id_produto
	FROM fornecimento f 
	WHERE f.prioridade = 'Primaria'
	GROUP BY f.id_produto 
	HAVING COUNT(DISTINCT f.id_fornecedor) > 1
),
produtos_ativos AS (
	SELECT 
		p.id_produto,
		p.descricao,
		p.categoria
	FROM produtos p 
	WHERE ativo = true
)
SELECT 
	pa.descricao,
	pa.categoria
	FROM produtos_fornecimento_primario pfp
	JOIN produtos_ativos pa
		ON pa.id_produto = pfp.id_produto
	ORDER BY pa.id_produto;
````

### Query plan 1

````sql
Sort  (cost=64.82..65.10 rows=114 width=25) (actual time=0.702..0.707 rows=24 loops=1)
  Sort Key: p.id_produto
  Sort Method: quicksort  Memory: 26kB
  ->  Hash Join  (cost=45.97..60.92 rows=114 width=25) (actual time=0.471..0.683 rows=24 loops=1)
        Hash Cond: (p.id_produto = f.id_produto)
        ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=549 width=25) (actual time=0.040..0.188 rows=549 loops=1)
              Filter: ativo
              Rows Removed by Filter: 101
        ->  Hash  (cost=44.28..44.28 rows=135 width=4) (actual time=0.409..0.410 rows=29 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 10kB
              ->  GroupAggregate  (cost=0.28..44.28 rows=135 width=4) (actual time=0.046..0.401 rows=29 loops=1)
                    Group Key: f.id_produto
                    Filter: (count(DISTINCT f.id_fornecedor) > 1)
                    Rows Removed by Filter: 139
                    ->  Index Only Scan using idx_fornecimento_produto_prioridade on fornecimento f  (cost=0.28..34.49 rows=948 width=8) (actual time=0.032..0.197 rows=948 loops=1)
                          Heap Fetches: 0
Planning Time: 0.450 ms
Execution Time: 0.786 ms
````

- Tempo de execução de 0.786 ms com a utilização do índice idx_fornecimento_produto_prioridade em fornecimento e Seq Scan em produtos. Essa consulta foi mais performática em razão da agregação ser realizada primeiro, isso permite reduzir a quantidade de dados nas etapas seguintes. 

## Query versão 4

````sql
EXPLAIN ANALYZE
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
````

### Query plan 1

````sql
Sort  (cost=64.82..65.10 rows=114 width=25) (actual time=0.693..0.697 rows=24 loops=1)
  Sort Key: p.id_produto
  Sort Method: quicksort  Memory: 26kB
  ->  Hash Join  (cost=45.97..60.92 rows=114 width=25) (actual time=0.494..0.678 rows=24 loops=1)
        Hash Cond: (p.id_produto = f.id_produto)
        ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=549 width=25) (actual time=0.030..0.158 rows=549 loops=1)
              Filter: ativo
              Rows Removed by Filter: 101
        ->  Hash  (cost=44.28..44.28 rows=135 width=4) (actual time=0.445..0.446 rows=29 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 10kB
              ->  GroupAggregate  (cost=0.28..44.28 rows=135 width=4) (actual time=0.042..0.435 rows=29 loops=1)
                    Group Key: f.id_produto
                    Filter: (count(DISTINCT f.id_fornecedor) > 1)
                    Rows Removed by Filter: 139
                    ->  Index Only Scan using idx_fornecimento_produto_prioridade on fornecimento f  (cost=0.28..34.49 rows=948 width=8) (actual time=0.027..0.205 rows=948 loops=1)
                          Heap Fetches: 0
Planning Time: 0.388 ms
Execution Time: 0.763 ms
````

- Tempo de execução de 0.763 com a utilização do índice idx_fornecimento_produto_prioridade em fornecimento e Seq Scan em produtos. A consulta com exists e a consulta com CTE sem exists são equivalentes, pois geraram o mesmo plano de execução.