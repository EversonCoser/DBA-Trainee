# Acumulado de vendas e média móvel

## Query

````sql
EXPLAIN ANALYZE 
WITH acumulado_vendas AS (
	SELECT 
		date_trunc('month', data_venda) AS mes,
		COUNT(*) AS qtd_vendas
	FROM vendas
	WHERE status_pedido = 'Pago'
	  AND data_venda >= '2024-01-01'
	  AND data_venda <  '2025-01-01'
	GROUP BY mes
)
SELECT 
	mes,
	qtd_vendas,
	SUM(qtd_vendas) OVER (ORDER BY mes) AS acumulado_vendas,
	ROUND(
		AVG(qtd_vendas) OVER (
			ORDER BY mes 
			ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
		), 2
	) AS media_3_meses
FROM acumulado_vendas
ORDER BY mes;
````

### Query plan

````sql
WindowAgg  (cost=40426.52..55289.08 rows=284044 width=80) (actual time=115.793..156.292 rows=12 loops=1)
  ->  WindowAgg  (cost=40426.47..50318.31 rows=284044 width=48) (actual time=111.019..156.225 rows=12 loops=1)
        ->  GroupAggregate  (cost=40376.77..46057.65 rows=284044 width=16) (actual time=106.315..156.149 rows=12 loops=1)
              Group Key: (date_trunc('month'::text, vendas.data_venda))
              ->  Sort  (cost=40376.77..41086.88 rows=284044 width=8) (actual time=101.423..128.319 rows=280697 loops=1)
                    Sort Key: (date_trunc('month'::text, vendas.data_venda))
                    Sort Method: external merge  Disk: 3304kB
                    ->  Index Only Scan using idx_vendas_pago_data_id on vendas  (cost=0.43..10763.42 rows=284044 width=8) (actual time=0.031..65.900 rows=280697 loops=1)
                          Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda < '2025-01-01 00:00:00'::timestamp without time zone))
                          Heap Fetches: 0
Planning Time: 0.280 ms
Execution Time: 157.174 ms
````

- Tempo de execução de 157.174 ms com uso do índice idx_vendas_pago_data_id em vendas.