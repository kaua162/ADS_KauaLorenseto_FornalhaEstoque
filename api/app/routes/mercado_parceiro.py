import re

from flask import Blueprint, request, jsonify

from app.extensions import db
from app.models.mercado_parceiro import MercadoParceiro
from app.models.pedido_revenda import PedidoRevenda

mercado_parceiro_bp = Blueprint("mercado_parceiro", __name__)

UFS = {
    "AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO", "MA", "MT", "MS", "MG", "PA",
    "PB", "PR", "PE", "PI", "RJ", "RN", "RS", "RO", "RR", "SC", "SP", "SE", "TO",
}

# Tamanho máximo de cada campo de texto (igual às colunas do model)
TAMANHOS = {
    "nome": 150, "email": 120, "nome_contato": 120, "logradouro": 150, "numero": 20,
    "bairro": 100, "cidade": 100, "endereco": 255,
}

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class DadosInvalidos(Exception):
    pass


@mercado_parceiro_bp.errorhandler(DadosInvalidos)
def _dados_invalidos(e):
    return jsonify({"erro": str(e)}), 400


def _digitos(valor):
    """Mantém só os dígitos, para que '12.345.678/0001-90' e '12345678000190' sejam o mesmo CNPJ."""
    return re.sub(r"\D", "", str(valor or ""))


def _documento_valido(documento):
    return len(documento) in (11, 14)  # CPF ou CNPJ


def _texto(valor):
    """Texto opcional: espaços nas pontas removidos; vazio vira None."""
    if valor is None:
        return None
    texto = str(valor).strip()
    return texto or None


def _normalizar_opcionais(dados):
    """Valida e normaliza os campos opcionais presentes em `dados`.

    Só os campos enviados entram no resultado (no PUT, campo ausente = não altera;
    campo enviado vazio ou null = apaga o valor).
    """
    campos = {}
    for campo in MercadoParceiro.CAMPOS_OPCIONAIS:
        if campo not in dados:
            continue
        valor = _texto(dados[campo])

        if valor is not None:
            if campo == "telefone":
                valor = _digitos(valor)
                if len(valor) not in (10, 11):
                    raise DadosInvalidos("telefone deve ter DDD + número (10 ou 11 dígitos).")
            elif campo == "email":
                valor = valor.lower()
                if not EMAIL_RE.match(valor):
                    raise DadosInvalidos("email inválido.")
            elif campo == "uf":
                valor = valor.upper()
                if valor not in UFS:
                    raise DadosInvalidos("uf deve ser a sigla de um estado com 2 letras (ex.: RS).")
            elif campo == "cep":
                valor = _digitos(valor)
                if len(valor) != 8:
                    raise DadosInvalidos("cep deve ter 8 dígitos.")

            limite = TAMANHOS.get(campo)
            if limite and len(valor) > limite:
                raise DadosInvalidos(f"{campo} deve ter no máximo {limite} caracteres.")

        campos[campo] = valor
    return campos


def _validar_nome(nome):
    nome = _texto(nome)
    if not nome:
        raise DadosInvalidos("nome não pode ficar vazio.")
    if len(nome) > TAMANHOS["nome"]:
        raise DadosInvalidos(f"nome deve ter no máximo {TAMANHOS['nome']} caracteres.")
    return nome


def _validar_documento(valor, id_atual=None):
    cnpj_cpf = _digitos(valor)
    if not _documento_valido(cnpj_cpf):
        raise DadosInvalidos("cnpj_cpf deve ter 11 (CPF) ou 14 (CNPJ) dígitos.")
    existente = MercadoParceiro.query.filter_by(cnpj_cpf=cnpj_cpf).first()
    if existente and existente.id_mercado != id_atual:
        return cnpj_cpf, True
    return cnpj_cpf, False


@mercado_parceiro_bp.get("")
def listar():
    """RF06 - HU07: lista os mercados parceiros com todos os campos"""
    mercados = MercadoParceiro.query.order_by(MercadoParceiro.nome).all()
    return jsonify([m.to_dict() for m in mercados]), 200


@mercado_parceiro_bp.get("/<int:id_mercado>")
def detalhar(id_mercado):
    """RF06 - HU07: detalha um mercado parceiro"""
    mercado = MercadoParceiro.query.get_or_404(id_mercado)
    return jsonify(mercado.to_dict()), 200


@mercado_parceiro_bp.post("")
def cadastrar():
    """RF06 - HU07: cadastrar novo mercado parceiro (nome e cnpj_cpf obrigatórios)"""
    dados = request.get_json(silent=True) or {}

    if not _texto(dados.get("nome")) or not _digitos(dados.get("cnpj_cpf")):
        return jsonify({"erro": "Informe nome e cnpj_cpf."}), 400

    nome = _validar_nome(dados["nome"])
    cnpj_cpf, duplicado = _validar_documento(dados["cnpj_cpf"])
    opcionais = _normalizar_opcionais(dados)

    if duplicado:
        return jsonify({"erro": "Já existe um mercado com esse CNPJ/CPF."}), 409

    mercado = MercadoParceiro(nome=nome, cnpj_cpf=cnpj_cpf, **opcionais)
    db.session.add(mercado)
    db.session.commit()
    return jsonify(mercado.to_dict()), 201


@mercado_parceiro_bp.put("/<int:id_mercado>")
def atualizar(id_mercado):
    """RF06 - HU07: atualiza dados cadastrais de um mercado parceiro (só os campos enviados)"""
    mercado = MercadoParceiro.query.get_or_404(id_mercado)
    dados = request.get_json(silent=True) or {}

    nome = _validar_nome(dados["nome"]) if "nome" in dados else mercado.nome
    cnpj_cpf = mercado.cnpj_cpf
    if "cnpj_cpf" in dados:
        cnpj_cpf, duplicado = _validar_documento(dados["cnpj_cpf"], id_atual=id_mercado)
        if duplicado:
            return jsonify({"erro": "Já existe um mercado com esse CNPJ/CPF."}), 409
    opcionais = _normalizar_opcionais(dados)

    mercado.nome = nome
    mercado.cnpj_cpf = cnpj_cpf
    for campo, valor in opcionais.items():
        setattr(mercado, campo, valor)

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
