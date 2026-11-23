import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fornalha_app/screens/sabor_form_screen.dart';
import 'package:fornalha_app/services/api_client.dart';
import 'package:google_fonts/google_fonts.dart';

import 'apoio.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('preço vazio, zero ou negativo não é enviado; preço válido é', (tester) async {
    final api = ApiFalsa({
      'POST /pizza-sabor': (_) => {'id_sabor': 1, 'nome': 'Calabresa', 'descricao': null, 'preco_unitario': 25.5},
    });
    ApiClient.instance = api.cliente;
    await abrir(tester, const SaborFormScreen());

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome do sabor'), 'Calabresa');
    final preco = find.widgetWithText(TextFormField, 'Preço unitário');

    for (final (valor, mensagem) in [
      ('', 'Informe o preço'),
      ('0', 'O preço deve ser maior que zero'),
      ('0,00', 'O preço deve ser maior que zero'),
      ('-5', 'O preço deve ser maior que zero'),
    ]) {
      await tester.enterText(preco, valor);
      await tester.tap(find.text('Cadastrar sabor'));
      await tester.pumpAndSettle();
      expect(find.text(mensagem), findsOneWidget, reason: 'preço "$valor"');
    }
    expect(api.requisicoes, isEmpty);

    await tester.enterText(preco, '25,50');
    await tester.tap(find.text('Cadastrar sabor'));
    await tester.pumpAndSettle();
    expect(api.requisicoes.single.body, contains('"preco_unitario":25.5'));
  });
}
