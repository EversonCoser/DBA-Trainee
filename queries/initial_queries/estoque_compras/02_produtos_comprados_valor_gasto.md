# Produtos mais comprados e valor gasto

## Query versão 1

````sql
EXPLAIN ANALYZE 
SELECT
	p.descricao,
	p.estoque,
	SUM(ic.quantidade) AS qtd_comprada,
	SUM(ic.valor_unitario * ic.quantidade ) AS total_gasto
FROM produtos p
JOIN (
    SELECT 
        ic.id_produto,
        ic.quantidade,
        ic.valor_unitario
    FROM itens_compra ic
    JOIN compras c 
        ON c.id_compra = ic.id_compra
    WHERE data_compra BETWEEN '2025-01-01' AND '2025-12-31'
) ic 
	ON p.id_produto = ic.id_produto
GROUP BY p.descricao, p.estoque 
ORDER BY qtd_comprada DESC, total_gasto DESC
LIMIT 10; 
````

### Query plan 1

````sql
Limit  (cost=38089.79..38089.81 rows=10 width=55) (actual time=450.439..455.793 rows=10 loops=1)
  ->  Sort  (cost=38089.79..38091.41 rows=650 width=55) (actual time=450.437..455.789 rows=10 loops=1)
        Sort Key: (sum(ic.quantidade)) DESC, (sum((ic.valor_unitario * (ic.quantidade)::numeric))) DESC
        Sort Method: top-N heapsort  Memory: 26kB
        ->  Finalize GroupAggregate  (cost=37899.69..38075.74 rows=650 width=55) (actual time=446.318..455.422 rows=650 loops=1)
              Group Key: p.descricao, p.estoque
              ->  Gather Merge  (cost=37899.69..38051.37 rows=1300 width=55) (actual time=446.294..453.438 rows=1950 loops=1)
                    Workers Planned: 2
                    Workers Launched: 2
                    ->  Sort  (cost=36899.67..36901.29 rows=650 width=55) (actual time=378.548..378.608 rows=650 loops=3)
                          Sort Key: p.descricao, p.estoque
                          Sort Method: quicksort  Memory: 96kB
                          Worker 0:  Sort Method: quicksort  Memory: 96kB
                          Worker 1:  Sort Method: quicksort  Memory: 96kB
                          ->  Partial HashAggregate  (cost=36861.17..36869.30 rows=650 width=55) (actual time=375.560..375.817 rows=650 loops=3)
                                Group Key: p.descricao, p.estoque
                                Batches: 1  Memory Usage: 297kB
                                Worker 0:  Batches: 1  Memory Usage: 297kB
                                Worker 1:  Batches: 1  Memory Usage: 297kB
                                ->  Hash Join  (cost=16696.81..34560.91 rows=153351 width=25) (actual time=69.989..292.057 rows=124341 loops=3)
                                      Hash Cond: (ic.id_produto = p.id_produto)
                                      ->  Parallel Hash Join  (cost=16675.19..34134.11 rows=153351 width=14) (actual time=69.630..256.974 rows=124341 loops=3)
                                            Hash Cond: (ic.id_compra = c.id_compra)
                                            ->  Parallel Seq Scan on itens_compra ic  (cost=0.00..15816.98 rows=625498 width=18) (actual time=0.047..52.380 rows=500398 loops=3)
                                            ->  Parallel Hash  (cost=15717.50..15717.50 rows=76615 width=4) (actual time=68.532..68.533 rows=62114 loops=3)
                                                  Buckets: 262144  Batches: 1  Memory Usage: 9408kB
                                                  ->  Parallel Seq Scan on compras c  (cost=0.00..15717.50 rows=76615 width=4) (actual time=14.251..50.994 rows=62114 loops=3)
                                                        Filter: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-12-31 00:00:00'::timestamp without time zone))
                                                        Rows Removed by Filter: 187886
                                      ->  Hash  (cost=13.50..13.50 rows=650 width=19) (actual time=0.342..0.343 rows=650 loops=3)
                                            Buckets: 1024  Batches: 1  Memory Usage: 42kB
                                            ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=650 width=19) (actual time=0.065..0.192 rows=650 loops=3)
Planning Time: 0.964 ms
Execution Time: 456.142 ms
````

- Tempo de execução de 456.142 ms. Seq Scan em produtos, em compras e em itens_compra.
- Índice composto criado na tabela compras nos atributos (data_compra, id_compra).
- Índice composto criado na tabela itens_compra nos atributos (id_compra, id_produto).

### Query plan 2

````sql
Limit  (cost=27809.61..27809.63 rows=10 width=55) (actual time=307.958..311.832 rows=10 loops=1)
  ->  Sort  (cost=27809.61..27811.23 rows=650 width=55) (actual time=307.957..311.829 rows=10 loops=1)
        Sort Key: (sum(ic.quantidade)) DESC, (sum((ic.valor_unitario * (ic.quantidade)::numeric))) DESC
        Sort Method: top-N heapsort  Memory: 26kB
        ->  Finalize GroupAggregate  (cost=27619.51..27795.56 rows=650 width=55) (actual time=304.496..311.608 rows=650 loops=1)
              Group Key: p.descricao, p.estoque
              ->  Gather Merge  (cost=27619.51..27771.19 rows=1300 width=55) (actual time=304.480..309.904 rows=1950 loops=1)
                    Workers Planned: 2
                    Workers Launched: 2
                    ->  Sort  (cost=26619.49..26621.11 rows=650 width=55) (actual time=246.888..246.934 rows=650 loops=3)
                          Sort Key: p.descricao, p.estoque
                          Sort Method: quicksort  Memory: 96kB
                          Worker 0:  Sort Method: quicksort  Memory: 96kB
                          Worker 1:  Sort Method: quicksort  Memory: 96kB
                          ->  Partial HashAggregate  (cost=26580.99..26589.12 rows=650 width=55) (actual time=244.712..244.935 rows=650 loops=3)
                                Group Key: p.descricao, p.estoque
                                Batches: 1  Memory Usage: 297kB
                                Worker 0:  Batches: 1  Memory Usage: 297kB
                                Worker 1:  Batches: 1  Memory Usage: 297kB
                                ->  Hash Join  (cost=6416.63..24280.73 rows=153351 width=25) (actual time=34.778..190.684 rows=124341 loops=3)
                                      Hash Cond: (ic.id_produto = p.id_produto)
                                      ->  Parallel Hash Join  (cost=6395.01..23853.93 rows=153351 width=14) (actual time=34.505..167.274 rows=124341 loops=3)
                                            Hash Cond: (ic.id_compra = c.id_compra)
                                            ->  Parallel Seq Scan on itens_compra ic  (cost=0.00..15816.98 rows=625498 width=18) (actual time=0.077..36.206 rows=500398 loops=3)
                                            ->  Parallel Hash  (cost=5437.32..5437.32 rows=76615 width=4) (actual time=33.609..33.610 rows=62114 loops=3)
                                                  Buckets: 262144  Batches: 1  Memory Usage: 9376kB
                                                  ->  Parallel Index Only Scan using idx_compras_data_id on compras c  (cost=0.42..5437.32 rows=76615 width=4) (actual time=0.071..13.185 rows=62114 loops=3)
                                                        Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-12-31 00:00:00'::timestamp without time zone))
                                                        Heap Fetches: 0
                                      ->  Hash  (cost=13.50..13.50 rows=650 width=19) (actual time=0.256..0.257 rows=650 loops=3)
                                            Buckets: 1024  Batches: 1  Memory Usage: 42kB
                                            ->  Seq Scan on produtos p  (cost=0.00..13.50 rows=650 width=19) (actual time=0.073..0.160 rows=650 loops=3)
Planning Time: 1.770 ms
Execution Time: 312.126 ms
````

- Tempo de execução de 312.126 ms. Seq Scan em produtos, utilização do índice idx_compras_data_id em compras e Seq Scan e itens_compra.

## Query versão 2

````sql
EXPLAIN ANALYZE 
SELECT
	p.descricao,
	p.estoque,
	ic.qtd_comprada,
	ic.total_gasto
FROM produtos p
JOIN (
    SELECT 
        ic.id_produto,
        SUM(ic.quantidade) as qtd_comprada,
        SUM(ic.valor_unitario * ic.quantidade ) AS total_gasto
    FROM itens_compra ic
    JOIN compras c 
        ON c.id_compra = ic.id_compra
    WHERE data_compra BETWEEN '2025-01-01' AND '2025-12-31'
    GROUP BY ic.id_produto
) ic 
	ON p.id_produto = ic.id_produto
ORDER BY qtd_comprada DESC, total_gasto DESC
LIMIT 10; 
````

### Query plan 1

````sql
Limit  (cost=27048.46..27048.48 rows=10 width=55) (actual time=263.469..267.149 rows=10 loops=1)
  ->  Sort  (cost=27048.46..27050.08 rows=650 width=55) (actual time=263.468..267.145 rows=10 loops=1)
        Sort Key: (sum(ic.quantidade)) DESC, (sum((ic.valor_unitario * (ic.quantidade)::numeric))) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        ->  Merge Join  (cost=26809.61..27034.41 rows=650 width=55) (actual time=260.432..266.950 rows=650 loops=1)
              Merge Cond: (p.id_produto = ic.id_produto)
              ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..36.02 rows=650 width=19) (actual time=0.026..0.333 rows=650 loops=1)
              ->  Finalize GroupAggregate  (cost=26809.34..26982.14 rows=650 width=44) (actual time=260.400..266.226 rows=650 loops=1)
                    Group Key: ic.id_produto
                    ->  Gather Merge  (cost=26809.34..26961.01 rows=1300 width=44) (actual time=260.388..264.795 rows=1950 loops=1)
                          Workers Planned: 2
                          Workers Launched: 2
                          ->  Sort  (cost=25809.31..25810.94 rows=650 width=44) (actual time=208.735..208.780 rows=650 loops=3)
                                Sort Key: ic.id_produto
                                Sort Method: quicksort  Memory: 91kB
                                Worker 0:  Sort Method: quicksort  Memory: 91kB
                                Worker 1:  Sort Method: quicksort  Memory: 91kB
                                ->  Partial HashAggregate  (cost=25770.82..25778.94 rows=650 width=44) (actual time=208.334..208.556 rows=650 loops=3)
                                      Group Key: ic.id_produto
                                      Batches: 1  Memory Usage: 297kB
                                      Worker 0:  Batches: 1  Memory Usage: 297kB
                                      Worker 1:  Batches: 1  Memory Usage: 297kB
                                      ->  Parallel Hash Join  (cost=6395.01..23853.93 rows=153351 width=14) (actual time=32.308..165.073 rows=124341 loops=3)
                                            Hash Cond: (ic.id_compra = c.id_compra)
                                            ->  Parallel Seq Scan on itens_compra ic  (cost=0.00..15816.98 rows=625498 width=18) (actual time=0.054..35.610 rows=500398 loops=3)
                                            ->  Parallel Hash  (cost=5437.32..5437.32 rows=76615 width=4) (actual time=31.499..31.500 rows=62114 loops=3)
                                                  Buckets: 262144  Batches: 1  Memory Usage: 9408kB
                                                  ->  Parallel Index Only Scan using idx_compras_data_id on compras c  (cost=0.42..5437.32 rows=76615 width=4) (actual time=0.064..12.116 rows=62114 loops=3)
                                                        Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-12-31 00:00:00'::timestamp without time zone))
                                                        Heap Fetches: 0
Planning Time: 0.647 ms
Execution Time: 267.411 ms
````

- Tempo de execução de 267.411 ms. Utilização do índex idx_compras_data_id em compras, Seq Scan em itens_compra e índice pk_produtos_id_produto em produtos.

## Query versão 3

````sql
EXPLAIN ANALYZE 
WITH produtos_comprados AS (
	SELECT
		ic.id_produto,
		SUM(ic.quantidade) AS qtd_comprada,
		SUM(ic.valor_unitario * ic.quantidade) AS valor_gasto
	FROM compras c
	JOIN itens_compra ic 
		ON c.id_compra = ic.id_compra
	WHERE data_compra BETWEEN '2025-01-01' AND '2025-12-31'
	GROUP BY ic.id_produto
	ORDER BY qtd_comprada DESC, valor_gasto DESC, ic.id_produto ASC 
	LIMIT 10
)
SELECT
	p.descricao,
	p.estoque,
	pc.qtd_comprada,
	pc.valor_gasto
FROM produtos p 
JOIN produtos_comprados pc
	ON p.id_produto = pc.id_produto 
ORDER BY qtd_comprada DESC, valor_gasto DESC, pc.id_produto ASC 
````

### Query plan 1

````sql
Nested Loop  (cost=26996.46..27039.25 rows=10 width=59) (actual time=251.485..256.610 rows=10 loops=1)
  ->  Limit  (cost=26996.18..26996.21 rows=10 width=44) (actual time=251.455..256.553 rows=10 loops=1)
        ->  Sort  (cost=26996.18..26997.81 rows=650 width=44) (actual time=251.453..256.549 rows=10 loops=1)
              Sort Key: (sum(ic.quantidade)) DESC, (sum((ic.valor_unitario * (ic.quantidade)::numeric))) DESC, ic.id_produto
              Sort Method: top-N heapsort  Memory: 25kB
              ->  Finalize GroupAggregate  (cost=26809.34..26982.14 rows=650 width=44) (actual time=249.523..256.424 rows=650 loops=1)
                    Group Key: ic.id_produto
                    ->  Gather Merge  (cost=26809.34..26961.01 rows=1300 width=44) (actual time=249.512..255.180 rows=1950 loops=1)
                          Workers Planned: 2
                          Workers Launched: 2
                          ->  Sort  (cost=25809.31..25810.94 rows=650 width=44) (actual time=200.775..200.812 rows=650 loops=3)
                                Sort Key: ic.id_produto
                                Sort Method: quicksort  Memory: 91kB
                                Worker 0:  Sort Method: quicksort  Memory: 91kB
                                Worker 1:  Sort Method: quicksort  Memory: 91kB
                                ->  Partial HashAggregate  (cost=25770.82..25778.94 rows=650 width=44) (actual time=200.413..200.585 rows=650 loops=3)
                                      Group Key: ic.id_produto
                                      Batches: 1  Memory Usage: 297kB
                                      Worker 0:  Batches: 1  Memory Usage: 297kB
                                      Worker 1:  Batches: 1  Memory Usage: 297kB
                                      ->  Parallel Hash Join  (cost=6395.01..23853.93 rows=153351 width=14) (actual time=30.686..157.290 rows=124341 loops=3)
                                            Hash Cond: (ic.id_compra = c.id_compra)
                                            ->  Parallel Seq Scan on itens_compra ic  (cost=0.00..15816.98 rows=625498 width=18) (actual time=0.058..33.605 rows=500398 loops=3)
                                            ->  Parallel Hash  (cost=5437.32..5437.32 rows=76615 width=4) (actual time=29.947..29.948 rows=62114 loops=3)
                                                  Buckets: 262144  Batches: 1  Memory Usage: 9376kB
                                                  ->  Parallel Index Only Scan using idx_compras_data_id on compras c  (cost=0.42..5437.32 rows=76615 width=4) (actual time=0.069..11.395 rows=62114 loops=3)
                                                        Index Cond: ((data_compra >= '2025-01-01 00:00:00'::timestamp without time zone) AND (data_compra <= '2025-12-31 00:00:00'::timestamp without time zone))
                                                        Heap Fetches: 0
  ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..4.29 rows=1 width=19) (actual time=0.004..0.004 rows=1 loops=10)
        Index Cond: (id_produto = ic.id_produto)
Planning Time: 0.705 ms
Execution Time: 256.860 ms
````

- Tempo de execução de 256.860 ms. Utilização do índice pk_produtos_id_produto em produtos e idx_compras_data_id em compras, Seq Scan em itens_compra.