# Modelo de Dados

## 1. Visão Geral

O modelo de dados foi projetado para simular um sistema de vendas simples, com foco em:

- Integridade referencial
- Facilidade de análise
- Base para testes de performance

O sistema contempla controle de pessoas (clientes, funcionários e fornecedores), produtos, vendas, itens vendidos, formas de pagamento, compras, itens comprados e informações de fornecimento.

---

## 2. Entidades 

### 2.1 Pessoas

Representa as entidades do sistema que podem assumir diferentes papéis (como funcionário, fornecedor, cliente), armazenando informações comuns a todas elas.

**Atributos:**
- id_pessoa (PK)
- nome
- email
- telefone
- ativo
- fisica_juridica
- cpf_cnpj
- data_cadastro

**Observações:**
- Atua como superclasse em uma especialização (generalização/especialização).
- Contém apenas atributos comuns às entidades derivadas.
- id_pessoa atua como chave primária da entidade.
- O campo fisica_juridica restringe o tipo da pessoa para Física ('F') ou Jurídica ('J').
- cpf_cnpj é obrigatório e deve respeitar a natureza da pessoa (CPF para Física, CNPJ para Jurídica), além da quantidade de caracteres (11 para CPF e 14 para CNPJ).
- ativo permite controle lógico de desativação sem exclusão física.
- data_cadastro é preenchida automaticamente com a data e hora da inserção, podendo ser sobrescrita manualmente.
- email e cpf_cnpj possuem restrição de unicidade.

---

### 2.2 Clientes

Representa os consumidores que realizam compras.

**Atributos:**
- id_cliente (PK, FK)
- data_nascimento
- pontos_fidelidade

**Observações:**
- Atua como subclasse em uma especialização (generalização/especialização).
- Contém apenas atributos específicos da entidade.
- O atributo id_cliente é uma chave primária que também exerce o papel de chave estrangeira, estabelecendo a herança entre Clientes e Pessoas.
- data_nascimento é preenchida manualmente apenas com a data em razão de ser do tipo DATE.
- O atributo pontos_fidelidade representa a quantidade de pontos acumulados pelo cliente ao realizar compras. Caso nenhum valor seja informado, é automaticamente inicializado com zero.

---

### 2.3 Funcionários

Representa os funcionários do estabelecimento comercial.

**Atributos:**
- id_funcionario (PK, FK)
- cargo 
- salario 
- data_contratacao 

**Observações:**
- Atua como subclasse em uma especialização (generalização/especialização).
- Contém apenas atributos específicos da entidade.
- O atributo id_funcionario é uma chave primária que também exerce o papel de chave estrangeira, estabelecendo a herança entre Funcionários e Pessoas.
- cargo é representado por ENUM (ex: Gerente, Vendedor, Estoquista, Financeiro).
- salario deve ser positivo e é verificado por CHECK CONSTRAINT.
- data_contratacao é preenchida manualmente apenas com a data em razão de ser do tipo DATE.

---

### 2.4 Fornecedores

Representa os fornecedores dos produtos para o estabelecimento.

**Atributos:**
- id_fornecedor (PK, FK)
- prazo_entrega

**Observações:**
- Atua como subclasse em uma especialização (generalização/especialização).
- Contém apenas atributos específicos da entidade.
- O atributo id_fornecedor é uma chave primária que também exerce o papel de chave estrangeira, estabelecendo a herança entre Fornecedor e Pessoas.

---

### 2.5 Produtos

Representa as informações dos produtos da unidade comercial.

**Atributos:**
- id_produto (PK)
- descricao  
- categoria 
- preco      
- estoque    
- ativo      
- data_cadastro

**Observações:**
- id_produto é a chave primária da entidade.
- preço e estoque devem ser positivos e é verificado por CHECK CONSTRAINT.

---

### 2.6 Fornecimento

Representa a associação entre produtos e fornecedores, indicando quais produtos são ofertados por cada fornecedor e a respectiva prioridade de fornecimento.

**Atributos:**
- id_fornecimento (PK)
- id_fornecedor (FK)
- id_produto (FK)
- prioridade

**Observações:**
- id_fornecimento é a chave primária da entidade.
- Os atributos id_fornecedor e id_produto são chaves estrangeiras responsáveis por manter a integridade referencial da tabela Fornecimento em relação às tabelas Fornecedor e Produto.
- O atributo prioridade é representado por ENUM (ex: Primaria, Secundaria, Terciaria, Outros)

---

### 2.7 Compras

Representa as compras efetuadas pela unidade comercial.

**Atributos:**
- id_compra (PK)
- id_fornecedor (FK)
- id_funcionario (FK)
- data_compra 
- valor_total

**Observações:**
- id_compra é a chave primária da entidade.
- Os atributos id_fornecedor e id_funcionario são chaves estrangeiras responsáveis por manter a integridade referencial da tabela Compras em relação às tabelas Fornecedor e Funcionários.
- O atributo valor_total deve ser positivo e é controlado por CHECK CONSTRAINT.

---

### 2.8 Itens_compra

Tabela associativa que materializa o relacionamento entre Compras e Produtos, detalhando os produtos adquiridos em cada compra realizada pela unidade comercial.

**Atributos:**
- id_itens (PK)
- id_compra (FK)
- id_produto (FK)
- quantidade 
- valor_unitario

**Observações:**
- id_itens é a chave primária da entidade.
- Os atributos id_compra e id_produto são chaves estrangeiras responsáveis por manter a integridade referencial da tabela Itens_compra em relação às tabelas Compras e Produtos.
- Os atributos quantidade e valor_unitario devem ser positivos e são controlados por CHECK CONSTRAINT.
- Foi definida uma constraint UNIQUE sobre a combinação (id_compra, id_produto), assegurando que não existam registros duplicados para o mesmo produto dentro de uma mesma compra.

---

### 2.9 Formas_pagamento

Apresenta quais são as formas de pagamento aceitáveis. 

**Atributos:**
- id_forma_pagamento (PK)
- nome

**Observações:**
- id_forma_pagamento é a chave primária da entidade.
- O atributo nome é representado por ENUM (ex: Dinheiro, Credito, Debito, Pix, Boleto).

---

### 2.10 Vendas

Apresenta as vendas realizadas pela unidade comercial. 

**Atributos:**
- id_venda (PK)
- id_cliente (FK)
- id_forma_pagamento (FK)
- id_funcionario (FK)
- data_venda 
- data_pagamento 
- status_pedido 
- valor_total

**Observações:**
- id_venda é a chave primária da entidade.
- Os atributos id_cliente, id_forma_pagamento e id_funcionario são chaves estrangeiras responsáveis por manter a integridade referencial da tabela Vendas em relação às tabelas Clientes, Formas_pagamento e Funcionarios.
- Foi definida uma constraint CHECK que condiciona o preenchimento de data_pagamento ao status_pedido ser "Pago", garantindo coerência entre o estado da transação e a data de pagamento.
- O atributo status_pedido é representado por ENUM (ex: Pendente, Pago, Cancelado).
- O atributo valor_total deve ser positivo e é controlado por CHECK CONSTRAINT.

---

### 2.11 Itens_venda

Tabela associativa responsável por registrar os produtos vinculados a cada venda, incluindo informações como quantidade e preço unitário praticado no momento da transação.

**Atributos:**
- id_itens_venda (PK)
- id_venda (FK)
- id_produto (FK)
- quantidade 
- preco_unitario_venda

**Observações:**
- id_itens_venda é a chave primária da entidade.
- Os atributos id_venda e id_produto são chaves estrangeiras responsáveis por manter a integridade referencial da tabela Itens_venda em relação às tabelas Vendas e Produtos.
- Os atributos quantidade e preco_unitario_venda devem ser positivos e são controlados por CHECK CONSTRAINT.

---

## 3. Relacionamentos

**Observações:**
A cardinalidade fica do lado oposto da entidade a que ela se refere.

### Cliente 1:1 <--> 0:N Vendas
Um cliente pode estar associado a várias vendas.
Uma venda deve estar associado a pelo menos um cliente.

### Venda 0:N <--> 1:N Produtos
Uma venda pode conter vários produtos.
O produto pode estar associado ou não a uma venda.

### Vendas 0:N <--> 1:1 Funcionários
Uma venda deve estar associada a um funcionário.
O funcionário pode estar associado ou não a uma venda.

### Forma_Pagamento 1:1 <--> 0:N Venda
Uma forma de pagamento pode estar associada a várias vendas.
Uma venda deve conter apenas uma forma de pagamento.

### Funcionario 1:1 <--> 0:N Compras
O funcionário pode estar associado a várias compras.
Uma compra deve estar associada a um funcionário.

### Fornecedor 1:1 <--> 0:N Compras
O fornecedor pode estar associado a várias compras.
Uma compra deve estar associada a um fornecedor.

### Compras 0:N <--> 1:N Produtos
Uma compra deve conter pelo menos um produto e pode estar associada a vários podutos.
O produto pode estar associado ou não a uma compra.

### Fornecedor 1:N <--> 1:N Produto
Um fornecedor deve estar associado a pelo menos um produto.
Um produto deve estar associado a pelo menos um fornecedor. 

---

## 4. Índices

