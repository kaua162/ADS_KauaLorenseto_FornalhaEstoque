from flask import Blueprint, request, jsonify

from app.extensions import db
from app.models.materia_prima import MateriaPrima
from app.models.movimentacao_estoque import MovimentacaoEstoque
from app.services.validacao import ler_numero

materia_prima_bp = Blueprint("materia_prima", __name__)


def _nao_negativo(dados, campo):
    """Valida um campo de quantidade (>= 0). Devolve (valor, None) ou (None, resposta de erro 400)."""
    valor = ler_numero(dados[campo])
    if valor is None or valor < 0:
        return None, (jsonify({"erro": f"{campo} deve ser um número maior ou igual a zero."}), 400)
    return valor, None


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

    if not nome or not unidade:
        return jsonify({"erro": "Informe nome e unidade_medida."}), 400

    quantidades = {"qtd_atual": 0.0, "qtd_minima": 0.0}
    for campo in quantidades:
        if campo in dados:
            quantidades[campo], erro = _nao_negativo(dados, campo)
            if erro:
                return erro

    if MateriaPrima.query.filter_by(nome=nome).first():
        return jsonify({"erro": "Já existe um insumo com esse nome."}), 409

    item = MateriaPrima(
        nome=nome,
        unidade_medida=unidade,
        qtd_atual=quantidades["qtd_atual"],
        qtd_minima=quantidades["qtd_minima"],
    )
    db.session.add(item)
    db.session.commit()
    return jsonify(item.to_dict()), 201


@materia_prima_bp.put("/<int:id_materia_prima>")
def atualizar(id_materia_prima):
    """RF02 - atualiza dados cadastrais de um insumo"""
    item = MateriaPrima.query.get_or_404(id_materia_prima)
    dados = request.get_json(silent=True) or {}

    if "qtd_minima" in dados:
        qtd_minima, erro = _nao_negativo(dados, "qtd_minima")
        if erro:
            return erro
        item.qtd_minima = qtd_minima

    item.nome = dados.get("nome", item.nome)
    item.unidade_medida = dados.get("unidade_medida", item.unidade_medida)

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

    if tipo not in ("entrada", "saida") or quantidade is None:
        return jsonify({"erro": "Informe tipo ('entrada' ou 'saida') e quantidade."}), 400

    quantidade = ler_numero(quantidade)
    if quantidade is None or quantidade <= 0:
        return jsonify({"erro": "A quantidade deve ser um número maior que zero."}), 400

    if tipo == "saida" and quantidade > float(item.qtd_atual):
        return jsonify({"erro": "Quantidade de saída maior que o estoque disponível."}), 400

    item.qtd_atual = float(item.qtd_atual) + quantidade if tipo == "entrada" else float(item.qtd_atual) - quantidade

    movimentacao = MovimentacaoEstoque(id_materia_prima=item.id_materia_prima, tipo=tipo, quantidade=quantidade)
    db.session.add(movimentacao)
    db.session.commit()

    return jsonify(item.to_dict()), 200
