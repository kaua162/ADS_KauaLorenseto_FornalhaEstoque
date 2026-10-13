import os
import unittest

# Banco SQLite em memória: os testes nunca tocam no PostgreSQL.
# Precisa ser definido antes de importar o app (o load_dotenv não sobrescreve variáveis já definidas).
os.environ["DATABASE_URL"] = "sqlite://"

from app import create_app  # noqa: E402
from app.extensions import db  # noqa: E402


class ApiTestCase(unittest.TestCase):
    """Cria um app com banco vazio para cada teste."""

    def setUp(self):
        self.app = create_app()
        self.client = self.app.test_client()
        self.ctx = self.app.app_context()
        self.ctx.push()

    def tearDown(self):
        db.session.remove()
        db.drop_all()
        db.engine.dispose()
        self.ctx.pop()

    def post(self, url, json):
        return self.client.post(url, json=json)

    def put(self, url, json):
        return self.client.put(url, json=json)
