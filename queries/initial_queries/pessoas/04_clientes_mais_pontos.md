# Top 15 clientes com mais pontos de fidelidade

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT 
    p.nome AS nome_cliente,
    c.pontos_fidelidade AS pontos
FROM pessoas p
JOIN clientes c ON c.id_cliente = p.id_pessoa
ORDER BY c.pontos_fidelidade DESC, p.id_pessoa ASC
LIMIT 15;
````

### Query plan 1

````sql
Limit  (cost=1366.32..1366.36 rows=15 width=21) (actual time=19.572..19.593 rows=15 loops=1)
   ->  Sort  (cost=1366.32..1408.82 rows=17000 width=21) (actual time=19.570..19.574 rows=15 loops=1)
         Sort Key: c.pontos_fidelidade DESC, p.id_pessoa
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Hash Join  (cost=474.50..949.24 rows=17000 width=21) (actual time=8.354..16.127 rows=17000 loops=1)
               Hash Cond: (p.id_pessoa = c.id_cliente)
               ->  Seq Scan on pessoas p  (cost=0.00..428.00 rows=17800 width=17) (actual time=0.025..1.839 rows=17800 loops=1)
               ->  Hash  (cost=262.00..262.00 rows=17000 width=8) (actual time=8.175..8.176 rows=17000 loops=1)
                     Buckets: 32768  Batches: 1  Memory Usage: 921kB
                     ->  Seq Scan on clientes c  (cost=0.00..262.00 rows=17000 width=8) (actual time=0.016..3.382 rows=17000 loops=1)
 Planning Time: 0.542 ms
 Execution Time: 20.034 ms
````

- Tempo de execução de 20.034 ms com Seq Scan em clientes e pessoas
- Um índice baseado na ordenação pode ser criado para agilizar a consulta

````sql
CREATE INDEX idx_clientes_pontos_id
ON clientes (pontos_fidelidade DESC, id_cliente ASC);
````

### Query plan 2

````sql
Limit  (cost=0.57..6.61 rows=15 width=21) (actual time=0.038..0.115 rows=15 loops=1)
   ->  Nested Loop  (cost=0.57..6840.20 rows=17000 width=21) (actual time=0.037..0.112 rows=15 loops=1)
         ->  Index Only Scan using idx_clientes_pontos_id on clientes c  (cost=0.29..451.29 rows=17000 width=8) (actual time=0.018..0.023 rows=15 loops=1)
               Heap Fetches: 0
         ->  Index Scan using pk_pessoas_id_pessoa on pessoas p  (cost=0.29..0.38 rows=1 width=17) (actual time=0.005..0.005 rows=1 loops=15)
               Index Cond: (id_pessoa = c.id_cliente)
 Planning Time: 0.481 ms
 Execution Time: 0.148 ms
 ````

- Tempo de execução de 0.148 ms com a utilização dos índices pk_pessoas_id_pessoa e idx_clientes_pontos_id

## Query versão 2

````sql
EXPLAIN ANALYZE
WITH ranking AS (
    SELECT
        p.nome AS nome_cliente,
        p.id_pessoa,
        c.pontos_fidelidade AS pontos
    FROM pessoas p
    JOIN clientes c ON c.id_cliente = p.id_pessoa
    ORDER BY c.pontos_fidelidade DESC, p.id_pessoa ASC
    LIMIT 15
)
SELECT
    nome_cliente,
    pontos
FROM ranking;
````

### Query plan 1

````sql
Subquery Scan on ranking  (cost=0.57..6.76 rows=15 width=17) (actual time=0.025..0.079 rows=15 loops=1)
   ->  Limit  (cost=0.57..6.61 rows=15 width=21) (actual time=0.025..0.078 rows=15 loops=1)
         ->  Nested Loop  (cost=0.57..6840.20 rows=17000 width=21) (actual time=0.025..0.076 rows=15 loops=1)
               ->  Index Only Scan using idx_clientes_pontos_id on clientes c  (cost=0.29..451.29 rows=17000 width=8) (actual time=0.013..0.014 rows=15 loops=1)
                     Heap Fetches: 0
               ->  Index Scan using pk_pessoas_id_pessoa on pessoas p  (cost=0.29..0.38 rows=1 width=17) (actual time=0.004..0.004 rows=1 loops=15)
                     Index Cond: (id_pessoa = c.id_cliente)
 Planning Time: 0.306 ms
 Execution Time: 0.104 ms
````

- Tempo de execução de 0.104, utilização dos índices pk_pessoas_id_pessoa e idx_clientes_pontos_id.

## Query versão 3 - com window function

````sql
EXPLAIN ANALYZE 
WITH pontos_fidelidade AS (
	SELECT 
		p.id_pessoa, 
		p.nome,
		c.pontos_fidelidade,
		dense_rank() OVER (ORDER BY c.pontos_fidelidade DESC) AS posicao
	FROM pessoas p 
	JOIN clientes c 	
		ON p.id_pessoa = c.id_cliente 
	WHERE p.ativo = TRUE 
)
SELECT 
	pf.nome,
	pf.pontos_fidelidade,
	pf.posicao 
FROM pontos_fidelidade pf
WHERE posicao <=3
ORDER BY pontos_fidelidade DESC, pf.id_pessoa ASC;
````

### Query plan 1

````sql
Incremental Sort  (cost=1355.66..1853.16 rows=8607 width=29) (actual time=14.309..14.312 rows=21 loops=1)
  Sort Key: pf.pontos_fidelidade DESC, pf.id_pessoa
  Presorted Key: pf.pontos_fidelidade
  Full-sort Groups: 1  Sort Method: quicksort  Average Memory: 26kB  Peak Memory: 26kB
  ->  Subquery Scan on pf  (cost=1355.29..1591.97 rows=8607 width=29) (actual time=14.271..14.293 rows=21 loops=1)
        ->  WindowAgg  (cost=1355.29..1505.90 rows=8607 width=29) (actual time=14.270..14.288 rows=21 loops=1)
              Run Condition: (dense_rank() OVER (?) <= 3)
              ->  Sort  (cost=1355.27..1376.79 rows=8607 width=21) (actual time=14.245..14.250 rows=22 loops=1)
                    Sort Key: c.pontos_fidelidade DESC
                    Sort Method: quicksort  Memory: 721kB
                    ->  Hash Join  (cost=486.12..792.75 rows=8607 width=21) (actual time=6.412..11.288 rows=8612 loops=1)
                          Hash Cond: (c.id_cliente = p.id_pessoa)
                          ->  Seq Scan on clientes c  (cost=0.00..262.00 rows=17000 width=8) (actual time=0.049..1.354 rows=17000 loops=1)
                          ->  Hash  (cost=373.47..373.47 rows=9012 width=17) (actual time=6.234..6.234 rows=9013 loops=1)
                                Buckets: 16384  Batches: 1  Memory Usage: 564kB
                                ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.020..3.736 rows=9013 loops=1)
Planning Time: 0.624 ms
Execution Time: 14.731 ms
````

- Tempo de execução de 14.731 ms om utilização do índice idx_pessoas_ativas em pessoas e Seq Scan em clientes. O índice na tabela clientes não foi utilizado porque o plano de consulta mostrou que o JOIN foi executado antes da window function, e o filtro de posicao <= 3 foi aplicado apenas no final, após a window function ter realizado todas as operações sobre o resultado do JOIN.

## Query versão 4

````sql
EXPLAIN ANALYZE 
SELECT  
	p.nome,
	c.pontos_fidelidade,
	c.posicao
FROM pessoas p 
JOIN (
	SELECT 
		c.id_cliente,
		c.pontos_fidelidade,
		dense_rank() OVER (ORDER BY c.pontos_fidelidade DESC) AS posicao
	FROM clientes c
) c 	
	ON p.id_pessoa = c.id_cliente 
WHERE p.ativo = TRUE 
	AND c.posicao <= 3
ORDER BY pontos_fidelidade DESC, p.id_pessoa ASC;
````

### Query plan 1

````sql
Sort  (cost=1969.56..1991.08 rows=8607 width=29) (actual time=4.669..4.672 rows=21 loops=1)
  Sort Key: c.pontos_fidelidade DESC, p.id_pessoa
  Sort Method: quicksort  Memory: 26kB
  ->  Hash Join  (cost=486.44..1407.04 rows=8607 width=29) (actual time=4.614..4.655 rows=21 loops=1)
        Hash Cond: (c.id_cliente = p.id_pessoa)
        ->  WindowAgg  (cost=0.33..706.29 rows=17000 width=16) (actual time=0.027..0.070 rows=46 loops=1)
              Run Condition: (dense_rank() OVER (?) <= 3)
              ->  Index Only Scan using idx_clientes_pontos_id on clientes c  (cost=0.29..451.29 rows=17000 width=8) (actual time=0.018..0.026 rows=47 loops=1)
                    Heap Fetches: 0
        ->  Hash  (cost=373.47..373.47 rows=9012 width=17) (actual time=4.456..4.456 rows=9013 loops=1)
              Buckets: 16384  Batches: 1  Memory Usage: 584kB
              ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.018..2.649 rows=9013 loops=1)
Planning Time: 0.413 ms
Execution Time: 4.845 ms
````

- Tempo de execução de 4.845 ms com utilização dos índices idx_pessoas_ativas em pessoas e idx_clientes_pontos_id em clientes. O plano de execução mostra que a window function foi realizada diretamente na tabela clientes, antes do JOIN, isso fez com que o índice pode ser usado, pois o filtro posição <= 3 foi aplicado antes.