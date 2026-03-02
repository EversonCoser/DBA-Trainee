# Fornecedores acima do prazo de entrega média

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT
    f.id_fornecedor,
    p.nome,
    f.prazo_entrega
FROM fornecedores f
JOIN pessoas p 
    ON p.id_pessoa = f.id_fornecedor
WHERE p.ativo = true
  AND f.prazo_entrega > (
        SELECT AVG(f2.prazo_entrega)
        FROM fornecedores f2
        JOIN pessoas p2
            ON p2.id_pessoa = f2.id_fornecedor
        WHERE p2.ativo = true
    )
ORDER BY f.prazo_entrega DESC, f.id_fornecedor ASC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=660.61..660.63 rows=10 width=21) (actual time=6.277..6.285 rows=10 loops=1)
   InitPlan 1
     ->  Aggregate  (cost=251.20..251.21 rows=1 width=32) (actual time=1.323..1.325 rows=1 loops=1)
           ->  Nested Loop  (cost=0.29..250.63 rows=228 width=4) (actual time=0.028..1.252 rows=233 loops=1)
                 ->  Seq Scan on fornecedores f2  (cost=0.00..6.50 rows=450 width=8) (actual time=0.013..0.111 rows=450 loops=1)
                 ->  Index Only Scan using idx_pessoas_ativas on pessoas p2  (cost=0.29..0.54 rows=1 width=4) (actual time=0.002..0.002 rows=1 loops=450)
                       Index Cond: (id_pessoa = f2.id_fornecedor)
                       Heap Fetches: 0
   ->  Sort  (cost=409.40..409.59 rows=76 width=21) (actual time=6.276..6.279 rows=10 loops=1)
         Sort Key: f.prazo_entrega DESC, f.id_fornecedor
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Hash Join  (cost=10.91..407.76 rows=76 width=21) (actual time=6.081..6.226 rows=122 loops=1)
               Hash Cond: (p.id_pessoa = f.id_fornecedor)
               ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.020..3.174 rows=9012 loops=1)
               ->  Hash  (cost=8.75..8.75 rows=150 width=8) (actual time=1.561..1.561 rows=226 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 17kB
                     ->  Seq Scan on fornecedores f  (cost=0.00..8.75 rows=150 width=8) (actual time=1.361..1.516 rows=226 loops=1)
                           Filter: ((prazo_entrega)::numeric > (InitPlan 1).col1)
                           Rows Removed by Filter: 224
 Planning Time: 0.861 ms
 Execution Time: 6.384 ms
````

- Tempo de 6.384 ms. Seq Scan em fornecedores e utilização do índice idx_pessoas_ativas em pessoas. Um Seq Scan em fornecedores também foi realizado para calcular a média.
- Índice criado para a ordenação.

````sql
CREATE INDEX idx_fornecedores_prazo_id
ON fornecedores (prazo_entrega DESC, id_fornecedor ASC);
````

### Query plan 2

````sql
 Limit  (cost=251.77..337.30 rows=10 width=21) (actual time=0.959..1.017 rows=10 loops=1)
   InitPlan 1
     ->  Aggregate  (cost=251.20..251.21 rows=1 width=32) (actual time=0.886..0.887 rows=1 loops=1)
           ->  Nested Loop  (cost=0.29..250.63 rows=228 width=4) (actual time=0.025..0.849 rows=233 loops=1)
                 ->  Seq Scan on fornecedores f2  (cost=0.00..6.50 rows=450 width=8) (actual time=0.014..0.063 rows=450 loops=1)
                 ->  Index Only Scan using idx_pessoas_ativas on pessoas p2  (cost=0.29..0.54 rows=1 width=4) (actual time=0.001..0.001 rows=1 loops=450)
                       Index Cond: (id_pessoa = f2.id_fornecedor)
                       Heap Fetches: 0
   ->  Nested Loop  (cost=0.56..650.62 rows=76 width=21) (actual time=0.958..1.013 rows=10 loops=1)
         ->  Index Only Scan using idx_fornecedores_prazo_id on fornecedores f  (cost=0.27..33.25 rows=150 width=8) (actual time=0.938..0.958 rows=18 loops=1)
               Filter: ((prazo_entrega)::numeric > (InitPlan 1).col1)
               Heap Fetches: 18
         ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..4.12 rows=1 width=17) (actual time=0.002..0.002 rows=1 loops=18)
               Index Cond: (id_pessoa = f.id_fornecedor)
 Planning Time: 0.958 ms
 Execution Time: 1.067 ms
 ````

- Tempo de 1.067. Utilização do índice idx_pessoas_ativas em pessoas e idx_fornecedores_prazo_id em fornecedores. Seq Scan na tabela fornecedores para calcular a média.

## Query versão 2

````sql
EXPLAIN ANALYZE
WITH media AS (
    SELECT AVG(prazo_entrega) AS avg_prazo
    FROM fornecedores f
    JOIN pessoas p
        ON p.id_pessoa = f.id_fornecedor
    WHERE p.ativo = true
)
SELECT
    f.id_fornecedor,
    p.nome,
    f.prazo_entrega
FROM fornecedores f
JOIN pessoas p 
    ON p.id_pessoa = f.id_fornecedor
    AND p.ativo = true
CROSS JOIN media m
WHERE f.prazo_entrega > m.avg_prazo
ORDER BY f.prazo_entrega DESC, f.id_fornecedor ASC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=251.76..309.08 rows=10 width=21) (actual time=1.026..1.081 rows=10 loops=1)
   ->  Nested Loop  (cost=251.76..687.46 rows=76 width=21) (actual time=1.025..1.078 rows=10 loops=1)
         ->  Nested Loop  (cost=251.47..290.08 rows=150 width=8) (actual time=1.000..1.023 rows=18 loops=1)
               Join Filter: ((f.prazo_entrega)::numeric > (avg(fornecedores.prazo_entrega)))
               ->  Index Only Scan using idx_fornecedores_prazo_id on fornecedores f  (cost=0.27..31.00 rows=450 width=8) (actual time=0.027..0.036 rows=18 loops=1)
                     Heap Fetches: 18
               ->  Materialize  (cost=251.20..251.21 rows=1 width=32) (actual time=0.054..0.054 rows=1 loops=18)
                     ->  Aggregate  (cost=251.20..251.21 rows=1 width=32) (actual time=0.964..0.965 rows=1 loops=1)
                           ->  Nested Loop  (cost=0.29..250.63 rows=228 width=4) (actual time=0.043..0.913 rows=233 loops=1)
                                 ->  Seq Scan on fornecedores  (cost=0.00..6.50 rows=450 width=8) (actual time=0.024..0.094 rows=450 loops=1)
                                 ->  Index Only Scan using idx_pessoas_ativas on pessoas  (cost=0.29..0.54 rows=1 width=4) (actual time=0.001..0.001 rows=1 loops=450)
                                       Index Cond: (id_pessoa = fornecedores.id_fornecedor)
                                       Heap Fetches: 0
         ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..2.65 rows=1 width=17) (actual time=0.002..0.002 rows=1 loops=18)
               Index Cond: (id_pessoa = f.id_fornecedor)
 Planning Time: 0.792 ms
 Execution Time: 1.142 ms
````

- Tempo de execução de 1.142 ms. Utilização do índice idx_pessoas_ativas em pessoas e Seq Scan em fornecedores.