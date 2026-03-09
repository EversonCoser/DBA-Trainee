# Quantidade de vendas em cada mês e comparação com o mês anterior

## Query verão 1 - Comparação com o mês anterior

````sql
EXPLAIN ANALYZE
WITH total_vendas_comparadas AS (
	SELECT 
		to_char(data_venda, 'MM/YYYY') AS mes,
		count(*) AS qtd_total_vendas
	FROM vendas v 
	WHERE v.status_pedido = 'Pago'
		AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
	GROUP BY mes
	ORDER BY mes 
)
SELECT 
	tvc.mes,
	tvc.qtd_total_vendas,
	lag(tvc.qtd_total_vendas) OVER (ORDER BY mes) AS vendas_mes_anterior
FROM total_vendas_comparadas tvc
ORDER BY mes;
````

### Query plan 1

````sql
WindowAgg  (cost=43209.24..53072.24 rows=283216 width=48) (actual time=202.406..267.663 rows=12 loops=1)
  ->  GroupAggregate  (cost=43159.68..48824.00 rows=283216 width=40) (actual time=198.147..267.597 rows=12 loops=1)
        Group Key: (to_char(v.data_venda, 'MM/YYYY'::text))
        ->  Sort  (cost=43159.68..43867.72 rows=283216 width=32) (actual time=192.695..231.035 rows=279922 loops=1)
              Sort Key: (to_char(v.data_venda, 'MM/YYYY'::text))
              Sort Method: external merge  Disk: 4112kB
              ->  Index Only Scan using idx_vendas_pago_data_id on vendas v  (cost=0.43..10732.79 rows=283216 width=32) (actual time=0.037..143.158 rows=279922 loops=1)
                    Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                    Heap Fetches: 0
Planning Time: 0.333 ms
Execution Time: 269.744 ms
````

- Tempo de execução de 269.744 ms com uso do índice idx_vendas_pago_data_id em vendas.

# Quantidade de vendas em cada ano e comparação com o ano anterior

## Query versão 2 - Comparação com o ano anterior

````sql
EXPLAIN ANALYZE 
WITH total_vendas_comparadas AS (
	SELECT 
		date_trunc('year', data_venda) AS ano,
		count(*) AS qtd_total_vendas
	FROM vendas v 
	WHERE v.status_pedido = 'Pago'
	GROUP BY ano
)
SELECT 
	tvc.ano,
	tvc.qtd_total_vendas,
	lag(tvc.qtd_total_vendas) OVER (ORDER BY ano) AS vendas_ano_anterior
FROM total_vendas_comparadas tvc
ORDER BY ano;
````

- Essa consulta é referente a todo o período de vendas, para melhorar a performance um filtro por data é necessário.

### Query plan 1

````sql
WindowAgg  (cost=165130.39..204190.11 rows=1121600 width=24) (actual time=371.666..440.340 rows=5 loops=1)
  ->  GroupAggregate  (cost=164934.11..187366.11 rows=1121600 width=16) (actual time=337.347..440.251 rows=5 loops=1)
        Group Key: (date_trunc('year'::text, v.data_venda))
        ->  Sort  (cost=164934.11..167738.11 rows=1121600 width=8) (actual time=305.920..376.966 rows=1124584 loops=1)
              Sort Key: (date_trunc('year'::text, v.data_venda))
              Sort Method: external merge  Disk: 13232kB
              ->  Index Only Scan using idx_vendas_pago_data_id on vendas v  (cost=0.43..36892.43 rows=1121600 width=8) (actual time=0.032..205.481 rows=1124584 loops=1)
                    Heap Fetches: 0
Planning Time: 0.272 ms
Execution Time: 442.143 ms
````

- Tempo de execução de 442.143 ms com uso do índice idx_vendas_pago_data_id em vendas.

# Comparação da quantidade total de vendas entre os meses do ano de 2023 a 2025

## Query versão 1

````sql
EXPLAIN ANALYZE 
WITH total_vendas_comparadas AS (
	SELECT 
		date_trunc('month', v.data_venda ) AS mes,
		count(*) AS qtd_total_vendas
	FROM vendas v 
	WHERE v.status_pedido = 'Pago'
		AND v.data_venda BETWEEN '2023-01-01' AND '2026-01-01'
	GROUP BY mes
	ORDER BY mes 
)
SELECT 
	tvc.mes,
	tvc.qtd_total_vendas,
	lag(tvc.qtd_total_vendas, 12, 0) OVER (ORDER BY mes) AS vendas_mes_anterior
FROM total_vendas_comparadas tvc
ORDER BY mes;
````

### Query plan 1

````sql
WindowAgg  (cost=126533.44..155877.61 rows=842618 width=24) (actual time=333.741..478.388 rows=36 loops=1)
  ->  GroupAggregate  (cost=126385.98..143238.34 rows=842618 width=16) (actual time=329.823..478.232 rows=36 loops=1)
        Group Key: (date_trunc('month'::text, v.data_venda))
        ->  Sort  (cost=126385.98..128492.53 rows=842618 width=8) (actual time=324.768..404.345 rows=842355 loops=1)
              Sort Key: (date_trunc('month'::text, v.data_venda))
              Sort Method: external merge  Disk: 9912kB
              ->  Index Only Scan using idx_vendas_pago_data_id on vendas v  (cost=0.43..31931.33 rows=842618 width=8) (actual time=0.026..226.017 rows=842355 loops=1)
                    Index Cond: ((data_venda >= '2023-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2026-01-01 00:00:00'::timestamp without time zone))
                    Heap Fetches: 0
Planning Time: 0.283 ms
Execution Time: 481.450 ms
````

- Tempo de execução de 481.450 ms e uso do índice idx_vendas_pago_data_id em vendas.