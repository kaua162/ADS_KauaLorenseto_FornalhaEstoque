from sqlalchemy import func, and_

from app.extensions import db
from app.models.estoque_pizza import EstoquePizzaCongelada
from app.models.pizza_sabor import PizzaSabor
from app.utils import hoje_brasilia


def saldo_por_sabor():
    """Saldo disponível de cada sabor (inclusive os zerados) e a data do lote mais antigo com saldo."""
    linhas = (
        db.session.query(
            PizzaSabor.id_sabor,
            PizzaSabor.nome,
            func.coalesce(func.sum(EstoquePizzaCongelada.quantidade_disponivel), 0),
            func.min(EstoquePizzaCongelada.data_producao),
        )
        .outerjoin(EstoquePizzaCongelada, and_(
            EstoquePizzaCongelada.id_sabor == PizzaSabor.id_sabor,
            EstoquePizzaCongelada.quantidade_disponivel > 0,
        ))
        .group_by(PizzaSabor.id_sabor, PizzaSabor.nome)
        .order_by(PizzaSabor.nome)
        .all()
    )
    return [
        {
            "id_sabor": id_sabor,
            "sabor": nome,
            "quantidade_disponivel": int(total),
            "data_lote_mais_antigo": lote_antigo.isoformat() if lote_antigo else None,
        }
        for id_sabor, nome, total, lote_antigo in linhas
    ]


class EstoqueInsuficiente(Exception):
    def __init__(self, id_sabor, solicitado, disponivel):
        self.id_sabor = id_sabor
        self.solicitado = solicitado
        self.disponivel = disponivel
        super().__init__(f"Estoque insuficiente para o sabor {id_sabor}: solicitado {solicitado}, disponível {disponivel}.")


def dar_baixa_fifo(id_sabor, quantidade):
    """Consome `quantidade` pizzas do sabor, começando pelos lotes mais antigos (FIFO).

    Não faz commit: quem chama decide entre commit e rollback, o que permite agrupar
    várias baixas numa única transação. Lança EstoqueInsuficiente sem alterar nada
    se o saldo do sabor não for suficiente. Retorna o saldo restante do sabor.
    """
    lotes = (
        EstoquePizzaCongelada.query
        .filter(EstoquePizzaCongelada.id_sabor == id_sabor, EstoquePizzaCongelada.quantidade_disponivel > 0)
        .order_by(EstoquePizzaCongelada.data_producao, EstoquePizzaCongelada.id_estoque_pizza)
        .with_for_update()
        .all()
    )

    disponivel = sum(l.quantidade_disponivel for l in lotes)
    if quantidade > disponivel:
        raise EstoqueInsuficiente(id_sabor, quantidade, disponivel)

    restante = quantidade
    for lote in lotes:
        if restante == 0:
            break
        consumido = min(lote.quantidade_disponivel, restante)
        lote.quantidade_disponivel -= consumido
        restante -= consumido

    return disponivel - quantidade


def devolver_ao_estoque(id_sabor, quantidade):
    """Devolve pizzas ao estoque como um novo lote com data de hoje. Não faz commit."""
    lote = EstoquePizzaCongelada(id_sabor=id_sabor, quantidade_disponivel=quantidade, data_producao=hoje_brasilia())
    db.session.add(lote)
    return lote
