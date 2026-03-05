# Produtos sem movimentação de vendas

## Query versão 1

````sql
EXPLAIN ANALYZE 
SELECT 
    p.descricao,
    p.categoria,
    p.estoque
FROM produtos p
WHERE NOT EXISTS (
    SELECT 1
    FROM itens_venda iv
    JOIN vendas v
        ON v.id_venda = iv.id_venda
    WHERE iv.id_produto = p.id_produto
      AND v.status_pedido = 'Pago'
      AND v.data_venda BETWEEN '2025-01-01' AND '2026-01-01'
);
````

### Query plan 1

````sql
Nested Loop Anti Join  (cost=0.86..7901.44 rows=1 width=25) (actual time=16.895..16.896 rows=1 loops=1)
  ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=650 width=29) (actual time=0.008..0.146 rows=651 loops=1)
  ->  Nested Loop  (cost=0.86..3655.98 rows=1295 width=4) (actual time=0.025..0.025 rows=1 loops=651)
        ->  Index Scan using idx_itens_venda_produto on itens_venda iv  (cost=0.43..313.90 rows=6923 width=8) (actual time=0.006..0.008 rows=5 loops=651)
              Index Cond: (id_produto = p.id_produto)
        ->  Index Scan using pk_vendas_id_venda on vendas v  (cost=0.43..0.48 rows=1 width=4) (actual time=0.003..0.003 rows=0 loops=3280)
              Index Cond: (id_venda = iv.id_venda)
              Filter: ((data_venda >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2026-01-01 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
              Rows Removed by Filter: 1
Planning Time: 0.369 ms
Execution Time: 16.923 ms
````

- Tempo de execução de 16.923 ms com a utilização do índice pk_vendas_id_venda em vendas e idx_itens_venda_produto em itens_venda seguido de um Seq Scan em produtos.

## Query versão 2

````sql
EXPLAIN ANALYZE 
WITH com_venda AS (
    SELECT 
        p.id_produto
    FROM produtos p
    WHERE EXISTS (
        SELECT 1
        FROM itens_venda iv
        JOIN vendas v
            ON v.id_venda = iv.id_venda
        WHERE iv.id_produto = p.id_produto
          AND v.status_pedido = 'Pago'
          AND v.data_venda BETWEEN '2025-01-01' AND '2026-01-01'
    )
)
SELECT 
    p.descricao,
    p.categoria,
    p.estoque
FROM produtos p
LEFT JOIN com_venda cv
    ON p.id_produto = cv.id_produto
WHERE cv.id_produto IS NULL;
````

- Utilização do Existis em vez do Not Exists

### Query plan 1

````sql
Merge Anti Join  (cost=1.41..7969.74 rows=1 width=25) (actual time=17.386..17.388 rows=1 loops=1)
  Merge Cond: (p.id_produto = p_1.id_produto)
  ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..36.02 rows=650 width=29) (actual time=0.010..0.228 rows=651 loops=1)
  ->  Nested Loop Semi Join  (cost=1.14..7923.97 rows=650 width=4) (actual time=0.045..16.925 rows=650 loops=1)
        ->  Index Only Scan using pk_produtos_id_produto on produtos p_1  (cost=0.28..36.02 rows=650 width=4) (actual time=0.010..0.279 rows=651 loops=1)
              Heap Fetches: 651
        ->  Nested Loop  (cost=0.86..3655.98 rows=1295 width=4) (actual time=0.025..0.025 rows=1 loops=651)
              ->  Index Scan using idx_itens_venda_produto on itens_venda iv  (cost=0.43..313.90 rows=6923 width=8) (actual time=0.006..0.008 rows=5 loops=651)
                    Index Cond: (id_produto = p_1.id_produto)
              ->  Index Scan using pk_vendas_id_venda on vendas v  (cost=0.43..0.48 rows=1 width=4) (actual time=0.003..0.003 rows=0 loops=3280)
                    Index Cond: (id_venda = iv.id_venda)
                    Filter: ((data_venda >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2026-01-01 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
                    Rows Removed by Filter: 1
Planning Time: 0.750 ms
Execution Time: 17.431 ms
````

- Tempo de execução de 17.431 ms com uso dos índices pk_vendas_id_venda em vendas, idx_itens_venda_produto em itens_venda e pk_produtos_id_produto em produtos