# Receita mensal, gasto mensal e lucro mensal

## Query versão 1

````sql
EXPLAIN ANALYZE 
WITH receita_mensal AS (
	SELECT 
		date_trunc('month', v.data_venda) AS mes,
		sum(v.valor_total) AS receita_mensal
	FROM vendas v 
	WHERE v.data_venda BETWEEN '2025-01-01' AND '2026-01-01'
		AND v.status_pedido = 'Pago'
	GROUP BY 1 
),
custo_mensal AS (
	SELECT 
		date_trunc('month', c.data_compra) AS mes,
		sum(c.valor_total) AS custo_mensal 
	FROM compras c
	WHERE c.data_compra BETWEEN '2025-01-01' AND '2026-01-01'
	GROUP BY 1 
)
SELECT 
	rm.mes,
	rm.receita_mensal,
	cm.custo_mensal,
	(rm.receita_mensal - cm.custo_mensal) AS lucro_mensal
FROM receita_mensal rm
JOIN custo_mensal cm
	ON rm.mes = cm.mes 
ORDER BY lucro_mensal DESC;
````

### Query plan 1

````sql
Sort  (cost=93461431.36..94108193.92 rows=258705021 width=104) (actual time=238.706..238.710 rows=12 loops=1)
  Sort Key: (((sum(v.valor_total)) - cm.custo_mensal)) DESC
  Sort Method: quicksort  Memory: 25kB
  ->  Hash Join  (cost=59616.39..719906.87 rows=258705021 width=104) (actual time=237.519..238.679 rows=12 loops=1)
        Hash Cond: ((date_trunc('month'::text, v.data_venda)) = cm.mes)
        ->  HashAggregate  (cost=29840.31..36789.10 rows=280582 width=40) (actual time=127.327..127.383 rows=12 loops=1)
              Group Key: date_trunc('month'::text, v.data_venda)
              Planned Partitions: 16  Batches: 1  Memory Usage: 793kB
              ->  Index Only Scan using idx_vendas_pago_cover on vendas v  (cost=0.43..11865.52 rows=280582 width=14) (actual time=0.024..70.107 rows=281165 loops=1)
                    Index Cond: ((data_venda >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2026-01-01 00:00:00'::timestamp without time zone))
                    Heap Fetches: 0
        ->  Hash  (cost=26030.01..26030.01 rows=184406 width=40) (actual time=109.377..109.379 rows=12 loops=1)
              Buckets: 131072  Batches: 2  Memory Usage: 1025kB
              ->  Subquery Scan on cm  (cost=19618.62..26030.01 rows=184406 width=40) (actual time=108.880..108.944 rows=12 loops=1)
                    ->  HashAggregate  (cost=19618.62..24185.95 rows=184406 width=40) (actual time=108.879..108.941 rows=12 loops=1)
                          Group Key: date_trunc('month'::text, c.data_compra)
                          Planned Partitions: 8  Batches: 1  Memory Usage: 793kB
                          ->  Index Only Scan using idx_compras_data_id on compras c  (cost=0.42..7802.48 rows=184447 width=14) (actual time=0.042..61.518 rows=186856 loops=1)
                                Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2026-01-01 00:00:00'::timestamp without time zone))
                                Heap Fetches: 0
Planning Time: 0.591 ms
Execution Time: 239.737 ms
````

- Tempo de exeução de 239.737 ms com a utlização de dois Index Only Scan, um em compras com o índice idx_compras_data_id e outro em idx_vendas_pago_cover em vendas.