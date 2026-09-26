from app.extensions import db


class MateriaPrima(db.Model):
    __tablename__ = "materia_prima"

    id_materia_prima = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(120), unique=True, nullable=False)
    unidade_medida = db.Column(db.String(20), nullable=False)  # kg, g, l, ml, un
    qtd_atual = db.Column(db.Numeric(10, 2), nullable=False, default=0)
    qtd_minima = db.Column(db.Numeric(10, 2), nullable=False, default=0)

    @property
    def estoque_critico(self):
        return self.qtd_atual <= self.qtd_minima

    def to_dict(self):
        return {
            "id_materia_prima": self.id_materia_prima,
            "nome": self.nome,
            "unidade_medida": self.unidade_medida,
            "qtd_atual": float(self.qtd_atual),
            "qtd_minima": float(self.qtd_minima),
            "estoque_critico": self.estoque_critico,
        }
