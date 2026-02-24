# Performance por funcionário

## Query versão 1
- Contagem da quantidade de vendas, utilizando COUNT.
- Valor total utilizando SUM.
- Utilização de índices já criados.
- Tabela vendas com 1.500.000 registros.
- Tabela funcionarios com 350 registros.
- Tabela pessoas com 17800 registros.

```sql
EXPLAIN ANALYZE
SELECT
    f.id_funcionario,
    p.nome,
    SUM(v.valor_total) AS valor_total,
    COUNT(*) AS total_vendas
FROM vendas v
JOIN funcionarios f 
    ON f.id_funcionario = v.id_funcionario
JOIN pessoas p 
    ON p.id_pessoa = f.id_funcionario
    AND p.ativo = true
WHERE v.status_pedido = 'Pago'
    AND v.data_venda BETWEEN '2024-01-01' AND '2024-12-31'
GROUP BY f.id_funcionario, p.nome
ORDER BY valor_total DESC
LIMIT 10;
```

### Query plan 1

````sql
Limit  (cost=58006.26..58006.28 rows=10 width=57) (actual time=270.460..270.466 rows=10 loops=1)
   ->  Sort  (cost=58006.26..58364.73 rows=143390 width=57) (actual time=270.458..270.463 rows=10 loops=1)
         Sort Key: (sum(v.valor_total)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  HashAggregate  (cost=51434.92..54907.65 rows=143390 width=57) (actual time=270.216..270.388 rows=167 loops=1)
               Group Key: f.id_funcionario, p.nome
               Planned Partitions: 8  Batches: 1  Memory Usage: 913kB
               ->  Hash Join  (cost=8526.96..40411.82 rows=143390 width=23) (actual time=40.481..213.937 rows=133877 loops=1)
                     Hash Cond: (v.id_funcionario = f.id_funcionario)
                     ->  Hash Join  (cost=8516.08..40019.98 rows=143390 width=27) (actual time=40.187..181.261 rows=133877 loops=1)
                           Hash Cond: (v.id_funcionario = p.id_pessoa)
                           ->  Bitmap Heap Scan on vendas v  (cost=7975.43..38735.71 rows=283216 width=10) (actual time=34.357..105.273 rows=279922 loops=1)
                                 Recheck Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                 Heap Blocks: exact=13639
                                 ->  Bitmap Index Scan on idx_vendas_status_data  (cost=0.00..7904.63 rows=283216 width=0) (actual time=30.788..30.788 rows=279922 loops=1)
                                       Index Cond: ((status_pedido = 'Pago'::status_pedido_enum) AND (data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                           ->  Hash  (cost=428.00..428.00 rows=9012 width=17) (actual time=5.724..5.725 rows=9012 loops=1)
                                 Buckets: 16384  Batches: 1  Memory Usage: 584kB
                                 ->  Seq Scan on pessoas p  (cost=0.00..428.00 rows=9012 width=17) (actual time=0.044..3.478 rows=9012 loops=1)
                                       Filter: ativo
                                       Rows Removed by Filter: 8788
                     ->  Hash  (cost=6.50..6.50 rows=350 width=4) (actual time=0.278..0.278 rows=350 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 21kB
                           ->  Seq Scan on funcionarios f  (cost=0.00..6.50 rows=350 width=4) (actual time=0.032..0.093 rows=350 loops=1)
 Planning Time: 0.895 ms
 Execution Time: 271.513 ms
 ````

- Tempo de execução de 271.513 ms, Seq Scan nas tabelas pessoas e funcionarios, seguido de um Hash. Além disso, um Bitmap Index Scan com o índice idx_vendas_status_data foi realizado, um Bitmap Heap Scan em vendas seguido de Hash Join e Limit.
- Após a análise, um índice em id_funcionario na tabela vendas foi criado.

### Query plan 2

````sql
Limit  (cost=38055.95..38055.98 rows=10 width=57) (actual time=782.028..782.032 rows=10 loops=1)
   ->  Sort  (cost=38055.95..38414.43 rows=143390 width=57) (actual time=782.026..782.029 rows=10 loops=1)
         Sort Key: (sum(v.valor_total)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  GroupAggregate  (cost=797.32..34957.35 rows=143390 width=57) (actual time=18.065..781.557 rows=167 loops=1)
               Group Key: f.id_funcionario, p.nome
               ->  Incremental Sort  (cost=797.32..31731.07 rows=143390 width=23) (actual time=12.920..738.096 rows=133877 loops=1)
                     Sort Key: f.id_funcionario, p.nome
                     Presorted Key: f.id_funcionario
                     Full-sort Groups: 167  Sort Method: quicksort  Average Memory: 28kB  Peak Memory: 28kB
                     Pre-sorted Groups: 167  Sort Method: quicksort  Average Memory: 62kB  Peak Memory: 62kB
                     ->  Nested Loop  (cost=713.84..23709.74 rows=143390 width=23) (actual time=6.744..687.516 rows=133877 loops=1)
                           Join Filter: (v.id_funcionario = f.id_funcionario)
                           ->  Merge Join  (cost=713.42..749.97 rows=177 width=21) (actual time=6.664..8.239 rows=167 loops=1)
                                 Merge Cond: (f.id_funcionario = p.id_pessoa)
                                 ->  Index Only Scan using pk_funcionarios_id_funcionario on funcionarios f  (cost=0.15..19.40 rows=350 width=4) (actual time=0.029..0.706 rows=350 loops=1)
                                       Heap Fetches: 350
                                 ->  Index Scan using pk_pessoas_id_pessoa on pessoas p  (cost=0.29..724.29 rows=9012 width=17) (actual time=0.021..6.121 rows=8780 loops=1)
                                       Filter: ativo
                                       Rows Removed by Filter: 8571
                           ->  Index Scan using idx_vendas_id_funcionario on vendas v  (cost=0.43..119.60 rows=809 width=10) (actual time=0.019..3.890 rows=802 loops=167)
                                 Index Cond: (id_funcionario = p.id_pessoa)
                                 Filter: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
                                 Rows Removed by Filter: 3483
 Planning Time: 1.080 ms
 Execution Time: 782.101 ms
````

- O tempo de execução foi de 782.101, a utilização do índice idx_vendas_id_funcionario acabou por gerar um Nested Loop, o que causou um aumento significativo de custos. Portanto, índice simples em id_funcionario não é viável.
- Na sequência, um novo índice foi criado:

````sql
CREATE INDEX idx_vendas_pago_data_func
ON vendas (data_venda, id_funcionario)
WHERE status_pedido = 'Pago';
````

### Query plan 3

`````sql
Limit  (cost=57294.22..57294.24 rows=10 width=57) (actual time=292.981..292.986 rows=10 loops=1)
   ->  Sort  (cost=57294.22..57652.69 rows=143390 width=57) (actual time=292.979..292.983 rows=10 loops=1)
         Sort Key: (sum(v.valor_total)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  HashAggregate  (cost=50722.88..54195.61 rows=143390 width=57) (actual time=292.785..292.923 rows=167 loops=1)
               Group Key: f.id_funcionario, p.nome
               Planned Partitions: 8  Batches: 1  Memory Usage: 913kB
               ->  Hash Join  (cost=7814.92..39699.78 rows=143390 width=23) (actual time=54.007..233.758 rows=133877 loops=1)
                     Hash Cond: (v.id_funcionario = f.id_funcionario)
                     ->  Hash Join  (cost=7804.04..39307.94 rows=143390 width=27) (actual time=53.848..198.991 rows=133877 loops=1)
                           Hash Cond: (v.id_funcionario = p.id_pessoa)
                           ->  Bitmap Heap Scan on vendas v  (cost=7263.39..38023.67 rows=283216 width=10) (actual time=47.407..118.832 rows=279922 loops=1)
                                 Recheck Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone) AND (status_pedido = 'Pago'::status_pedido_enum))
                                 Heap Blocks: exact=13639
                                 ->  Bitmap Index Scan on idx_vendas_pago_data_func  (cost=0.00..7192.59 rows=283216 width=0) (actual time=42.896..42.897 rows=279922 loops=1)
                                       Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                           ->  Hash  (cost=428.00..428.00 rows=9012 width=17) (actual time=6.335..6.335 rows=9012 loops=1)
                                 Buckets: 16384  Batches: 1  Memory Usage: 584kB
                                 ->  Seq Scan on pessoas p  (cost=0.00..428.00 rows=9012 width=17) (actual time=0.011..3.805 rows=9012 loops=1)
                                       Filter: ativo
                                       Rows Removed by Filter: 8788
                     ->  Hash  (cost=6.50..6.50 rows=350 width=4) (actual time=0.144..0.145 rows=350 loops=1)
                           Buckets: 1024  Batches: 1  Memory Usage: 21kB
                           ->  Seq Scan on funcionarios f  (cost=0.00..6.50 rows=350 width=4) (actual time=0.044..0.081 rows=350 loops=1)
 Planning Time: 1.687 ms
 Execution Time: 293.827 ms
`````

- Plano de consulta estruturado da mesma forma que o plano de consulta 1, mas com a utilização do índice idx_vendas_pago_data_func criado anteriormente.

## Query versão 2

````sql
EXPLAIN ANALYSE
WITH performance_funcionario AS (
    SELECT
        id_funcionario,
        SUM(valor_total) AS valor_total,
        COUNT(*) AS total_vendas
    FROM vendas
    WHERE status_pedido = 'Pago'
      AND data_venda BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY id_funcionario
)
SELECT
    pf.id_funcionario,
    p.nome,
    pf.valor_total,
    pf.total_vendas
FROM performance_funcionario pf
JOIN pessoas p
    ON p.id_pessoa = pf.id_funcionario
   AND p.ativo = true
ORDER BY pf.valor_total DESC
LIMIT 10;
````

- Para essa consulta optou-se por alterar excluir o índice idx_vendas_pago_data_func e criar os índices a seguir:

````sql
CREATE INDEX idx_vendas_pago_cover
ON vendas (data_venda, id_funcionario)
INCLUDE (valor_total)
WHERE status_pedido = 'Pago';


CREATE INDEX idx_pessoas_ativas
ON pessoas (id_pessoa)
WHERE ativo = true;
````

### Query plan 1

````sql
Limit  (cost=12016.41..12016.43 rows=10 width=57) (actual time=135.543..135.821 rows=10 loops=1)
   ->  Sort  (cost=12016.41..12016.85 rows=177 width=57) (actual time=135.540..135.815 rows=10 loops=1)
         Sort Key: (sum(vendas.valor_total)) DESC
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Merge Join  (cost=11521.18..12012.58 rows=177 width=57) (actual time=133.040..135.629 rows=167 loops=1)
               Merge Cond: (vendas.id_funcionario = p.id_pessoa)
               ->  Finalize GroupAggregate  (cost=11520.90..11613.94 rows=350 width=44) (actual time=129.004..131.298 rows=350 loops=1)
                     Group Key: vendas.id_funcionario
                     ->  Gather Merge  (cost=11520.90..11602.57 rows=700 width=44) (actual time=128.972..129.851 rows=1050 loops=1)
                           Workers Planned: 2
                           Workers Launched: 2
                           ->  Sort  (cost=10520.87..10521.75 rows=350 width=44) (actual time=56.485..56.518 rows=350 loops=3)
                                 Sort Key: vendas.id_funcionario
                                 Sort Method: quicksort  Memory: 57kB
                                 Worker 0:  Sort Method: quicksort  Memory: 57kB
                                 Worker 1:  Sort Method: quicksort  Memory: 57kB
                                 ->  Partial HashAggregate  (cost=10501.71..10506.08 rows=350 width=44) (actual time=56.178..56.319 rows=350 loops=3)
                                       Group Key: vendas.id_funcionario
                                       Batches: 1  Memory Usage: 285kB
                                       Worker 0:  Batches: 1  Memory Usage: 285kB
                                       Worker 1:  Batches: 1  Memory Usage: 285kB
                                       ->  Parallel Index Only Scan using idx_vendas_pago_cover on vendas  (cost=0.43..9616.65 rows=118007 width=10) (actual time=0.074..20.927 rows=93307 loops=3)
                                             Index Cond: ((data_venda >= '2024-01-01 00:00:00'::timestamp without time zone) AND (data_venda <= '2024-12-31 00:00:00'::timestamp without time zone))
                                             Heap Fetches: 0
               ->  Index Scan using idx_pessoas_ativas on pessoas p  (cost=0.29..373.47 rows=9012 width=17) (actual time=0.060..3.123 rows=8780 loops=1)
 Planning Time: 0.700 ms
 Execution Time: 136.031 ms
 ````

 - O tempo de execução foi de 136.031 ms, os índices idx_pessoas_ativas e idx_vendas_pago_cover foram utilizados.