import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/modelos.dart';
import '../utils/formatos.dart';

/// Erro já com a mensagem pronta para mostrar ao usuário.
class ApiException implements Exception {
  const ApiException(this.mensagem, {this.statusCode});

  final String mensagem;
  final int? statusCode;

  @override
  String toString() => mensagem;
}

/// Cliente da API Flask do FornalhaEstoque.
///
/// A URL base vem de `--dart-define=API_URL=...` (padrão: http://127.0.0.1:5000).
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? const String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:5000');

  /// Instância usada pelo app. Os testes podem trocar por uma com MockClient.
  static ApiClient instance = ApiClient();

  final http.Client _client;
  final String baseUrl;

  static const _timeout = Duration(seconds: 15);
  static const _headers = {'Content-Type': 'application/json'};
  static const mensagemSemConexao = 'Não foi possível conectar ao servidor';

  Uri _uri(String caminho, [Map<String, String?>? query]) {
    final params = <String, String>{
      for (final e in (query ?? const <String, String?>{}).entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    final uri = Uri.parse('$baseUrl$caminho');
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  Future<dynamic> _enviar(Future<http.Response> Function() requisicao) async {
    final http.Response resposta;
    try {
      resposta = await requisicao().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(mensagemSemConexao);
    } on http.ClientException {
      throw const ApiException(mensagemSemConexao);
    } catch (_) {
      // SocketException (Android) e outras falhas de rede
      throw const ApiException(mensagemSemConexao);
    }

    dynamic corpo;
    try {
      corpo = resposta.body.isEmpty ? null : jsonDecode(utf8.decode(resposta.bodyBytes));
    } on FormatException {
      corpo = null; // ex.: página HTML de erro 404/500 do Flask
    }

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return corpo;

    if (corpo is Map && corpo['erro'] is String) {
      throw ApiException(corpo['erro'] as String, statusCode: resposta.statusCode);
    }
    throw ApiException(switch (resposta.statusCode) {
      404 => 'Registro não encontrado.',
      >= 500 => 'Erro no servidor (${resposta.statusCode}). Tente novamente.',
      _ => 'Erro inesperado (${resposta.statusCode}).',
    }, statusCode: resposta.statusCode);
  }

  Future<dynamic> _get(String caminho, [Map<String, String?>? query]) =>
      _enviar(() => _client.get(_uri(caminho, query)));

  Future<dynamic> _post(String caminho, Map<String, dynamic> corpo) =>
      _enviar(() => _client.post(_uri(caminho), headers: _headers, body: jsonEncode(corpo)));

  Future<dynamic> _put(String caminho, Map<String, dynamic> corpo) =>
      _enviar(() => _client.put(_uri(caminho), headers: _headers, body: jsonEncode(corpo)));

  Future<dynamic> _delete(String caminho) => _enviar(() => _client.delete(_uri(caminho)));

  List<T> _lista<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) =>
      (json as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();

  // ---------- RF01 - Login ----------

  Future<Usuario> login(String login, String senha) async {
    final json = await _post('/auth/login', {'login': login, 'senha': senha});
    return Usuario.fromJson(json['usuario'] as Map<String, dynamic>);
  }

  // ---------- RF02/RF03 - Matéria-prima ----------

  Future<List<MateriaPrima>> listarMateriasPrimas() async =>
      _lista(await _get('/materia-prima'), MateriaPrima.fromJson);

  Future<MateriaPrima> cadastrarMateriaPrima({
    required String nome,
    required String unidadeMedida,
    required double qtdAtual,
    required double qtdMinima,
  }) async => MateriaPrima.fromJson(
    await _post('/materia-prima', {
      'nome': nome,
      'unidade_medida': unidadeMedida,
      'qtd_atual': qtdAtual,
      'qtd_minima': qtdMinima,
    }),
  );

  /// A API só atualiza nome, unidade e mínimo; a quantidade muda por movimentação.
  Future<MateriaPrima> atualizarMateriaPrima(
    int id, {
    required String nome,
    required String unidadeMedida,
    required double qtdMinima,
  }) async => MateriaPrima.fromJson(
    await _put('/materia-prima/$id', {'nome': nome, 'unidade_medida': unidadeMedida, 'qtd_minima': qtdMinima}),
  );

  Future<void> removerMateriaPrima(int id) => _delete('/materia-prima/$id');

  /// [tipo]: 'entrada' ou 'saida'
  Future<MateriaPrima> registrarMovimentacao(int id, {required String tipo, required double quantidade}) async =>
      MateriaPrima.fromJson(await _post('/materia-prima/$id/movimentacao', {'tipo': tipo, 'quantidade': quantidade}));

  // ---------- RF05 - Sabores e estoque de pizza ----------

  Future<List<PizzaSabor>> listarSabores() async => _lista(await _get('/pizza-sabor'), PizzaSabor.fromJson);

  Future<PizzaSabor> cadastrarSabor({required String nome, String? descricao, required double precoUnitario}) async =>
      PizzaSabor.fromJson(
        await _post('/pizza-sabor', {'nome': nome, 'descricao': descricao, 'preco_unitario': precoUnitario}),
      );

  Future<PizzaSabor> atualizarSabor(
    int id, {
    required String nome,
    String? descricao,
    required double precoUnitario,
  }) async => PizzaSabor.fromJson(
    await _put('/pizza-sabor/$id', {'nome': nome, 'descricao': descricao, 'preco_unitario': precoUnitario}),
  );

  Future<void> removerSabor(int id) => _delete('/pizza-sabor/$id');

  Future<List<SaldoSabor>> resumoEstoquePizza() async =>
      _lista(await _get('/estoque-pizza/resumo'), SaldoSabor.fromJson);

  Future<List<LotePizza>> listarLotesPizza({int? idSabor}) async =>
      _lista(await _get('/estoque-pizza', {'id_sabor': idSabor?.toString()}), LotePizza.fromJson);

  Future<LotePizza> registrarProducao({required int idSabor, required int quantidade, DateTime? dataProducao}) async =>
      LotePizza.fromJson(
        await _post('/estoque-pizza/producao', {
          'id_sabor': idSabor,
          'quantidade': quantidade,
          if (dataProducao != null) 'data_producao': formatarDataIso(dataProducao),
        }),
      );

  // ---------- RF06 - Mercados e pedidos ----------

  Future<List<MercadoParceiro>> listarMercados() async =>
      _lista(await _get('/mercado-parceiro'), MercadoParceiro.fromJson);

  Future<MercadoParceiro> detalharMercado(int id) async =>
      MercadoParceiro.fromJson(await _get('/mercado-parceiro/$id'));

  /// [dados] com as chaves da API: nome, cnpj_cpf, telefone, email, nome_contato,
  /// logradouro, numero, bairro, cidade, uf, cep, observacoes. Valores null apagam o campo.
  Future<MercadoParceiro> cadastrarMercado(Map<String, String?> dados) async =>
      MercadoParceiro.fromJson(await _post('/mercado-parceiro', dados));

  /// Envia só as chaves presentes em [dados] (a API não altera as ausentes).
  Future<MercadoParceiro> atualizarMercado(int id, Map<String, String?> dados) async =>
      MercadoParceiro.fromJson(await _put('/mercado-parceiro/$id', dados));

  Future<void> removerMercado(int id) => _delete('/mercado-parceiro/$id');

  /// [status] no formato da API: Pendente, Em Produção, Entregue, Cancelado.
  Future<List<Pedido>> listarPedidos({String? status, int? idMercado}) async =>
      _lista(await _get('/pedido-revenda', {'status': status, 'id_mercado': idMercado?.toString()}), Pedido.fromJson);

  Future<Pedido> detalharPedido(int id) async => Pedido.fromJson(await _get('/pedido-revenda/$id'));

  Future<Pedido> criarPedido({
    required int idMercado,
    required int idUsuario,
    required Map<int, int> quantidadesPorSabor,
  }) async => Pedido.fromJson(
    await _post('/pedido-revenda', {
      'id_mercado': idMercado,
      'id_usuario': idUsuario,
      'itens': [
        for (final e in quantidadesPorSabor.entries)
          if (e.value > 0) {'id_sabor': e.key, 'quantidade': e.value},
      ],
    }),
  );

  Future<Pedido> atualizarStatusPedido(int id, String status) async =>
      Pedido.fromJson(await _put('/pedido-revenda/$id/status', {'status': status}));

  // ---------- RF07 - Relatórios ----------

  Future<RelatorioVendas> relatorioVendas({
    DateTime? dataInicio,
    DateTime? dataFim,
    int? idMercado,
    String? status,
  }) async => RelatorioVendas.fromJson(
    await _get('/relatorios/vendas', {
      'data_inicio': dataInicio == null ? null : formatarDataIso(dataInicio),
      'data_fim': dataFim == null ? null : formatarDataIso(dataFim),
      'id_mercado': idMercado?.toString(),
      'status': status,
    }),
  );

  Future<RelatorioEstoqueMateriaPrima> relatorioEstoqueMateriaPrima({bool apenasCriticos = false}) async =>
      RelatorioEstoqueMateriaPrima.fromJson(
        await _get('/relatorios/estoque-materia-prima', {'apenas_criticos': apenasCriticos ? 'true' : null}),
      );

  Future<RelatorioEstoquePizza> relatorioEstoquePizza() async =>
      RelatorioEstoquePizza.fromJson(await _get('/relatorios/estoque-pizza'));

  Future<List<Movimentacao>> relatorioMovimentacoes({
    int? idMateriaPrima,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
  }) async => _lista(
    await _get('/relatorios/movimentacoes-materia-prima', {
      'id_materia_prima': idMateriaPrima?.toString(),
      'data_inicio': dataInicio == null ? null : formatarDataIso(dataInicio),
      'data_fim': dataFim == null ? null : formatarDataIso(dataFim),
      'tipo': tipo,
    }),
    Movimentacao.fromJson,
  );
}
