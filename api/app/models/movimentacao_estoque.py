from app.extensions import db
from app.utils import agora_brasilia


class MovimentacaoEstoque(db.Model):
    __tablename__ = "movimentacao_estoque"

    id_movimentacao = db.Column(db.Integer, primary_key=True)
    id_materia_prima = db.Column(db.Integer, db.ForeignKey("materia_prima.id_materia_prima"), nullable=False)
    tipo = db.Column(db.String(10), nullable=False)  # 'entrada' ou 'saida'
    quantidade = db.Column(db.Numeric(10, 2), nullable=False)
    data_hora = db.Column(db.DateTime, default=agora_brasilia)

    materia_prima = db.relationship("MateriaPrima", backref="movimentacoes")

    def to_dict(self):
        return {
            "id_movimentacao": self.id_movimentacao,
            "id_materia_prima": self.id_materia_prima,
            "materia_prima": self.materia_prima.nome if self.materia_prima else None,
            "unidade_medida": self.materia_prima.unidade_medida if self.materia_prima else None,
            "tipo": self.tipo,
            "quantidade": float(self.quantidade),
            "data_hora": self.data_hora.isoformat() if self.data_hora else None,
        }
