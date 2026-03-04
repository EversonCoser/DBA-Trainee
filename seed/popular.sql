INSERT INTO formas_pagamento (nome) VALUES
('Dinheiro'), ('Credito'), ('Debito'), ('Pix'), ('Boleto');

CREATE OR REPLACE PROCEDURE popular_banco(
    p_qtd_clientes INT,
    p_qtd_funcionarios INT,
    p_qtd_fornecedores INT,
    p_qtd_produtos INT,
    p_qtd_compras INT,
    p_qtd_vendas INT,
    p_qtd_fornecedores_fornecimento INT,
    p_qtd_produtos_fornecimento INT
)
AS $$
BEGIN
    CALL gera_pessoas_especializadas(p_qtd_clientes, p_qtd_funcionarios, p_qtd_fornecedores);
    CALL gerar_produtos(p_qtd_produtos);
    CALL gerar_fornecimento(p_qtd_fornecedores_fornecimento, p_qtd_produtos_fornecimento);
    CALL gerar_compras(p_qtd_compras);
    CALL gera_vendas(p_qtd_vendas);
    
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE gera_pessoas_especializadas(
    p_qtd_clientes INT,
    p_qtd_funcionarios INT,
    p_qtd_fornecedores INT
)
AS $$
BEGIN

    -- Clientes

    WITH novas_pessoas AS (
    INSERT INTO pessoas (
        nome,
        email,
        telefone,
        ativo,
        fisica_juridica,
        cpf_cnpj,
        data_cadastro
    )
    SELECT
        'Cliente ' || gs,
        'cliente' || gs || '@email.com',
        '(' || (11 + floor(random() * 89))::INT || ')9' ||
        (1000 + floor(random() * 9000))::INT || '-' ||
        (1000 + floor(random() * 9000))::INT,
        (random() < 0.5),
        tipo,
        CASE 
            WHEN tipo = 'F' THEN lpad(gs::TEXT, 11, '0')
            ELSE lpad(gs::TEXT, 14, '0')
        END,
        CURRENT_DATE - (floor(random() * 1460))::INT
    FROM (
        SELECT 
            gs,
            (ARRAY['F','J'])[floor(random()*2+1)::INT]::tipo_pessoa_enum AS tipo
        FROM generate_series(1, p_qtd_clientes) gs
    ) t
    RETURNING id_pessoa
    )
    INSERT INTO clientes (id_cliente, data_nascimento, pontos_fidelidade)
    SELECT
        id_pessoa,
        CURRENT_DATE - ((18 + floor(random()*83))::INT * INTERVAL '1 year'),
        floor(random() * 1001)::INT
    FROM novas_pessoas;

    -- Funcionários

    WITH dados_funcionarios AS (
        SELECT
            gs,
            CURRENT_TIMESTAMP - (random() * INTERVAL '4 years') AS data_base
        FROM generate_series(1, p_qtd_funcionarios) gs
    ),
    novas_pessoas AS (
        INSERT INTO pessoas (
            nome,
            email,
            telefone,
            ativo,
            fisica_juridica,
            cpf_cnpj,
            data_cadastro
        )
        SELECT
            'Funcionario ' || gs,
            'funcionario' || gs || '@email.com',
            '(' || (11 + floor(random() * 89))::INT || ')9' ||
            (1000 + floor(random() * 9000))::INT || '-' ||
            (1000 + floor(random() * 9000))::INT,
            (random() < 0.5),
            'F',
            lpad((100000 + gs)::TEXT, 11, '0'),
            data_base
        FROM dados_funcionarios
        RETURNING id_pessoa, data_cadastro
    )
    INSERT INTO funcionarios (
        id_funcionario,
        cargo,
        salario,
        data_contratacao
    )
    SELECT
        np.id_pessoa,
        (ARRAY['Gerente','Vendedor','Estoquista','Financeiro'])
            [floor(random()*4+1)::INT]::tipo_funcionario_enum,
        2000 + floor(random()*5000),
        np.data_cadastro
    FROM novas_pessoas np;


    -- Fornecedores

    WITH novas_pessoas AS (
        INSERT INTO pessoas (
            nome,
            email,
            telefone,
            ativo,
            fisica_juridica,
            cpf_cnpj, 
            data_cadastro
        )
        SELECT
            'Fornecedor ' || gs,
            'fornecedor' || gs || '@email.com',
            '(' || (11 + floor(random() * 89))::INT || ')9' ||
            (1000 + floor(random() * 9000))::INT || '-' ||
            (1000 + floor(random() * 9000))::INT,
            (random() < 0.5),
            'J',
            lpad((1000000 + gs)::TEXT, 14, '0'),
            CURRENT_DATE - (floor(random() * 1460))::INT
        FROM generate_series(1, p_qtd_fornecedores) gs
        RETURNING id_pessoa
    )
    INSERT INTO fornecedores (
        id_fornecedor,
        prazo_entrega
    )
    SELECT
        id_pessoa,
        5 + floor(random()*20)
    FROM novas_pessoas;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE gerar_produtos(
    p_qtd_produtos INT
)
AS $$
BEGIN
    INSERT INTO produtos (descricao, categoria, preco, estoque, ativo, data_cadastro)
    SELECT
        'Produto ' || gs,
        (ARRAY['Eletrônicos', 'Roupas', 'Alimentos', 'Móveis', 'Brinquedos'])
            [floor(random()*5+1)::INT],
        round((10 + random() * 490)::numeric, 2),
        floor(random() * 1000),
        (random() < 0.8),
        CURRENT_TIMESTAMP - (random() * INTERVAL '4 years')
    FROM generate_series(1, p_qtd_produtos) gs;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE gerar_fornecimento(
    qtd_fornecedores INT,
    qtd_produtos INT
)
AS $$
BEGIN

    INSERT INTO fornecimento (
        id_fornecedor,
        id_produto,
        prioridade
    )
    SELECT
        f.id_fornecedor,
        p.id_produto,
        (ARRAY['Primaria', 'Secundaria', 'Terciaria', 'Outros'])
            [floor(random()*4 + 1)::INT]::prioridade_enum
    FROM (
        SELECT id_fornecedor
        FROM fornecedores
        ORDER BY random()
        LIMIT qtd_fornecedores
    ) f
    CROSS JOIN LATERAL (
        SELECT pr.id_produto
        FROM produtos pr
        WHERE NOT EXISTS (
            SELECT 1
            FROM fornecimento fo
            WHERE fo.id_fornecedor = f.id_fornecedor
              AND fo.id_produto = pr.id_produto
        )
        ORDER BY random()
        LIMIT qtd_produtos
    ) p;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE gerar_compras(
    p_qtd_compras INT
)
AS $$
DECLARE
    v_fornecedores INT[];
    v_funcionarios INT[];
    v_produtos INT[];
    v_total_produtos INT;

    v_id_compra INT;
    v_qtd_itens INT;
BEGIN

    SELECT array_agg(id_fornecedor) INTO v_fornecedores FROM fornecedores;
    SELECT array_agg(id_funcionario) INTO v_funcionarios FROM funcionarios;
    SELECT array_agg(id_produto) INTO v_produtos FROM produtos;

    v_total_produtos := array_length(v_produtos, 1);

    FOR v_id_compra IN
        INSERT INTO compras (
            id_fornecedor,
            id_funcionario,
            data_compra,
            valor_total
        )
        SELECT
            v_fornecedores[floor(random()*array_length(v_fornecedores,1) + 1)],
            v_funcionarios[floor(random()*array_length(v_funcionarios,1) + 1)],
            CURRENT_TIMESTAMP - (random() * INTERVAL '4 years'),
            0
        FROM generate_series(1, p_qtd_compras)
        RETURNING id_compra
    LOOP

        v_qtd_itens := floor(random()*3 + 1);

        INSERT INTO itens_compra (
            id_compra,
            id_produto,
            quantidade,
            valor_unitario
        )
        SELECT
            v_id_compra,
            p.id_produto,
            floor(random()*10 + 1)::INT,
            p.preco * 0.75
        FROM (
            SELECT DISTINCT v_produtos[
                floor(random()*v_total_produtos + 1)::INT
            ] AS id_produto
            FROM generate_series(1, v_qtd_itens * 3)
            LIMIT v_qtd_itens
        ) sorteados
        JOIN produtos p USING (id_produto);

    END LOOP;

    UPDATE compras c
    SET valor_total = sub.total
    FROM (
        SELECT id_compra,
               SUM(quantidade * valor_unitario) AS total
        FROM itens_compra
        GROUP BY id_compra
    ) sub
    WHERE c.id_compra = sub.id_compra
      AND c.valor_total = 0;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE gera_vendas (
    p_qtd_vendas INT
)
AS $$
DECLARE
    v_clientes INT[];
    v_funcionarios INT[];
    v_formas INT[];
    v_produtos INT[];
    v_total_produtos INT;

    v_id_venda INT;
    v_qtd_itens INT;
BEGIN

    SELECT array_agg(id_cliente) INTO v_clientes FROM clientes;
    SELECT array_agg(id_funcionario) INTO v_funcionarios FROM funcionarios;
    SELECT array_agg(id_forma_pagamento) INTO v_formas FROM formas_pagamento;
    SELECT array_agg(id_produto) INTO v_produtos FROM produtos;

    v_total_produtos := array_length(v_produtos, 1);

    FOR v_id_venda IN
        INSERT INTO vendas (
            id_cliente,
            id_forma_pagamento,
            id_funcionario,
            data_venda,
            data_pagamento,
            status_pedido,
            valor_total
        )
        SELECT
            v_clientes[floor(random()*array_length(v_clientes,1) + 1)],
            v_formas[floor(random()*array_length(v_formas,1) + 1)],
            v_funcionarios[floor(random()*array_length(v_funcionarios,1) + 1)],
            dv.data_venda,
            CASE 
                WHEN dv.status = 'Pago'
                    THEN dv.data_venda + (random() * INTERVAL '30 days')
                ELSE NULL
            END,
            dv.status,
            0
        FROM (
            SELECT
                data_venda,
                CASE
                    WHEN r < 0.75 THEN 'Pago'
                    WHEN r < 0.90 THEN 'Pendente'
                    ELSE 'Cancelado'
                END::status_pedido_enum AS status
            FROM (
                SELECT 
                    random() AS r,
                    CURRENT_TIMESTAMP - (random() * INTERVAL '4 years') AS data_venda
                FROM generate_series(1, p_qtd_vendas)
            ) t
        ) dv
        RETURNING id_venda
    LOOP

        v_qtd_itens := floor(random()*5 + 1);

        INSERT INTO itens_venda (
            id_venda,
            id_produto,
            quantidade,
            preco_unitario_venda
        )
        SELECT
            v_id_venda,
            p.id_produto,
            floor(random()*5 + 1)::INT,
            p.preco
        FROM (
            SELECT DISTINCT v_produtos[
                floor(random()*v_total_produtos + 1)::INT
            ] AS id_produto
            FROM generate_series(1, v_qtd_itens * 3)
            LIMIT v_qtd_itens
        ) sorteados
        JOIN produtos p USING (id_produto);

    END LOOP;

    UPDATE vendas v
    SET valor_total = sub.total
    FROM (
        SELECT id_venda,
               SUM(quantidade * preco_unitario_venda) AS total
        FROM itens_venda
        GROUP BY id_venda
    ) sub
    WHERE v.id_venda = sub.id_venda
      AND v.valor_total = 0;

END;
$$ LANGUAGE plpgsql;
