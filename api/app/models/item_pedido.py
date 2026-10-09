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

    def to_dict(self):
        return {
            "id_item_pedido": self.id_item_pedido,
            "id_sabor": self.id_sabor,
            "sabor": self.sabor.nome if self.sabor else None,
            "quantidade": self.quantidade,
            "valor_unitario": float(self.valor_unitario),
            "subtotal": float(self.valor_unitario * self.quantidade),
        }
