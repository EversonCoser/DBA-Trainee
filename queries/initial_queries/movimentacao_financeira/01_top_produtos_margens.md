# Produtos com maior e menor margem de lucro considerando pedidos pagos

### Query versão 1

````sql
-- Margem de lucro por produto para vendas realizadas entre 01/01/2025 e 01/02/2025, 
-- considerando apenas pedidos pagos. A consulta retorna os 10 produtos com maior margem 
-- de lucro e os 10 produtos com menor margem de lucro, ordenados por lucro.

WITH vendas_filtradas AS (
    SELECT id_venda
    FROM vendas
    WHERE data_venda BETWEEN '2025-01-01' AND '2025-02-01'
      AND status_pedido = 'Pago'
),
compras_filtradas AS (
    SELECT id_compra
    FROM compras
    WHERE data_compra BETWEEN '2025-01-01' AND '2025-02-01'
),
receita AS (
    SELECT
        iv.id_produto,
        SUM(iv.preco_unitario_venda * iv.quantidade) AS receita_total
    FROM itens_venda iv
    JOIN vendas_filtradas vf
        ON vf.id_venda = iv.id_venda
    GROUP BY iv.id_produto
),
gastos AS (
    SELECT
        ic.id_produto,
        SUM(ic.valor_unitario * ic.quantidade) AS gasto_total
    FROM itens_compra ic
    JOIN compras_filtradas cf
        ON cf.id_compra = ic.id_compra
    GROUP BY ic.id_produto
),
lucro AS (
    SELECT
        g.id_produto,
        (r.receita_total - g.gasto_total) AS lucro
    FROM gastos g
    JOIN receita r
        ON r.id_produto = g.id_produto
)
(
SELECT
    p.descricao,
    l.lucro
FROM lucro l
JOIN produtos p
    ON p.id_produto = l.id_produto
ORDER BY l.lucro DESC
LIMIT 10
)

UNION ALL

(
SELECT *
FROM (
    SELECT
        p.descricao,
        l.lucro
    FROM lucro l
    JOIN produtos p
        ON p.id_produto = l.id_produto
    ORDER BY l.lucro ASC
    LIMIT 10
) menores
ORDER BY lucro DESC
);
````

### Query plan 1

````sql
Limit  (cost=74416.62..74416.64 rows=10 width=43) (actual time=501.443..502.288 rows=10 loops=1)
  ->  Sort  (cost=74416.62..74421.90 rows=2112 width=43) (actual time=501.442..502.285 rows=10 loops=1)
        Sort Key: (((sum((iv.preco_unitario_venda * (iv.quantidade)::numeric))) - (sum((ic.valor_unitario * (ic.quantidade)::numeric))))) DESC
        Sort Method: top-N heapsort  Memory: 26kB
        ->  Merge Join  (cost=73943.72..74370.98 rows=2112 width=43) (actual time=496.067..501.955 rows=650 loops=1)
              Merge Cond: (ic.id_produto = iv.id_produto)
              ->  Merge Join  (cost=19380.10..19601.66 rows=650 width=51) (actual time=173.960..176.745 rows=650 loops=1)
                    Merge Cond: (ic.id_produto = p.id_produto)
                    ->  Finalize GroupAggregate  (cost=19379.83..19549.38 rows=650 width=36) (actual time=173.918..176.055 rows=650 loops=1)
                          Group Key: ic.id_produto
                          ->  Gather Merge  (cost=19379.83..19531.51 rows=1300 width=36) (actual time=173.905..174.704 rows=1950 loops=1)
                                Workers Planned: 2
                                Workers Launched: 2
                                ->  Sort  (cost=18379.80..18381.43 rows=650 width=36) (actual time=111.889..111.932 rows=650 loops=3)
                                      Sort Key: ic.id_produto
                                      Sort Method: quicksort  Memory: 80kB
                                      Worker 0:  Sort Method: quicksort  Memory: 80kB
                                      Worker 1:  Sort Method: quicksort  Memory: 80kB
                                      ->  Partial HashAggregate  (cost=18341.31..18349.44 rows=650 width=36) (actual time=111.545..111.719 rows=650 loops=3)
                                            Group Key: ic.id_produto
                                            Batches: 1  Memory Usage: 297kB
                                            Worker 0:  Batches: 1  Memory Usage: 297kB
                                            Worker 1:  Batches: 1  Memory Usage: 297kB
                                            ->  Hash Join  (cost=752.11..18211.03 rows=13028 width=14) (actual time=4.535..105.610 rows=10348 loops=3)
                                                  Hash Cond: (ic.id_compra = compras.id_compra)
                                                  ->  Parallel Seq Scan on itens_compra ic  (cost=0.00..15816.98 rows=625498 width=18) (actual time=0.091..42.440 rows=500398 loops=3)
                                                  ->  Hash  (cost=556.85..556.85 rows=15621 width=4) (actual time=4.340..4.341 rows=15542 loops=3)
                                                        Buckets: 16384  Batches: 1  Memory Usage: 675kB
                                                        ->  Index Only Scan using idx_compras_data_id on compras  (cost=0.42..556.85 rows=15621 width=4) (actual time=0.074..2.334 rows=15542 loops=3)
                                                              Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-02-01 00:00:00'::timestamp without time zone))
                                                              Heap Fetches: 0
                    ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..36.02 rows=650 width=15) (actual time=0.038..0.399 rows=650 loops=1)
              ->  Finalize GroupAggregate  (cost=54563.62..54733.17 rows=650 width=36) (actual time=322.102..324.820 rows=650 loops=1)
                    Group Key: iv.id_produto
                    ->  Gather Merge  (cost=54563.62..54715.30 rows=1300 width=36) (actual time=322.092..323.410 rows=1950 loops=1)
                          Workers Planned: 2
                          Workers Launched: 2
                          ->  Sort  (cost=53563.60..53565.22 rows=650 width=36) (actual time=283.506..283.551 rows=650 loops=3)
                                Sort Key: iv.id_produto
                                Sort Method: quicksort  Memory: 80kB
                                Worker 0:  Sort Method: quicksort  Memory: 80kB
                                Worker 1:  Sort Method: quicksort  Memory: 80kB
                                ->  Partial HashAggregate  (cost=53525.10..53533.23 rows=650 width=36) (actual time=283.138..283.320 rows=650 loops=3)
                                      Group Key: iv.id_produto
                                      Batches: 1  Memory Usage: 297kB
                                      Worker 0:  Batches: 1  Memory Usage: 297kB
                                      Worker 1:  Batches: 1  Memory Usage: 297kB
                                      ->  Parallel Hash Join  (cost=900.16..53234.74 rows=29036 width=14) (actual time=3.415..272.187 rows=23628 loops=3)
                                            Hash Cond: (iv.id_venda = vendas.id_venda)
                                            ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=18) (actual time=0.072..107.358 rows=1499981 loops=3)
                                            ->  Parallel Hash  (cost=729.36..729.36 rows=13664 width=4) (actual time=3.087..3.087 rows=7854 loops=3)
                                                  Buckets: 32768  Batches: 1  Memory Usage: 1184kB
                                                  ->  Parallel Index Only Scan using idx_vendas_pago_data_id on vendas  (cost=0.43..729.36 rows=13664 width=4) (actual time=0.040..3.995 rows=23561 loops=1)
                                                        Index Cond: ((data_venda >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2025-02-01 00:00:00'::timestamp without time zone))
                                                        Heap Fetches: 0
Planning Time: 1.653 ms
Execution Time: 502.828 ms
````

- Tempo de execução de 502.828 ms. Consulta com dois GroupAggregate, um para realizar as operações referentes à venda e outro para a compra. Utilização do índice idx_vendas_pago_data_id em vendas seguido de um Seq Scan em itens_venda. Uso do índice idx_compras_data_id em compras e Seq Scan em itens_compra. Uso do índice pk_produtos_id_produto em produtos. 
- O gargalo na consulta se refere aos Seq Scans nas tabelas itens_venda e itens_compra, uma forma de otimizar tal operação seria com a criação de um atributo de data nas tabelas.