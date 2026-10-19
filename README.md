# FornalhaEstoque

Aplicativo mobile para gestão de uma pizzaria, dividido em dois módulos:

1. **Estoque de matéria-prima** — controle dos insumos usados no preparo das pizzas (queijo, molhos, chocolate, etc).
2. **Pedidos de pizza congelada** — gestão do estoque de pizzas congeladas e dos pedidos de revenda para mercados parceiros.

Projeto acadêmico — Curso de Análise e Desenvolvimento de Sistemas (ADS) — Universidade de Passo Fundo (UPF).

## Estrutura do repositório

```
.
├── api/          # Backend - API REST (Python + Flask + PostgreSQL)
├── app/          # Aplicativo mobile (Flutter)
├── docs/         # Documentação do projeto (DVP, diagramas, etc.)
└── README.md
```

## Documentação

O Documento de Visão do Produto (DVP) está disponível em [`docs/DVP.docx`](docs/DVP.docx).

## Arquitetura

Arquitetura cliente-servidor em três camadas:

```
[App Flutter] <--HTTP/JSON--> [API Flask] <--> [PostgreSQL]
```

## Status

Numeração dos requisitos conforme o DVP.

| Requisito | Descrição | API | App |
|---|---|---|---|
| RF01 | Gerenciar login (HU01, HU02) | ✅ | ✅ Login |
| RF02 | Gerenciar insumos e matéria-prima (HU03) | ✅ | ✅ Insumos |
| RF03 | Controle de estoque crítico de insumos (HU04) | ✅ | ✅ Insumos (entrada/saída, filtro de críticos) |
| RF04 | Gerenciar sabores de pizzas congeladas (HU05) | ✅ | ✅ Pizzas |
| RF05 | Gerenciar estoque de pizzas congeladas (HU06) | ✅ | ✅ Pizzas (produção por lote, baixa FIFO) |
| RF06 | Gerenciar cadastros de mercados parceiros (HU07) | ✅ | ✅ Mercados |
| RF07 | Gerenciar pedidos de revenda (HU08) | ✅ | ✅ Pedidos |
| — | Relatórios de estoque e vendas (além do DVP) | ✅ | ✅ Relatórios |

O app Flutter roda na **web** e no **Android**.

> As docstrings das rotas da API usam uma numeração anterior: sabores e estoque de pizzas
> aparecem como "RF05", mercados e pedidos como "RF06 (HU07/HU08)" e relatórios como "RF07".
> A tabela acima segue o DVP.

## Como rodar

Pré-requisitos: Python 3, PostgreSQL (com o banco `fornalha_estoque` criado), Flutter SDK.
Detalhes em [`api/README.md`](api/README.md) e [`app/README.md`](app/README.md).

### 1. API

```bash
cd api
.venv\Scripts\activate          # Linux/macOS: source .venv/bin/activate
python run.py
```

A API sobe em `http://127.0.0.1:5000`. Use `python run.py` em vez de `flask run`: com acento no
nome do usuário do Windows (ex.: `C:\Users\Kauã`) o `flask run` pode falhar.

Na primeira vez, crie o `.venv`, instale as dependências e copie o `.env.example` para `.env`
(passo a passo em [`api/README.md`](api/README.md)).

### 2. App

Com a API rodando, em outro terminal:

```bash
cd app
flutter run -d chrome --web-port 8080 --dart-define=API_URL=http://127.0.0.1:5000
```

### 3. Migração do banco

O `create_all()` da API cria tabelas novas, mas não adiciona colunas em tabelas que já existem.
Quando houver um script novo em [`api/migracoes/`](api/migracoes/), rode-o uma vez no pgAdmin:
selecione o banco `fornalha_estoque` → **Tools > Query Tool** → abra o arquivo `.sql` → **F5**.

Scripts atuais:

- [`2026-10-13_mercado_endereco.sql`](api/migracoes/2026-10-13_mercado_endereco.sql): contato,
  e-mail, endereço completo e observações em `mercado_parceiro` (necessário para a aba Mercados).

## Cronograma

O cronograma de codificação do projeto está descrito no DVP (seção "Gestão de Projetos").
