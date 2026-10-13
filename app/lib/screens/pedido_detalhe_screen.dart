import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/mensagens.dart';
import '../widgets/pill.dart';

/// RF06 - HU08: detalhe do pedido com itens e mudança de status.
class PedidoDetalheScreen extends StatefulWidget {
  const PedidoDetalheScreen({super.key, required this.idPedido});

  final int idPedido;

  @override
  State<PedidoDetalheScreen> createState() => _PedidoDetalheScreenState();
}

class _PedidoDetalheScreenState extends State<PedidoDetalheScreen> {
  late Future<Pedido> _futuro = ApiClient.instance.detalharPedido(widget.idPedido);
  bool _alterou = false;
  bool _enviando = false;

  Future<void> _recarregar() async {
    final futuro = ApiClient.instance.detalharPedido(widget.idPedido);
    setState(() {
      _futuro = futuro;
    });
    await futuro.then((_) {}, onError: (_) {});
  }

  Future<void> _mudarStatus(Pedido pedido, StatusPedido novo) async {
    if (novo == StatusPedido.cancelado) {
      final ok = await confirmar(
        context,
        titulo: 'Cancelar pedido #${pedido.id}?',
        mensagem:
            'As ${pedido.quantidadePizzas} pizzas voltam para o estoque como um lote de hoje. '
            'Depois de cancelado, o pedido não pode mais mudar de status.',
        textoConfirmar: 'Cancelar pedido',
      );
      if (!ok) return;
    } else if (novo == StatusPedido.entregue) {
      final ok = await confirmar(
        context,
        titulo: 'Marcar como entregue?',
        mensagem: 'Depois de entregue, o pedido não pode mais mudar de status.',
        textoConfirmar: 'Marcar entregue',
      );
      if (!ok) return;
    }
    if (!mounted) return;

    setState(() => _enviando = true);
    try {
      final atualizado = await ApiClient.instance.atualizarStatusPedido(pedido.id, novo.valorApi);
      _alterou = true;
      if (!mounted) return;
      setState(() {
        _futuro = Future.value(atualizado);
      });
      mostrarMensagem(
        context,
        novo == StatusPedido.cancelado
            ? 'Pedido cancelado. Pizzas devolvidas ao estoque.'
            : 'Status alterado para ${novo.rotulo}.',
      );
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _alterou);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Pedido #${widget.idPedido}')),
        body: FutureBuilder<Pedido>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Carregando();
            if (snap.hasError) {
              return EstadoErro(mensagem: snap.error.toString(), onTentarNovamente: _recarregar);
            }
            return _conteudo(snap.data!);
          },
        ),
      ),
    );
  }

  Widget _conteudo(Pedido pedido) {
    final itens = pedido.itens ?? const <ItemPedido>[];
    final status = pedido.status;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Row(
          children: [
            Expanded(child: Text(pedido.mercado ?? 'Mercado #${pedido.idMercado}', style: estiloTitulo(24))),
            Pill.status(statusApi: pedido.statusApi),
          ],
        ),
        if (pedido.dataPedido != null) ...[
          const SizedBox(height: 4),
          Text(
            'Feito em ${formatarDataHora(pedido.dataPedido!)}',
            style: const TextStyle(color: Cores.textoSecundario),
          ),
        ],
        const SizedBox(height: 16),
        CardBase(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (final item in itens) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.sabor ?? 'Sabor #${item.idSabor}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${item.quantidade} × ${formatarMoeda(item.valorUnitario)}',
                              style: const TextStyle(color: Cores.textoSecundario, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(formatarMoeda(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Cores.bordaCard),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '${pedido.quantidadePizzas} ${pedido.quantidadePizzas == 1 ? 'pizza' : 'pizzas'}',
                      style: const TextStyle(color: Cores.textoSecundario),
                    ),
                    const Spacer(),
                    Text(formatarMoeda(pedido.valorTotal), style: estiloTitulo(22)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (status == null || status.finalizado)
          _AvisoFinalizado(status: status)
        else ...[
          Text('Mudar status', style: estiloTitulo(18)),
          const SizedBox(height: 10),
          for (final novo in StatusPedido.values)
            if (novo != status && novo != StatusPedido.cancelado)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: FilledButton.icon(
                  onPressed: _enviando ? null : () => _mudarStatus(pedido, novo),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  icon: Icon(switch (novo) {
                    StatusPedido.pendente => Icons.schedule_rounded,
                    StatusPedido.emProducao => Icons.local_fire_department_outlined,
                    _ => Icons.check_circle_outline_rounded,
                  }),
                  label: Text(novo == StatusPedido.entregue ? 'Marcar como entregue' : 'Mover para ${novo.rotulo}'),
                ),
              ),
          OutlinedButton.icon(
            onPressed: _enviando ? null : () => _mudarStatus(pedido, StatusPedido.cancelado),
            style: OutlinedButton.styleFrom(
              foregroundColor: Cores.primariaEscura,
              side: const BorderSide(color: Cores.primariaEscura),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar pedido'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cancelar devolve as pizzas ao estoque.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Cores.textoSecundario, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _AvisoFinalizado extends StatelessWidget {
  const _AvisoFinalizado({required this.status});

  final StatusPedido? status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Cores.trilho, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: Cores.textoSecundario),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status == StatusPedido.cancelado
                  ? 'Pedido cancelado. As pizzas já voltaram ao estoque e o status não pode mais mudar.'
                  : 'Pedido entregue. O status não pode mais mudar.',
              style: const TextStyle(color: Cores.textoSecundario),
            ),
          ),
        ],
      ),
    );
  }
}
