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

## Como rodar a API localmente

Veja [`api/README.md`](api/README.md).

## Como rodar o app localmente

Veja [`app/README.md`](app/README.md).

## Cronograma

O cronograma de codificação do projeto está descrito no DVP (seção "Gestão de Projetos").
