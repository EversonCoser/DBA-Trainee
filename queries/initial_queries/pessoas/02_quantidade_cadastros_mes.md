# Quantidade de cadastros por mês

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT
    DATE_TRUNC('month', data_cadastro) AS mes,
    COUNT(*) AS total_cadastros
FROM pessoas
WHERE data_cadastro BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY mes
ORDER BY mes;
````

### Query plan 1

````sql
Sort  (cost=662.87..667.12 rows=1702 width=16) (actual time=8.065..8.069 rows=12 loops=1)
   Sort Key: (date_trunc('month'::text, data_cadastro))
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=550.26..571.53 rows=1702 width=16) (actual time=8.031..8.049 rows=12 loops=1)
         Group Key: date_trunc('month'::text, data_cadastro)
         Batches: 1  Memory Usage: 73kB
         ->  Seq Scan on pessoas  (cost=0.00..528.09 rows=4434 width=8) (actual time=0.035..6.684 rows=4440 loops=1)
               Filter: ((data_cadastro >= '2023-01-01 00:00:00'::timestamp without time zone) AND (data_cadastro <= '2023-12-31 00:00:00'::timestamp without time zone))
               Rows Removed by Filter: 13360
 Planning Time: 0.249 ms
 Execution Time: 8.190 ms
````

- Tempo de execução de 8.190 ms com uma leitura sequencial em pessoas.
- Criação de um índice em data_cadastro.

### Query plan 2

````sql
Sort  (cost=258.84..263.09 rows=1702 width=16) (actual time=5.366..5.369 rows=12 loops=1)
   Sort Key: (date_trunc('month'::text, data_cadastro))
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=146.22..167.50 rows=1702 width=16) (actual time=5.330..5.345 rows=12 loops=1)
         Group Key: date_trunc('month'::text, data_cadastro)
         Batches: 1  Memory Usage: 73kB
         ->  Index Only Scan using idx_pessoas_data_cadastro on pessoas  (cost=0.29..124.05 rows=4434 width=8) (actual time=0.692..3.549 rows=4440 loops=1)
               Index Cond: ((data_cadastro >= '2023-01-01 00:00:00'::timestamp without time zone) AND (data_cadastro <= '2023-12-31 00:00:00'::timestamp without time zone))
               Heap Fetches: 0
 Planning Time: 1.456 ms
 Execution Time: 5.535 ms
````

- Tempo de execução de 5.535 ms e utilização do índice idx_pessoas_data_cadastro na tabela pessoas.

## Query versão 2

````sql
EXPLAIN ANALYZE
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
ORDER BY mes;
````

### Query plan 1

````sql
Sort  (cost=258.84..263.09 rows=1702 width=16) (actual time=3.950..3.954 rows=12 loops=1)
   Sort Key: (date_trunc('month'::text, pessoas.data_cadastro))
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=146.22..167.50 rows=1702 width=16) (actual time=3.914..3.932 rows=12 loops=1)
         Group Key: date_trunc('month'::text, pessoas.data_cadastro)
         Batches: 1  Memory Usage: 73kB
         ->  Index Only Scan using idx_pessoas_data_cadastro on pessoas  (cost=0.29..124.05 rows=4434 width=8) (actual time=0.052..2.293 rows=4440 loops=1)
               Index Cond: ((data_cadastro >= '2023-01-01 00:00:00'::timestamp without time zone) AND (data_cadastro <= '2023-12-31 00:00:00'::timestamp without time zone))
               Heap Fetches: 0
 Planning Time: 0.371 ms
 Execution Time: 4.046 ms
````

- O plano de execução para a consulta com cte e sem cte são equivalentes, com CTE o tempo de execução foi ligeiramente menor em comparação com a outra consulta.