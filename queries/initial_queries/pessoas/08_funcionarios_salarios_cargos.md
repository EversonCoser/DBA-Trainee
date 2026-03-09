# Top 3 funcionários por cargo com maior salário

## Query

````sql
EXPLAIN ANALYZE 
WITH funcionarios_ativos AS (
	SELECT 
		p.nome,
		f.cargo,
		f.salario,
		rank() OVER (PARTITION BY cargo ORDER BY salario DESC) AS posicao
	FROM funcionarios f 
	JOIN pessoas p 
		ON f.id_funcionario = p.id_pessoa 
	WHERE p.ativo = TRUE 
)
SELECT  
	nome,
	cargo,
	salario,
	posicao 
FROM funcionarios_ativos 
WHERE posicao <= 3;
````

### Query plan

````sql
WindowAgg  (cost=414.64..418.16 rows=177 width=30) (actual time=3.800..3.856 rows=12 loops=1)
  Run Condition: (rank() OVER (?) <= 3)
  ->  Sort  (cost=414.62..415.06 rows=177 width=22) (actual time=3.787..3.803 rows=167 loops=1)
        Sort Key: f.cargo, f.salario DESC
        Sort Method: quicksort  Memory: 32kB
        ->  Hash Join  (cost=11.16..408.01 rows=177 width=22) (actual time=3.400..3.622 rows=167 loops=1)
              Hash Cond: (p.id_pessoa = f.id_funcionario)
              ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.017..2.071 rows=9013 loops=1)
              ->  Hash  (cost=6.50..6.50 rows=350 width=13) (actual time=0.254..0.255 rows=350 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 25kB
                    ->  Seq Scan on funcionarios f  (cost=0.00..6.50 rows=350 width=13) (actual time=0.026..0.182 rows=350 loops=1)
Planning Time: 0.488 ms
Execution Time: 3.904 ms
````

- Tempo de execução de 3.904 ms. Seq Scan em funcionarios e índice idx_pessoas_ativas em pessoas.