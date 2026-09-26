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

## Endpoints implementados (semana 1)

| Método | Rota                  | Descrição                          |
|--------|-----------------------|-------------------------------------|
| POST   | /auth/login            | Autentica usuário (RF01)            |
| GET    | /materia-prima         | Lista matéria-prima (RF02)          |
| POST   | /materia-prima         | Cadastra matéria-prima (RF02)       |
| PUT    | /materia-prima/<id>    | Atualiza matéria-prima (RF02)       |
| DELETE | /materia-prima/<id>    | Remove matéria-prima (RF02)         |

## Estrutura

```
api/
├── app/
│   ├── __init__.py       # app factory
│   ├── extensions.py     # db, etc.
│   ├── models/           # modelos SQLAlchemy (um por entidade do DER)
│   └── routes/           # blueprints por módulo
├── requirements.txt
├── .env.example
└── run.py
```
