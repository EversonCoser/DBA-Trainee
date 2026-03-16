# Clientes que mais gastaram e a quantidade gasta

## Query 

````sql
EXPLAIN ANALYZE 
WITH clientes_gastos AS (
	SELECT 
		v.id_cliente,
		SUM(v.valor_total) AS qtd_gasta,
		rank() OVER (ORDER BY SUM(v.valor_total) DESC) AS posicao
	FROM vendas v
	WHERE v.status_pedido = 'Pago'
		AND v.data_venda BETWEEN '2024-01-01' AND '2025-01-01'
	GROUP BY id_cliente 
)
SELECT 
	p.nome,
	cg.qtd_gasta,
	cg.posicao 
FROM pessoas p 
JOIN clientes_gastos cg
	ON p.id_pessoa = cg.id_cliente 
WHERE posicao <= 20
ORDER BY posicao;
````

### Quey plan

````sql
Sort  (cost=43230.21..43272.65 rows=16976 width=53) (actual time=375.241..375.248 rows=20 loops=1)
  Sort Key: cg.posicao
  Sort Method: quicksort  Memory: 25kB
  ->  Hash Join  (cost=41562.81..42037.54 rows=16976 width=53) (actual time=371.217..375.222 rows=20 loops=1)
        Hash Cond: (p.id_pessoa = cg.id_cliente)
        ->  Seq Scan on pessoas p  (cost=0.00..428.00 rows=17800 width=17) (actual time=0.056..1.828 rows=17801 loops=1)
        ->  Hash  (cost=41350.61..41350.61 rows=16976 width=44) (actual time=370.784..370.787 rows=20 loops=1)
              Buckets: 32768  Batches: 1  Memory Usage: 258kB
              ->  Subquery Scan on cg  (cost=40883.79..41350.61 rows=16976 width=44) (actual time=370.731..370.763 rows=20 loops=1)
                    ->  WindowAgg  (cost=40883.79..41180.85 rows=16976 width=44) (actual time=370.729..370.757 rows=20 loops=1)
                          Run Condition: (rank() OVER (?) <= 20)
                          ->  Sort  (cost=40883.77..40926.21 rows=16976 width=36) (actual time=370.712..370.718 rows=21 loops=1)
                                Sort Key: (sum(v.valor_total)) DESC
                                Sort Method: quicksort  Memory: 1300kB
                                ->  HashAggregate  (cost=39478.90..39691.10 rows=16976 width=36) (actual time=342.882..357.434 rows=17000 loops=1)
                                      Group Key: v.id_cliente
                                      Batches: 1  Memory Usage: 7185kB
                                      ->  Bitmap Heap Scan on vendas v  (cost=7283.89..38058.68 rows=284045 width=10) (actual time=50.478..134.465 rows=280697 loops=1)
                                            Recheck Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2025-01-01 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
                                            Heap Blocks: exact=13639
                                            ->  Bitmap Index Scan on idx_vendas_pago_data_id  (cost=0.00..7212.88 rows=284045 width=0) (actual time=43.818..43.818 rows=280697 loops=1)
                                                  Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2025-01-01 00:00:00'::timestamp without time zone))
Planning Time: 0.676 ms
Execution Time: 378.127 ms
````

- Tempo de execução de 378.127 ms com a utilização do índice idx_vendas_pago_data_id em vendas e de um Bitmap Heap Scan em vendas. Um Seq Scan também foi realizado na tabela pessoas.