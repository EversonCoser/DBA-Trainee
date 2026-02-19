# Total de vendas, faturamento e tiket médio 

## Query versão 1
- Contagem da quantidade de vendas, utilizando COUNT.
- Faturamento total, utilizando SUM.
- Ticket médio, utilizando AVG e ROUND para arredondamento em duas casas decimais.
- Nenhum índice criado até o momento.
- Tabela vendas com 1.500.000 registros.

```sql
EXPLAIN ANALYZE
SELECT 
    COUNT(*) AS total_vendas,
    SUM(valor_total) AS faturamento_total,
    ROUND(AVG(valor_total), 2) AS ticket_medio
FROM vendas
    WHERE status_pedido = 'Pago' 
    AND data_venda BETWEEN '2024-01-01' 
    AND '2024-12-31';
```
### Query plan 1

```sql
 Finalize Aggregate  (cost=38331.77..38331.78 rows=1 width=72) (actual time=351.033..356.664 rows=1 loops=1)
   ->  Gather  (cost=38331.54..38331.75 rows=2 width=72) (actual time=350.926..356.562 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=37331.54..37331.55 rows=1 width=72) (actual time=279.872..279.873 rows=1 loops=3)
               ->  Parallel Seq Scan on vendas  (cost=0.00..36741.50 rows=118007 width=6) (actual time=101.795..268.447 rows=93307 loops=3)
                     Filter: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
                     Rows Removed by Filter: 406693
 Planning Time: 132.059 ms
 Execution Time: 356.807 ms
 ```
- O plano de execução indica que o PostgreSQL levou 132,059 ms para planejar e 356,807 ms para executar a consulta, optando por um Parallel Seq Scan na tabela vendas, ou seja, realizou uma varredura completa da tabela. Em seguida, realizou uma agregação parcial (COUNT, SUM e AVG), os resultados foram reunidos pelo operador Gather e consolidados em Finalize Aggregate para gerar o resultado final.
- Após essa análise um índice em data_venda foi criado.
- Fica evidente que ao ler a tabela completa muitas informações desnecessárias foram acessadas, o que contribuiu para o tempo de execução.

### Query plan 2

```sql
Finalize Aggregate  (cost=38174.99..38175.01 rows=1 width=72) (actual time=122.280..129.017 rows=1 loops=1)
   ->  Gather  (cost=38174.76..38174.97 rows=2 width=72) (actual time=121.962..129.002 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=37174.76..37174.77 rows=1 width=72) (actual time=73.813..73.814 rows=1 loops=3)
               ->  Parallel Bitmap Heap Scan on vendas  (cost=8018.89..36584.73 rows=118007 width=6) (actual time=11.184..62.157 rows=93307 loops=3)
                     Recheck Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                     Filter: (status_pedido = 'Pago'::status_pedido_enum)
                     Rows Removed by Filter: 31104
                     Heap Blocks: exact=5079
                     ->  Bitmap Index Scan on idx_vendas_data_venda  (cost=0.00..7948.09 rows=378766 width=0) (actual time=28.015..28.015 rows=373233 loops=1)
                           Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
 Planning Time: 0.200 ms
 Execution Time: 129.072 ms
```

- O PostgreSQL executou a consulta em 129 ms utilizando um Parallel Bitmap Heap Scan na tabela vendas. Primeiro, fez um Bitmap Index Scan no índice idx_vendas_data_venda para localizar os registros dentro do intervalo de datas e depois acessou os blocos correspondentes na tabela, aplicando o filtro status_pedido = 'Pago'.
- Outro índice foi criado, desta vez um índice composto por data e status.

### Query plan 3

```sql
Finalize Aggregate  (cost=37434.82..37434.83 rows=1 width=72) (actual time=133.590..141.055 rows=1 loops=1)
   ->  Gather  (cost=37434.59..37434.80 rows=2 width=72) (actual time=133.176..141.038 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=36434.59..36434.60 rows=1 width=72) (actual time=74.262..74.263 rows=1 loops=3)
               ->  Parallel Bitmap Heap Scan on vendas  (cost=7975.43..35844.55 rows=118007 width=6) (actual time=26.131..59.967 rows=93307 loops=3)
                     Recheck Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                     Heap Blocks: exact=4386
                     ->  Bitmap Index Scan on idx_vendas_status_data  (cost=0.00..7904.63 rows=283216 width=0) (actual time=74.374..74.375 rows=279922 loops=1)
                           Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
 Planning Time: 3.616 ms
 Execution Time: 141.172 ms
```

- A criação do novo índice mostrou que o desempenho piorou. Mesmo utilizando o índice, o PostgreSQL precisou executar um Parallel Bitmap Heap Scan, lendo o índice e depois acessando milhares de blocos da tabela vendas.
- Outro índice foi criado, desta vez um índice com colunas incluídas, neste caso o valor_total.

### Query plan 4

```sql
Finalize Aggregate  (cost=11922.96..11922.97 rows=1 width=72) (actual time=92.741..97.442 rows=1 loops=1)
   ->  Gather  (cost=11922.73..11922.94 rows=2 width=72) (actual time=92.446..97.427 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=10922.73..10922.74 rows=1 width=72) (actual time=40.955..40.955 rows=1 loops=3)
               ->  Parallel Index Only Scan using idx_vendas_covering on vendas  (cost=0.43..10332.69 rows=118007 width=6) (actual time=0.187..28.197 rows=93307 loops=3)
                     Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                     Heap Fetches: 0
 Planning Time: 1.507 ms
 Execution Time: 97.561 ms
```

- O desempenho apresentado ao utilizar o índice idx_vendas_covering melhorou, isso ocorre porque todas as colunas necessárias para o processamento da consulta estão presentes no índice, assim, um Parallel Index Only Scan foi realizado e não foi necessário acessar a tabela principal.
