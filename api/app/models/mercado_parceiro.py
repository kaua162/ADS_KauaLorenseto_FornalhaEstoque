from app.extensions import db


class MercadoParceiro(db.Model):
    __tablename__ = "mercado_parceiro"

    id_mercado = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(150), nullable=False)
    cnpj_cpf = db.Column(db.String(20), unique=True, nullable=False)
    telefone = db.Column(db.String(20))
    endereco = db.Column(db.String(255))
