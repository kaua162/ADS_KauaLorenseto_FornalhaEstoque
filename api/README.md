# API - FornalhaEstoque

API REST em Flask + PostgreSQL, responsável pelas regras de negócio do aplicativo.

## Setup

```bash
cd api
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env       # ajuste os dados do seu PostgreSQL local
```

Crie o banco no PostgreSQL (ex.: via pgAdmin ou psql):

```sql
CREATE DATABASE fornalha_estoque;
```

## Rodando

```bash
flask --app run.py run --debug
```

A API sobe em `http://127.0.0.1:5000`.

## Endpoints implementados

| Método | Rota                              | Descrição                                                   |
|--------|-----------------------------------|-------------------------------------------------------------|
| POST   | /auth/login                       | Autentica usuário (RF01)                                    |
| GET    | /materia-prima                    | Lista matéria-prima (RF02)                                  |
| POST   | /materia-prima                    | Cadastra matéria-prima (RF02)                               |
| PUT    | /materia-prima/<id>               | Atualiza matéria-prima (RF02)                               |
| DELETE | /materia-prima/<id>               | Remove matéria-prima (RF02)                                 |
| POST   | /materia-prima/<id>/movimentacao  | Entrada/saída de insumo (RF03)                              |
| GET    | /pizza-sabor                      | Lista sabores de pizza (RF05)                               |
| POST   | /pizza-sabor                      | Cadastra sabor (RF05)                                       |
| PUT    | /pizza-sabor/<id>                 | Atualiza sabor (RF05)                                       |
| DELETE | /pizza-sabor/<id>                 | Remove sabor sem estoque/pedidos vinculados (RF05)          |
| GET    | /estoque-pizza                    | Lista lotes com saldo, filtro `?id_sabor=` (RF05)           |
| GET    | /estoque-pizza/resumo             | Saldo total por sabor (RF05)                                |
| POST   | /estoque-pizza/producao           | Registra lote produzido (RF05)                              |
| POST   | /estoque-pizza/baixa              | Baixa de estoque, lotes mais antigos primeiro (RF05)        |
| GET    | /mercado-parceiro                 | Lista mercados parceiros (RF06 - HU07)                      |
| POST   | /mercado-parceiro                 | Cadastra mercado; `cnpj_cpf` obrigatório e único (RF06 - HU07) |
| PUT    | /mercado-parceiro/<id>            | Atualiza mercado (RF06 - HU07)                              |
| DELETE | /mercado-parceiro/<id>            | Remove mercado sem pedidos vinculados (RF06 - HU07)         |
| GET    | /pedido-revenda                   | Lista pedidos, filtros `?status=` e `?id_mercado=` (RF06 - HU08) |
| GET    | /pedido-revenda/<id>              | Detalha pedido com itens (RF06 - HU08)                      |
| POST   | /pedido-revenda                   | Cria pedido e dá baixa no estoque, tudo ou nada (RF06 - HU08) |
| PUT    | /pedido-revenda/<id>/status       | Atualiza status; cancelar devolve ao estoque (RF06 - HU08)  |

### Exemplo: criar pedido

```json
POST /pedido-revenda
{
  "id_mercado": 1,
  "id_usuario": 1,
  "itens": [
    {"id_sabor": 1, "quantidade": 10},
    {"id_sabor": 2, "quantidade": 5}
  ]
}
```

- O `valor_unitario` de cada item é o `preco_unitario` do sabor no momento do pedido; o `valor_total` é a soma dos itens.
- Se faltar estoque de qualquer sabor, retorna 400 e nada é gravado.
- Status: `Pendente` (inicial), `Em Produção`, `Entregue`, `Cancelado`. Pedidos `Entregue` ou `Cancelado` não mudam mais de status.
- Ao cancelar, as quantidades voltam ao estoque como um novo lote com data de hoje.

## Estrutura

```
api/
├── app/
│   ├── __init__.py       # app factory
│   ├── extensions.py     # db, etc.
│   ├── models/           # modelos SQLAlchemy (um por entidade do DER)
│   ├── routes/           # blueprints por módulo
│   └── services/         # regras compartilhadas entre rotas (ex.: baixa FIFO de estoque)
├── requirements.txt
├── .env.example
└── run.py
```
