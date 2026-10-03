from flask import Blueprint, request, jsonify

from app.extensions import db
from app.models.pizza_sabor import PizzaSabor
from app.models.estoque_pizza import EstoquePizzaCongelada
from app.models.item_pedido import ItemPedido

pizza_sabor_bp = Blueprint("pizza_sabor", __name__)


@pizza_sabor_bp.get("")
def listar():
    """RF05 - lista todos os sabores de pizza congelada"""
    sabores = PizzaSabor.query.order_by(PizzaSabor.nome).all()
    return jsonify([s.to_dict() for s in sabores]), 200


@pizza_sabor_bp.post("")
def cadastrar():
    """RF05 - cadastrar novo sabor de pizza congelada"""
    dados = request.get_json(silent=True) or {}
    nome = dados.get("nome")
    preco = dados.get("preco_unitario")

    if not nome or preco is None:
        return jsonify({"erro": "Informe nome e preco_unitario."}), 400

    if float(preco) < 0:
        return jsonify({"erro": "preco_unitario não pode ser negativo."}), 400

    if PizzaSabor.query.filter_by(nome=nome).first():
        return jsonify({"erro": "Já existe um sabor com esse nome."}), 409

    sabor = PizzaSabor(nome=nome, descricao=dados.get("descricao"), preco_unitario=preco)
    db.session.add(sabor)
    db.session.commit()
    return jsonify(sabor.to_dict()), 201


@pizza_sabor_bp.put("/<int:id_sabor>")
def atualizar(id_sabor):
    """RF05 - atualiza dados cadastrais de um sabor"""
    sabor = PizzaSabor.query.get_or_404(id_sabor)
    dados = request.get_json(silent=True) or {}

    nome = dados.get("nome", sabor.nome)
    if nome != sabor.nome and PizzaSabor.query.filter_by(nome=nome).first():
        return jsonify({"erro": "Já existe um sabor com esse nome."}), 409

    preco = dados.get("preco_unitario", sabor.preco_unitario)
    if float(preco) < 0:
        return jsonify({"erro": "preco_unitario não pode ser negativo."}), 400

    sabor.nome = nome
    sabor.descricao = dados.get("descricao", sabor.descricao)
    sabor.preco_unitario = preco

    db.session.commit()
    return jsonify(sabor.to_dict()), 200


@pizza_sabor_bp.delete("/<int:id_sabor>")
def remover(id_sabor):
    """RF05 - remove um sabor do cadastro (somente se não tiver estoque nem pedidos vinculados)"""
    sabor = PizzaSabor.query.get_or_404(id_sabor)

    if EstoquePizzaCongelada.query.filter_by(id_sabor=id_sabor).first() or \
            ItemPedido.query.filter_by(id_sabor=id_sabor).first():
        return jsonify({"erro": "Sabor possui estoque ou pedidos vinculados e não pode ser removido."}), 409

    db.session.delete(sabor)
    db.session.commit()
    return jsonify({"mensagem": "Sabor removido."}), 200
