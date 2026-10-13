import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/chips_filtro.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/pill.dart';
import 'novo_pedido_screen.dart';
import 'pedido_detalhe_screen.dart';

/// RF06 - HU08: pedidos de pizza congelada para mercados.
class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key, this.barra});

  /// Barra de navegação inferior (vem da HomeScreen).
  final Widget? barra;

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  StatusPedido? _status;
  Future<List<Pedido>>? _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _buscar();
  }

  /// O filtro de status é feito pela API (?status=).
  Future<List<Pedido>> _buscar() => ApiClient.instance.listarPedidos(status: _status?.valorApi);

  Future<void> _recarregar() async {
    final futuro = _buscar();
    setState(() {
      _futuro = futuro;
    });
    await futuro.catchError((_) => <Pedido>[]);
  }

  void _filtrar(StatusPedido? status) {
    _status = status;
    _recarregar();
  }

  Future<void> _abrir(Widget tela) async {
    final alterou = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => tela));
    if (alterou == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.barra,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(const NovoPedidoScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo pedido'),
      ),
      body: ConteudoAssincrono<List<Pedido>>(
        future: _futuro,
        onRecarregar: _recarregar,
        cabecalho: [
          const CabecalhoTela(titulo: 'Pedidos', subtitulo: 'Revenda para mercados parceiros'),
          ChipsFiltro<StatusPedido?>(
            opcoes: [(null, 'Todos'), for (final s in StatusPedido.values) (s, s.rotulo)],
            selecionado: _status,
            onSelecionar: _filtrar,
          ),
          const SizedBox(height: 8),
        ],
        construir: (pedidos) {
          if (pedidos.isEmpty) {
            return [
              EstadoVazio(
                icone: Icons.receipt_long_outlined,
                titulo: _status == null ? 'Nenhum pedido ainda' : 'Nenhum pedido ${_status!.rotulo.toLowerCase()}',
                mensagem: _status == null ? 'Toque em "Novo pedido" para registrar o primeiro.' : null,
              ),
            ];
          }
          return [
            for (final p in pedidos)
              Margem(
                child: _CardPedido(
                  pedido: p,
                  onTap: () => _abrir(PedidoDetalheScreen(idPedido: p.id)),
                ),
              ),
          ];
        },
      ),
    );
  }
}

class _CardPedido extends StatelessWidget {
  const _CardPedido({required this.pedido, required this.onTap});

  final Pedido pedido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cancelado = pedido.status == StatusPedido.cancelado;
    final data = pedido.dataPedido == null ? '' : ' · ${formatarDiaMes(pedido.dataPedido!)}';
    return CardBase(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pedido.mercado ?? 'Mercado #${pedido.idMercado}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Pill.status(statusApi: pedido.statusApi),
            ],
          ),
          const SizedBox(height: 4),
          Text('Pedido #${pedido.id}$data', style: const TextStyle(color: Cores.textoSecundario, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.local_pizza_outlined, size: 18, color: Cores.textoSecundario),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${pedido.quantidadePizzas} ${pedido.quantidadePizzas == 1 ? 'pizza' : 'pizzas'}',
                  style: const TextStyle(color: Cores.textoSecundario),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatarMoeda(pedido.valorTotal),
                style: estiloTitulo(
                  20,
                  cor: cancelado ? Cores.textoSecundario : Cores.texto,
                ).copyWith(decoration: cancelado ? TextDecoration.lineThrough : null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
