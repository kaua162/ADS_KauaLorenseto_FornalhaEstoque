from flask import Blueprint, request, jsonify

from app.extensions import db
from app.models.usuario import Usuario

auth_bp = Blueprint("auth", __name__)


@auth_bp.post("/login")
def login():
    """RF01 - Gerenciar Login (HU01, HU02)"""
    dados = request.get_json(silent=True) or {}
    login = dados.get("login")
    senha = dados.get("senha")

    if not login or not senha:
        return jsonify({"erro": "Informe login e senha."}), 400

    usuario = Usuario.query.filter_by(login=login).first()

    # Mensagem genérica de propósito: não revelar se o erro foi no usuário ou na senha (HU02)
    if not usuario or not usuario.checar_senha(senha):
        return jsonify({"erro": "Usuário ou senha inválidos."}), 401

    return jsonify({"mensagem": "Login realizado com sucesso.", "usuario": usuario.to_dict()}), 200


@auth_bp.post("/registrar")
def registrar():
    """Endpoint auxiliar para criar o primeiro usuário (uso interno/dev)."""
    dados = request.get_json(silent=True) or {}
    nome, login, senha = dados.get("nome"), dados.get("login"), dados.get("senha")

    if not all([nome, login, senha]):
        return jsonify({"erro": "Informe nome, login e senha."}), 400

    if Usuario.query.filter_by(login=login).first():
        return jsonify({"erro": "Login já cadastrado."}), 409

    usuario = Usuario(nome=nome, login=login)
    usuario.set_senha(senha)
    db.session.add(usuario)
    db.session.commit()

    return jsonify(usuario.to_dict()), 201
