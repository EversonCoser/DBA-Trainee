# Total gasto por fornecedor ativo

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT
    p.nome,
    SUM(c.valor_total) AS total_gasto
FROM compras c
JOIN pessoas p ON p.id_pessoa = c.id_fornecedor
WHERE p.ativo = true
GROUP BY p.nome
ORDER BY total_gasto DESC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=19610.33..19610.36 rows=10 width=45) (actual time=165.419..169.504 rows=10 loops=1)
  ->  Sort  (cost=19610.33..19632.86 rows=9012 width=45) (actual time=165.418..169.501 rows=10 loops=1)
        Sort Key: (sum(c.valor_total)) DESC
        Sort Method: top-N heapsort  Memory: 26kB
        ->  Finalize HashAggregate  (cost=19302.94..19415.59 rows=9012 width=45) (actual time=165.038..169.289 rows=233 loops=1)
              Group Key: p.nome
              Batches: 1  Memory Usage: 529kB
              ->  Gather  (cost=17252.71..19167.76 rows=18024 width=45) (actual time=163.748..168.137 rows=699 loops=1)
                    Workers Planned: 2
                    Workers Launched: 2
                    ->  Partial HashAggregate  (cost=16252.71..16365.36 rows=9012 width=45) (actual time=109.970..110.143 rows=233 loops=3)
                          Group Key: p.nome
                          Batches: 1  Memory Usage: 529kB
                          Worker 0:  Batches: 1  Memory Usage: 529kB
                          Worker 1:  Batches: 1  Memory Usage: 529kB
                          ->  Hash Join  (cost=486.12..15461.63 rows=158216 width=19) (actual time=17.048..77.599 rows=129659 loops=3)
                                Hash Cond: (c.id_fornecedor = p.id_pessoa)
                                ->  Parallel Seq Scan on compras c  (cost=0.00..14155.00 rows=312500 width=10) (actual time=12.688..31.434 rows=250000 loops=3)
                                ->  Hash  (cost=373.47..373.47 rows=9012 width=17) (actual time=4.252..4.253 rows=9012 loops=3)
                                      Buckets: 16384  Batches: 1  Memory Usage: 584kB
                                      ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.099..2.709 rows=9012 loops=3)
Planning Time: 0.513 ms
Execution Time: 170.299 ms
````

- Tempo de 170.299 ms com utilização do índice idx_pessoas_ativas em pessoas e Seq Scan em compras
- Índice no atributo id_fornecedor da tabela compras criado.

## Query versão 2

````sql
EXPLAIN ANALYZE 
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
````

### Query plan 1

````sql
Limit  (cost=17269.19..17269.21 rows=10 width=45) (actual time=155.727..156.824 rows=10 loops=1)
  ->  Sort  (cost=17269.19..17269.76 rows=228 width=45) (actual time=155.725..156.821 rows=10 loops=1)
        Sort Key: (sum(c.valor_total)) DESC
        Sort Method: top-N heapsort  Memory: 26kB
        ->  Merge Join  (cost=16743.26..17264.26 rows=228 width=45) (actual time=154.287..156.712 rows=233 loops=1)
              Merge Cond: (c.id_fornecedor = p.id_pessoa)
              ->  Finalize GroupAggregate  (cost=16742.98..16860.36 rows=450 width=36) (actual time=150.939..153.163 rows=450 loops=1)
                    Group Key: c.id_fornecedor
                    ->  Gather Merge  (cost=16742.98..16847.99 rows=900 width=36) (actual time=150.930..152.380 rows=1350 loops=1)
                          Workers Planned: 2
                          Workers Launched: 2
                          ->  Sort  (cost=15742.96..15744.08 rows=450 width=36) (actual time=93.878..93.902 rows=450 loops=3)
                                Sort Key: c.id_fornecedor
                                Sort Method: quicksort  Memory: 63kB
                                Worker 0:  Sort Method: quicksort  Memory: 63kB
                                Worker 1:  Sort Method: quicksort  Memory: 63kB
                                ->  Partial HashAggregate  (cost=15717.50..15723.12 rows=450 width=36) (actual time=93.658..93.766 rows=450 loops=3)
                                      Group Key: c.id_fornecedor
                                      Batches: 1  Memory Usage: 285kB
                                      Worker 0:  Batches: 1  Memory Usage: 285kB
                                      Worker 1:  Batches: 1  Memory Usage: 285kB
                                      ->  Parallel Seq Scan on compras c  (cost=0.00..14155.00 rows=312500 width=10) (actual time=12.182..29.310 rows=250000 loops=3)
              ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.019..2.458 rows=9012 loops=1)
Planning Time: 0.388 ms
Execution Time: 157.018 ms
````

- Tempo de execução de 157.018 ms. Utilização do índice idx_pessoas_ativas na tabela pessoas e Seq Scan em compras.
- Consulta com CTE e sem CTE são equivalentes. 