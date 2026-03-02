# Quantidade de pessoas por faixa etária
- Índice criado em id_cliente e data_nascimento na tabela clientes

## Query versão 1

````sql
EXPLAIN ANALYZE
SELECT 
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(c.data_nascimento)) BETWEEN 18 AND 25 THEN '18-25'
        WHEN EXTRACT(YEAR FROM AGE(c.data_nascimento)) BETWEEN 26 AND 35 THEN '26-35'
        WHEN EXTRACT(YEAR FROM AGE(c.data_nascimento)) BETWEEN 36 AND 50 THEN '36-50'
        ELSE '50+'
    END AS faixa_etaria,
    COUNT(*) AS total
FROM clientes c
JOIN pessoas p ON p.id_pessoa = c.id_cliente
WHERE p.ativo = true
GROUP BY faixa_etaria
ORDER BY total DESC;
````

### Query plan 1

````sql
 Sort  (cost=1491.36..1491.57 rows=83 width=40) (actual time=74.826..74.830 rows=4 loops=1)
   Sort Key: (count(*)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=1480.42..1488.72 rows=83 width=40) (actual time=74.809..74.815 rows=4 loops=1)
         Group Key: CASE WHEN ((EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (c.data_nascimento)::timestamp with time zone)) >= '18'::numeric) AND (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (c.data_nascimento)::timestamp with time zone)) <= '25'::numeric)) THEN '18-25'::text WHEN ((EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (c.data_nascimento)::timestamp with time zone)) >= '26'::numeric) AND (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (c.data_nascimento)::timestamp with time zone)) <= '35'::numeric)) THEN '26-35'::text WHEN ((EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (c.data_nascimento)::timestamp with time zone)) >= '36'::numeric) AND (EXTRACT(year FROM age((CURRENT_DATE)::timestamp with time zone, (c.data_nascimento)::timestamp with time zone)) <= '50'::numeric)) THEN '36-50'::text ELSE '50+'::text END
         Batches: 1  Memory Usage: 24kB
         ->  Hash Join  (cost=356.12..1437.38 rows=8607 width=32) (actual time=4.598..69.193 rows=8612 loops=1)
               Hash Cond: (c.id_cliente = p.id_pessoa)
               ->  Seq Scan on clientes c  (cost=0.00..262.00 rows=17000 width=8) (actual time=0.024..3.775 rows=17000 loops=1)
               ->  Hash  (cost=243.47..243.47 rows=9012 width=4) (actual time=4.407..4.409 rows=9012 loops=1)
                     Buckets: 16384  Batches: 1  Memory Usage: 445kB
                     ->  Index Only Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..243.47 rows=9012 width=4) (actual time=0.039..1.980 rows=9012 loops=1)
                           Heap Fetches: 0
 Planning Time: 0.896 ms
 Execution Time: 75.082 ms
````

- Tempo de execução de 75.0823 ms, índice utilizado na tabela pessoas e leitura sequencial em clientes. O maior gargalo está atrelado ao cálculo da idade com a função AGE, uma vez que o índice não é utilizado.

## Query versão 2

````sql
EXPLAIN ANALYZE
SELECT 
    CASE 
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '25 years' 
                                 AND CURRENT_DATE - INTERVAL '18 years' THEN '18-25'
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '35 years' 
                                 AND CURRENT_DATE - INTERVAL '26 years' THEN '26-35'
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '50 years' 
                                 AND CURRENT_DATE - INTERVAL '36 years' THEN '36-50'
        ELSE '50+'
    END AS faixa_etaria,
    COUNT(*) AS total
FROM clientes
JOIN pessoas ON pessoas.id_pessoa = clientes.id_cliente
WHERE pessoas.ativo = true
GROUP BY faixa_etaria
ORDER BY total DESC;
````

### Query plan 1

````sql
Sort  (cost=1100.31..1100.52 rows=83 width=40) (actual time=29.062..29.068 rows=4 loops=1)
   Sort Key: (count(*)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=1093.10..1097.67 rows=83 width=40) (actual time=29.039..29.046 rows=4 loops=1)
         Group Key: CASE WHEN ((clientes.data_nascimento >= (CURRENT_DATE - '25 years'::interval)) AND (clientes.data_nascimento <= (CURRENT_DATE - '18 years'::interval))) THEN '18-25'::text WHEN ((clientes.data_nascimento >= (CURRENT_DATE - '35 years'::interval)) AND (clientes.data_nascimento <= (CURRENT_DATE - '26 years'::interval))) THEN '26-35'::text WHEN ((clientes.data_nascimento >= (CURRENT_DATE - '50 years'::interval)) AND (clientes.data_nascimento <= (CURRENT_DATE - '36 years'::interval))) THEN '36-50'::text ELSE '50+'::text END
         Batches: 1  Memory Usage: 24kB
         ->  Hash Join  (cost=356.12..1050.07 rows=8607 width=32) (actual time=5.403..25.188 rows=8612 loops=1)
               Hash Cond: (clientes.id_cliente = pessoas.id_pessoa)
               ->  Seq Scan on clientes  (cost=0.00..262.00 rows=17000 width=8) (actual time=0.100..2.824 rows=17000 loops=1)
               ->  Hash  (cost=243.47..243.47 rows=9012 width=4) (actual time=5.173..5.174 rows=9012 loops=1)
                     Buckets: 16384  Batches: 1  Memory Usage: 445kB
                     ->  Index Only Scan using idx_pessoas_ativas on pessoas  (cost=0.29..243.47 rows=9012 width=4) (actual time=0.030..2.375 rows=9012 loops=1)
                           Heap Fetches: 0
 Planning Time: 0.821 ms
 Execution Time: 29.442 ms
````

- Plano de execução semelhante ao da consulta anterior mas com desempenho melhor em razão de não existirem funções durante a execução da consulta.

## Query versão 3

````sql
EXPLAIN ANALYZE
WITH pesssoas_filtradas AS (
    SELECT
        p.id_pessoa
    FROM pessoas p
    WHERE p.ativo = true
)
SELECT 
    CASE 
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '25 years' 
                                 AND CURRENT_DATE - INTERVAL '18 years' THEN '18-25'
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '35 years' 
                                 AND CURRENT_DATE - INTERVAL '26 years' THEN '26-35'
        WHEN data_nascimento BETWEEN CURRENT_DATE - INTERVAL '50 years' 
                                 AND CURRENT_DATE - INTERVAL '36 years' THEN '36-50'
        ELSE '50+'
    END AS faixa_etaria,
    COUNT(*) AS total
FROM clientes
JOIN pesssoas_filtradas pf ON pf.id_pessoa = clientes.id_cliente
GROUP BY faixa_etaria
ORDER BY total DESC;
````

### Query plan 1

````sql
Sort  (cost=1100.31..1100.52 rows=83 width=40) (actual time=30.793..30.799 rows=4 loops=1)
   Sort Key: (count(*)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=1093.10..1097.67 rows=83 width=40) (actual time=30.768..30.776 rows=4 loops=1)
         Group Key: CASE WHEN ((clientes.data_nascimento >= (CURRENT_DATE - '25 years'::interval)) AND (clientes.data_nascimento <= (CURRENT_DATE - '18 years'::interval))) THEN '18-25'::text WHEN ((clientes.data_nascimento >= (CURRENT_DATE - '35 years'::interval)) AND (clientes.data_nascimento <= (CURRENT_DATE - '26 years'::interval))) THEN '26-35'::text WHEN ((clientes.data_nascimento >= (CURRENT_DATE - '50 years'::interval)) AND (clientes.data_nascimento <= (CURRENT_DATE - '36 years'::interval))) THEN '36-50'::text ELSE '50+'::text END
         Batches: 1  Memory Usage: 24kB
         ->  Hash Join  (cost=356.12..1050.07 rows=8607 width=32) (actual time=5.511..26.366 rows=8612 loops=1)
               Hash Cond: (clientes.id_cliente = p.id_pessoa)
               ->  Seq Scan on clientes  (cost=0.00..262.00 rows=17000 width=8) (actual time=0.044..3.045 rows=17000 loops=1)
               ->  Hash  (cost=243.47..243.47 rows=9012 width=4) (actual time=5.328..5.330 rows=9012 loops=1)
                     Buckets: 16384  Batches: 1  Memory Usage: 445kB
                     ->  Index Only Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..243.47 rows=9012 width=4) (actual time=0.035..2.270 rows=9012 loops=1)
                           Heap Fetches: 0
 Planning Time: 1.092 ms
 Execution Time: 31.234 ms
````

- Consulta com CTE apresentou o mesmo plano em comparação com a anterior.