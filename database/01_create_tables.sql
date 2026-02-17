CREATE TYPE tipo_pessoa_enum AS ENUM ('F', 'J');

CREATE TABLE pessoas (
    id_pessoa SERIAL,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    telefone VARCHAR(20),
    ativo BOOLEAN DEFAULT TRUE,
    fisica_juridica tipo_pessoa_enum NOT NULL,
    cpf_cnpj VARCHAR(14) NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clientes (
    id_cliente INT NOT NULL,
    data_nascimento DATE NOT NULL,
    pontos_fidelidade INT DEFAULT 0
);

CREATE TYPE tipo_funcionario_enum AS ENUM ('Gerente', 'Vendedor', 'Estoquista', 'Financeiro');

CREATE TABLE funcionarios (
    id_funcionario INT NOT NULL,
    cargo tipo_funcionario_enum NOT NULL,
    salario NUMERIC(10,2) NOT NULL,
    data_contratacao DATE NOT NULL
);

CREATE TABLE fornecedores (
    id_fornecedor INT NOT NULL,
    prazo_entrega INT NOT NULL
);

CREATE TABLE produtos (
    id_produto SERIAL,
    descricao  VARCHAR(150) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    preco      NUMERIC(10,2) NOT NULL,
    estoque    INT NOT NULL DEFAULT 0,
    ativo      BOOLEAN DEFAULT TRUE,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TYPE prioridade_enum AS ENUM ('Primaria', 'Secundaria', 'Terciaria', 'Outros');

CREATE TABLE fornecimento (
    id_fornecimento SERIAL,
    id_fornecedor INT NOT NULL,
    id_produto INT NOT NULL,
    prioridade prioridade_enum NOT NULL
);

CREATE TABLE compras (
    id_compra SERIAL,
    id_fornecedor INT NOT NULL,
    id_funcionario INT NOT NULL,
    data_compra TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valor_total NUMERIC(10,2)
);

CREATE TABLE itens_compra (
    id_itens SERIAL,
    id_compra INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    valor_unitario NUMERIC(10,2) NOT NULL
);

CREATE TYPE tipo_pagamento_enum AS ENUM ('Dinheiro', 'Credito', 'Debito', 'Pix', 'Boleto');

CREATE TABLE formas_pagamento (
    id_forma_pagamento SERIAL,
    nome tipo_pagamento_enum NOT NULL
);

CREATE TYPE status_pedido_enum AS ENUM ('Pendente', 'Pago', 'Cancelado');

CREATE TABLE vendas (
    id_venda SERIAL,
    id_cliente INT NOT NULL,
    id_forma_pagamento INT NOT NULL,
    id_funcionario INT NOT NULL,
    data_venda TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_pagamento TIMESTAMP,
    status_pedido status_pedido_enum NOT NULL,
    valor_total NUMERIC(10,2) NOT NULL
);

CREATE TABLE itens_venda (
    id_itens_venda SERIAL,
    id_venda INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario_venda NUMERIC(10,2) NOT NULL
);

