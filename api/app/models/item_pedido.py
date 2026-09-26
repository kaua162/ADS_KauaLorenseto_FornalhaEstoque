from app.extensions import db


class ItemPedido(db.Model):
    __tablename__ = "item_pedido"

    id_item_pedido = db.Column(db.Integer, primary_key=True)
    id_pedido = db.Column(db.Integer, db.ForeignKey("pedido_revenda.id_pedido"), nullable=False)
    id_sabor = db.Column(db.Integer, db.ForeignKey("pizza_sabor.id_sabor"), nullable=False)
    quantidade = db.Column(db.Integer, nullable=False)
    valor_unitario = db.Column(db.Numeric(10, 2), nullable=False)

    pedido = db.relationship("PedidoRevenda", backref="itens")
    sabor = db.relationship("PizzaSabor")
