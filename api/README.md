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

## Migrações do banco

O `db.create_all()` cria tabelas novas, mas **não adiciona colunas** em tabelas que já existem.
Quando um model ganha campos, há um script em [`migracoes/`](migracoes/) para rodar uma vez no banco:

| Arquivo | O que faz |
|---|---|
| `2026-10-13_mercado_endereco.sql` | Contato, e-mail, endereço completo e observações em `mercado_parceiro` |

No pgAdmin: selecione o banco `fornalha_estoque` → **Tools > Query Tool** → abra o arquivo
(ícone de pasta) → **F5**. Os scripts usam `IF NOT EXISTS`, então podem ser rodados de novo sem problema.

## Testes

```bash
cd api
python -m unittest discover -s tests -t .
```

Os testes usam SQLite em memória (não tocam no PostgreSQL).

## Endpoints implementados

| Método | Rota                              | Descrição                                                   |
|--------|-----------------------------------|-------------------------------------------------------------|
| POST   | /auth/login                       | Autentica usuário (RF01)                                    |
| GET    | /materia-prima                    | Lista matéria-prima (RF02)                                  |
| POST   | /materia-prima                    | Cadastra matéria-prima (RF02)                               |
| PUT    | /materia-prima/<id>               | Atualiza matéria-prima (RF02)                               |
| DELETE | /materia-prima/<id>               | Remove matéria-prima sem movimentações (RF02)               |
| POST   | /materia-prima/<id>/movimentacao  | Entrada/saída de insumo (RF03)                              |
| GET    | /pizza-sabor                      | Lista sabores de pizza (RF05)                               |
| POST   | /pizza-sabor                      | Cadastra sabor (RF05)                                       |
| PUT    | /pizza-sabor/<id>                 | Atualiza sabor (RF05)                                       |
| DELETE | /pizza-sabor/<id>                 | Remove sabor sem estoque/pedidos vinculados (RF05)          |
| GET    | /estoque-pizza                    | Lista lotes com saldo, filtro `?id_sabor=` (RF05)           |
| GET    | /estoque-pizza/resumo             | Saldo total por sabor (RF05)                                |
| POST   | /estoque-pizza/producao           | Registra lote produzido (RF05)                              |
| POST   | /estoque-pizza/baixa              | Baixa de estoque, lotes mais antigos primeiro (RF05)        |
| GET    | /mercado-parceiro                 | Lista mercados parceiros com todos os campos (RF06 - HU07)  |
| GET    | /mercado-parceiro/<id>            | Detalha um mercado (RF06 - HU07)                            |
| POST   | /mercado-parceiro                 | Cadastra mercado; `nome` e `cnpj_cpf` obrigatórios (RF06 - HU07) |
| PUT    | /mercado-parceiro/<id>            | Atualiza só os campos enviados (RF06 - HU07)                |
| DELETE | /mercado-parceiro/<id>            | Remove mercado sem pedidos vinculados (RF06 - HU07)         |
| GET    | /pedido-revenda                   | Lista pedidos, filtros `?status=` e `?id_mercado=` (RF06 - HU08) |
| GET    | /pedido-revenda/<id>              | Detalha pedido com itens (RF06 - HU08)                      |
| POST   | /pedido-revenda                   | Cria pedido e dá baixa no estoque, tudo ou nada (RF06 - HU08) |
| PUT    | /pedido-revenda/<id>/status       | Atualiza status; cancelar devolve ao estoque (RF06 - HU08)  |
| GET    | /relatorios/estoque-materia-prima | Estoque de insumos com resumo; filtro `?apenas_criticos=true` (RF07) |
| GET    | /relatorios/estoque-pizza         | Pizzas por sabor e lote mais antigo com saldo (RF07)        |
| GET    | /relatorios/vendas                | Totais de vendas, por status, sabor e mercado (RF07)        |
| GET    | /relatorios/movimentacoes-materia-prima | Histórico de entradas/saídas de insumos (RF07)        |

### Mercado parceiro: campos

```json
POST /mercado-parceiro
{
  "nome": "Mercado Central",
  "cnpj_cpf": "12.345.678/0001-90",
  "telefone": "(54) 3311-0000",
  "email": "compras@mercadocentral.com.br",
  "nome_contato": "Ana Souza",
  "logradouro": "Rua Independência",
  "numero": "1200",
  "bairro": "Centro",
  "cidade": "Passo Fundo",
  "uf": "RS",
  "cep": "99010-040",
  "observacoes": "Entregas só pela manhã."
}
```

| Campo | Regra |
|---|---|
| `nome` | Obrigatório, até 150 caracteres |
| `cnpj_cpf` | Obrigatório e único; guardado só com dígitos (11 = CPF, 14 = CNPJ) |
| `telefone` | Opcional; guardado só com dígitos, DDD + número (10 ou 11) |
| `email` | Opcional; formato `nome@dominio.ext`, guardado em minúsculas |
| `uf` | Opcional; sigla de um dos 27 estados, guardada em maiúsculas |
| `cep` | Opcional; guardado só com dígitos (8) |
| `nome_contato`, `logradouro`, `numero`, `bairro`, `cidade`, `observacoes` | Opcionais, texto |
| `endereco` | Campo antigo (texto livre), mantido para não perder dados; a migração copia para `logradouro` |

Campos opcionais enviados vazios (`""`) ou `null` são gravados como `null`. No `PUT`, campos
ausentes do corpo não são alterados. Validação inválida retorna 400 com `{"erro": "..."}`;
CNPJ/CPF de outro mercado retorna 409.

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
- A listagem `GET /pedido-revenda` traz `quantidade_pizzas` (soma dos itens) em cada pedido; os itens completos vêm em `GET /pedido-revenda/<id>`.
- Status: `Pendente` (inicial), `Em Produção`, `Entregue`, `Cancelado`. Pedidos `Entregue` ou `Cancelado` não mudam mais de status.
- Ao cancelar, as quantidades voltam ao estoque como um novo lote com data de hoje.

### Relatórios (RF07)

Todos são somente leitura (GET). Datas no formato `AAAA-MM-DD`; `data_fim` é inclusiva
(considera o dia inteiro). Filtros inválidos retornam 400.

**`GET /relatorios/estoque-materia-prima?apenas_criticos=true`**

```json
{
  "resumo": {"total_insumos": 3, "total_criticos": 2},
  "insumos": [
    {"id_materia_prima": 3, "nome": "Molho", "unidade_medida": "l",
     "qtd_atual": 2.0, "qtd_minima": 2.0, "estoque_critico": true}
  ]
}
```

O `resumo` sempre considera todos os insumos, mesmo com o filtro.

**`GET /relatorios/estoque-pizza`**

```json
{
  "total_pizzas": 119,
  "sabores": [
    {"id_sabor": 1, "sabor": "Calabresa", "quantidade_disponivel": 86, "data_lote_mais_antigo": "2026-08-01"},
    {"id_sabor": 3, "sabor": "Portuguesa", "quantidade_disponivel": 0, "data_lote_mais_antigo": null}
  ]
}
```

**`GET /relatorios/vendas`**

Filtros opcionais: `?data_inicio=`, `?data_fim=`, `?id_mercado=`, `?status=`
(ex.: `/relatorios/vendas?data_inicio=2026-09-01&data_fim=2026-09-30&id_mercado=1`).
Os filtros valem para todos os blocos, inclusive `por_status`. Pedidos `Cancelado` não entram em `quantidade_pedidos`,
`quantidade_pizzas`, `valor_total`, `por_sabor` e `por_mercado`; aparecem só em `por_status`.
`por_sabor` e `por_mercado` vêm ordenados do maior para o menor valor.

```json
{
  "quantidade_pedidos": 4,
  "quantidade_pizzas": 21,
  "valor_total": 490.0,
  "por_status": {
    "Pendente":    {"pedidos": 1, "valor": 150.0},
    "Em Produção": {"pedidos": 1, "valor": 60.0},
    "Entregue":    {"pedidos": 2, "valor": 280.0},
    "Cancelado":   {"pedidos": 1, "valor": 110.0}
  },
  "por_sabor": [
    {"id_sabor": 1, "sabor": "Calabresa", "quantidade": 14, "valor": 280.0},
    {"id_sabor": 2, "sabor": "Frango", "quantidade": 7, "valor": 210.0}
  ],
  "por_mercado": [
    {"id_mercado": 1, "mercado": "Mercado A", "pedidos": 2, "valor": 320.0},
    {"id_mercado": 2, "mercado": "Mercado B", "pedidos": 2, "valor": 170.0}
  ]
}
```

**`GET /relatorios/movimentacoes-materia-prima?id_materia_prima=1&tipo=saida&data_inicio=2026-09-01&data_fim=2026-09-30`**

Mais recentes primeiro. `tipo` aceita `entrada` ou `saida`.

```json
[
  {"id_movimentacao": 2, "id_materia_prima": 1, "materia_prima": "Farinha", "unidade_medida": "kg",
   "tipo": "saida", "quantidade": 5.0, "data_hora": "2026-09-15T23:59:00"}
]
```

## Estrutura

```
api/
├── app/
│   ├── __init__.py       # app factory
│   ├── extensions.py     # db, etc.
│   ├── models/           # modelos SQLAlchemy (um por entidade do DER)
│   ├── routes/           # blueprints por módulo
│   └── services/         # regras compartilhadas entre rotas (ex.: baixa FIFO de estoque)
├── migracoes/            # scripts SQL para colunas novas em tabelas existentes
├── tests/                # testes (unittest + SQLite em memória)
├── requirements.txt
├── .env.example
└── run.py
```
