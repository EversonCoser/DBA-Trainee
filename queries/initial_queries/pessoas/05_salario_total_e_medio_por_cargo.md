# Salário total e médio por cargo

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT
    f.cargo,
    COUNT(*) AS total_funcionarios,
    SUM(f.salario) AS folha_total,
    AVG(f.salario) AS salario_medio
FROM funcionarios f
JOIN pessoas p 
    ON p.id_pessoa = f.id_funcionario
    AND p.ativo = true
GROUP BY f.cargo
ORDER BY folha_total DESC;
````

### Query plan 1

````sql
Sort  (cost=221.80..221.81 rows=4 width=76) (actual time=1.211..1.213 rows=4 loops=1)
   Sort Key: (sum(f.salario)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=221.70..221.76 rows=4 width=76) (actual time=1.188..1.194 rows=4 loops=1)
         Group Key: f.cargo
         Batches: 1  Memory Usage: 24kB
         ->  Nested Loop  (cost=0.29..220.38 rows=177 width=9) (actual time=0.070..1.022 rows=167 loops=1)
               ->  Seq Scan on funcionarios f  (cost=0.00..6.50 rows=350 width=13) (actual time=0.036..0.121 rows=350 loops=1)
               ->  Index Only Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..0.61 rows=1 width=4) (actual time=0.002..0.002 rows=0 loops=350)
                     Index Cond: (id_pessoa = f.id_funcionario)
                     Heap Fetches: 0
 Planning Time: 0.774 ms
 Execution Time: 1.291 ms
````

- Tempo de execução de 1.291 ms com a utilização do índice idx_pessoas_ativas em pessoas e Seq Scan em funcionários.

## Query versão 2

````sql
EXPLAIN ANALYZE
WITH funcionarios_ativos AS (
    SELECT
        f.cargo AS cargo,
        f.salario AS salario
    FROM funcionarios f
    JOIN pessoas p 
        ON p.id_pessoa = f.id_funcionario
        AND p.ativo = true
)
SELECT
    cargo,
    COUNT(*) AS total_funcionarios,
    SUM(salario) AS folha_total,
    AVG(salario) AS salario_medio
FROM funcionarios_ativos
GROUP BY cargo
ORDER BY folha_total DESC;
````

### Query plan 1

````sql
Sort  (cost=221.80..221.81 rows=4 width=76) (actual time=1.005..1.006 rows=4 loops=1)
   Sort Key: (sum(f.salario)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=221.70..221.76 rows=4 width=76) (actual time=0.989..0.993 rows=4 loops=1)
         Group Key: f.cargo
         Batches: 1  Memory Usage: 24kB
         ->  Nested Loop  (cost=0.29..220.38 rows=177 width=9) (actual time=0.040..0.838 rows=167 loops=1)
               ->  Seq Scan on funcionarios f  (cost=0.00..6.50 rows=350 width=13) (actual time=0.020..0.088 rows=350 loops=1)
               ->  Index Only Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..0.61 rows=1 width=4) (actual time=0.002..0.002 rows=0 loops=350)
                     Index Cond: (id_pessoa = f.id_funcionario)
                     Heap Fetches: 0
 Planning Time: 0.405 ms
 Execution Time: 1.056 ms
````

- A consulta com CTE não apresetou ganho quando comparado com a consulta sem CTE. O tempo de execução foi de 1.056 ms com a utilização do índice idx_pessoas_ativas e um Seq Scan em funcionários.