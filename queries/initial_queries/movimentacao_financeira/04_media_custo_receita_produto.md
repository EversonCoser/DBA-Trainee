# Média de custo e receita por produto

## Query versão 1

````sql
EXPLAIN ANALYZE
WITH custo_medio_compra AS (
	SELECT 
		ic.id_produto,
		round(avg(ic.valor_unitario),2) AS media_custo 
	FROM itens_compra ic
	GROUP BY ic.id_produto 
),
receita_media AS (
	SELECT 	
		iv.id_produto,
		round(avg(iv.preco_unitario_venda),2) AS valor_medio
	FROM itens_venda iv 
	GROUP BY iv.id_produto
)
SELECT 	
	p.descricao,
	cmc.media_custo,
	rm.valor_medio
FROM produtos p 
JOIN custo_medio_compra cmc
	ON p.id_produto = cmc.id_produto 
JOIN receita_media rm
	ON p.id_produto = rm.id_produto
ORDER BY cmc.id_produto; 
````

### Query plan 1

````sql
Merge Join  (cost=77809.42..78220.03 rows=650 width=79) (actual time=642.506..647.948 rows=650 loops=1)
  Merge Cond: (p.id_produto = iv.id_produto)
  ->  Merge Join  (cost=19983.26..20206.44 rows=650 width=51) (actual time=187.602..190.411 rows=650 loops=1)
        Merge Cond: (p.id_produto = ic.id_produto)
        ->  Index Scan using pk_produtos_id_produto on produtos p  (cost=0.28..36.02 rows=650 width=15) (actual time=0.034..0.329 rows=651 loops=1)
        ->  Finalize GroupAggregate  (cost=19982.99..20154.16 rows=650 width=36) (actual time=187.564..189.794 rows=650 loops=1)
              Group Key: ic.id_produto
              ->  Gather Merge  (cost=19982.99..20134.66 rows=1300 width=36) (actual time=187.551..188.253 rows=1950 loops=1)
                    Workers Planned: 2
                    Workers Launched: 2
                    ->  Sort  (cost=18982.96..18984.59 rows=650 width=36) (actual time=145.843..145.897 rows=650 loops=3)
                          Sort Key: ic.id_produto
                          Sort Method: quicksort  Memory: 80kB
                          Worker 0:  Sort Method: quicksort  Memory: 80kB
                          Worker 1:  Sort Method: quicksort  Memory: 80kB
                          ->  Partial HashAggregate  (cost=18944.47..18952.59 rows=650 width=36) (actual time=145.486..145.676 rows=650 loops=3)
                                Group Key: ic.id_produto
                                Batches: 1  Memory Usage: 297kB
                                Worker 0:  Batches: 1  Memory Usage: 297kB
                                Worker 1:  Batches: 1  Memory Usage: 297kB
                                ->  Parallel Seq Scan on itens_compra ic  (cost=0.00..15816.98 rows=625498 width=10) (actual time=0.134..35.985 rows=500398 loops=3)
  ->  Finalize GroupAggregate  (cost=57826.16..57997.34 rows=650 width=36) (actual time=454.900..457.318 rows=650 loops=1)
        Group Key: iv.id_produto
        ->  Gather Merge  (cost=57826.16..57977.84 rows=1300 width=36) (actual time=454.888..456.039 rows=1950 loops=1)
              Workers Planned: 2
              Workers Launched: 2
              ->  Sort  (cost=56826.14..56827.76 rows=650 width=36) (actual time=414.503..414.569 rows=650 loops=3)
                    Sort Key: iv.id_produto
                    Sort Method: quicksort  Memory: 80kB
                    Worker 0:  Sort Method: quicksort  Memory: 80kB
                    Worker 1:  Sort Method: quicksort  Memory: 80kB
                    ->  Partial HashAggregate  (cost=56787.64..56795.77 rows=650 width=36) (actual time=414.167..414.326 rows=650 loops=3)
                          Group Key: iv.id_produto
                          Batches: 1  Memory Usage: 297kB
                          Worker 0:  Batches: 1  Memory Usage: 297kB
                          Worker 1:  Batches: 1  Memory Usage: 297kB
                          ->  Parallel Seq Scan on itens_venda iv  (cost=0.00..47412.76 rows=1874976 width=10) (actual time=0.096..103.108 rows=1499981 loops=3)
Planning Time: 0.526 ms
Execution Time: 648.384 ms
````

- Tempo de execução de 648.384 ms, leituras sequenciais em itens_veda e itens_compra e utilização do índice pk_produtos_id_produto em produtos.
- Uma forma de otimizar essa consulta seria com a criação de um atributo data nas tabelas de joins para filtrar as pesquisas e intervalos menores. 