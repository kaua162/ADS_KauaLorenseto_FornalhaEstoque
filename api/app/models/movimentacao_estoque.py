from datetime import datetime
from app.extensions import db


class MovimentacaoEstoque(db.Model):
    __tablename__ = "movimentacao_estoque"

    id_movimentacao = db.Column(db.Integer, primary_key=True)
    id_materia_prima = db.Column(db.Integer, db.ForeignKey("materia_prima.id_materia_prima"), nullable=False)
    tipo = db.Column(db.String(10), nullable=False)  # 'entrada' ou 'saida'
    quantidade = db.Column(db.Numeric(10, 2), nullable=False)
    data_hora = db.Column(db.DateTime, default=datetime.utcnow)

    materia_prima = db.relationship("MateriaPrima", backref="movimentacoes")
