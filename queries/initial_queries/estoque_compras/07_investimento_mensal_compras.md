# Investimento mensal em compras

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT  
	date_trunc('month', data_compra) AS mes,
	count(*) AS total_compras,
	sum(c.valor_total) AS total_gasto
FROM compras c 
WHERE c.data_compra BETWEEN '2025-01-01' AND '2025-12-01'
GROUP BY mes
ORDER BY total_gasto; 
````

### Query plan 1

````sql
Sort  (cost=53547.63..53969.24 rows=168644 width=48) (actual time=138.225..138.227 rows=11 loops=1)
  Sort Key: (sum(valor_total))
  Sort Method: quicksort  Memory: 25kB
  ->  HashAggregate  (cost=29538.87..33715.77 rows=168644 width=48) (actual time=138.149..138.206 rows=11 loops=1)
        Group Key: date_trunc('month'::text, data_compra)
        Planned Partitions: 8  Batches: 1  Memory Usage: 793kB
        ->  Bitmap Heap Scan on compras c  (cost=4329.37..18311.24 rows=168678 width=14) (actual time=22.530..91.279 rows=171283 loops=1)
              Recheck Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-12-01 00:00:00'::timestamp without time zone))
              Heap Blocks: exact=5516
              ->  Bitmap Index Scan on idx_compras_data_id  (cost=0.00..4287.20 rows=168678 width=0) (actual time=21.226..21.226 rows=171283 loops=1)
                    Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-12-01 00:00:00'::timestamp without time zone))
Planning Time: 0.215 ms
Execution Time: 139.656 ms
````

- Tempo de execução de 139.656 ms com a utilização do índice idx_compras_data_id e de um  Bitmap Heap Scan em compras

## Query versão 2

````sql
EXPLAIN ANALYZE 
WITH gastos AS (
	SELECT
		c.valor_total,
		c.data_compra
	FROM compras c
	WHERE c.data_compra BETWEEN '2025-01-01' AND '2025-12-01'
)
SELECT
	date_trunc('month', g.data_compra) AS mes,
	count(*) AS total_compras,
	sum(g.valor_total) AS total_gasto
FROM gastos g
GROUP BY mes 
ORDER BY total_gasto; 
````

- Uma alteração no group by pode ser feita, em vez de ordenar pelo mês é possível ordenar por 1: group by 1

### Query plan 1

````sql
Sort  (cost=53547.63..53969.24 rows=168644 width=48) (actual time=126.331..126.334 rows=11 loops=1)
  Sort Key: (sum(c.valor_total))
  Sort Method: quicksort  Memory: 25kB
  ->  HashAggregate  (cost=29538.87..33715.77 rows=168644 width=48) (actual time=126.209..126.316 rows=11 loops=1)
        Group Key: date_trunc('month'::text, c.data_compra)
        Planned Partitions: 8  Batches: 1  Memory Usage: 793kB
        ->  Bitmap Heap Scan on compras c  (cost=4329.37..18311.24 rows=168678 width=14) (actual time=20.702..83.723 rows=171283 loops=1)
              Recheck Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-12-01 00:00:00'::timestamp without time zone))
              Heap Blocks: exact=5516
              ->  Bitmap Index Scan on idx_compras_data_id  (cost=0.00..4287.20 rows=168678 width=0) (actual time=19.379..19.379 rows=171283 loops=1)
                    Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-12-01 00:00:00'::timestamp without time zone))
Planning Time: 0.226 ms
Execution Time: 127.038 ms
````

- Tempo de execução de 127.038 ms com a utilização do índice idx_compras_data_id e Bitmap Heap Scan em compras. Planos de consulta equivalentes quando comparados.