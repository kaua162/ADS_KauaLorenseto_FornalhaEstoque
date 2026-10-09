from datetime import date

from flask import Blueprint, request, jsonify
from app.extensions import db
from app.models.pizza_sabor import PizzaSabor
from app.models.estoque_pizza import EstoquePizzaCongelada
from app.services.estoque_pizza import dar_baixa_fifo, saldo_por_sabor, EstoqueInsuficiente
from app.utils import hoje_brasilia

estoque_pizza_bp = Blueprint("estoque_pizza", __name__)


@estoque_pizza_bp.get("")
def listar():
    """RF05 - lista os lotes de pizza congelada com saldo (filtro opcional ?id_sabor=)"""
    consulta = EstoquePizzaCongelada.query.filter(EstoquePizzaCongelada.quantidade_disponivel > 0)
    id_sabor = request.args.get("id_sabor", type=int)
    if id_sabor:
        consulta = consulta.filter_by(id_sabor=id_sabor)

    lotes = consulta.order_by(EstoquePizzaCongelada.data_producao, EstoquePizzaCongelada.id_estoque_pizza).all()
    return jsonify([l.to_dict() for l in lotes]), 200


@estoque_pizza_bp.get("/resumo")
def resumo():
    """RF05 - saldo total disponível por sabor"""
    return jsonify(saldo_por_sabor()), 200


@estoque_pizza_bp.post("/producao")
def registrar_producao():
    """RF05 - registra a produção de um lote de pizzas congeladas"""
    dados = request.get_json(silent=True) or {}
    id_sabor = dados.get("id_sabor")
    quantidade = dados.get("quantidade")

    if not id_sabor or not quantidade or int(quantidade) <= 0:
        return jsonify({"erro": "Informe id_sabor e quantidade (maior que zero)."}), 400

    PizzaSabor.query.get_or_404(id_sabor)

    data_producao = hoje_brasilia()
    if dados.get("data_producao"):
        try:
            data_producao = date.fromisoformat(dados["data_producao"])
        except ValueError:
            return jsonify({"erro": "data_producao deve estar no formato AAAA-MM-DD."}), 400

    lote = EstoquePizzaCongelada(id_sabor=id_sabor, quantidade_disponivel=int(quantidade), data_producao=data_producao)
    db.session.add(lote)
    db.session.commit()
    return jsonify(lote.to_dict()), 201


@estoque_pizza_bp.post("/baixa")
def registrar_baixa():
    """RF05 - dá baixa no estoque de um sabor, consumindo primeiro os lotes mais antigos (FIFO)"""
    dados = request.get_json(silent=True) or {}
    id_sabor = dados.get("id_sabor")
    quantidade = dados.get("quantidade")

    if not id_sabor or not quantidade or int(quantidade) <= 0:
        return jsonify({"erro": "Informe id_sabor e quantidade (maior que zero)."}), 400

    PizzaSabor.query.get_or_404(id_sabor)
    quantidade = int(quantidade)

    try:
        saldo = dar_baixa_fifo(id_sabor, quantidade)
    except EstoqueInsuficiente:
        db.session.rollback()
        return jsonify({"erro": "Quantidade de baixa maior que o estoque disponível."}), 400

    db.session.commit()
    return jsonify({"id_sabor": id_sabor, "quantidade_baixada": quantidade, "quantidade_disponivel": saldo}), 200
