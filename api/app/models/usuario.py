from werkzeug.security import generate_password_hash, check_password_hash
from app.extensions import db


class Usuario(db.Model):
    __tablename__ = "usuario"

    id_usuario = db.Column(db.Integer, primary_key=True)
    nome = db.Column(db.String(120), nullable=False)
    login = db.Column(db.String(80), unique=True, nullable=False)
    senha_hash = db.Column(db.String(255), nullable=False)

    def set_senha(self, senha_plana):
        self.senha_hash = generate_password_hash(senha_plana)

    def checar_senha(self, senha_plana):
        return check_password_hash(self.senha_hash, senha_plana)

    def to_dict(self):
        return {"id_usuario": self.id_usuario, "nome": self.nome, "login": self.login}
