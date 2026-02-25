# Faturamento por categoria

## Query versão 1
- Valor total do faturamento utilizando SUM.
- Utilização de índices já criados.
- Tabela produtos com 650 registros.
- Tabela itens_venda com 4.499.943 registros.
- Tabela vendas com 1.500.000 registros.

````sql
EXPLAIN ANALYZE
SELECT 
    pr.categoria,
    SUM(iv.quantidade * iv.preco_unitario_venda) AS faturamento_total
FROM vendas v
JOIN itens_venda iv 
    ON iv.id_venda = v.id_venda
JOIN produtos pr 
    ON pr.id_produto = iv.id_produto
WHERE v.status_pedido = 'Pago'
  AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY pr.categoria
ORDER BY faturamento_total DESC;
````

### Query plan 1

````sql
Sort  (cost=67680.96..67680.97 rows=5 width=42) (actual time=849.609..859.270 rows=5 loops=1)
   Sort Key: (sum(((iv.quantidade)::numeric * iv.preco_unitario_venda))) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Finalize GroupAggregate  (cost=67679.60..67680.90 rows=5 width=42) (actual time=849.579..859.255 rows=5 loops=1)
         Group Key: pr.categoria
         ->  Gather Merge  (cost=67679.60..67680.77 rows=10 width=42) (actual time=849.564..859.233 rows=15 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Sort  (cost=66679.58..66679.59 rows=5 width=42) (actual time=749.318..749.324 rows=5 loops=3)
                     Sort Key: pr.categoria
                     Sort Method: quicksort  Memory: 25kB
                     Worker 0:  Sort Method: quicksort  Memory: 25kB
                     Worker 1:  Sort Method: quicksort  Memory: 25kB
                     ->  Partial HashAggregate  (cost=66679.45..66679.52 rows=5 width=42) (actual time=749.256..749.264 rows=5 loops=3)
                           Group Key: pr.categoria
                           Batches: 1  Memory Usage: 24kB
                           Worker 0:  Batches: 1  Memory Usage: 24kB
                           Worker 1:  Batches: 1  Memory Usage: 24kB
                           ->  Hash Join  (cost=9869.37..63139.30 rows=354015 width=20) (actual time=69.849..593.757 rows=279627 loops=3)
                                 Hash Cond: (iv.id_produto = pr.id_produto)
                                 ->  Parallel Hash Join  (cost=9847.74..62182.33 rows=354015 width=14) (actual time=69.434..523.754 rows=279627 loops=3)
                                       Hash Cond: (iv.id_venda = v.id_venda)
                                       ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=18) (actual time=0.160..142.275 rows=1499981 loops=3)
                                       ->  Parallel Hash  (cost=8372.65..8372.65 rows=118007 width=4) (actual time=68.014..68.015 rows=93307 loops=3)
                                             Buckets: 524288  Batches: 1  Memory Usage: 15072kB
                                             ->  Parallel Index Only Scan using idx_vendas_pago_data_id on vendas v  (cost=0.43..8372.65 rows=118007 width=4) (actual time=0.103..25.212 rows=93307 loops=3)
                                                   Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                                   Heap Fetches: 0
                                 ->  Hash  (cost=13.50..13.50 rows=650 width=14) (actual time=0.375..0.377 rows=650 loops=3)
                                       Buckets: 1024  Batches: 1  Memory Usage: 38kB
                                       ->  Seq Scan on produtos pr  (cost=0.00..13.50 rows=650 width=14) (actual time=0.076..0.234 rows=650 loops=3)
 Planning Time: 1.515 ms
 Execution Time: 859.513 ms
 ````

- Tempo de execução de 859.513 ms. Utilização de índice na tabela vendas. O maior problema está na tabela itens_venda, como 19% dos dados são necessários para a consulta, o otimizador optou por realizar uma leitura sequencial na tabela.
- O próximo passo foi criar a consulta com CTE.

## Query versão 2

````sql
EXPLAIN ANALYZE
WITH vendas_filtradas AS (
    SELECT 
        id_venda
    FROM vendas
    WHERE status_pedido = 'Pago'
      AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
),
itens_calculados AS (
    SELECT
        iv.id_produto,
        (iv.quantidade * iv.preco_unitario_venda) AS valor_item
    FROM itens_venda iv
    JOIN vendas_filtradas vf 
        ON vf.id_venda = iv.id_venda
)
SELECT 
    pr.categoria,
    SUM(ic.valor_item) AS faturamento_total
FROM itens_calculados ic
JOIN produtos pr 
    ON pr.id_produto = ic.id_produto
GROUP BY pr.categoria
ORDER BY faturamento_total DESC;
````

### Query plan 1

````sql
Sort  (cost=67680.96..67680.97 rows=5 width=42) (actual time=841.075..848.389 rows=5 loops=1)
   Sort Key: (sum(((iv.quantidade)::numeric * iv.preco_unitario_venda))) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Finalize GroupAggregate  (cost=67679.60..67680.90 rows=5 width=42) (actual time=841.028..848.357 rows=5 loops=1)
         Group Key: pr.categoria
         ->  Gather Merge  (cost=67679.60..67680.77 rows=10 width=42) (actual time=841.008..848.330 rows=15 loops=1)
               Workers Planned: 2
               Workers Launched: 2
               ->  Sort  (cost=66679.58..66679.59 rows=5 width=42) (actual time=751.830..751.834 rows=5 loops=3)
                     Sort Key: pr.categoria
                     Sort Method: quicksort  Memory: 25kB
                     Worker 0:  Sort Method: quicksort  Memory: 25kB
                     Worker 1:  Sort Method: quicksort  Memory: 25kB
                     ->  Partial HashAggregate  (cost=66679.45..66679.52 rows=5 width=42) (actual time=751.768..751.773 rows=5 loops=3)
                           Group Key: pr.categoria
                           Batches: 1  Memory Usage: 24kB
                           Worker 0:  Batches: 1  Memory Usage: 24kB
                           Worker 1:  Batches: 1  Memory Usage: 24kB
                           ->  Hash Join  (cost=9869.37..63139.30 rows=354015 width=20) (actual time=64.118..593.055 rows=279627 loops=3)
                                 Hash Cond: (iv.id_produto = pr.id_produto)
                                 ->  Parallel Hash Join  (cost=9847.74..62182.33 rows=354015 width=14) (actual time=63.753..521.661 rows=279627 loops=3)
                                       Hash Cond: (iv.id_venda = vendas.id_venda)
                                       ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=18) (actual time=0.193..146.414 rows=1499981 loops=3)
                                       ->  Parallel Hash  (cost=8372.65..8372.65 rows=118007 width=4) (actual time=61.737..61.737 rows=93307 loops=3)
                                             Buckets: 524288  Batches: 1  Memory Usage: 15104kB
                                             ->  Parallel Index Only Scan using idx_vendas_pago_data_id on vendas  (cost=0.43..8372.65 rows=118007 width=4) (actual time=0.066..22.871 rows=93307 loops=3)
                                                   Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                                   Heap Fetches: 0
                                 ->  Hash  (cost=13.50..13.50 rows=650 width=14) (actual time=0.327..0.327 rows=650 loops=3)
                                       Buckets: 1024  Batches: 1  Memory Usage: 38kB
                                       ->  Seq Scan on produtos pr  (cost=0.00..13.50 rows=650 width=14) (actual time=0.064..0.186 rows=650 loops=3)
 Planning Time: 1.540 ms
 Execution Time: 848.565 ms
````

- Tempo de execução de 848.565 ms. Novamente o índice em vendas foi utilizado mas o problema está na leitura sequencial em itens_venda.