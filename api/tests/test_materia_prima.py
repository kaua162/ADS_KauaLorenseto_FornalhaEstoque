from tests.base import ApiTestCase

QUEIJO = {"nome": "Queijo", "unidade_medida": "kg", "qtd_atual": 10, "qtd_minima": 3}


class MovimentacaoTest(ApiTestCase):
    def setUp(self):
        super().setUp()
        self.id = self.post("/materia-prima", QUEIJO).get_json()["id_materia_prima"]

    def mover(self, tipo, quantidade):
        return self.post(f"/materia-prima/{self.id}/movimentacao", {"tipo": tipo, "quantidade": quantidade})

    def estoque(self):
        return next(i for i in self.client.get("/materia-prima").get_json() if i["id_materia_prima"] == self.id)[
            "qtd_atual"
        ]

    def test_quantidade_invalida_retorna_400_e_nao_altera_o_estoque(self):
        for tipo in ("entrada", "saida"):
            for quantidade in (-5, 0, "abc", "", True, "nan", [1]):
                with self.subTest(tipo=tipo, quantidade=quantidade):
                    r = self.mover(tipo, quantidade)
                    self.assertEqual(r.status_code, 400, r.get_json())
                    self.assertEqual(r.get_json()["erro"], "A quantidade deve ser um número maior que zero.")
                    self.assertEqual(self.estoque(), 10.0)

    def test_sem_quantidade_ou_tipo_invalido(self):
        self.assertEqual(self.post(f"/materia-prima/{self.id}/movimentacao", {"tipo": "entrada"}).status_code, 400)
        self.assertEqual(self.mover("ajuste", 5).status_code, 400)
        self.assertEqual(self.estoque(), 10.0)

    def test_saida_maior_que_o_estoque(self):
        r = self.mover("saida", 10.5)
        self.assertEqual(r.status_code, 400)
        self.assertEqual(r.get_json()["erro"], "Quantidade de saída maior que o estoque disponível.")
        self.assertEqual(self.estoque(), 10.0)

    def test_entrada_e_saida_validas_atualizam_o_estoque(self):
        r = self.mover("entrada", 5)
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.get_json()["qtd_atual"], 15.0)

        r = self.mover("saida", "2.5")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.get_json()["qtd_atual"], 12.5)

        self.assertEqual(self.mover("saida", 12.5).get_json()["qtd_atual"], 0.0, "pode zerar o estoque")


class CadastroTest(ApiTestCase):
    def test_quantidades_negativas_ou_invalidas_retornam_400(self):
        for campo in ("qtd_minima", "qtd_atual"):
            for valor in (-1, -0.5, "abc", None, False):
                with self.subTest(campo=campo, valor=valor):
                    r = self.post("/materia-prima", {**QUEIJO, campo: valor})
                    self.assertEqual(r.status_code, 400, r.get_json())
                    self.assertEqual(r.get_json()["erro"], f"{campo} deve ser um número maior ou igual a zero.")
        self.assertEqual(self.client.get("/materia-prima").get_json(), [], "nada foi gravado")

    def test_zero_e_aceito_e_campos_ausentes_valem_zero(self):
        r = self.post("/materia-prima", {"nome": "Sal", "unidade_medida": "kg", "qtd_atual": 0, "qtd_minima": "0"})
        self.assertEqual(r.status_code, 201, r.get_json())
        r = self.post("/materia-prima", {"nome": "Açúcar", "unidade_medida": "kg"})
        self.assertEqual(r.status_code, 201)
        self.assertEqual((r.get_json()["qtd_atual"], r.get_json()["qtd_minima"]), (0.0, 0.0))


class AtualizacaoTest(ApiTestCase):
    def setUp(self):
        super().setUp()
        self.id = self.post("/materia-prima", QUEIJO).get_json()["id_materia_prima"]

    def test_qtd_minima_negativa_ou_invalida_retorna_400(self):
        for valor in (-1, "abc", None):
            with self.subTest(valor=valor):
                r = self.put(f"/materia-prima/{self.id}", {"qtd_minima": valor, "nome": "Outro nome"})
                self.assertEqual(r.status_code, 400, r.get_json())
        item = self.client.get("/materia-prima").get_json()[0]
        self.assertEqual((item["nome"], item["qtd_minima"]), ("Queijo", 3.0), "nada foi alterado")

    def test_valida_so_os_campos_enviados(self):
        r = self.put(f"/materia-prima/{self.id}", {"nome": "Queijo mussarela"})
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.get_json()["qtd_minima"], 3.0)

        r = self.put(f"/materia-prima/{self.id}", {"qtd_minima": 0})
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.get_json()["qtd_minima"], 0.0)
