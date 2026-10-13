import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fornalha_app/services/api_client.dart';
import 'package:fornalha_app/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Backend falso: responde pelo "MÉTODO /caminho" e registra as requisições.
class ApiFalsa {
  ApiFalsa(this.rotas);

  final Map<String, Object Function(http.Request req)> rotas;
  final requisicoes = <http.Request>[];

  ApiClient get cliente => ApiClient(
    baseUrl: 'http://api',
    client: MockClient((req) async {
      requisicoes.add(req);
      final chave = '${req.method} ${req.url.path}';
      final resposta = rotas[chave];
      if (resposta == null) return http.Response('{"erro": "rota não mockada: $chave"}', 500);
      final r = resposta(req);
      if (r is http.Response) return r;
      return http.Response(jsonEncode(r), 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }),
  );
}

http.Response erro(String mensagem, int status) =>
    http.Response(jsonEncode({'erro': mensagem}), status, headers: {'content-type': 'application/json; charset=utf-8'});

Future<void> abrir(WidgetTester tester, Widget tela) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: criarTema(), home: tela));
  await tester.pumpAndSettle();
}
