/// Modelos espelhando exatamente o JSON devolvido pelos `to_dict()` da API (api/app/models).
library;

double _dbl(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
DateTime? _data(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

/// usuario.to_dict()
class Usuario {
  const Usuario({required this.id, required this.nome, required this.login});

  factory Usuario.fromJson(Map<String, dynamic> j) =>
      Usuario(id: _int(j['id_usuario']), nome: j['nome'] as String, login: j['login'] as String);

  final int id;
  final String nome;
  final String login;
}

/// materia_prima.to_dict()
class MateriaPrima {
  const MateriaPrima({
    required this.id,
    required this.nome,
    required this.unidadeMedida,
    required this.qtdAtual,
    required this.qtdMinima,
    required this.estoqueCritico,
  });

  factory MateriaPrima.fromJson(Map<String, dynamic> j) => MateriaPrima(
    id: _int(j['id_materia_prima']),
    nome: j['nome'] as String,
    unidadeMedida: j['unidade_medida'] as String,
    qtdAtual: _dbl(j['qtd_atual']),
    qtdMinima: _dbl(j['qtd_minima']),
    estoqueCritico: j['estoque_critico'] as bool? ?? false,
  );

  final int id;
  final String nome;
  final String unidadeMedida;
  final double qtdAtual;
  final double qtdMinima;

  /// Calculado pela API: qtd_atual <= qtd_minima.
  final bool estoqueCritico;
}

/// pizza_sabor.to_dict()
class PizzaSabor {
  const PizzaSabor({required this.id, required this.nome, this.descricao, required this.precoUnitario});

  factory PizzaSabor.fromJson(Map<String, dynamic> j) => PizzaSabor(
    id: _int(j['id_sabor']),
    nome: j['nome'] as String,
    descricao: j['descricao'] as String?,
    precoUnitario: _dbl(j['preco_unitario']),
  );

  final int id;
  final String nome;
  final String? descricao;
  final double precoUnitario;
}

/// Item de GET /estoque-pizza/resumo e de /relatorios/estoque-pizza
class SaldoSabor {
  const SaldoSabor({
    required this.idSabor,
    required this.sabor,
    required this.quantidadeDisponivel,
    this.dataLoteMaisAntigo,
  });

  factory SaldoSabor.fromJson(Map<String, dynamic> j) => SaldoSabor(
    idSabor: _int(j['id_sabor']),
    sabor: j['sabor'] as String,
    quantidadeDisponivel: _int(j['quantidade_disponivel']),
    dataLoteMaisAntigo: _data(j['data_lote_mais_antigo']),
  );

  final int idSabor;
  final String sabor;
  final int quantidadeDisponivel;
  final DateTime? dataLoteMaisAntigo;
}

/// estoque_pizza.to_dict() (um lote de produção)
class LotePizza {
  const LotePizza({
    required this.id,
    required this.idSabor,
    this.sabor,
    required this.quantidadeDisponivel,
    this.dataProducao,
  });

  factory LotePizza.fromJson(Map<String, dynamic> j) => LotePizza(
    id: _int(j['id_estoque_pizza']),
    idSabor: _int(j['id_sabor']),
    sabor: j['sabor'] as String?,
    quantidadeDisponivel: _int(j['quantidade_disponivel']),
    dataProducao: _data(j['data_producao']),
  );

  final int id;
  final int idSabor;
  final String? sabor;
  final int quantidadeDisponivel;
  final DateTime? dataProducao;
}

/// mercado_parceiro.to_dict()
class MercadoParceiro {
  const MercadoParceiro({
    required this.id,
    required this.nome,
    required this.cnpjCpf,
    this.telefone,
    this.email,
    this.nomeContato,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.uf,
    this.cep,
    this.observacoes,
    this.enderecoAntigo,
  });

  factory MercadoParceiro.fromJson(Map<String, dynamic> j) => MercadoParceiro(
    id: _int(j['id_mercado']),
    nome: j['nome'] as String,
    cnpjCpf: j['cnpj_cpf'] as String,
    telefone: j['telefone'] as String?,
    email: j['email'] as String?,
    nomeContato: j['nome_contato'] as String?,
    logradouro: j['logradouro'] as String?,
    numero: j['numero'] as String?,
    bairro: j['bairro'] as String?,
    cidade: j['cidade'] as String?,
    uf: j['uf'] as String?,
    cep: j['cep'] as String?,
    observacoes: j['observacoes'] as String?,
    enderecoAntigo: j['endereco'] as String?,
  );

  final int id;
  final String nome;

  /// Só dígitos (a API remove pontuação).
  final String cnpjCpf;

  /// Só dígitos (DDD + número).
  final String? telefone;
  final String? email;
  final String? nomeContato;
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cidade;

  /// Sigla do estado, ex.: RS.
  final String? uf;

  /// Só dígitos.
  final String? cep;
  final String? observacoes;

  /// Campo `endereco` antigo (texto livre), anterior aos campos de endereço completo.
  final String? enderecoAntigo;

  /// "Passo Fundo/RS", "Passo Fundo", "RS" ou null.
  String? get cidadeUf {
    final partes = [cidade, uf].where((p) => p != null && p.isNotEmpty).toList();
    return partes.isEmpty ? null : partes.join('/');
  }

  /// "Rua X, 120" (ou o endereço antigo, se os campos novos estiverem vazios).
  String? get logradouroNumero {
    if (logradouro == null || logradouro!.isEmpty) return enderecoAntigo;
    return numero == null || numero!.isEmpty ? logradouro : '$logradouro, $numero';
  }
}

/// Status de pedido aceitos pela API.
enum StatusPedido {
  pendente('Pendente', 'Pendente'),
  emProducao('Em Produção', 'Em produção'),
  entregue('Entregue', 'Entregue'),
  cancelado('Cancelado', 'Cancelado');

  const StatusPedido(this.valorApi, this.rotulo);

  /// Valor exato enviado/recebido pela API.
  final String valorApi;

  /// Texto mostrado na interface.
  final String rotulo;

  bool get finalizado => this == entregue || this == cancelado;

  static StatusPedido? daApi(String? valor) {
    for (final s in values) {
      if (s.valorApi == valor) return s;
    }
    return null;
  }
}

/// item_pedido.to_dict()
class ItemPedido {
  const ItemPedido({
    required this.id,
    required this.idSabor,
    this.sabor,
    required this.quantidade,
    required this.valorUnitario,
    required this.subtotal,
  });

  factory ItemPedido.fromJson(Map<String, dynamic> j) => ItemPedido(
    id: _int(j['id_item_pedido']),
    idSabor: _int(j['id_sabor']),
    sabor: j['sabor'] as String?,
    quantidade: _int(j['quantidade']),
    valorUnitario: _dbl(j['valor_unitario']),
    subtotal: _dbl(j['subtotal']),
  );

  final int id;
  final int idSabor;
  final String? sabor;
  final int quantidade;
  final double valorUnitario;
  final double subtotal;
}

/// pedido_revenda.to_dict() — `itens` só vem em `GET /pedido-revenda/<id>`, POST e PUT de status.
class Pedido {
  const Pedido({
    required this.id,
    required this.idMercado,
    this.mercado,
    required this.idUsuario,
    this.dataPedido,
    required this.statusApi,
    required this.valorTotal,
    required this.quantidadePizzas,
    this.itens,
  });

  factory Pedido.fromJson(Map<String, dynamic> j) => Pedido(
    id: _int(j['id_pedido']),
    idMercado: _int(j['id_mercado']),
    mercado: j['mercado'] as String?,
    idUsuario: _int(j['id_usuario']),
    dataPedido: _data(j['data_pedido']),
    statusApi: j['status'] as String? ?? '',
    valorTotal: _dbl(j['valor_total']),
    quantidadePizzas: _int(j['quantidade_pizzas']),
    itens: (j['itens'] as List?)?.map((e) => ItemPedido.fromJson(e as Map<String, dynamic>)).toList(),
  );

  final int id;
  final int idMercado;
  final String? mercado;
  final int idUsuario;
  final DateTime? dataPedido;
  final String statusApi;
  final double valorTotal;
  final int quantidadePizzas;
  final List<ItemPedido>? itens;

  StatusPedido? get status => StatusPedido.daApi(statusApi);
}

/// Linha de "por_status" em /relatorios/vendas
class TotalStatus {
  const TotalStatus({required this.pedidos, required this.valor});

  factory TotalStatus.fromJson(Map<String, dynamic> j) =>
      TotalStatus(pedidos: _int(j['pedidos']), valor: _dbl(j['valor']));

  final int pedidos;
  final double valor;
}

/// Linha de "por_sabor" em /relatorios/vendas
class VendaSabor {
  const VendaSabor({required this.idSabor, required this.sabor, required this.quantidade, required this.valor});

  factory VendaSabor.fromJson(Map<String, dynamic> j) => VendaSabor(
    idSabor: _int(j['id_sabor']),
    sabor: j['sabor'] as String,
    quantidade: _int(j['quantidade']),
    valor: _dbl(j['valor']),
  );

  final int idSabor;
  final String sabor;
  final int quantidade;
  final double valor;
}

/// Linha de "por_mercado" em /relatorios/vendas
class VendaMercado {
  const VendaMercado({required this.idMercado, required this.mercado, required this.pedidos, required this.valor});

  factory VendaMercado.fromJson(Map<String, dynamic> j) => VendaMercado(
    idMercado: _int(j['id_mercado']),
    mercado: j['mercado'] as String,
    pedidos: _int(j['pedidos']),
    valor: _dbl(j['valor']),
  );

  final int idMercado;
  final String mercado;
  final int pedidos;
  final double valor;
}

/// GET /relatorios/vendas — pedidos cancelados não entram nos totais.
class RelatorioVendas {
  const RelatorioVendas({
    required this.quantidadePedidos,
    required this.quantidadePizzas,
    required this.valorTotal,
    required this.porStatus,
    required this.porSabor,
    required this.porMercado,
  });

  factory RelatorioVendas.fromJson(Map<String, dynamic> j) => RelatorioVendas(
    quantidadePedidos: _int(j['quantidade_pedidos']),
    quantidadePizzas: _int(j['quantidade_pizzas']),
    valorTotal: _dbl(j['valor_total']),
    porStatus: {
      for (final e in (j['por_status'] as Map<String, dynamic>).entries)
        e.key: TotalStatus.fromJson(e.value as Map<String, dynamic>),
    },
    porSabor: (j['por_sabor'] as List).map((e) => VendaSabor.fromJson(e as Map<String, dynamic>)).toList(),
    porMercado: (j['por_mercado'] as List).map((e) => VendaMercado.fromJson(e as Map<String, dynamic>)).toList(),
  );

  final int quantidadePedidos;
  final int quantidadePizzas;
  final double valorTotal;

  /// Chave = status no formato da API.
  final Map<String, TotalStatus> porStatus;
  final List<VendaSabor> porSabor;
  final List<VendaMercado> porMercado;
}

/// GET /relatorios/estoque-materia-prima
class RelatorioEstoqueMateriaPrima {
  const RelatorioEstoqueMateriaPrima({required this.totalInsumos, required this.totalCriticos, required this.insumos});

  factory RelatorioEstoqueMateriaPrima.fromJson(Map<String, dynamic> j) {
    final resumo = j['resumo'] as Map<String, dynamic>;
    return RelatorioEstoqueMateriaPrima(
      totalInsumos: _int(resumo['total_insumos']),
      totalCriticos: _int(resumo['total_criticos']),
      insumos: (j['insumos'] as List).map((e) => MateriaPrima.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  final int totalInsumos;
  final int totalCriticos;
  final List<MateriaPrima> insumos;
}

/// GET /relatorios/estoque-pizza
class RelatorioEstoquePizza {
  const RelatorioEstoquePizza({required this.totalPizzas, required this.sabores});

  factory RelatorioEstoquePizza.fromJson(Map<String, dynamic> j) => RelatorioEstoquePizza(
    totalPizzas: _int(j['total_pizzas']),
    sabores: (j['sabores'] as List).map((e) => SaldoSabor.fromJson(e as Map<String, dynamic>)).toList(),
  );

  final int totalPizzas;
  final List<SaldoSabor> sabores;
}

/// movimentacao_estoque.to_dict()
class Movimentacao {
  const Movimentacao({
    required this.id,
    required this.idMateriaPrima,
    this.materiaPrima,
    this.unidadeMedida,
    required this.tipo,
    required this.quantidade,
    this.dataHora,
  });

  factory Movimentacao.fromJson(Map<String, dynamic> j) => Movimentacao(
    id: _int(j['id_movimentacao']),
    idMateriaPrima: _int(j['id_materia_prima']),
    materiaPrima: j['materia_prima'] as String?,
    unidadeMedida: j['unidade_medida'] as String?,
    tipo: j['tipo'] as String,
    quantidade: _dbl(j['quantidade']),
    dataHora: _data(j['data_hora']),
  );

  final int id;
  final int idMateriaPrima;
  final String? materiaPrima;
  final String? unidadeMedida;

  /// 'entrada' ou 'saida'
  final String tipo;
  final double quantidade;
  final DateTime? dataHora;
}
