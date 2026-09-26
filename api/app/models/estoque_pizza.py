from datetime import date
from app.extensions import db


class EstoquePizzaCongelada(db.Model):
    __tablename__ = "estoque_pizza_congelada"

    id_estoque_pizza = db.Column(db.Integer, primary_key=True)
    id_sabor = db.Column(db.Integer, db.ForeignKey("pizza_sabor.id_sabor"), nullable=False)
    quantidade_disponivel = db.Column(db.Integer, nullable=False, default=0)
    data_producao = db.Column(db.Date, default=date.today)

    sabor = db.relationship("PizzaSabor", backref="estoques")
