# 10 produtos mais vendidos e sua categoria

## Query versão 1
- Valor total de unidades vendidas utilizando SUM.
- Utilização de índices já criados.
- Tabela produtos com 650 registros.
- Tabela itens_venda com 4.499.943 registros.
- Tabela vendas com 1.500.000 registros.

````sql
EXPLAIN ANALYSE
SELECT
    p.id_produto,
    p.descricao,
    p.categoria,
    SUM(iv.quantidade) AS total_vendido
FROM itens_venda iv
JOIN vendas v
    ON iv.id_venda = v.id_venda
JOIN produtos p 
    ON p.id_produto = iv.id_produto
WHERE v.status_pedido = 'Pago'
  AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY p.id_produto, p.descricao, p.categoria
ORDER BY total_vendido DESC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=93596.89..93596.92 rows=10 width=33) (actual time=570.540..576.507 rows=10 loops=1)
   ->  Sort  (cost=93596.89..93598.52 rows=650 width=33) (actual time=570.538..576.502 rows=10 loops=1)
         Sort Key: (sum(iv.quantidade)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Finalize GroupAggregate  (cost=93418.17..93582.84 rows=650 width=33) (actual time=569.429..576.337 rows=650 loops=1)
               Group Key: p.id_produto
               ->  Gather Merge  (cost=93418.17..93569.84 rows=1300 width=33) (actual time=569.421..575.882 rows=1950 loops=1)
                     Workers Planned: 2
                     Workers Launched: 2
                     ->  Sort  (cost=92418.14..92419.77 rows=650 width=33) (actual time=503.180..503.213 rows=650 loops=3)
                           Sort Key: p.id_produto
                           Sort Method: quicksort  Memory: 58kB
                           Worker 0:  Sort Method: quicksort  Memory: 58kB
                           Worker 1:  Sort Method: quicksort  Memory: 58kB
                           ->  Partial HashAggregate  (cost=92381.27..92387.77 rows=650 width=33) (actual time=502.913..502.998 rows=650 loops=3)
                                 Group Key: p.id_produto
                                 Batches: 1  Memory Usage: 105kB
                                 Worker 0:  Batches: 1  Memory Usage: 105kB
                                 Worker 1:  Batches: 1  Memory Usage: 105kB
                                 ->  Hash Join  (cost=37341.26..90611.20 rows=354015 width=29) (actual time=77.928..459.788 rows=279627 loops=3)
                                       Hash Cond: (iv.id_produto = p.id_produto)
                                       ->  Parallel Hash Join  (cost=37319.64..89654.22 rows=354015 width=8) (actual time=77.692..409.428 rows=279627 loops=3)
                                             Hash Cond: (iv.id_venda = v.id_venda)
                                             ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=12) (actual time=0.687..106.195 rows=1499981 loops=3)
                                             ->  Parallel Hash  (cost=35844.55..35844.55 rows=118007 width=4) (actual time=75.904..75.905 rows=93307 loops=3)
                                                   Buckets: 524288  Batches: 1  Memory Usage: 15104kB
                                                   ->  Parallel Bitmap Heap Scan on vendas v  (cost=7975.43..35844.55 rows=118007 width=4) (actual time=12.211..49.509 rows=93307 loops=3)
                                                         Recheck Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                                         Heap Blocks: exact=6220
                                                         ->  Bitmap Index Scan on idx_vendas_status_data  (cost=0.00..7904.63 rows=283216 width=0) (actual time=29.453..29.453 rows=279922 loops=1)
                                                               Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                       ->  Hash  (cost=13.50..13.50 rows=650 width=25) (actual time=0.217..0.218 rows=650 loops=3)
                                             Buckets: 1024  Batches: 1  Memory Usage: 45kB
                                             ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=650 width=25) (actual time=0.045..0.122 rows=650 loops=3)
 Planning Time: 1.211 ms
 Execution Time: 576.818 ms
 ````

- Tempo de execução de 576.818 ms. Seq Scan na tabela produtos e itens_venda.
- Os seguintes índices foram criados:

````sql
CREATE INDEX idx_itens_venda_produto
ON itens_venda (id_produto);

CREATE INDEX idx_vendas_pago_data_id
ON vendas (data_venda, id_venda)
WHERE status_pedido = 'Pago';

CREATE INDEX idx_itens_venda_idvenda
ON itens_venda (id_venda);

CREATE INDEX idx_itens_venda_idvenda_produto
ON itens_venda (id_venda, id_produto)
INCLUDE (quantidade);
````

### Query plan 2

````sql
Limit  (cost=66125.00..66125.02 rows=10 width=33) (actual time=570.442..575.865 rows=10 loops=1)
   ->  Sort  (cost=66125.00..66126.62 rows=650 width=33) (actual time=570.440..575.861 rows=10 loops=1)
         Sort Key: (sum(iv.quantidade)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Finalize GroupAggregate  (cost=65946.27..66110.95 rows=650 width=33) (actual time=568.675..575.557 rows=650 loops=1)
               Group Key: p.id_produto
               ->  Gather Merge  (cost=65946.27..66097.95 rows=1300 width=33) (actual time=568.668..574.668 rows=1950 loops=1)
                     Workers Planned: 2
                     Workers Launched: 2
                     ->  Sort  (cost=64946.25..64947.87 rows=650 width=33) (actual time=492.076..492.143 rows=650 loops=3)
                           Sort Key: p.id_produto
                           Sort Method: quicksort  Memory: 58kB
                           Worker 0:  Sort Method: quicksort  Memory: 58kB
                           Worker 1:  Sort Method: quicksort  Memory: 58kB
                           ->  Partial HashAggregate  (cost=64909.38..64915.88 rows=650 width=33) (actual time=491.702..491.840 rows=650 loops=3)
                                 Group Key: p.id_produto
                                 Batches: 1  Memory Usage: 105kB
                                 Worker 0:  Batches: 1  Memory Usage: 105kB
                                 Worker 1:  Batches: 1  Memory Usage: 105kB
                                 ->  Hash Join  (cost=9869.37..63139.30 rows=354015 width=29) (actual time=54.246..447.775 rows=279627 loops=3)
                                       Hash Cond: (iv.id_produto = p.id_produto)
                                       ->  Parallel Hash Join  (cost=9847.74..62182.33 rows=354015 width=8) (actual time=54.023..396.887 rows=279627 loops=3)
                                             Hash Cond: (iv.id_venda = v.id_venda)
                                             ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=12) (actual time=0.167..106.378 rows=1499981 loops=3)
                                             ->  Parallel Hash  (cost=8372.65..8372.65 rows=118007 width=4) (actual time=52.879..52.879 rows=93307 loops=3)
                                                   Buckets: 524288  Batches: 1  Memory Usage: 15104kB
                                                   ->  Parallel Index Only Scan using idx_vendas_pago_data_id on vendas v  (cost=0.43..8372.65 rows=118007 width=4) (actual time=0.048..19.182 rows=93307 loops=3)
                                                         Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                                         Heap Fetches: 0
                                       ->  Hash  (cost=13.50..13.50 rows=650 width=25) (actual time=0.205..0.206 rows=650 loops=3)
                                             Buckets: 1024  Batches: 1  Memory Usage: 45kB
                                             ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=650 width=25) (actual time=0.053..0.122 rows=650 loops=3)
 Planning Time: 0.898 ms
 Execution Time: 576.031 ms
 ````

- Com a criação dos índices acima o desempenho da consulta praticamente não sofreu alteração. O próximo passo é reescrever a consulta.

## Query versão 2

````sql
WITH produtos_mais_vendidos_por_categoria AS (
    SELECT 
        v.id_venda
    FROM vendas v
        WHERE v.status_pedido = 'Pago'
            AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
),
itens_agrupados AS (
    SELECT 
        iv.id_produto,
        SUM(iv.quantidade) AS total_vendido
    FROM itens_venda iv
    JOIN produtos_mais_vendidos_por_categoria pmv
        ON iv.id_venda = pmv.id_venda
    GROUP BY iv.id_produto
)
SELECT
    p.descricao,
    p.categoria,
    ia.total_vendido
FROM itens_agrupados ia
JOIN produtos p ON p.id_produto = ia.id_produto
ORDER BY ia.total_vendido DESC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=65220.29..65220.32 rows=10 width=29) (actual time=511.477..516.488 rows=10 loops=1)
   ->  Sort  (cost=65220.29..65221.92 rows=650 width=29) (actual time=511.475..516.485 rows=10 loops=1)
         Sort Key: (sum(iv.quantidade)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Merge Join  (cost=64989.57..65206.25 rows=650 width=29) (actual time=510.769..516.388 rows=650 loops=1)
               Merge Cond: (iv.id_produto = p.id_produto)
               ->  Finalize GroupAggregate  (cost=64989.30..65153.97 rows=650 width=12) (actual time=510.745..516.179 rows=650 loops=1)
                     Group Key: iv.id_produto
                     ->  Gather Merge  (cost=64989.30..65140.97 rows=1300 width=12) (actual time=510.740..515.978 rows=1950 loops=1)
                           Workers Planned: 2
                           Workers Launched: 2
                           ->  Sort  (cost=63989.27..63990.90 rows=650 width=12) (actual time=438.553..438.578 rows=650 loops=3)
                                 Sort Key: iv.id_produto
                                 Sort Method: quicksort  Memory: 45kB
                                 Worker 0:  Sort Method: quicksort  Memory: 45kB
                                 Worker 1:  Sort Method: quicksort  Memory: 45kB
                                 ->  Partial HashAggregate  (cost=63952.40..63958.90 rows=650 width=12) (actual time=438.345..438.410 rows=650 loops=3)
                                       Group Key: iv.id_produto
                                       Batches: 1  Memory Usage: 105kB
                                       Worker 0:  Batches: 1  Memory Usage: 105kB
                                       Worker 1:  Batches: 1  Memory Usage: 105kB
                                       ->  Parallel Hash Join  (cost=9847.74..62182.33 rows=354015 width=8) (actual time=51.937..396.739 rows=279627 loops=3)
                                             Hash Cond: (iv.id_venda = v.id_venda)
                                             ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=12) (actual time=0.176..107.686 rows=1499981 loops=3)
                                             ->  Parallel Hash  (cost=8372.65..8372.65 rows=118007 width=4) (actual time=49.882..49.882 rows=93307 loops=3)
                                                   Buckets: 524288  Batches: 1  Memory Usage: 15104kB
                                                   ->  Parallel Index Only Scan using idx_vendas_pago_data_id on vendas v  (cost=0.43..8372.65 rows=118007 width=4) (actual time=0.115..18.229 rows=93307 loops=3)
                                                         Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                                         Heap Fetches: 0
               ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..36.02 rows=650 width=25) (actual time=0.021..0.089 rows=650 loops=1)
 Planning Time: 1.305 ms
 Execution Time: 516.641 ms
 ````

- O tempo de execução diminuiu um pouco em comparação com as consultas sem CTE. No entanto, a principal questão se refere ao Sec Scan na tabela itens_venda, o otimizador de consultas entende que como existem muitos dados para serem lidos na tabela itens_venda um Seq Scan é a melhor opção. 279627 tuplas foram lidas por cada worker, neste caso 3, totalizando 838881 tuplas finais. Isso representa quase 19% da tabela.