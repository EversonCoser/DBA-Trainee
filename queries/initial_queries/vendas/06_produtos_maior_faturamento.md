# Produtos com maior faturamento

## Query versão 1
- Valor total do faturamento utilizando SUM.
- Utilização de índices já criados.
- Tabela produtos com 650 registros.
- Tabela pessoas com 4.499.943 registros.
- Tabela vendas com 1.500.000 registros.

````sql
EXPLAIN ANALYSE
WITH produtos_maiores_faturamentos AS (
    SELECT 
        v.id_venda
    FROM vendas v
        WHERE v.status_pedido = 'Pago'
            AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
),
maior_faturamento AS (
    SELECT 
        iv.id_produto,
        SUM(iv.quantidade * iv.preco_unitario_venda) AS faturamento
    FROM itens_venda iv
    JOIN produtos_maiores_faturamentos pmf ON pmf.id_venda = iv.id_venda
    GROUP BY iv.id_produto
)
SELECT 
    p.descricao AS produto,
    mf.faturamento AS faturamento
FROM maior_faturamento mf
JOIN produtos p ON p.id_produto = mf.id_produto
ORDER BY mf.faturamento DESC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=66996.87..66996.89 rows=10 width=43) (actual time=524.314..529.199 rows=10 loops=1)
   ->  Sort  (cost=66996.87..66998.49 rows=650 width=43) (actual time=524.312..529.195 rows=10 loops=1)
         Sort Key: (sum(((iv.quantidade)::numeric * iv.preco_unitario_venda))) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Merge Join  (cost=66761.27..66982.82 rows=650 width=43) (actual time=522.156..528.964 rows=650 loops=1)
               Merge Cond: (iv.id_produto = p.id_produto)
               ->  Finalize GroupAggregate  (cost=66761.00..66930.55 rows=650 width=36) (actual time=522.118..528.554 rows=650 loops=1)
                     Group Key: iv.id_produto
                     ->  Gather Merge  (cost=66761.00..66912.67 rows=1300 width=36) (actual time=522.108..527.553 rows=1950 loops=1)
                           Workers Planned: 2
                           Workers Launched: 2
                           ->  Sort  (cost=65760.97..65762.60 rows=650 width=36) (actual time=465.327..465.360 rows=650 loops=3)
                                 Sort Key: iv.id_produto
                                 Sort Method: quicksort  Memory: 80kB
                                 Worker 0:  Sort Method: quicksort  Memory: 80kB
                                 Worker 1:  Sort Method: quicksort  Memory: 80kB
                                 ->  Partial HashAggregate  (cost=65722.48..65730.60 rows=650 width=36) (actual time=464.977..465.145 rows=650 loops=3)
                                       Group Key: iv.id_produto
                                       Batches: 1  Memory Usage: 297kB
                                       Worker 0:  Batches: 1  Memory Usage: 297kB
                                       Worker 1:  Batches: 1  Memory Usage: 297kB
                                       ->  Parallel Hash Join  (cost=9847.74..62182.33 rows=354015 width=14) (actual time=44.036..375.978 rows=279627 loops=3)
                                             Hash Cond: (iv.id_venda = v.id_venda)
                                             ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=18) (actual time=0.197..103.661 rows=1499981 loops=3)
                                             ->  Parallel Hash  (cost=8372.65..8372.65 rows=118007 width=4) (actual time=41.978..41.979 rows=93307 loops=3)
                                                   Buckets: 524288  Batches: 1  Memory Usage: 15104kB
                                                   ->  Parallel Index Only Scan using idx_vendas_pago_data_id on vendas v  (cost=0.43..8372.65 rows=118007 width=4) (actual time=0.066..15.259 rows=93307 loops=3)
                                                         Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                                         Heap Fetches: 0
               ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..36.02 rows=650 width=15) (actual time=0.033..0.217 rows=650 loops=1)
 Planning Time: 1.203 ms
 Execution Time: 529.427 m
 ````

- Tempo de execução de 529.427 ms, o maior gargalo é justamente o Seq Scan na tabela itens_venda, como existem vários registros compatíveis o otimizador opta por realizar a leitura sequencial da tabela. É possível melhorar o desempenho com uma view materializada, particionamento por data ...