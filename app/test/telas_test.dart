import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fornalha_app/main.dart';
import 'package:fornalha_app/models/modelos.dart';
import 'package:fornalha_app/screens/home_screen.dart';
import 'package:fornalha_app/screens/novo_pedido_screen.dart';
import 'package:fornalha_app/services/api_client.dart';
import 'package:fornalha_app/services/sessao.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'apoio.dart';

const insumos = [
  {
    'id_materia_prima': 1,
    'nome': 'Farinha',
    'unidade_medida': 'kg',
    'qtd_atual': 50.0,
    'qtd_minima': 10.0,
    'estoque_critico': false,
  },
  {
    'id_materia_prima': 2,
    'nome': 'Molho',
    'unidade_medida': 'l',
    'qtd_atual': 2.0,
    'qtd_minima': 2.0,
    'estoque_critico': true,
  },
  {
    'id_materia_prima': 3,
    'nome': 'Queijo',
    'unidade_medida': 'kg',
    'qtd_atual': 1.5,
    'qtd_minima': 5.0,
    'estoque_critico': true,
  },
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => Sessao.sair());

  testWidgets('Login: mostra o erro da API e entra com sucesso', (tester) async {
    var senhaCerta = false;
    final api = ApiFalsa({
      'POST /auth/login': (_) => senhaCerta
          ? {
              'mensagem': 'ok',
              'usuario': {'id_usuario': 4, 'nome': 'Kauã', 'login': 'kaua'},
            }
          : erro('Usuário ou senha inválidos.', 401),
      'GET /materia-prima': (_) => insumos,
    });
    ApiClient.instance = api.cliente;

    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const FornalhaApp());
    await tester.pumpAndSettle();

    expect(find.text('La Fornalha'), findsOneWidget);
    expect(find.text('Acesso exclusivo do vendedor'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Usuário'), 'kaua');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'errada');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Usuário ou senha inválidos.'), findsOneWidget);
    expect(Sessao.usuario, isNull);

    senhaCerta = true;
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(Sessao.usuario?.id, 4);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('3 insumos · 2 em estoque crítico'), findsOneWidget);
  });

  testWidgets('Insumos: resumo e filtro Críticos', (tester) async {
    ApiClient.instance = ApiFalsa({'GET /materia-prima': (_) => insumos}).cliente;
    await abrir(tester, const HomeScreen());

    expect(find.text('3 insumos · 2 em estoque crítico'), findsOneWidget);
    expect(find.text('Farinha'), findsOneWidget);
    expect(find.text('Estoque crítico'), findsNWidgets(2));
    expect(find.text('Em dia'), findsOneWidget);
    expect(find.text('mínimo 10 kg'), findsOneWidget);
    expect(find.text('1,5'), findsOneWidget);

    await tester.tap(find.text('Críticos'));
    await tester.pumpAndSettle();
    expect(find.text('Farinha'), findsNothing);
    expect(find.text('Molho'), findsOneWidget);
    expect(find.text('Queijo'), findsOneWidget);
  });

  testWidgets('Insumos: erro de conexão mostra estado de erro com "Tentar novamente"', (tester) async {
    var falhar = true;
    ApiClient.instance = ApiClient(
      baseUrl: 'http://api',
      client: MockClient((_) async {
        if (falhar) throw http.ClientException('refused');
        return http.Response(jsonEncode(insumos), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      }),
    );
    await abrir(tester, const HomeScreen());
    expect(find.text('Não foi possível conectar ao servidor'), findsOneWidget);

    falhar = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Farinha'), findsOneWidget);
  });

  testWidgets('Pedidos: chip de status filtra pela API (Em produção -> "Em Produção")', (tester) async {
    final api = ApiFalsa({
      'GET /materia-prima': (_) => insumos,
      'GET /pedido-revenda': (req) => [
        if (req.url.queryParameters['status'] == null || req.url.queryParameters['status'] == 'Em Produção')
          {
            'id_pedido': 12,
            'id_mercado': 1,
            'mercado': 'Mercado Central',
            'id_usuario': 1,
            'data_pedido': '2026-10-09T14:00:00',
            'status': 'Em Produção',
            'valor_total': 1558.0,
            'quantidade_pizzas': 52,
          },
      ],
    });
    ApiClient.instance = api.cliente;
    await abrir(tester, const HomeScreen());
    await tester.tap(find.text('Pedidos'));
    await tester.pumpAndSettle();

    expect(find.text('Mercado Central'), findsOneWidget);
    expect(find.text('Pedido #12 · 09/10'), findsOneWidget);
    expect(find.text('52 pizzas'), findsOneWidget);
    expect(find.text('R\$ 1.558,00'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Em produção'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Em produção'));
    await tester.pumpAndSettle();
    expect(api.requisicoes.last.url.queryParameters['status'], 'Em Produção');
    expect(find.text('Mercado Central'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Entregue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Entregue'));
    await tester.pumpAndSettle();
    expect(api.requisicoes.last.url.queryParameters['status'], 'Entregue');
    expect(find.text('Nenhum pedido entregue'), findsOneWidget);
  });

  testWidgets('Novo pedido: stepper respeita o disponível e envia o pedido', (tester) async {
    Sessao.usuario = const Usuario(id: 9, nome: 'Kauã', login: 'kaua');
    var recusar = true;
    final api = ApiFalsa({
      'GET /mercado-parceiro': (_) => [
        {'id_mercado': 1, 'nome': 'Mercado Central', 'cnpj_cpf': '11111111111111', 'telefone': null, 'endereco': null},
      ],
      'GET /pizza-sabor': (_) => [
        {'id_sabor': 1, 'nome': 'Calabresa', 'descricao': null, 'preco_unitario': 25.0},
        {'id_sabor': 2, 'nome': 'Frango', 'descricao': null, 'preco_unitario': 30.0},
      ],
      'GET /estoque-pizza/resumo': (_) => [
        {'id_sabor': 1, 'sabor': 'Calabresa', 'quantidade_disponivel': 2, 'data_lote_mais_antigo': '2026-10-01'},
        {'id_sabor': 2, 'sabor': 'Frango', 'quantidade_disponivel': 0, 'data_lote_mais_antigo': null},
      ],
      'POST /pedido-revenda': (_) => recusar
          ? erro("Estoque insuficiente para o sabor 'Calabresa'.", 400)
          : {
              'id_pedido': 30,
              'id_mercado': 1,
              'mercado': 'Mercado Central',
              'id_usuario': 9,
              'data_pedido': '2026-10-13T10:00:00',
              'status': 'Pendente',
              'valor_total': 50.0,
              'quantidade_pizzas': 2,
              'itens': [],
            },
    });
    ApiClient.instance = api.cliente;
    await abrir(tester, const NovoPedidoScreen());

    expect(find.text('R\$ 25,00 · 2 disponíveis'), findsOneWidget);
    expect(find.text('R\$ 30,00 · sem estoque'), findsOneWidget);
    expect(find.text('Ao confirmar, o estoque de pizzas é baixado automaticamente.'), findsOneWidget);

    final mais = find.byTooltip('Mais Calabresa');
    for (var i = 0; i < 4; i++) {
      await tester.tap(mais);
      await tester.pump();
    }
    expect(find.text('2 pizzas'), findsOneWidget, reason: 'não passa do disponível');
    expect(find.text('R\$ 50,00'), findsOneWidget);
    IconButton botao(String tooltip) =>
        tester.widget<IconButton>(find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)));
    expect(botao('Mais Calabresa').onPressed, isNull, reason: 'chegou no disponível');
    expect(botao('Menos Calabresa').onPressed, isNotNull);
    expect(botao('Mais Frango').onPressed, isNull, reason: 'sem estoque');

    // Sem mercado escolhido não confirma
    expect(find.text('Escolha o mercado'), findsWidgets);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mercado Central').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar pedido'));
    await tester.pumpAndSettle();
    expect(find.text("Estoque insuficiente para o sabor 'Calabresa'."), findsOneWidget);

    recusar = false;
    await tester.tap(find.text('Confirmar pedido'));
    await tester.pumpAndSettle();
    final post = api.requisicoes.where((r) => r.method == 'POST').last;
    expect(jsonDecode(post.body), {
      'id_mercado': 1,
      'id_usuario': 9,
      'itens': [
        {'id_sabor': 1, 'quantidade': 2},
      ],
    });
  });

  testWidgets('Relatórios: totais, barras por sabor e período nos filtros', (tester) async {
    final api = ApiFalsa({
      'GET /materia-prima': (_) => insumos,
      'GET /relatorios/vendas': (_) => {
        'quantidade_pedidos': 4,
        'quantidade_pizzas': 21,
        'valor_total': 1558.0,
        'por_status': {
          'Pendente': {'pedidos': 1, 'valor': 150.0},
          'Em Produção': {'pedidos': 1, 'valor': 60.0},
          'Entregue': {'pedidos': 2, 'valor': 1348.0},
          'Cancelado': {'pedidos': 1, 'valor': 110.0},
        },
        'por_sabor': [
          {'id_sabor': 1, 'sabor': 'Calabresa', 'quantidade': 14, 'valor': 1000.0},
          {'id_sabor': 2, 'sabor': 'Frango', 'quantidade': 7, 'valor': 558.0},
        ],
        'por_mercado': [],
      },
    });
    ApiClient.instance = api.cliente;
    await abrir(tester, const HomeScreen());
    await tester.tap(find.text('Relatórios'));
    await tester.pumpAndSettle();

    expect(find.text('R\$ 1.558,00'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.text('Calabresa'), findsOneWidget);
    expect(find.text('Pedidos cancelados não entram nos totais.'), findsOneWidget);

    final hoje = api.requisicoes.last.url.queryParameters;
    expect(hoje['data_inicio'], hoje['data_fim']);

    await tester.tap(find.text('7 dias'));
    await tester.pumpAndSettle();
    final semana = api.requisicoes.last.url.queryParameters;
    final inicio = DateTime.parse(semana['data_inicio']!);
    final fim = DateTime.parse(semana['data_fim']!);
    expect(fim.difference(inicio).inDays, 6);

    await tester.tap(find.text('Este mês'));
    await tester.pumpAndSettle();
    expect(api.requisicoes.last.url.queryParameters['data_inicio']!.endsWith('-01'), isTrue);
  });
}
