from tests.base import ApiTestCase

COMPLETO = {
    "nome": "Mercado Central",
    "cnpj_cpf": "12.345.678/0001-90",
    "telefone": "(54) 99999-1234",
    "email": "Compras@MercadoCentral.com.br",
    "nome_contato": "Ana Souza",
    "logradouro": "Rua Independência",
    "numero": "1200",
    "bairro": "Centro",
    "cidade": "Passo Fundo",
    "uf": "rs",
    "cep": "99010-040",
    "observacoes": "Entregas só pela manhã.",
}


class CadastroTest(ApiTestCase):
    def test_cadastra_com_todos_os_campos_normalizados(self):
        r = self.post("/mercado-parceiro", COMPLETO)
        self.assertEqual(r.status_code, 201, r.get_json())
        j = r.get_json()
        self.assertEqual(j["cnpj_cpf"], "12345678000190")
        self.assertEqual(j["telefone"], "54999991234")
        self.assertEqual(j["email"], "compras@mercadocentral.com.br")
        self.assertEqual(j["uf"], "RS")
        self.assertEqual(j["cep"], "99010040")
        self.assertEqual(j["nome_contato"], "Ana Souza")
        self.assertEqual(j["observacoes"], "Entregas só pela manhã.")

    def test_so_nome_e_documento_sao_obrigatorios(self):
        r = self.post("/mercado-parceiro", {"nome": "Mercado B", "cnpj_cpf": "123.456.789-01"})
        self.assertEqual(r.status_code, 201)
        j = r.get_json()
        for campo in ("telefone", "email", "nome_contato", "logradouro", "numero",
                      "bairro", "cidade", "uf", "cep", "observacoes", "endereco"):
            self.assertIn(campo, j)
            self.assertIsNone(j[campo], campo)

    def test_campos_vazios_viram_null(self):
        r = self.post("/mercado-parceiro", {"nome": "B", "cnpj_cpf": "12345678901", "email": "  ", "cep": ""})
        self.assertEqual(r.status_code, 201)
        self.assertIsNone(r.get_json()["email"])
        self.assertIsNone(r.get_json()["cep"])

    def test_obrigatorios(self):
        self.assertEqual(self.post("/mercado-parceiro", {"nome": "B"}).status_code, 400)
        self.assertEqual(self.post("/mercado-parceiro", {"cnpj_cpf": "12345678901"}).status_code, 400)
        self.assertEqual(self.post("/mercado-parceiro", {"nome": "   ", "cnpj_cpf": "12345678901"}).status_code, 400)

    def test_validacoes_retornam_400_com_mensagem(self):
        casos = {
            "cnpj_cpf": "123",
            "uf": "RSS",
            "cep": "9901004",
            "telefone": "9999-1234",
            "email": "sem-arroba.com",
            "nome": "x" * 151,
            "cidade": "x" * 101,
        }
        for campo, valor in casos.items():
            with self.subTest(campo=campo):
                r = self.post("/mercado-parceiro", {**COMPLETO, "cnpj_cpf": "11111111111", campo: valor})
                self.assertEqual(r.status_code, 400, r.get_json())
                self.assertIn("erro", r.get_json())

    def test_uf_precisa_existir(self):
        r = self.post("/mercado-parceiro", {**COMPLETO, "uf": "XX"})
        self.assertEqual(r.status_code, 400)

    def test_cnpj_duplicado_mesmo_com_pontuacao_diferente(self):
        self.post("/mercado-parceiro", COMPLETO)
        r = self.post("/mercado-parceiro", {"nome": "Outro", "cnpj_cpf": "12345678000190"})
        self.assertEqual(r.status_code, 409)

    def test_campo_antigo_endereco_continua_aceito(self):
        r = self.post("/mercado-parceiro", {"nome": "B", "cnpj_cpf": "12345678901", "endereco": "Rua X, 10"})
        self.assertEqual(r.status_code, 201)
        self.assertEqual(r.get_json()["endereco"], "Rua X, 10")


class ConsultaTest(ApiTestCase):
    def test_lista_e_detalhe_devolvem_todos_os_campos(self):
        criado = self.post("/mercado-parceiro", COMPLETO).get_json()
        lista = self.client.get("/mercado-parceiro").get_json()
        detalhe = self.client.get(f"/mercado-parceiro/{criado['id_mercado']}")
        self.assertEqual(detalhe.status_code, 200)
        self.assertEqual(lista, [criado])
        self.assertEqual(detalhe.get_json(), criado)

    def test_detalhe_inexistente(self):
        self.assertEqual(self.client.get("/mercado-parceiro/999").status_code, 404)


class AtualizacaoTest(ApiTestCase):
    def setUp(self):
        super().setUp()
        self.id = self.post("/mercado-parceiro", COMPLETO).get_json()["id_mercado"]
        self.post("/mercado-parceiro", {"nome": "Outro", "cnpj_cpf": "98765432000110"})

    def test_atualiza_so_os_campos_enviados(self):
        r = self.put(f"/mercado-parceiro/{self.id}", {"cidade": "Carazinho", "cep": "99500-000"})
        self.assertEqual(r.status_code, 200)
        j = r.get_json()
        self.assertEqual(j["cidade"], "Carazinho")
        self.assertEqual(j["cep"], "99500000")
        self.assertEqual(j["bairro"], "Centro")
        self.assertEqual(j["nome"], "Mercado Central")

    def test_enviar_vazio_apaga_o_campo(self):
        r = self.put(f"/mercado-parceiro/{self.id}", {"observacoes": "", "email": None})
        self.assertEqual(r.status_code, 200)
        self.assertIsNone(r.get_json()["observacoes"])
        self.assertIsNone(r.get_json()["email"])

    def test_validacoes_no_put(self):
        for corpo in ({"uf": "R"}, {"cep": "abc"}, {"cnpj_cpf": "1"}, {"nome": ""}, {"email": "a@b"}):
            with self.subTest(corpo=corpo):
                self.assertEqual(self.put(f"/mercado-parceiro/{self.id}", corpo).status_code, 400)
        # nada foi alterado
        self.assertEqual(self.client.get(f"/mercado-parceiro/{self.id}").get_json()["uf"], "RS")

    def test_cnpj_de_outro_mercado_e_409_mas_o_proprio_e_aceito(self):
        self.assertEqual(self.put(f"/mercado-parceiro/{self.id}", {"cnpj_cpf": "98.765.432/0001-10"}).status_code, 409)
        self.assertEqual(self.put(f"/mercado-parceiro/{self.id}", {"cnpj_cpf": "12345678000190"}).status_code, 200)

    def test_put_inexistente(self):
        self.assertEqual(self.put("/mercado-parceiro/999", {"cidade": "X"}).status_code, 404)


class RemocaoTest(ApiTestCase):
    def test_remove_sem_pedidos_e_bloqueia_com_pedidos(self):
        self.post("/auth/registrar", {"nome": "K", "login": "k", "senha": "x"})
        livre = self.post("/mercado-parceiro", {"nome": "Livre", "cnpj_cpf": "11111111111"}).get_json()
        com_pedido = self.post("/mercado-parceiro", COMPLETO).get_json()
        self.post("/pizza-sabor", {"nome": "Calabresa", "preco_unitario": 25})
        self.post("/estoque-pizza/producao", {"id_sabor": 1, "quantidade": 5})
        r = self.post("/pedido-revenda", {
            "id_mercado": com_pedido["id_mercado"], "id_usuario": 1, "itens": [{"id_sabor": 1, "quantidade": 2}],
        })
        self.assertEqual(r.status_code, 201)

        self.assertEqual(self.client.delete(f"/mercado-parceiro/{com_pedido['id_mercado']}").status_code, 409)
        self.assertEqual(self.client.delete(f"/mercado-parceiro/{livre['id_mercado']}").status_code, 200)

        pedidos = self.client.get(f"/pedido-revenda?id_mercado={com_pedido['id_mercado']}").get_json()
        self.assertEqual(len(pedidos), 1)
        self.assertEqual(pedidos[0]["quantidade_pizzas"], 2)
