import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fornalha_app/models/modelos.dart';
import 'package:fornalha_app/screens/home_screen.dart';
import 'package:fornalha_app/screens/mercado_detalhe_screen.dart';
import 'package:fornalha_app/screens/mercado_form_screen.dart';
import 'package:fornalha_app/services/api_client.dart';
import 'package:fornalha_app/utils/formatos.dart';
import 'package:fornalha_app/utils/mascaras.dart';
import 'package:google_fonts/google_fonts.dart';

import 'apoio.dart';

const central = {
  'id_mercado': 1,
  'nome': 'Mercado Central',
  'cnpj_cpf': '12345678000190',
  'telefone': '54999991234',
  'email': 'compras@central.com.br',
  'nome_contato': 'Ana Souza',
  'logradouro': 'Rua Independência',
  'numero': '1200',
  'bairro': 'Centro',
  'cidade': 'Passo Fundo',
  'uf': 'RS',
  'cep': '99010040',
  'observacoes': 'Entregas só pela manhã.',
  'endereco': null,
};

const joao = {
  'id_mercado': 2,
  'nome': 'Armazém São João',
  'cnpj_cpf': '12345678901',
  'telefone': null,
  'email': null,
  'nome_contato': null,
  'logradouro': null,
  'numero': null,
  'bairro': null,
  'cidade': null,
  'uf': null,
  'cep': null,
  'observacoes': null,
  'endereco': null,
};

Map<String, dynamic> pedido(int id, String status, double valor, int pizzas) => {
  'id_pedido': id,
  'id_mercado': 1,
  'mercado': 'Mercado Central',
  'id_usuario': 1,
  'data_pedido': '2026-10-0${id}T10:00:00',
  'status': status,
  'valor_total': valor,
  'quantidade_pizzas': pizzas,
};

/// Digita num TextFormField identificado pelo rótulo, rolando até ele.
Future<void> digitar(WidgetTester tester, String rotulo, String texto) async {
  final campo = find.widgetWithText(TextFormField, rotulo);
  await tester.ensureVisible(campo);
  await tester.enterText(campo, texto);
  await tester.pump();
}

String valorDoCampo(WidgetTester tester, String rotulo) =>
    tester.widget<TextFormField>(find.widgetWithText(TextFormField, rotulo)).controller!.text;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('formatação', () {
    test('CNPJ, CPF, telefone e CEP', () {
      expect(formatarDocumento('12345678000190'), '12.345.678/0001-90');
      expect(formatarDocumento('12345678901'), '123.456.789-01');
      expect(formatarDocumento('123'), '123', reason: 'tamanho inesperado fica como está');
      expect(formatarTelefone('54999991234'), '(54) 99999-1234');
      expect(formatarTelefone('5433110000'), '(54) 3311-0000');
      expect(formatarTelefone('(54) 3311-0000'), '(54) 3311-0000');
      expect(formatarCep('99010040'), '99010-040');
    });

    test('busca ignora acentos e maiúsculas', () {
      expect(normalizarBusca('Armazém SÃO João'), 'armazem sao joao');
    });

    TextEditingValue digitarNaMascara(TextInputFormatter m, String antes, String depois) =>
        m.formatEditUpdate(TextEditingValue(text: antes), TextEditingValue(text: depois));

    test('máscara de CNPJ/CPF troca de padrão conforme a quantidade de dígitos', () {
      final m = MascaraDigitos.documento();
      expect(digitarNaMascara(m, '', '12345678901').text, '123.456.789-01');
      expect(digitarNaMascara(m, '', '123456789012').text, '12.345.678/9012');
      expect(digitarNaMascara(m, '', '12345678000190999').text, '12.345.678/0001-90', reason: 'limita a 14');
      expect(digitarNaMascara(m, '', '12a.3b').text, '123');
    });

    test('máscara de telefone e CEP', () {
      expect(digitarNaMascara(MascaraDigitos.telefone(), '', '5433110000').text, '(54) 3311-0000');
      expect(digitarNaMascara(MascaraDigitos.telefone(), '', '54999991234').text, '(54) 99999-1234');
      expect(digitarNaMascara(MascaraDigitos.cep(), '', '99010040').text, '99010-040');
    });

    test('backspace sobre um separador apaga o dígito anterior a ele', () {
      expect(
        digitarNaMascara(MascaraDigitos.cep(), '99010-0', '99010-').text,
        '99010',
        reason: 'apagou o último dígito',
      );
      // cursor depois do "-" de "99010-0": apagar o "-" remove o "0" antes dele
      expect(digitarNaMascara(MascaraDigitos.cep(), '99010-0', '990100').text, '99010');
      // "123.456": apagar o "." remove o "3"
      expect(digitarNaMascara(MascaraDigitos.documento(), '123.456', '123456').text, '124.56');
    });
  });

  group('lista', () {
    late ApiFalsa api;

    setUp(() {
      api = ApiFalsa({
        'GET /materia-prima': (_) => [],
        'GET /mercado-parceiro': (_) => [joao, central],
      });
      ApiClient.instance = api.cliente;
    });

    Future<void> abrirAba(WidgetTester tester) async {
      await abrir(tester, const HomeScreen());
      await tester.tap(find.text('Mercados'));
      await tester.pumpAndSettle();
    }

    testWidgets('quinta aba mostra cards com CNPJ formatado, cidade/UF e telefone', (tester) async {
      await abrirAba(tester);
      expect(find.text('Mercados parceiros'), findsOneWidget);
      expect(find.text('2 mercados cadastrados'), findsOneWidget);
      expect(find.text('12.345.678/0001-90'), findsOneWidget);
      expect(find.text('123.456.789-01'), findsOneWidget);
      expect(find.text('Passo Fundo/RS'), findsOneWidget);
      expect(find.text('(54) 99999-1234'), findsOneWidget);
      expect(find.text('Cidade não informada'), findsOneWidget);
      expect(find.text('Novo mercado'), findsOneWidget);
    });

    testWidgets('busca por nome (sem acento) e por CNPJ', (tester) async {
      await abrirAba(tester);
      final busca = find.widgetWithText(TextField, 'Buscar por nome ou CNPJ/CPF');

      await tester.enterText(busca, 'armazem sao');
      await tester.pump();
      expect(find.text('Armazém São João'), findsOneWidget);
      expect(find.text('Mercado Central'), findsNothing);

      await tester.enterText(busca, '12.345.678/0001');
      await tester.pump();
      expect(find.text('Mercado Central'), findsOneWidget);
      expect(find.text('Armazém São João'), findsNothing);

      await tester.enterText(busca, 'padaria');
      await tester.pump();
      expect(find.text('Nenhum mercado encontrado'), findsOneWidget);

      await tester.tap(find.byTooltip('Limpar busca'));
      await tester.pump();
      expect(find.text('Mercado Central'), findsOneWidget);
      expect(find.text('Armazém São João'), findsOneWidget);
    });
  });

  group('detalhe', () {
    testWidgets('seções, últimos pedidos pela API e exclusão recusada', (tester) async {
      final api = ApiFalsa({
        'GET /mercado-parceiro/1': (_) => central,
        'GET /pedido-revenda': (_) => [
          for (var i = 7; i >= 1; i--) pedido(i, i == 2 ? 'Cancelado' : 'Entregue', 100.0 * i, i),
        ],
        'DELETE /mercado-parceiro/1': (_) => erro('Mercado possui pedidos vinculados e não pode ser removido.', 409),
      });
      ApiClient.instance = api.cliente;
      await abrir(tester, const MercadoDetalheScreen(idMercado: 1));

      final lista = api.requisicoes.firstWhere((r) => r.url.path == '/pedido-revenda');
      expect(lista.url.queryParameters['id_mercado'], '1');

      for (final secao in ['Identificação', 'Contato', 'Endereço', 'Observações']) {
        expect(find.text(secao), findsOneWidget, reason: secao);
      }
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('compras@central.com.br'), findsOneWidget);
      expect(find.text('Rua Independência, 1200'), findsOneWidget);
      expect(find.text('99010-040'), findsOneWidget);
      expect(find.text('Entregas só pela manhã.'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Últimos pedidos'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('7 pedidos no total'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Pedido #3 · 03/10'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Pedido #7 · 07/10'), findsOneWidget);
      expect(find.text('Pedido #2 · 02/10'), findsNothing, reason: 'mostra só os 5 mais recentes');

      await tester.scrollUntilVisible(find.text('Excluir'), -200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir mercado?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(find.text('Mercado possui pedidos vinculados e não pode ser removido.'), findsOneWidget);
      expect(find.byType(MercadoDetalheScreen), findsOneWidget, reason: 'continua na tela');
    });

    testWidgets('campos vazios aparecem como "Não informado"', (tester) async {
      ApiClient.instance = ApiFalsa({'GET /mercado-parceiro/2': (_) => joao, 'GET /pedido-revenda': (_) => []}).cliente;
      await abrir(tester, const MercadoDetalheScreen(idMercado: 2));
      expect(find.text('CPF'), findsOneWidget);
      expect(find.text('Não informado'), findsNWidgets(7));
      expect(find.text('Nenhuma observação.'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Nenhum pedido para este mercado ainda.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    });
  });

  group('formulário', () {
    testWidgets('valida e envia só dígitos, UF e campos vazios como null', (tester) async {
      final api = ApiFalsa({
        'POST /mercado-parceiro': (req) => {...central, ...jsonDecode(req.body), 'id_mercado': 9},
      });
      ApiClient.instance = api.cliente;
      await abrir(tester, const MercadoFormScreen());

      await digitar(tester, 'Nome *', 'Mercado Vila Nova');
      await digitar(tester, 'CNPJ ou CPF *', '1234567800019');
      await digitar(tester, 'E-mail', 'compras@');
      await digitar(tester, 'CEP', '9901004');
      await tester.tap(find.text('Cadastrar mercado'));
      await tester.pumpAndSettle();
      expect(find.text('CPF tem 11 dígitos e CNPJ tem 14'), findsOneWidget);
      expect(find.text('E-mail inválido'), findsOneWidget);
      expect(find.text('O CEP tem 8 dígitos'), findsOneWidget);
      expect(api.requisicoes, isEmpty);

      await digitar(tester, 'CNPJ ou CPF *', '12345678000190');
      expect(valorDoCampo(tester, 'CNPJ ou CPF *'), '12.345.678/0001-90');
      await digitar(tester, 'E-mail', 'compras@vilanova.com.br');
      await digitar(tester, 'CEP', '99010040');
      await digitar(tester, 'Telefone', '54999991234');
      expect(valorDoCampo(tester, 'Telefone'), '(54) 99999-1234');
      await digitar(tester, 'Cidade', 'Passo Fundo');

      final uf = find.byType(DropdownButtonFormField<String?>);
      await tester.ensureVisible(uf);
      await tester.tap(uf);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('RS').hitTestable(), 50, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.text('RS').hitTestable());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cadastrar mercado'));
      await tester.pumpAndSettle();
      final corpo = jsonDecode(api.requisicoes.single.body) as Map<String, dynamic>;
      expect(corpo, {
        'nome': 'Mercado Vila Nova',
        'cnpj_cpf': '12345678000190',
        'nome_contato': null,
        'telefone': '54999991234',
        'email': 'compras@vilanova.com.br',
        'cep': '99010040',
        'logradouro': null,
        'numero': null,
        'bairro': null,
        'cidade': 'Passo Fundo',
        'uf': 'RS',
        'observacoes': null,
      });
    });

    testWidgets('editar abre preenchido, faz PUT e mostra erro da API', (tester) async {
      var recusar = true;
      final api = ApiFalsa({
        'PUT /mercado-parceiro/1': (req) =>
            recusar ? erro('Já existe um mercado com esse CNPJ/CPF.', 409) : {...central, ...jsonDecode(req.body)},
      });
      ApiClient.instance = api.cliente;
      MercadoParceiro? salvo;
      await abrir(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => salvo = await Navigator.push<MercadoParceiro>(
                  context,
                  MaterialPageRoute(builder: (_) => MercadoFormScreen(mercado: MercadoParceiro.fromJson(central))),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Editar mercado'), findsOneWidget);
      expect(valorDoCampo(tester, 'CNPJ ou CPF *'), '12.345.678/0001-90');
      expect(valorDoCampo(tester, 'Telefone'), '(54) 99999-1234');
      expect(valorDoCampo(tester, 'CEP'), '99010-040');

      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();
      expect(find.text('Já existe um mercado com esse CNPJ/CPF.'), findsOneWidget);
      expect(find.text('Editar mercado'), findsOneWidget, reason: 'continua no formulário');

      recusar = false;
      await digitar(tester, 'Bairro', '');
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();
      final corpo = jsonDecode(api.requisicoes.last.body) as Map<String, dynamic>;
      expect(api.requisicoes.last.method, 'PUT');
      expect(corpo['bairro'], isNull, reason: 'campo apagado vai como null');
      expect(corpo['uf'], 'RS');
      expect(salvo?.nome, 'Mercado Central');
    });
  });
}
