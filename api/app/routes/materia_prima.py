from flask import Blueprint, request, jsonify

from app.extensions import db
from app.models.materia_prima import MateriaPrima
from app.models.movimentacao_estoque import MovimentacaoEstoque

materia_prima_bp = Blueprint("materia_prima", __name__)


@materia_prima_bp.get("")
def listar():
    """RF02 - lista todos os insumos, com destaque para estoque crítico (RF03)"""
    itens = MateriaPrima.query.order_by(MateriaPrima.nome).all()
    return jsonify([i.to_dict() for i in itens]), 200


@materia_prima_bp.post("")
def cadastrar():
    """RF02 - HU03: Cadastrar novo insumo"""
    dados = request.get_json(silent=True) or {}
    nome = dados.get("nome")
    unidade = dados.get("unidade_medida")
    qtd_minima = dados.get("qtd_minima", 0)

    if not nome or not unidade:
        return jsonify({"erro": "Informe nome e unidade_medida."}), 400

    if MateriaPrima.query.filter_by(nome=nome).first():
        return jsonify({"erro": "Já existe um insumo com esse nome."}), 409

    item = MateriaPrima(
        nome=nome,
        unidade_medida=unidade,
        qtd_atual=dados.get("qtd_atual", 0),
        qtd_minima=qtd_minima,
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(item.to_dict()), 201


@materia_prima_bp.put("/<int:id_materia_prima>")
def atualizar(id_materia_prima):
    """RF02 - atualiza dados cadastrais de um insumo"""
    item = MateriaPrima.query.get_or_404(id_materia_prima)
    dados = request.get_json(silent=True) or {}

    item.nome = dados.get("nome", item.nome)
    item.unidade_medida = dados.get("unidade_medida", item.unidade_medida)
    item.qtd_minima = dados.get("qtd_minima", item.qtd_minima)

    db.session.commit()
    return jsonify(item.to_dict()), 200


@materia_prima_bp.delete("/<int:id_materia_prima>")
def remover(id_materia_prima):
    """RF02 - remove um insumo do cadastro (somente se não tiver movimentações registradas)"""
    item = MateriaPrima.query.get_or_404(id_materia_prima)

    if MovimentacaoEstoque.query.filter_by(id_materia_prima=id_materia_prima).first():
        return jsonify({"erro": "Insumo possui movimentações registradas e não pode ser removido."}), 409

    db.session.delete(item)
    db.session.commit()
    return jsonify({"mensagem": "Insumo removido."}), 200


@materia_prima_bp.post("/<int:id_materia_prima>/movimentacao")
def registrar_movimentacao(id_materia_prima):
    """RF03 - HU04: Registrar entrada/saída de insumo e atualizar estoque"""
    item = MateriaPrima.query.get_or_404(id_materia_prima)
    dados = request.get_json(silent=True) or {}
    tipo = dados.get("tipo")
    quantidade = dados.get("quantidade")

    if tipo not in ("entrada", "saida") or not quantidade:
        return jsonify({"erro": "Informe tipo ('entrada' ou 'saida') e quantidade."}), 400

    quantidade = float(quantidade)
    if tipo == "saida" and quantidade > float(item.qtd_atual):
        return jsonify({"erro": "Quantidade de saída maior que o estoque disponível."}), 400

    item.qtd_atual = float(item.qtd_atual) + quantidade if tipo == "entrada" else float(item.qtd_atual) - quantidade

    movimentacao = MovimentacaoEstoque(id_materia_prima=item.id_materia_prima, tipo=tipo, quantidade=quantidade)
    db.session.add(movimentacao)
    db.session.commit()

    return jsonify(item.to_dict()), 200
