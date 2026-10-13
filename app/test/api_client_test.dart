import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fornalha_app/services/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Object corpo, [int status = 200]) =>
    http.Response(jsonEncode(corpo), status, headers: {'content-type': 'application/json; charset=utf-8'});

void main() {
  test('mensagem {"erro": ...} da API vira ApiException', () async {
    final api = ApiClient(
      baseUrl: 'http://api',
      client: MockClient((_) async => json({'erro': 'Usuário ou senha inválidos.'}, 401)),
    );
    await expectLater(
      api.login('x', 'y'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.mensagem, 'mensagem', 'Usuário ou senha inválidos.')
            .having((e) => e.statusCode, 'status', 401),
      ),
    );
  });

  test('404 em HTML (get_or_404 do Flask) vira mensagem amigável', () async {
    final api = ApiClient(
      baseUrl: 'http://api',
      client: MockClient((_) async => http.Response('<!doctype html><title>404 Not Found</title>', 404)),
    );
    await expectLater(
      api.detalharPedido(99),
      throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', 'Registro não encontrado.')),
    );
  });

  test('falha de conexão', () async {
    final api = ApiClient(
      baseUrl: 'http://api',
      client: MockClient((_) async => throw http.ClientException('Connection refused')),
    );
    await expectLater(
      api.listarMateriasPrimas(),
      throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem', 'Não foi possível conectar ao servidor')),
    );
  });

  test('criarPedido envia id_usuario e só itens com quantidade', () async {
    late Map<String, dynamic> enviado;
    final api = ApiClient(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        expect(req.method, 'POST');
        expect(req.url.path, '/pedido-revenda');
        enviado = jsonDecode(req.body) as Map<String, dynamic>;
        return json({
          'id_pedido': 7,
          'id_mercado': 1,
          'mercado': 'Mercado A',
          'id_usuario': 3,
          'data_pedido': '2026-10-13T10:00:00',
          'status': 'Pendente',
          'valor_total': 70.0,
          'quantidade_pizzas': 3,
          'itens': [],
        }, 201);
      }),
    );
    final pedido = await api.criarPedido(idMercado: 1, idUsuario: 3, quantidadesPorSabor: {1: 2, 2: 0, 5: 1});
    expect(enviado, {
      'id_mercado': 1,
      'id_usuario': 3,
      'itens': [
        {'id_sabor': 1, 'quantidade': 2},
        {'id_sabor': 5, 'quantidade': 1},
      ],
    });
    expect(pedido.id, 7);
    expect(pedido.quantidadePizzas, 3);
  });

  test('filtros vazios não vão na query string', () async {
    final urls = <Uri>[];
    final api = ApiClient(
      baseUrl: 'http://api',
      client: MockClient((req) async {
        urls.add(req.url);
        return json([]);
      }),
    );
    await api.listarPedidos();
    await api.listarPedidos(status: 'Em Produção', idMercado: 2);
    expect(urls[0].toString(), 'http://api/pedido-revenda');
    expect(urls[1].queryParameters, {'status': 'Em Produção', 'id_mercado': '2'});
  });
}
