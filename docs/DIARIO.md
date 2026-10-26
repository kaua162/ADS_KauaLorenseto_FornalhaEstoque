# Diário de desenvolvimento — FornalhaEstoque

Registro semanal do progresso do projeto, montado a partir do histórico do Git.

Os títulos dos commits usam uma numeração de requisitos anterior à do DVP. Em cada entrada,
o requisito correspondente do DVP aparece entre parênteses (mesma convenção do [README](../README.md#status)).

---

## Semana de 21/09 a 27/09/2026

**26/09 — Estrutura inicial do projeto**
Criação do repositório com a API Flask (login e cadastro de matéria-prima, RF01 e RF02), os models
do banco conforme o DER e um esqueleto do app Flutter.

## Semana de 28/09 a 04/10/2026

**03/10 — RF05: sabores e estoque de pizza congelada** *(DVP: RF04 e RF05)*
Cadastro de sabores de pizza e controle do estoque por lote de produção, com baixa consumindo
primeiro os lotes mais antigos (FIFO).

## Semana de 05/10 a 11/10/2026

**09/10 — Troca do driver do PostgreSQL para pg8000**
Troca feita por compatibilidade com o Windows: o pg8000 é escrito em Python puro e não precisa de compilação.

**09/10 — RF06: mercados parceiros e pedidos de revenda** *(DVP: RF06 e RF07)*
Cadastro de mercados com CNPJ/CPF único e pedidos de pizza congelada com baixa automática do
estoque, tudo ou nada; cancelar um pedido devolve as pizzas ao estoque.

**09/10 — RF07: relatórios de estoque e vendas** *(funcionalidade extra, fora do DVP)*
Relatórios de estoque de insumos e de pizzas, vendas por período, status, sabor e mercado, e
histórico de movimentações. As datas passaram a ser gravadas no horário de Brasília.

## Semana de 12/10 a 18/10/2026

**13/10 — App Flutter e área de mercados parceiros**
App La Fornalha (web e Android) com login, insumos, pizzas, pedidos, mercados e relatórios, com
testes automatizados. Mercados ganharam contato, e-mail, endereço completo e observações, com
migração SQL para o banco existente e testes da API.

## Semana de 19/10 a 25/10/2026

**19/10 — Documentação**
README da raiz com o status dos requisitos (numeração do DVP) e a seção "Como rodar"; README da
API com a lista completa de endpoints, o driver pg8000 e o formato do `DATABASE_URL`.

## Semana de 26/10 a 01/11/2026

**26/10 — Projeto configurado em outro computador**
Instalação do Git, do Python e do Flutter 3.47.7, clone do repositório e instalação das
dependências da API (`pip install -r requirements.txt`). Foi preciso atualizar o Flutter, porque
o app exige Dart 3.13.5 (`sdk: ^3.13.5` no `pubspec.yaml`), versão que vem com o Flutter 3.47.7.

### Próximos passos

- **Abrir o app no iPhone:** acessar a versão web pelo Safari, com o iPhone na mesma rede Wi-Fi
  do computador. Para isso, a API e o app precisam aceitar conexões da rede (não só do
  `127.0.0.1`), e o app deve apontar para o IP do computador.
- **Hospedar a API e o banco:** colocar a API Flask e o PostgreSQL num servidor, para o app
  funcionar fora da rede local.
- **Atualizar o DVP:** incluir o driver pg8000 na tabela de ferramentas.
