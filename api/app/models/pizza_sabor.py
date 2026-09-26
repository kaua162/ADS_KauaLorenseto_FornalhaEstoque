from app.extensions import db


class PizzaSabor(db.Model):
    __tablename__ = "pizza_sabor"

    id_sabor = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(120), unique=True, nullable=False)
    descricao = db.Column(db.String(255))
    preco_unitario = db.Column(db.Numeric(10, 2), nullable=False)
