from datetime import datetime
from app.extensions import db

STATUS_PEDIDO = ("Pendente", "Em Produção", "Entregue", "Cancelado")
STATUS_FINAIS = ("Entregue", "Cancelado")


class PedidoRevenda(db.Model):
    __tablename__ = "pedido_revenda"

    id_pedido = db.Column(db.Integer, primary_key=True)
    id_mercado = db.Column(db.Integer, db.ForeignKey("mercado_parceiro.id_mercado"), nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey("usuario.id_usuario"), nullable=False)
    data_pedido = db.Column(db.DateTime, default=datetime.utcnow)
    status = db.Column(db.String(20), default="Pendente")  # Pendente, Em Produção, Entregue, Cancelado
    valor_total = db.Column(db.Numeric(10, 2), default=0)

    mercado = db.relationship("MercadoParceiro", backref="pedidos")
    usuario = db.relationship("Usuario", backref="pedidos")

    def to_dict(self, incluir_itens=False):
        dados = {
            "id_pedido": self.id_pedido,
            "id_mercado": self.id_mercado,
            "mercado": self.mercado.nome if self.mercado else None,
            "id_usuario": self.id_usuario,
            "data_pedido": self.data_pedido.isoformat() if self.data_pedido else None,
            "status": self.status,
            "valor_total": float(self.valor_total or 0),
        }
        if incluir_itens:
            dados["itens"] = [i.to_dict() for i in self.itens]
        return dados
