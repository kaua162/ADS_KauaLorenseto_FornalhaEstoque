import math


def ler_numero(valor):
    """Converte o valor recebido no JSON em float, ou devolve None se não for um número válido.

    Aceita números e textos numéricos ("2.5"). Recusa booleanos (em Python, True/False são
    números), textos não numéricos ("abc") e valores não finitos ("nan", "inf").
    """
    if valor is None or isinstance(valor, bool):
        return None
    try:
        numero = float(valor)
    except (TypeError, ValueError):
        return None
    return numero if math.isfinite(numero) else None
