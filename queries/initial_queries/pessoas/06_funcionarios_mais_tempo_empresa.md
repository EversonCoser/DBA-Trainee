# 10 funcionários com mais tempo de empresa

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT
    p.nome,
    f.cargo,
    AGE(CURRENT_DATE, f.data_contratacao) AS tempo_casa
FROM pessoas p
JOIN funcionarios f 
    ON f.id_funcionario = p.id_pessoa
WHERE p.ativo = true
ORDER BY tempo_casa DESC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=413.60..413.63 rows=10 width=33) (actual time=4.215..4.220 rows=10 loops=1)
   ->  Sort  (cost=413.60..414.05 rows=177 width=33) (actual time=4.214..4.217 rows=10 loops=1)
         Sort Key: (age((CURRENT_DATE)::timestamp with time zone, (f.data_contratacao)::timestamp with time zone)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Hash Join  (cost=11.16..409.78 rows=177 width=33) (actual time=3.840..4.140 rows=167 loops=1)
               Hash Cond: (p.id_pessoa = f.id_funcionario)
               ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.015..2.498 rows=9012 loops=1)
               ->  Hash  (cost=6.50..6.50 rows=350 width=12) (actual time=0.137..0.138 rows=350 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 24kB
                     ->  Seq Scan on funcionarios f  (cost=0.00..6.50 rows=350 width=12) (actual time=0.020..0.077 rows=350 loops=1)
 Planning Time: 0.366 ms
 Execution Time: 4.263 ms
````

- Tempo de execução de 4.263 ms. Seq Scan em funcionarios e utilização de índice em pessoas.
- Para otimizar essa consulta é possível substituir o tempo_caso pela data_contratacao, porque é possível ordenar os funcionários com mais tempo de empresa utilizando a ordem ascendente da data_contratacao. Com isso, é possível criar um índice nesse atributo.

````sql
CREATE INDEX idx_funcionarios_data
ON funcionarios (data_contratacao);
````

## Query versão 2

````sql
EXPLAIN ANALYZE
SELECT
    p.nome,
    f.cargo,
    AGE(CURRENT_DATE, f.data_contratacao) AS tempo_casa
FROM pessoas p
JOIN funcionarios f 
    ON f.id_funcionario = p.id_pessoa
WHERE p.ativo = true
ORDER BY data_contratacao ASC
LIMIT 10;
````

### Query plan 1

````sql
Limit  (cost=0.43..60.58 rows=10 width=37) (actual time=0.043..0.157 rows=10 loops=1)
   ->  Nested Loop  (cost=0.43..1065.04 rows=177 width=37) (actual time=0.042..0.154 rows=10 loops=1)
         ->  Index Scan using idx_funcionarios_data on funcionarios f  (cost=0.15..25.40 rows=350 width=12) (actual time=0.018..0.039 rows=28 loops=1)
         ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..2.97 rows=1 width=17) (actual time=0.003..0.003 rows=0 loops=28)
               Index Cond: (id_pessoa = f.id_funcionario)
 Planning Time: 0.523 ms
 Execution Time: 0.197 ms
````

- Tempo de execução de 0.197 ms com a utilização dos índices idx_pessoas_ativas em pessoas e idx_funcionarios_data em funcionarios.