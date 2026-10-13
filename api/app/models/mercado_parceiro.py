from app.extensions import db


class MercadoParceiro(db.Model):
    __tablename__ = "mercado_parceiro"

    id_mercado = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(150), nullable=False)
    cnpj_cpf = db.Column(db.String(20), unique=True, nullable=False)  # só dígitos (11 ou 14)
    telefone = db.Column(db.String(20))  # só dígitos (DDD + número)
    email = db.Column(db.String(120))
    nome_contato = db.Column(db.String(120))

    # Endereço completo
    logradouro = db.Column(db.String(150))
    numero = db.Column(db.String(20))
    bairro = db.Column(db.String(100))
    cidade = db.Column(db.String(100))
    uf = db.Column(db.String(2))
    cep = db.Column(db.String(8))  # só dígitos

    observacoes = db.Column(db.Text)

    # Campo antigo (texto livre). Mantido para não perder dados já cadastrados;
    # a migração copia o conteúdo para `logradouro`. Novos cadastros usam os campos acima.
    endereco = db.Column(db.String(255))

    CAMPOS_OPCIONAIS = (
        "telefone", "email", "nome_contato", "logradouro", "numero",
        "bairro", "cidade", "uf", "cep", "observacoes", "endereco",
    )

    def to_dict(self):
        return {
            "id_mercado": self.id_mercado,
            "nome": self.nome,
            "cnpj_cpf": self.cnpj_cpf,
            **{campo: getattr(self, campo) for campo in self.CAMPOS_OPCIONAIS},
        }
