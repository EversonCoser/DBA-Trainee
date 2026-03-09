# Faturamento por categoria

## Query versão 1
- Valor total do faturamento utilizando SUM.
- Utilização de índices já criados.
- Tabela pessoas com 17.800 registros.
- Tabela clientes com 17.000 registros.
- Tabela vendas com 1.500.000 registros.

````sql
EXPLAIN ANALYZE
WITH ranking AS (
    SELECT 
        v.id_cliente,
        SUM(v.valor_total) AS total_gasto
    FROM vendas v
    WHERE v.status_pedido = 'Pago'
      AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY v.id_cliente
    ORDER BY total_gasto DESC
    LIMIT 10
)
SELECT p.nome, r.total_gasto
FROM ranking r
JOIN pessoas p ON p.id_pessoa = r.id_cliente
ORDER BY r.total_gasto DESC;
````

### Query plan 1

````sql
Nested Loop  (cost=40019.08..40101.97 rows=10 width=45) (actual time=277.647..277.692 rows=10 loops=1)
  ->  Limit  (cost=40018.80..40018.82 rows=10 width=36) (actual time=277.597..277.602 rows=10 loops=1)
        ->  Sort  (cost=40018.80..40061.24 rows=16976 width=36) (actual time=277.595..277.598 rows=10 loops=1)
              Sort Key: (sum(v.valor_total)) DESC
              Sort Method: top-N heapsort  Memory: 25kB
              ->  HashAggregate  (cost=39439.75..39651.95 rows=16976 width=36) (actual time=266.790..274.248 rows=17000 loops=1)
                    Group Key: v.id_cliente
                    Batches: 1  Memory Usage: 7185kB
                    ->  Bitmap Heap Scan on vendas v  (cost=7263.39..38023.67 rows=283216 width=10) (actual time=33.890..105.713 rows=279922 loops=1)
                          Recheck Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
                          Heap Blocks: exact=13639
                          ->  Bitmap Index Scan on idx_vendas_pago_data_id  (cost=0.00..7192.59 rows=283216 width=0) (actual time=30.558..30.559 rows=279922 loops=1)
                                Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
  ->  Index Scan using pk_pessoas_id_pessoa on pessoas p  (cost=0.29..8.30 rows=1 width=17) (actual time=0.008..0.008 rows=1 loops=10)
        Index Cond: (id_pessoa = v.id_cliente)
Planning Time: 0.467 ms
Execution Time: 280.840 ms
````

- Tempo de execução de 280.840 ms. Utilização de índice na tabela de vendas e pessoas. O gargalo está no Bitmap Heap Scan em vendas, o índice utilizado não contém o valor do pedido, isso faz com que mesmo tendo a utilização do índice o Postgres ainda precisa ir na tabela (Heap) buscar as informações faltantes. Um índice com a inclusão do valor_total poderia ser criado para melhorar a performance da consulta, mas cabe analisar os benefício e malefícios. 

## Query com window function

````sql
EXPLAIN ANALYZE 
WITH ranking AS (
    SELECT 
        v.id_cliente,
        SUM(v.valor_total) AS total_gasto,
        ROW_NUMBER() OVER (ORDER BY SUM(v.valor_total) DESC) AS posicao
    FROM vendas v
    WHERE v.status_pedido = 'Pago'
      AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY v.id_cliente
)
SELECT 
    p.nome,
    r.total_gasto,
    r.posicao
FROM ranking r
JOIN pessoas p 
    ON p.id_pessoa = r.id_cliente
WHERE r.posicao <= 10
ORDER BY r.total_gasto DESC;
````

### Query plan 1

````sql
Sort  (cost=43191.06..43233.50 rows=16976 width=53) (actual time=263.993..263.997 rows=10 loops=1)
  Sort Key: r.total_gasto DESC
  Sort Method: quicksort  Memory: 25kB
  ->  Hash Join  (cost=41523.66..41998.39 rows=16976 width=53) (actual time=261.900..263.984 rows=10 loops=1)
        Hash Cond: (p.id_pessoa = r.id_cliente)
        ->  Seq Scan on pessoas p  (cost=0.00..428.00 rows=17800 width=17) (actual time=0.046..1.037 rows=17801 loops=1)
        ->  Hash  (cost=41311.46..41311.46 rows=16976 width=44) (actual time=261.351..261.352 rows=10 loops=1)
              Buckets: 32768  Batches: 1  Memory Usage: 257kB
              ->  Subquery Scan on r  (cost=40844.64..41311.46 rows=16976 width=44) (actual time=261.332..261.340 rows=10 loops=1)
                    ->  WindowAgg  (cost=40844.64..41141.70 rows=16976 width=44) (actual time=261.331..261.337 rows=10 loops=1)
                          Run Condition: (row_number() OVER (?) <= 10)
                          ->  Sort  (cost=40844.62..40887.06 rows=16976 width=36) (actual time=261.320..261.323 rows=11 loops=1)
                                Sort Key: (sum(v.valor_total)) DESC
                                Sort Method: quicksort  Memory: 1300kB
                                ->  HashAggregate  (cost=39439.75..39651.95 rows=16976 width=36) (actual time=246.974..253.036 rows=17000 loops=1)
                                      Group Key: v.id_cliente
                                      Batches: 1  Memory Usage: 7185kB
                                      ->  Bitmap Heap Scan on vendas v  (cost=7263.39..38023.67 rows=283216 width=10) (actual time=33.094..99.375 rows=279922 loops=1)
                                            Recheck Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
                                            Heap Blocks: exact=13639
                                            ->  Bitmap Index Scan on idx_vendas_pago_data_id  (cost=0.00..7192.59 rows=283216 width=0) (actual time=30.613..30.613 rows=279922 loops=1)
                                                  Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
Planning Time: 0.625 ms
Execution Time: 265.702 ms
````