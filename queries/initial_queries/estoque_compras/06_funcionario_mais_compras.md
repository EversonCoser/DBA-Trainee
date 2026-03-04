# Funcionários que mais realizaram compras e valor total gasto

## Query versão 1

````sql
EXPLAIN ANALYZE 
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
ORDER BY p.id_pessoa 
````

### Query plan 1

````sql
Merge Join  (cost=17249.39..17744.29 rows=177 width=57) (actual time=90.541..93.068 rows=167 loops=1)
  Merge Cond: (p.id_pessoa = c.id_funcionario)
  ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.018..2.326 rows=8780 loops=1)
  ->  Finalize GroupAggregate  (cost=17249.10..17342.15 rows=350 width=44) (actual time=87.387..89.780 rows=350 loops=1)
        Group Key: c.id_funcionario
        ->  Gather Merge  (cost=17249.10..17330.78 rows=700 width=44) (actual time=87.375..89.054 rows=1050 loops=1)
              Workers Planned: 2
              Workers Launched: 2
              ->  Sort  (cost=16249.08..16249.95 rows=350 width=44) (actual time=44.011..44.032 rows=350 loops=3)
                    Sort Key: c.id_funcionario
                    Sort Method: quicksort  Memory: 60kB
                    Worker 0:  Sort Method: quicksort  Memory: 60kB
                    Worker 1:  Sort Method: quicksort  Memory: 60kB
                    ->  Partial HashAggregate  (cost=16229.92..16234.29 rows=350 width=44) (actual time=43.812..43.904 rows=350 loops=3)
                          Group Key: c.id_funcionario
                          Batches: 1  Memory Usage: 285kB
                          Worker 0:  Batches: 1  Memory Usage: 285kB
                          Worker 1:  Batches: 1  Memory Usage: 285kB
                          ->  Parallel Seq Scan on compras c  (cost=0.00..15717.50 rows=68322 width=10) (actual time=4.548..30.529 rows=54246 loops=3)
                                Filter: ((data_compra >= '2022-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2022-12-31 00:00:00'::timestamp without time zone))
                                Rows Removed by Filter: 195754
Planning Time: 0.391 ms
Execution Time: 93.242 ms
````

- Tempo de execução de 93.242 ms com um Seq Scan em compras seguido da agregação e posterior utilização do índice idx_pessoas_ativas em pessoas.

## Query versão 2

````sql
EXPLAIN ANALYZE 
WITH funcionario_compras AS (
	SELECT 
		c.id_funcionario,
		COUNT(*) AS qtd_compras,
		SUM(c.valor_total) AS valor_total_gasto
	FROM compras c 
	WHERE c.data_compra BETWEEN '2022-01-01' AND '2022-12-31'
	GROUP BY c.id_funcionario 
),
pessoas_ativas AS (
	SELECT 
		p.nome,
		p.id_pessoa 
	FROM pessoas p
	WHERE p.ativo = TRUE 
)
SELECT 
	p.nome,
	fc.qtd_compras,
	fc.valor_total_gasto
FROM pessoas_ativas p 
JOIN funcionario_compras fc
	ON fc.id_funcionario = p.id_pessoa 
ORDER BY p.id_pessoa 
````

### Query plan 1

````sql
Merge Join  (cost=17249.39..17744.29 rows=177 width=57) (actual time=102.606..106.476 rows=167 loops=1)
  Merge Cond: (p.id_pessoa = c.id_funcionario)
  ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.016..2.127 rows=8780 loops=1)
  ->  Finalize GroupAggregate  (cost=17249.10..17342.15 rows=350 width=44) (actual time=99.759..103.494 rows=350 loops=1)
        Group Key: c.id_funcionario
        ->  Gather Merge  (cost=17249.10..17330.78 rows=700 width=44) (actual time=99.713..102.781 rows=1050 loops=1)
              Workers Planned: 2
              Workers Launched: 2
              ->  Sort  (cost=16249.08..16249.95 rows=350 width=44) (actual time=49.304..49.328 rows=350 loops=3)
                    Sort Key: c.id_funcionario
                    Sort Method: quicksort  Memory: 60kB
                    Worker 0:  Sort Method: quicksort  Memory: 60kB
                    Worker 1:  Sort Method: quicksort  Memory: 60kB
                    ->  Partial HashAggregate  (cost=16229.92..16234.29 rows=350 width=44) (actual time=49.076..49.181 rows=350 loops=3)
                          Group Key: c.id_funcionario
                          Batches: 1  Memory Usage: 285kB
                          Worker 0:  Batches: 1  Memory Usage: 285kB
                          Worker 1:  Batches: 1  Memory Usage: 285kB
                          ->  Parallel Seq Scan on compras c  (cost=0.00..15717.50 rows=68322 width=10) (actual time=4.306..33.669 rows=54246 loops=3)
                                Filter: ((data_compra >= '2022-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2022-12-31 00:00:00'::timestamp without time zone))
                                Rows Removed by Filter: 195754
Planning Time: 0.378 ms
Execution Time: 106.632 ms
````

- Tempo de execução de 106.632. Mesmo plano de consulta da query na versão 1. Ambas as consultas são equivalentes.