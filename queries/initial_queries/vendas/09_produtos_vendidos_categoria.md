# Top 5 produtos mais vendidos por categoria

## Query versão 1

````sql
EXPLAIN ANALYZE 
WITH mais_vendidos AS (
    SELECT 
        iv.id_produto,
        SUM(iv.quantidade) AS qtd_produtos
    FROM itens_venda iv
    JOIN vendas v 
        ON iv.id_venda = v.id_venda
    WHERE v.status_pedido = 'Pago'
      AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY iv.id_produto
),
ranking AS (
    SELECT 
        mv.id_produto,
        mv.qtd_produtos,
        RANK() OVER (PARTITION BY p.categoria ORDER BY mv.qtd_produtos DESC) AS posicao
    FROM mais_vendidos mv
    JOIN produtos p 
        ON mv.id_produto = p.id_produto
)
SELECT 
    p.descricao,
    r.qtd_produtos,
    p.categoria,
    r.posicao
FROM ranking r
JOIN produtos p 
    ON p.id_produto = r.id_produto
WHERE r.posicao <= 5;
````

### Query plan 1

````sql
Hash Join  (cost=65229.33..65250.53 rows=650 width=37) (actual time=476.242..480.316 rows=25 loops=1)
  Hash Cond: (iv.id_produto = p.id_produto)
  ->  WindowAgg  (cost=65207.70..65220.68 rows=650 width=30) (actual time=475.846..479.910 rows=25 loops=1)
        Run Condition: (rank() OVER (?) <= 5)
        ->  Sort  (cost=65207.68..65209.31 rows=650 width=22) (actual time=475.836..479.841 rows=650 loops=1)
              Sort Key: p_1.categoria, (sum(iv.quantidade)) DESC
              Sort Method: quicksort  Memory: 51kB
              ->  Hash Join  (cost=65010.92..65177.31 rows=650 width=22) (actual time=474.038..479.043 rows=650 loops=1)
                    Hash Cond: (iv.id_produto = p_1.id_produto)
                    ->  Finalize GroupAggregate  (cost=64989.30..65153.97 rows=650 width=12) (actual time=473.764..478.560 rows=650 loops=1)
                          Group Key: iv.id_produto
                          ->  Gather Merge  (cost=64989.30..65140.97 rows=1300 width=12) (actual time=473.757..478.186 rows=1950 loops=1)
                                Workers Planned: 2
                                Workers Launched: 2
                                ->  Sort  (cost=63989.27..63990.90 rows=650 width=12) (actual time=419.191..419.225 rows=650 loops=3)
                                      Sort Key: iv.id_produto
                                      Sort Method: quicksort  Memory: 45kB
                                      Worker 0:  Sort Method: quicksort  Memory: 45kB
                                      Worker 1:  Sort Method: quicksort  Memory: 45kB
                                      ->  Partial HashAggregate  (cost=63952.40..63958.90 rows=650 width=12) (actual time=418.978..419.048 rows=650 loops=3)
                                            Group Key: iv.id_produto
                                            Batches: 1  Memory Usage: 105kB
                                            Worker 0:  Batches: 1  Memory Usage: 105kB
                                            Worker 1:  Batches: 1  Memory Usage: 105kB
                                            ->  Parallel Hash Join  (cost=9847.74..62182.33 rows=354015 width=8) (actual time=42.118..377.632 rows=279627 loops=3)
                                                  Hash Cond: (iv.id_venda = v.id_venda)
                                                  ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=12) (actual time=0.147..105.115 rows=1499981 loops=3)
                                                  ->  Parallel Hash  (cost=8372.65..8372.65 rows=118007 width=4) (actual time=40.651..40.652 rows=93307 loops=3)
                                                        Buckets: 524288  Batches: 1  Memory Usage: 15104kB
                                                        ->  Parallel Index Only Scan using idx_vendas_pago_data_id on vendas v  (cost=0.43..8372.65 rows=118007 width=4) (actual time=0.101..15.379 rows=93307 loops=3)
                                                              Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                                              Heap Fetches: 0
                    ->  Hash  (cost=13.50..13.50 rows=650 width=14) (actual time=0.262..0.263 rows=651 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 39kB
                          ->  Seq Scan on produtos p_1  (cost=0.00..13.50 rows=650 width=14) (actual time=0.018..0.144 rows=651 loops=1)
  ->  Hash  (cost=13.50..13.50 rows=650 width=25) (actual time=0.382..0.382 rows=651 loops=1)
        Buckets: 1024  Batches: 1  Memory Usage: 46kB
        ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=650 width=25) (actual time=0.028..0.147 rows=651 loops=1)
Planning Time: 0.880 ms
Execution Time: 480.482 ms
````

- Tempo de execução de 480.482 ms. Seq Scan em produtos e índice idx_vendas_pago_data_id em vendas.