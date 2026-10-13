import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/barra_nivel.dart';
import '../widgets/chips_filtro.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';

enum Periodo {
  hoje('Hoje'),
  seteDias('7 dias'),
  mes('Este mês');

  const Periodo(this.rotulo);

  final String rotulo;

  /// (data_inicio, data_fim) inclusivos, no calendário do aparelho.
  (DateTime, DateTime) intervalo(DateTime agora) {
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return switch (this) {
      Periodo.hoje => (hoje, hoje),
      Periodo.seteDias => (hoje.subtract(const Duration(days: 6)), hoje),
      Periodo.mes => (DateTime(hoje.year, hoje.month, 1), hoje),
    };
  }
}

/// RF07 - Relatório de vendas.
class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key, this.barra});

  /// Barra de navegação inferior (vem da HomeScreen).
  final Widget? barra;

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  Periodo _periodo = Periodo.hoje;
  Future<RelatorioVendas>? _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _buscar();
  }

  Future<RelatorioVendas> _buscar() {
    final (inicio, fim) = _periodo.intervalo(DateTime.now());
    return ApiClient.instance.relatorioVendas(dataInicio: inicio, dataFim: fim);
  }

  Future<void> _recarregar() async {
    final futuro = _buscar();
    setState(() {
      _futuro = futuro;
    });
    await futuro.then((_) {}, onError: (_) {});
  }

  void _mudarPeriodo(Periodo p) {
    _periodo = p;
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final (inicio, fim) = _periodo.intervalo(DateTime.now());
    final textoPeriodo = inicio == fim
        ? formatarDataCompleta(inicio)
        : '${formatarDiaMes(inicio)} a ${formatarDiaMes(fim)}';
    return Scaffold(
      bottomNavigationBar: widget.barra,
      body: ConteudoAssincrono<RelatorioVendas>(
        future: _futuro,
        onRecarregar: _recarregar,
        paddingInferior: 24,
        cabecalho: [
          CabecalhoTela(titulo: 'Relatórios', subtitulo: 'Vendas · $textoPeriodo'),
          ChipsFiltro<Periodo>(
            opcoes: [for (final p in Periodo.values) (p, p.rotulo)],
            selecionado: _periodo,
            onSelecionar: _mudarPeriodo,
          ),
          const SizedBox(height: 8),
        ],
        construir: (r) => [
          Margem(child: _CardTotais(relatorio: r)),
          Margem(child: _CardPorSabor(itens: r.porSabor)),
          const Margem(
            vertical: 10,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Cores.textoSecundario),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pedidos cancelados não entram nos totais.',
                    style: TextStyle(color: Cores.textoSecundario, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTotais extends StatelessWidget {
  const _CardTotais({required this.relatorio});

  final RelatorioVendas relatorio;

  @override
  Widget build(BuildContext context) {
    const rotulo = TextStyle(color: Color(0xFFBFB7AF), fontSize: 13);
    return CardEscuro(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Valor vendido', style: rotulo),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatarMoeda(relatorio.valorTotal), style: estiloTitulo(36, cor: Colors.white)),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF3A3430)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Numero(valor: relatorio.quantidadePedidos, rotulo: 'pedidos'),
              ),
              Expanded(
                child: _Numero(valor: relatorio.quantidadePizzas, rotulo: 'pizzas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({required this.valor, required this.rotulo});

  final int valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$valor', style: estiloTitulo(26, cor: Colors.white)),
        Text(rotulo, style: const TextStyle(color: Color(0xFFBFB7AF), fontSize: 13)),
      ],
    );
  }
}

class _CardPorSabor extends StatelessWidget {
  const _CardPorSabor({required this.itens});

  /// Já vem ordenado do maior para o menor valor pela API.
  final List<VendaSabor> itens;

  @override
  Widget build(BuildContext context) {
    final maior = itens.isEmpty ? 0.0 : itens.map((i) => i.valor).reduce((a, b) => a > b ? a : b);
    return CardBase(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Por sabor', style: estiloTitulo(18)),
          const SizedBox(height: 8),
          if (itens.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Nenhuma venda no período.', style: TextStyle(color: Cores.textoSecundario)),
            )
          else
            for (final i in itens)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(i.sabor, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Text(
                          '${i.quantidade} un · ',
                          style: const TextStyle(color: Cores.textoSecundario, fontSize: 13),
                        ),
                        Text(formatarMoeda(i.valor), style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    BarraNivel(fracao: maior == 0 ? 0 : i.valor / maior, cor: Cores.primaria, altura: 10),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
