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