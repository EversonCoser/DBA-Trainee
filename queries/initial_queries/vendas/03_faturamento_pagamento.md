# Faturamento e total de vendas por forma de pagamento

## Query versão 1
- Contagem da quantidade de vendas, utilizando COUNT.
- Faturamento utilizando SUM.
- Utilização de índices criado na etapa 1.
- Tabela vendas com 1.500.000 registros.
- Tabela formas_pagamento com 5 registros.

```sql
EXPLAIN ANALYZE
SELECT
    fp.nome AS forma_pagamento,
    SUM(v.valor_total) AS faturamento,
    COUNT(*) AS total_vendas
FROM vendas v
JOIN formas_pagamento fp 
    ON fp.id_forma_pagamento = v.id_forma_pagamento
WHERE v.status_pedido = 'Pago'
    AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY fp.id_forma_pagamento
ORDER BY faturamento DESC;
```

### Query plan 1

```sql
Sort  (cost=38981.70..38987.35 rows=2260 width=48) (actual time=152.202..158.563 rows=5 loops=1)
   Sort Key: (sum(v.valor_total)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Finalize GroupAggregate  (cost=38254.98..38855.80 rows=2260 width=48) (actual time=152.182..158.553 rows=5 loops=1)
         Group Key: fp.id_forma_pagamento
         ->  Gather Merge  (cost=38254.98..38782.35 rows=4520 width=48) (actual time=152.172..158.535 rows=15 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Sort  (cost=37254.95..37260.60 rows=2260 width=48) (actual time=95.160..95.162 rows=5 loops=3)
                     Sort Key: fp.id_forma_pagamento
                     Sort Method: quicksort  Memory: 25kB
                     Worker 0:  Sort Method: quicksort  Memory: 25kB
                     Worker 1:  Sort Method: quicksort  Memory: 25kB
                     ->  Partial HashAggregate  (cost=37100.80..37129.05 rows=2260 width=48) (actual time=95.125..95.137 rows=5 loops=3)
                           Group Key: fp.id_forma_pagamento
                           Batches: 1  Memory Usage: 121kB
                           Worker 0:  Batches: 1  Memory Usage: 121kB
                           Worker 1:  Batches: 1  Memory Usage: 121kB
                           ->  Hash Join  (cost=8036.28..36215.75 rows=118007 width=14) (actual time=17.001..75.374 rows=93307 loops=3)
                                 Hash Cond: (v.id_forma_pagamento = fp.id_forma_pagamento)
                                 ->  Parallel Bitmap Heap Scan on vendas v  (cost=7975.43..35844.55 rows=118007 width=10) (actual time=16.901..51.718 rows=93307 loops=3)
                                       Recheck Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                       Heap Blocks: exact=4946
                                       ->  Bitmap Index Scan on idx_vendas_status_data  (cost=0.00..7904.63 rows=283216 width=0) (actual time=44.773..44.773 rows=279922 loops=1)
                                             Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                 ->  Hash  (cost=32.60..32.60 rows=2260 width=8) (actual time=0.060..0.060 rows=5 loops=3)
                                       Buckets: 4096  Batches: 1  Memory Usage: 33kB
                                       ->  Seq Scan on formas_pagamento fp  (cost=0.00..32.60 rows=2260 width=8) (actual time=0.050..0.051 rows=5 loops=3)
 Planning Time: 0.460 ms
 Execution Time: 158.896 ms
```

- O plano de execução mostra um custo de 158.896 ms com um Seq Scan em formas_pagamento seguido de um Hash. Na sequência o índice idx_vendas_status_data foi utilizado e Parallel Bitmap Heap Scan em vendas seguido de um Hash Join.

## Query versão 2

```sql
EXPLAIN ANALYZE
WITH faturamento_pagamento AS (
    SELECT 
        fp.id_forma_pagamento,
        fp.nome AS forma_pagamento,
        v.valor_total 
    FROM vendas v 
    JOIN formas_pagamento fp 
        ON v.id_forma_pagamento = fp.id_forma_pagamento
    WHERE v.status_pedido = 'Pago'
        AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
)
SELECT 
    forma_pagamento,
    SUM(valor_total) AS faturamento,
    COUNT(*) AS total_vendas
FROM faturamento_pagamento
GROUP BY id_forma_pagamento, forma_pagamento
ORDER BY faturamento DESC;
```

### Query plan 2

````sql
Sort  (cost=38981.70..38987.35 rows=2260 width=48) (actual time=138.655..144.787 rows=5 loops=1)
   Sort Key: (sum(v.valor_total)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Finalize GroupAggregate  (cost=38254.98..38855.80 rows=2260 width=48) (actual time=138.635..144.777 rows=5 loops=1)
         Group Key: fp.id_forma_pagamento
         ->  Gather Merge  (cost=38254.98..38782.35 rows=4520 width=48) (actual time=138.622..144.756 rows=15 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Sort  (cost=37254.95..37260.60 rows=2260 width=48) (actual time=87.147..87.150 rows=5 loops=3)
                     Sort Key: fp.id_forma_pagamento
                     Sort Method: quicksort  Memory: 25kB
                     Worker 0:  Sort Method: quicksort  Memory: 25kB
                     Worker 1:  Sort Method: quicksort  Memory: 25kB
                     ->  Partial HashAggregate  (cost=37100.80..37129.05 rows=2260 width=48) (actual time=87.113..87.127 rows=5 loops=3)
                           Group Key: fp.id_forma_pagamento
                           Batches: 1  Memory Usage: 121kB
                           Worker 0:  Batches: 1  Memory Usage: 121kB
                           Worker 1:  Batches: 1  Memory Usage: 121kB
                           ->  Hash Join  (cost=8036.28..36215.75 rows=118007 width=14) (actual time=12.680..67.690 rows=93307 loops=3)
                                 Hash Cond: (v.id_forma_pagamento = fp.id_forma_pagamento)
                                 ->  Parallel Bitmap Heap Scan on vendas v  (cost=7975.43..35844.55 rows=118007 width=10) (actual time=12.593..44.121 rows=93307 loops=3)
                                       Recheck Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                       Heap Blocks: exact=5234
                                       ->  Bitmap Index Scan on idx_vendas_status_data  (cost=0.00..7904.63 rows=283216 width=0) (actual time=32.495..32.496 rows=279922 loops=1)
                                             Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                 ->  Hash  (cost=32.60..32.60 rows=2260 width=8) (actual time=0.057..0.058 rows=5 loops=3)
                                       Buckets: 4096  Batches: 1  Memory Usage: 33kB
                                       ->  Seq Scan on formas_pagamento fp  (cost=0.00..32.60 rows=2260 width=8) (actual time=0.045..0.046 rows=5 loops=3)
 Planning Time: 0.393 ms
 Execution Time: 145.122 ms
````
- Novamente, com CTE o custo de processamento diminuiu, muito em razão da utilização de dados que já estão em cache. Uma leitura sequencial foi realizada na tabela formas_pagamento seguido de um Hash e utilização do índice idx_vendas_status_data. Além disso, um Parallel Bitmap Heap Scan em vendas foi realizado, seguido do Hash Join. Ambas as consultas podem ser consideradas equivalentes.
- É válido resaltar que um índice específico para essa consulta poderia ser criado em caso de inúmeras leituras em vários momentos do dia.

````sql
CREATE INDEX idx_vendas_relatorio
ON vendas (status_pedido, data_venda, id_forma_pagamento)
INCLUDE (valor_total);
````

## Query versão 3

`````sql
WITH vendas_agrupadas AS (
    SELECT 
        id_forma_pagamento,
        SUM(valor_total) AS faturamento,
        COUNT(*) AS total_vendas
    FROM vendas
    WHERE status_pedido = 'Pago'
      AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY id_forma_pagamento
)
SELECT 
    fp.nome AS forma_pagamento,
    v.faturamento,
    v.total_vendas
FROM vendas_agrupadas v
JOIN formas_pagamento fp
    ON fp.id_forma_pagamento = v.id_forma_pagamento
ORDER BY v.faturamento DESC;
`````

-- Consulta reorganizada para realizar o agrupamento antes do join.

### Query plan 1

````sql
Sort  (cost=37756.05..37756.06 rows=5 width=44) (actual time=138.052..144.076 rows=5 loops=1)
   Sort Key: (sum(vendas.valor_total)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Nested Loop  (cost=37729.90..37755.99 rows=5 width=44) (actual time=138.010..144.057 rows=5 loops=1)
         ->  Finalize GroupAggregate  (cost=37729.74..37731.07 rows=5 width=44) (actual time=137.985..144.020 rows=5 loops=1)
               Group Key: vendas.id_forma_pagamento
               ->  Gather Merge  (cost=37729.74..37730.91 rows=10 width=44) (actual time=137.974..143.999 rows=15 loops=1)
                     Workers Planned: 2
                     Workers Launched: 2
                     ->  Sort  (cost=36729.72..36729.73 rows=5 width=44) (actual time=79.152..79.153 rows=5 loops=3)
                           Sort Key: vendas.id_forma_pagamento
                           Sort Method: quicksort  Memory: 25kB
                           Worker 0:  Sort Method: quicksort  Memory: 25kB
                           Worker 1:  Sort Method: quicksort  Memory: 25kB
                           ->  Partial HashAggregate  (cost=36729.60..36729.66 rows=5 width=44) (actual time=79.117..79.120 rows=5 loops=3)
                                 Group Key: vendas.id_forma_pagamento
                                 Batches: 1  Memory Usage: 24kB
                                 Worker 0:  Batches: 1  Memory Usage: 24kB
                                 Worker 1:  Batches: 1  Memory Usage: 24kB
                                 ->  Parallel Bitmap Heap Scan on vendas  (cost=7975.43..35844.55 rows=118007 width=10) (actual time=18.745..53.616 rows=93307 loops=3)
                                       Recheck Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                       Heap Blocks: exact=5668
                                       ->  Bitmap Index Scan on idx_vendas_status_data  (cost=0.00..7904.63 rows=283216 width=0) (actual time=50.629..50.629 rows=279922 loops=1)
                                             Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
         ->  Index Scan using pk_formas_pagamento_id_forma_pagamento on formas_pagamento fp  (cost=0.15..4.97 rows=1 width=8) (actual time=0.005..0.005 rows=1 loops=5)
               Index Cond: (id_forma_pagamento = vendas.id_forma_pagamento)
 Planning Time: 0.857 ms
 Execution Time: 144.310 ms
 ````

 - Consulta executada em 144.310 ms