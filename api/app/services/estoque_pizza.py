from datetime import date

from app.extensions import db
from app.models.estoque_pizza import EstoquePizzaCongelada


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
    lote = EstoquePizzaCongelada(id_sabor=id_sabor, quantidade_disponivel=quantidade, data_producao=date.today())
    db.session.add(lote)
    return lote
