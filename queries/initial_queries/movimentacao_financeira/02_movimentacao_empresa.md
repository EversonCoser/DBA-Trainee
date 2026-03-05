# Movimentação financeira da empresa

## Query versão 1

````sql
EXPLAIN ANALYZE 
WITH receitas_gerais AS (
	SELECT 
		sum(v.valor_total) AS receita_total 
	FROM vendas v
	WHERE v.data_venda BETWEEN '2025-01-01' AND '2025-02-01'
		AND v.status_pedido = 'Pago'
),
gastos_totais AS (
	SELECT 
		sum(c.valor_total) AS gastos_totais
	FROM compras c
	WHERE c.data_compra  BETWEEN '2025-01-01' AND '2025-02-01'
)
SELECT 
	rg.receita_total,
	gt.gastos_totais,
	(rg.receita_total - gt.gastos_totais) AS lucro
FROM receitas_gerais rg, gastos_totais gt
````

### Query plan 1

````sql
Nested Loop  (cost=13259.94..13259.97 rows=1 width=96) (actual time=24.292..24.295 rows=1 loops=1)
  ->  Aggregate  (cost=983.08..983.09 rows=1 width=32) (actual time=8.728..8.729 rows=1 loops=1)
        ->  Index Only Scan using idx_vendas_pago_cover on vendas v  (cost=0.43..925.01 rows=23229 width=6) (actual time=0.040..5.076 rows=23561 loops=1)
              Index Cond: ((data_venda >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2025-02-01 00:00:00'::timestamp without time zone))
              Heap Fetches: 0
  ->  Aggregate  (cost=12276.86..12276.87 rows=1 width=32) (actual time=15.554..15.555 rows=1 loops=1)
        ->  Bitmap Heap Scan on compras c  (cost=404.54..12237.80 rows=15621 width=6) (actual time=3.607..12.000 rows=15542 loops=1)
              Recheck Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-02-01 00:00:00'::timestamp without time zone))
              Heap Blocks: exact=5223
              ->  Bitmap Index Scan on idx_compras_data_id  (cost=0.00..400.64 rows=15621 width=0) (actual time=2.331..2.332 rows=15542 loops=1)
                    Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-02-01 00:00:00'::timestamp without time zone))
Planning Time: 0.486 ms
Execution Time: 24.360 ms
````

- Tempo de execução de 24.360 ms, utilização do índice idx_compras_data_id em compras seguido de um Heap Scan para buscar o valor da compra. Index Only Scan usando idx_vendas_pago_cover em vendas. 
- Para melhorar a performance da consulta é possível incluir o valor da compra no índice.

### Query plan 2

````sql
Nested Loop  (cost=1646.98..1647.02 rows=1 width=96) (actual time=12.891..12.894 rows=1 loops=1)
  ->  Aggregate  (cost=983.08..983.09 rows=1 width=32) (actual time=7.185..7.186 rows=1 loops=1)
        ->  Index Only Scan using idx_vendas_pago_cover on vendas v  (cost=0.43..925.01 rows=23229 width=6) (actual time=0.032..4.054 rows=23561 loops=1)
              Index Cond: ((data_venda >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2025-02-01 00:00:00'::timestamp without time zone))
              Heap Fetches: 0
  ->  Aggregate  (cost=663.90..663.91 rows=1 width=32) (actual time=5.699..5.700 rows=1 loops=1)
        ->  Index Only Scan using idx_compras_data_id on compras c  (cost=0.42..624.85 rows=15621 width=6) (actual time=0.030..3.232 rows=15542 loops=1)
              Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-02-01 00:00:00'::timestamp without time zone))
              Heap Fetches: 0
Planning Time: 0.463 ms
Execution Time: 12.944 ms
````

- Tempo de execução de 12.944 ms. Agora, todas as inormações necessárias para a consulta estão presentes no índice.