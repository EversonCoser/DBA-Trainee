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
Nested Loop  (cost=40019.08..40101.97 rows=10 width=45) (actual time=405.070..405.120 rows=10 loops=1)
   ->  Limit  (cost=40018.80..40018.82 rows=10 width=36) (actual time=404.993..404.998 rows=10 loops=1)
         ->  Sort  (cost=40018.80..40061.24 rows=16976 width=36) (actual time=404.990..404.993 rows=10 loops=1)
               Sort Key: (sum(v.valor_total)) DESC
               Sort Method: top-N heapsort  Memory: 25kB
               ->  HashAggregate  (cost=39439.75..39651.95 rows=16976 width=36) (actual time=392.322..400.940 rows=17000 loops=1)
                     Group Key: v.id_cliente
                     Batches: 1  Memory Usage: 7185kB
                     ->  Bitmap Heap Scan on vendas v  (cost=7263.39..38023.67 rows=283216 width=10) (actual time=57.093..160.902 rows=279922 loops=1)
                           Recheck Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
                           Heap Blocks: exact=13639
                           ->  Bitmap Index Scan on idx_vendas_pago_data_id  (cost=0.00..7192.59 rows=283216 width=0) (actual time=50.379..50.380 rows=279922 loops=1)
                                 Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
   ->  Index Scan using pk_pessoas_id_pessoa on pessoas p  (cost=0.29..8.30 rows=1 width=17) (actual time=0.010..0.010 rows=1 loops=10)
         Index Cond: (id_pessoa = v.id_cliente)
 Planning Time: 0.609 ms
 Execution Time: 407.445 m
````

- Tempo de execução de 407.445 ms. Utilização de índice na tabela de vendas. O gargalo está no Bitmap Heap Scan em vendas, o índice utilizado não contém o valor do pedido, isso faz com que mesmo tendo a utilização do índice o Postgres ainda precisa ir na tabela (Heap) buscar as informações faltantes. Um índice com a inclusão do valor_total poderia ser criado para melhorar a performance da consulta, mas cabe analisar os benefício e malefícios. 