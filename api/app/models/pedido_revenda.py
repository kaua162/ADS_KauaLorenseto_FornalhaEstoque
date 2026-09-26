from datetime import datetime
from app.extensions import db


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
