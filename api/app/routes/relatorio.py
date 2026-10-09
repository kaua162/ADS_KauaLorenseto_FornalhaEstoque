from datetime import date, datetime, time, timedelta

from flask import Blueprint, request, jsonify
from sqlalchemy import func

from app.extensions import db
from app.models.item_pedido import ItemPedido
from app.models.materia_prima import MateriaPrima
from app.models.mercado_parceiro import MercadoParceiro
from app.models.movimentacao_estoque import MovimentacaoEstoque
from app.models.pedido_revenda import PedidoRevenda, STATUS_PEDIDO
from app.models.pizza_sabor import PizzaSabor
from app.services.estoque_pizza import saldo_por_sabor

relatorio_bp = Blueprint("relatorio", __name__)


class FiltroInvalido(Exception):
    pass


@relatorio_bp.errorhandler(FiltroInvalido)
def _filtro_invalido(e):
    return jsonify({"erro": str(e)}), 400


def _param_int(nome):
    valor = request.args.get(nome)
    if valor is None or valor == "":
        return None
    if not valor.isdigit():
        raise FiltroInvalido(f"{nome} deve ser um número inteiro.")
    return int(valor)


def _param_bool(nome):
    valor = (request.args.get(nome) or "").strip().lower()
    if valor in ("", "false", "0", "nao", "não"):
        return False
    if valor in ("true", "1", "sim"):
        return True
    raise FiltroInvalido(f"{nome} deve ser true ou false.")


def _filtros_periodo(coluna):
    """Converte ?data_inicio= e ?data_fim= (AAAA-MM-DD) em filtros sobre uma coluna DateTime.

    data_fim é inclusiva: considera o dia inteiro (até 23:59:59).
    """
    datas = {}
    for nome in ("data_inicio", "data_fim"):
        valor = request.args.get(nome)
        if valor:
            try:
                datas[nome] = date.fromisoformat(valor)
            except ValueError:
                raise FiltroInvalido(f"{nome} deve estar no formato AAAA-MM-DD.")

    inicio, fim = datas.get("data_inicio"), datas.get("data_fim")
    if inicio and fim and inicio > fim:
        raise FiltroInvalido("data_inicio não pode ser posterior a data_fim.")

    filtros = []
    if inicio:
        filtros.append(coluna >= datetime.combine(inicio, time.min))
    if fim:
        filtros.append(coluna < datetime.combine(fim + timedelta(days=1), time.min))
    return filtros


def _valor(numero):
    return round(float(numero or 0), 2)


@relatorio_bp.get("/estoque-materia-prima")
def estoque_materia_prima():
    """RF07 - relatório de estoque de matéria-prima (filtro opcional ?apenas_criticos=true)"""
    apenas_criticos = _param_bool("apenas_criticos")

    insumos = [i.to_dict() for i in MateriaPrima.query.order_by(MateriaPrima.nome).all()]
    total_criticos = sum(1 for i in insumos if i["estoque_critico"])
    if apenas_criticos:
        insumos = [i for i in insumos if i["estoque_critico"]]

    return jsonify({
        "resumo": {"total_insumos": MateriaPrima.query.count(), "total_criticos": total_criticos},
        "insumos": insumos,
    }), 200


@relatorio_bp.get("/estoque-pizza")
def estoque_pizza():
    """RF07 - relatório de estoque de pizzas congeladas por sabor"""
    sabores = saldo_por_sabor()
    return jsonify({
        "total_pizzas": sum(s["quantidade_disponivel"] for s in sabores),
        "sabores": sabores,
    }), 200


@relatorio_bp.get("/vendas")
def vendas():
    """RF07 - relatório de vendas (filtros opcionais ?data_inicio=, ?data_fim=, ?id_mercado=, ?status=)"""
    filtros = _filtros_periodo(PedidoRevenda.data_pedido)

    id_mercado = _param_int("id_mercado")
    if id_mercado:
        filtros.append(PedidoRevenda.id_mercado == id_mercado)

    status = request.args.get("status")
    if status:
        if status not in STATUS_PEDIDO:
            raise FiltroInvalido(f"Status inválido. Use um destes: {', '.join(STATUS_PEDIDO)}.")
        filtros.append(PedidoRevenda.status == status)

    # Cancelados aparecem só em "por_status"; não contam como venda
    filtros_venda = filtros + [PedidoRevenda.status != "Cancelado"]

    qtd_pedidos, valor_total = (
        db.session.query(func.count(PedidoRevenda.id_pedido), func.sum(PedidoRevenda.valor_total))
        .filter(*filtros_venda)
        .one()
    )

    total_pizzas = (
        db.session.query(func.sum(ItemPedido.quantidade))
        .join(PedidoRevenda, ItemPedido.id_pedido == PedidoRevenda.id_pedido)
        .filter(*filtros_venda)
        .scalar()
    )

    por_status = {s: {"pedidos": 0, "valor": 0.0} for s in STATUS_PEDIDO}
    for st, qtd, valor in (
        db.session.query(PedidoRevenda.status, func.count(PedidoRevenda.id_pedido), func.sum(PedidoRevenda.valor_total))
        .filter(*filtros)
        .group_by(PedidoRevenda.status)
        .all()
    ):
        por_status[st] = {"pedidos": qtd, "valor": _valor(valor)}

    valor_sabor = func.sum(ItemPedido.quantidade * ItemPedido.valor_unitario)
    por_sabor = (
        db.session.query(PizzaSabor.id_sabor, PizzaSabor.nome, func.sum(ItemPedido.quantidade), valor_sabor)
        .join(ItemPedido, ItemPedido.id_sabor == PizzaSabor.id_sabor)
        .join(PedidoRevenda, ItemPedido.id_pedido == PedidoRevenda.id_pedido)
        .filter(*filtros_venda)
        .group_by(PizzaSabor.id_sabor, PizzaSabor.nome)
        .order_by(valor_sabor.desc(), PizzaSabor.nome)
        .all()
    )

    valor_mercado = func.sum(PedidoRevenda.valor_total)
    por_mercado = (
        db.session.query(MercadoParceiro.id_mercado, MercadoParceiro.nome, func.count(PedidoRevenda.id_pedido), valor_mercado)
        .join(PedidoRevenda, PedidoRevenda.id_mercado == MercadoParceiro.id_mercado)
        .filter(*filtros_venda)
        .group_by(MercadoParceiro.id_mercado, MercadoParceiro.nome)
        .order_by(valor_mercado.desc(), MercadoParceiro.nome)
        .all()
    )

    return jsonify({
        "quantidade_pedidos": qtd_pedidos,
        "quantidade_pizzas": int(total_pizzas or 0),
        "valor_total": _valor(valor_total),
        "por_status": por_status,
        "por_sabor": [
            {"id_sabor": i, "sabor": nome, "quantidade": int(qtd), "valor": _valor(valor)}
            for i, nome, qtd, valor in por_sabor
        ],
        "por_mercado": [
            {"id_mercado": i, "mercado": nome, "pedidos": qtd, "valor": _valor(valor)}
            for i, nome, qtd, valor in por_mercado
        ],
    }), 200


@relatorio_bp.get("/movimentacoes-materia-prima")
def movimentacoes_materia_prima():
    """RF07 - histórico de entradas e saídas de matéria-prima
    (filtros opcionais ?id_materia_prima=, ?data_inicio=, ?data_fim=, ?tipo=entrada|saida)"""
    filtros = _filtros_periodo(MovimentacaoEstoque.data_hora)

    id_materia_prima = _param_int("id_materia_prima")
    if id_materia_prima:
        filtros.append(MovimentacaoEstoque.id_materia_prima == id_materia_prima)

    tipo = request.args.get("tipo")
    if tipo:
        if tipo not in ("entrada", "saida"):
            raise FiltroInvalido("tipo deve ser 'entrada' ou 'saida'.")
        filtros.append(MovimentacaoEstoque.tipo == tipo)

    movimentacoes = (
        MovimentacaoEstoque.query
        .filter(*filtros)
        .order_by(MovimentacaoEstoque.data_hora.desc(), MovimentacaoEstoque.id_movimentacao.desc())
        .all()
    )
    return jsonify([m.to_dict() for m in movimentacoes]), 200
