import re

from flask import Blueprint, request, jsonify

from app.extensions import db
from app.models.mercado_parceiro import MercadoParceiro
from app.models.pedido_revenda import PedidoRevenda

mercado_parceiro_bp = Blueprint("mercado_parceiro", __name__)


def _normalizar_documento(valor):
    """Mantém só os dígitos, para que '12.345.678/0001-90' e '12345678000190' sejam o mesmo CNPJ."""
    return re.sub(r"\D", "", str(valor or ""))


def _documento_valido(documento):
    return len(documento) in (11, 14)  # CPF ou CNPJ


@mercado_parceiro_bp.get("")
def listar():
    """RF06 - HU07: lista os mercados parceiros"""
    mercados = MercadoParceiro.query.order_by(MercadoParceiro.nome).all()
    return jsonify([m.to_dict() for m in mercados]), 200


@mercado_parceiro_bp.post("")
def cadastrar():
    """RF06 - HU07: cadastrar novo mercado parceiro"""
    dados = request.get_json(silent=True) or {}
    nome = dados.get("nome")
    cnpj_cpf = _normalizar_documento(dados.get("cnpj_cpf"))

    if not nome or not cnpj_cpf:
        return jsonify({"erro": "Informe nome e cnpj_cpf."}), 400

    if not _documento_valido(cnpj_cpf):
        return jsonify({"erro": "cnpj_cpf deve ter 11 (CPF) ou 14 (CNPJ) dígitos."}), 400

    if MercadoParceiro.query.filter_by(cnpj_cpf=cnpj_cpf).first():
        return jsonify({"erro": "Já existe um mercado com esse CNPJ/CPF."}), 409

    mercado = MercadoParceiro(
        nome=nome,
        cnpj_cpf=cnpj_cpf,
        telefone=dados.get("telefone"),
        endereco=dados.get("endereco"),
    )
    db.session.add(mercado)
    db.session.commit()
    return jsonify(mercado.to_dict()), 201


@mercado_parceiro_bp.put("/<int:id_mercado>")
def atualizar(id_mercado):
    """RF06 - HU07: atualiza dados cadastrais de um mercado parceiro"""
    mercado = MercadoParceiro.query.get_or_404(id_mercado)
    dados = request.get_json(silent=True) or {}

    if "nome" in dados and not dados["nome"]:
        return jsonify({"erro": "nome não pode ficar vazio."}), 400

    if "cnpj_cpf" in dados:
        cnpj_cpf = _normalizar_documento(dados["cnpj_cpf"])
        if not _documento_valido(cnpj_cpf):
            return jsonify({"erro": "cnpj_cpf deve ter 11 (CPF) ou 14 (CNPJ) dígitos."}), 400
        if cnpj_cpf != mercado.cnpj_cpf and MercadoParceiro.query.filter_by(cnpj_cpf=cnpj_cpf).first():
            return jsonify({"erro": "Já existe um mercado com esse CNPJ/CPF."}), 409
        mercado.cnpj_cpf = cnpj_cpf

    mercado.nome = dados.get("nome", mercado.nome)
    mercado.telefone = dados.get("telefone", mercado.telefone)
    mercado.endereco = dados.get("endereco", mercado.endereco)

    db.session.commit()
    return jsonify(mercado.to_dict()), 200


@mercado_parceiro_bp.delete("/<int:id_mercado>")
def remover(id_mercado):
    """RF06 - HU07: remove um mercado parceiro (somente se não tiver pedidos vinculados)"""
    mercado = MercadoParceiro.query.get_or_404(id_mercado)

    if PedidoRevenda.query.filter_by(id_mercado=id_mercado).first():
        return jsonify({"erro": "Mercado possui pedidos vinculados e não pode ser removido."}), 409

    db.session.delete(mercado)
    db.session.commit()
    return jsonify({"mensagem": "Mercado removido."}), 200
