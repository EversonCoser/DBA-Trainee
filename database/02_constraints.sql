-- pessoas

ALTER TABLE pessoas
    ADD CONSTRAINT pk_pessoas_id_pessoa 
        PRIMARY KEY (id_pessoa);

ALTER TABLE pessoas
    ADD CONSTRAINT uq_pessoas_email
        UNIQUE (email);

ALTER TABLE pessoas
    ADD CONSTRAINT uq_pessoas_cpf_cnpj
        UNIQUE (cpf_cnpj);

ALTER TABLE pessoas
    ADD CONSTRAINT chk_email_formato
        CHECK (email LIKE '%@%.%');

ALTER TABLE pessoas
    ADD CONSTRAINT chk_cpf_cnpj_tipo
        CHECK (
            (
                fisica_juridica = 'F'
                AND cpf_cnpj ~ '^[0-9]{11}$'
            )
            OR
            (
                fisica_juridica = 'J'
                AND cpf_cnpj ~ '^[0-9]{14}$'
            )
        );


-- clientes

ALTER TABLE clientes
    ADD CONSTRAINT pk_clientes_id_cliente 
        PRIMARY KEY (id_cliente);

ALTER TABLE clientes
    ADD CONSTRAINT fk_clientes_pessoa
        FOREIGN KEY (id_cliente)
            REFERENCES pessoas(id_pessoa);

-- funcionarios

ALTER TABLE funcionarios
    ADD CONSTRAINT pk_funcionarios_id_funcionario 
        PRIMARY KEY (id_funcionario);

ALTER TABLE funcionarios
    ADD CONSTRAINT fk_funcionarios_pessoa
        FOREIGN KEY (id_funcionario)
            REFERENCES pessoas(id_pessoa);

ALTER TABLE funcionarios
    ADD CONSTRAINT chk_salario_positivo
        CHECK (salario > 0);

-- fornecedores

ALTER TABLE fornecedores
    ADD CONSTRAINT pk_fornecedores_id_fornecedor 
        PRIMARY KEY (id_fornecedor);

ALTER TABLE fornecedores
    ADD CONSTRAINT fk_fornecedores_pessoa
        FOREIGN KEY (id_fornecedor)
            REFERENCES pessoas(id_pessoa);

-- produtos

ALTER TABLE produtos
    ADD CONSTRAINT pk_produtos_id_produto 
        PRIMARY KEY (id_produto);

ALTER TABLE produtos
    ADD CONSTRAINT chk_preco_positivo
        CHECK (preco > 0);

ALTER TABLE produtos
    ADD CONSTRAINT chk_estoque_nao_negativo
        CHECK (estoque >= 0);

-- fornecimento

ALTER TABLE fornecimento
    ADD CONSTRAINT pk_fornecimento_id_fornecimento 
        PRIMARY KEY (id_fornecimento);

ALTER TABLE fornecimento
    ADD CONSTRAINT fk_fornecimento_fornecedor
        FOREIGN KEY (id_fornecedor)
            REFERENCES fornecedores(id_fornecedor);

ALTER TABLE fornecimento
    ADD CONSTRAINT fk_fornecimento_produto
        FOREIGN KEY (id_produto)
            REFERENCES produtos(id_produto);
    
ALTER TABLE fornecimento
    ADD CONSTRAINT uq_fornecimento_fornecedor_produto
        UNIQUE (id_fornecedor, id_produto);

-- compras

ALTER TABLE compras
    ADD CONSTRAINT pk_compras_id_compra 
        PRIMARY KEY (id_compra);

ALTER TABLE compras
    ADD CONSTRAINT fk_compras_fornecedor
        FOREIGN KEY (id_fornecedor)
            REFERENCES fornecedores(id_fornecedor);

ALTER TABLE compras
    ADD CONSTRAINT fk_compras_funcionario
        FOREIGN KEY (id_funcionario)
            REFERENCES funcionarios(id_funcionario);

ALTER TABLE compras
    ADD CONSTRAINT chk_valor_total_positivo
        CHECK (valor_total >= 0);

-- itens_compra

ALTER TABLE itens_compra
    ADD CONSTRAINT pk_itens_compra_id_item 
        PRIMARY KEY (id_itens);

ALTER TABLE itens_compra
    ADD CONSTRAINT fk_itens_compra_compra
        FOREIGN KEY (id_compra)
            REFERENCES compras(id_compra);

ALTER TABLE itens_compra
    ADD CONSTRAINT fk_itens_compra_produto
        FOREIGN KEY (id_produto)
            REFERENCES produtos(id_produto);

ALTER TABLE itens_compra
    ADD CONSTRAINT uq_itens_compra_compra_produto
        UNIQUE (id_compra, id_produto);

ALTER TABLE itens_compra
    ADD CONSTRAINT chk_quantidade_positiva
        CHECK (quantidade > 0);

ALTER TABLE itens_compra
    ADD CONSTRAINT chk_valor_unitario_positivo
        CHECK (valor_unitario >= 0);

-- formas_pagamento

ALTER TABLE formas_pagamento
    ADD CONSTRAINT pk_formas_pagamento_id_forma_pagamento 
        PRIMARY KEY (id_forma_pagamento);

-- vendas

ALTER TABLE vendas
    ADD CONSTRAINT pk_vendas_id_venda 
        PRIMARY KEY (id_venda);

ALTER TABLE vendas
    ADD CONSTRAINT fk_vendas_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente);

ALTER TABLE vendas
    ADD CONSTRAINT fk_vendas_forma_pagamento
        FOREIGN KEY (id_forma_pagamento)
            REFERENCES formas_pagamento(id_forma_pagamento);

ALTER TABLE vendas
    ADD CONSTRAINT fk_vendas_funcionario
        FOREIGN KEY (id_funcionario)
            REFERENCES funcionarios(id_funcionario);

ALTER TABLE vendas
    ADD CONSTRAINT chk_data_pagamento
        CHECK (
            (status_pedido = 'Pago' AND data_pagamento IS NOT NULL)
            OR
            (status_pedido <> 'Pago' AND data_pagamento IS NULL)
        );

ALTER TABLE vendas
    ADD CONSTRAINT chk_data_venda
        CHECK (data_pagamento >= data_venda);

ALTER TABLE vendas
    ADD CONSTRAINT chk_valor_total_venda_positivo
        CHECK (valor_total >= 0);

-- itens_venda

ALTER TABLE itens_venda
    ADD CONSTRAINT pk_itens_venda_id_item 
        PRIMARY KEY (id_itens_venda);

ALTER TABLE itens_venda
    ADD CONSTRAINT fk_itens_venda_venda
        FOREIGN KEY (id_venda)
            REFERENCES vendas(id_venda);

ALTER TABLE itens_venda
    ADD CONSTRAINT fk_itens_venda_produto
        FOREIGN KEY (id_produto)
            REFERENCES produtos(id_produto);

ALTER TABLE itens_venda
    ADD CONSTRAINT uq_itens_venda_venda_produto
        UNIQUE (id_venda, id_produto);

ALTER TABLE itens_venda
    ADD CONSTRAINT chk_quantidade_venda_positiva
        CHECK (quantidade > 0);

ALTER TABLE itens_venda    
    ADD CONSTRAINT chk_preco_unitario_venda_positivo
        CHECK (preco_unitario_venda >= 0);