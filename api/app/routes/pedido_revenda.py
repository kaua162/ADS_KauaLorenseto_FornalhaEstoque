from collections import defaultdict
from decimal import Decimal

from flask import Blueprint, request, jsonify

from app.extensions import db
from app.models.item_pedido import ItemPedido
from app.models.mercado_parceiro import MercadoParceiro
from app.models.pedido_revenda import PedidoRevenda, STATUS_PEDIDO, STATUS_FINAIS
from app.models.pizza_sabor import PizzaSabor
from app.models.usuario import Usuario
from app.services.estoque_pizza import dar_baixa_fifo, devolver_ao_estoque, EstoqueInsuficiente

pedido_revenda_bp = Blueprint("pedido_revenda", __name__)


@pedido_revenda_bp.get("")
def listar():
    """RF06 - HU08: lista os pedidos (filtros opcionais ?status= e ?id_mercado=)"""
    consulta = PedidoRevenda.query
    status = request.args.get("status")
    if status:
        consulta = consulta.filter_by(status=status)
    id_mercado = request.args.get("id_mercado", type=int)
    if id_mercado:
        consulta = consulta.filter_by(id_mercado=id_mercado)

    pedidos = consulta.order_by(PedidoRevenda.data_pedido.desc(), PedidoRevenda.id_pedido.desc()).all()
    return jsonify([p.to_dict() for p in pedidos]), 200


@pedido_revenda_bp.get("/<int:id_pedido>")
def detalhar(id_pedido):
    """RF06 - HU08: detalha um pedido com seus itens"""
    pedido = PedidoRevenda.query.get_or_404(id_pedido)
    return jsonify(pedido.to_dict(incluir_itens=True)), 200


@pedido_revenda_bp.post("")
def cadastrar():
    """RF06 - HU08: registra pedido de pizzas congeladas e dá baixa no estoque (tudo ou nada)"""
    dados = request.get_json(silent=True) or {}
    id_mercado = dados.get("id_mercado")
    id_usuario = dados.get("id_usuario")
    itens = dados.get("itens")

    if not id_mercado or not id_usuario or not isinstance(itens, list) or not itens:
        return jsonify({"erro": "Informe id_mercado, id_usuario e itens (lista não vazia)."}), 400

    MercadoParceiro.query.get_or_404(id_mercado)
    Usuario.query.get_or_404(id_usuario)

    # Valida todos os itens antes de mexer no estoque; sabores repetidos são somados
    quantidades = defaultdict(int)
    for item in itens:
        try:
            id_sabor = int(item.get("id_sabor"))
            quantidade = int(item.get("quantidade"))
        except (TypeError, ValueError, AttributeError):
            return jsonify({"erro": "Cada item deve ter id_sabor e quantidade numéricos."}), 400
        if quantidade <= 0:
            return jsonify({"erro": "A quantidade de cada item deve ser maior que zero."}), 400
        quantidades[id_sabor] += quantidade

    sabores = {s.id_sabor: s for s in PizzaSabor.query.filter(PizzaSabor.id_sabor.in_(quantidades)).all()}
    faltando = [i for i in quantidades if i not in sabores]
    if faltando:
        return jsonify({"erro": f"Sabor(es) não encontrado(s): {faltando}."}), 404

    try:
        for id_sabor, quantidade in quantidades.items():
            dar_baixa_fifo(id_sabor, quantidade)
    except EstoqueInsuficiente as e:
        db.session.rollback()
        return jsonify({
            "erro": f"Estoque insuficiente para o sabor '{sabores[e.id_sabor].nome}'.",
            "id_sabor": e.id_sabor,
            "solicitado": e.solicitado,
            "disponivel": e.disponivel,
        }), 400

    pedido = PedidoRevenda(id_mercado=id_mercado, id_usuario=id_usuario, status="Pendente")
    total = Decimal("0")
    for id_sabor, quantidade in quantidades.items():
        preco = sabores[id_sabor].preco_unitario  # preço do sabor no momento do pedido
        pedido.itens.append(ItemPedido(id_sabor=id_sabor, quantidade=quantidade, valor_unitario=preco))
        total += Decimal(preco) * quantidade
    pedido.valor_total = total

    db.session.add(pedido)
    db.session.commit()
    return jsonify(pedido.to_dict(incluir_itens=True)), 201


@pedido_revenda_bp.put("/<int:id_pedido>/status")
def atualizar_status(id_pedido):
    """RF06 - HU08: atualiza o status do pedido; ao cancelar, devolve as pizzas ao estoque"""
    pedido = PedidoRevenda.query.get_or_404(id_pedido)
    dados = request.get_json(silent=True) or {}
    novo_status = dados.get("status")

    if novo_status not in STATUS_PEDIDO:
        return jsonify({"erro": f"Status inválido. Use um destes: {', '.join(STATUS_PEDIDO)}."}), 400

    if pedido.status in STATUS_FINAIS:
        return jsonify({"erro": f"Pedido já está '{pedido.status}' e não pode mais mudar de status."}), 409

    if novo_status == pedido.status:
        return jsonify({"erro": f"Pedido já está com o status '{novo_status}'."}), 400

    if novo_status == "Cancelado":
        for item in pedido.itens:
            devolver_ao_estoque(item.id_sabor, item.quantidade)

    pedido.status = novo_status
    db.session.commit()
    return jsonify(pedido.to_dict(incluir_itens=True)), 200
