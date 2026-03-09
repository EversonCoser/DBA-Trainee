# Total de vendas, faturamento e tiket médio por mês

## Query versão 1
- Função DATE_TRUNC para processar o mês.
- Contagem da quantidade de vendas, utilizando COUNT.
- Faturamento total, utilizando SUM.
- Ticket médio, utilizando AVG e ROUND para arredondamento em duas casas decimais.
- Utilização de índices criado na etapa 1.
- Tabela vendas com 1.500.000 registros.

```sql
EXPLAIN ANALYZE
SELECT 
    DATE_TRUNC('month', data_venda) AS mes,
    SUM(valor_total) AS faturamento,
    COUNT(*) AS total_vendas,
    ROUND(AVG(valor_total), 2) AS ticket_medio
FROM vendas
    WHERE status_pedido = 'Pago'
    AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY mes
    ORDER BY faturamento DESC;
```
### Query plan 1

```sql
Sort  (cost=78207.89..78915.93 rows=283216 width=80) (actual time=154.017..154.018 rows=12 loops=1)
   Sort Key: (sum(valor_total)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=31544.39..39974.49 rows=283216 width=80) (actual time=153.886..154.003 rows=12 loops=1)
         Group Key: date_trunc('month'::text, data_venda)
         Planned Partitions: 16  Batches: 1  Memory Usage: 793kB
         ->  Index Only Scan using idx_vendas_covering on vendas  (cost=0.43..12692.83 rows=283216 width=14) (actual time=0.034..85.506 rows=279922 loops=1)
               Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
               Heap Fetches: 0
 Planning Time: 0.194 ms
 Execution Time: 154.584 ms
```

- Tempo de execução de 154.584 ms, utilização de Index Only Scan usando idx_vendas_covering na tabela vendas e HashAggregate. Sort realizado em memória.

## Query versão 2

- Utilização de CTE

````sql
EXPLAIN ANALYSE
WITH vendas_mensais AS (
    SELECT
        DATE_TRUNC('month', data_venda) AS mes,
        SUM(valor_total) AS faturamento,
        COUNT(*) AS total_vendas
    FROM vendas
    WHERE status_pedido = 'Pago'
    AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY mes
)
SELECT 
    mes,
    faturamento,
    total_vendas,
    ROUND(faturamento / NULLIF(total_vendas,0), 2) AS ticket_medio
FROM vendas_mensais
ORDER BY faturamento DESC;
````

### Query plan 2

````sql
Sort  (cost=79623.97..80332.01 rows=283216 width=80) (actual time=145.050..145.051 rows=12 loops=1)
   Sort Key: vendas_mensais.faturamento DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Subquery Scan on vendas_mensais  (cost=31544.39..41390.57 rows=283216 width=80) (actual time=144.924..145.036 rows=12 loops=1)
         ->  HashAggregate  (cost=31544.39..38558.41 rows=283216 width=48) (actual time=144.920..145.025 rows=12 loops=1)
               Group Key: date_trunc('month'::text, vendas.data_venda)
               Planned Partitions: 16  Batches: 1  Memory Usage: 793kB
               ->  Index Only Scan using idx_vendas_covering on vendas  (cost=0.43..12692.83 rows=283216 width=14) (actual time=0.042..78.799 rows=279922 loops=1)
                     Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                     Heap Fetches: 0
 Planning Time: 0.379 ms
 Execution Time: 145.775 ms
````

- A utilização da CTE apresentou um pequeno ganho de performance, com tempo de execução de 145.775. No entanto, as consultas estão equivalentes, esse ganho provavelmente está associado à utilização de cache. Novamente, o índice idx_vendas_covering foi utilizado, seguido de um HashAggregate. Além disso, uma leitura foi realizada na tabela temporaria vendas_mensais para ordenação.

## Query com window function para criar uma classificação do mês com maior faturamento para o mês de menor faturamento

````sql
WITH ranking_faturamento_mes AS (
	SELECT 
		to_char(data_venda, 'MM/YYYY') AS mes,
	    SUM(valor_total) AS faturamento,
	    COUNT(*) AS total_vendas,
	    ROUND(AVG(valor_total), 2) AS ticket_medio
	FROM vendas
	    WHERE status_pedido = 'Pago'
	    AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
	    GROUP BY mes
)
SELECT 
	mes,
	faturamento,
	total_vendas,
	ticket_medio,
	rank() over(ORDER BY faturamento DESC) AS posicao
FROM ranking_faturamento_mes;
````

### Query plan 1

````sql
WindowAgg  (cost=88694.21..93650.47 rows=283216 width=112) (actual time=150.196..150.205 rows=12 loops=1)
  ->  Sort  (cost=88694.19..89402.23 rows=283216 width=104) (actual time=150.183..150.184 rows=12 loops=1)
        Sort Key: ranking_faturamento_mes.faturamento DESC
        Sort Method: quicksort  Memory: 25kB
        ->  Subquery Scan on ranking_faturamento_mes  (cost=37466.23..47555.80 rows=283216 width=104) (actual time=150.105..150.172 rows=12 loops=1)
              ->  HashAggregate  (cost=37466.23..47555.80 rows=283216 width=104) (actual time=150.104..150.170 rows=12 loops=1)
                    Group Key: to_char(vendas.data_venda, 'MM/YYYY'::text)
                    Planned Partitions: 16  Batches: 1  Memory Usage: 793kB
                    ->  Index Only Scan using idx_vendas_pago_cover on vendas  (cost=0.43..11976.79 rows=283216 width=38) (actual time=0.043..92.825 rows=279922 loops=1)
                          Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                          Heap Fetches: 0
Planning Time: 0.343 ms
Execution Time: 150.681 ms
````