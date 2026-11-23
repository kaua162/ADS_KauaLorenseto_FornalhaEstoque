from tests.base import ApiTestCase

PRECOS_INVALIDOS = (0, "0", -1, -25.5, "abc", "", None, True)


class CadastroTest(ApiTestCase):
    def test_preco_zero_negativo_ou_invalido_retorna_400(self):
        for preco in PRECOS_INVALIDOS:
            with self.subTest(preco=preco):
                r = self.post("/pizza-sabor", {"nome": "Calabresa", "preco_unitario": preco})
                self.assertEqual(r.status_code, 400, r.get_json())
                self.assertIn("preco_unitario", r.get_json()["erro"])
        self.assertEqual(self.client.get("/pizza-sabor").get_json(), [], "nada foi gravado")

    def test_mensagens(self):
        r = self.post("/pizza-sabor", {"nome": "Calabresa", "preco_unitario": 0})
        self.assertEqual(r.get_json()["erro"], "preco_unitario deve ser maior que zero.")
        r = self.post("/pizza-sabor", {"nome": "Calabresa", "preco_unitario": "abc"})
        self.assertEqual(r.get_json()["erro"], "preco_unitario deve ser um número maior que zero.")

    def test_preco_valido(self):
        r = self.post("/pizza-sabor", {"nome": "Calabresa", "preco_unitario": 25.5})
        self.assertEqual(r.status_code, 201, r.get_json())
        self.assertEqual(r.get_json()["preco_unitario"], 25.5)

        r = self.post("/pizza-sabor", {"nome": "Frango", "preco_unitario": "0.01"})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.get_json()["preco_unitario"], 0.01)


class AtualizacaoTest(ApiTestCase):
    def setUp(self):
        super().setUp()
        self.id = self.post("/pizza-sabor", {"nome": "Calabresa", "preco_unitario": 25}).get_json()["id_sabor"]

    def preco_atual(self):
        return self.client.get("/pizza-sabor").get_json()[0]["preco_unitario"]

    def test_preco_zero_negativo_ou_invalido_retorna_400(self):
        for preco in PRECOS_INVALIDOS:
            with self.subTest(preco=preco):
                r = self.put(f"/pizza-sabor/{self.id}", {"preco_unitario": preco})
                self.assertEqual(r.status_code, 400, r.get_json())
                self.assertEqual(self.preco_atual(), 25.0)

    def test_preco_valido_e_put_sem_preco(self):
        r = self.put(f"/pizza-sabor/{self.id}", {"preco_unitario": 27.9})
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.get_json()["preco_unitario"], 27.9)

        r = self.put(f"/pizza-sabor/{self.id}", {"descricao": "Com cebola"})
        self.assertEqual(r.status_code, 200, "sem preco_unitario no corpo, o preço não é validado nem alterado")
        self.assertEqual(r.get_json()["preco_unitario"], 27.9)
