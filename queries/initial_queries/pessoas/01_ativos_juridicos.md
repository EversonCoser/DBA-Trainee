# Porcentagem de pessoas ativas e porcentagem de pessoas físicas

## Query para pessoas ativas

````sql
EXPLAIN ANALYZE
SELECT 
    COUNT(*) FILTER (WHERE ativo = true) AS pessoas_ativas,
    COUNT(*) FILTER (WHERE ativo = false) AS pessoas_inativas,
    ROUND(
        (COUNT(*) FILTER (WHERE ativo = true)::DECIMAL 
        / NULLIF(COUNT(*),0)) * 100, 
    2) AS percentual_ativos
FROM pessoas;
````

### Query plan 

````sql
Aggregate  (cost=561.50..561.52 rows=1 width=48) (actual time=5.176..5.177 rows=1 loops=1)
   ->  Seq Scan on pessoas  (cost=0.00..428.00 rows=17800 width=1) (actual time=0.022..1.995 rows=17800 loops=1)
 Planning Time: 0.168 ms
 Execution Time: 5.212 ms
````

- Leitura sequencial na tabela pessoas.

## Query para pessoas físicas

````sql
EXPLAIN ANALYZE
SELECT
    COUNT(*) FILTER (WHERE fisica_juridica = 'F') AS clientes_fisicos,
    COUNT(*) FILTER (WHERE fisica_juridica = 'J') AS clientes_juridicos,
    ROUND(
        (COUNT(*) FILTER (WHERE fisica_juridica = 'F')::DECIMAL
        / NULLIF(COUNT(*),0)) * 100,
    2) AS percentual_fisicos 
FROM pessoas;
````

# Query plan

````sql
Aggregate  (cost=650.50..650.52 rows=1 width=48) (actual time=5.606..5.607 rows=1 loops=1)
   ->  Seq Scan on pessoas  (cost=0.00..428.00 rows=17800 width=4) (actual time=0.015..1.914 rows=17800 loops=1)
 Planning Time: 0.135 ms
 Execution Time: 5.646 ms
 ````

- Leitura sequencial na tabela pessoas.