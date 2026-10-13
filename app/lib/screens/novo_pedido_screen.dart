import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../services/sessao.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/mensagens.dart';
import 'mercado_form_screen.dart';
import 'pizzas_screen.dart';

/// RF06 - HU08: novo pedido. A API dá baixa no estoque (tudo ou nada).
class NovoPedidoScreen extends StatefulWidget {
  const NovoPedidoScreen({super.key});

  @override
  State<NovoPedidoScreen> createState() => _NovoPedidoScreenState();
}

class _NovoPedidoScreenState extends State<NovoPedidoScreen> {
  late Future<(List<MercadoParceiro>, List<SaborComEstoque>)> _futuro = _carregar();
  final Map<int, int> _quantidades = {};
  int? _idMercado;
  bool _enviando = false;

  Future<(List<MercadoParceiro>, List<SaborComEstoque>)> _carregar() =>
      (ApiClient.instance.listarMercados(), carregarSaboresComEstoque()).wait;

  void _recarregar() => setState(() {
    _futuro = _carregar();
  });

  Future<void> _novoMercado() async {
    final mercado = await Navigator.push<MercadoParceiro>(
      context,
      MaterialPageRoute(builder: (_) => const MercadoFormScreen()),
    );
    if (mercado != null) {
      setState(() {
        _idMercado = mercado.id;
        _futuro = _carregar();
      });
    }
  }

  void _alterar(SaborComEstoque s, int delta) {
    final atual = _quantidades[s.sabor.id] ?? 0;
    final nova = (atual + delta).clamp(0, s.quantidade);
    setState(() => _quantidades[s.sabor.id] = nova);
  }

  Future<void> _confirmar(List<SaborComEstoque> sabores) async {
    final usuario = Sessao.usuario;
    if (usuario == null) {
      mostrarMensagem(context, 'Sessão expirada. Faça login novamente.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final pedido = await ApiClient.instance.criarPedido(
        idMercado: _idMercado!,
        idUsuario: usuario.id,
        quantidadesPorSabor: _quantidades,
      );
      if (!mounted) return;
      mostrarMensagem(context, 'Pedido #${pedido.id} criado · ${formatarMoeda(pedido.valorTotal)}');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      mostrarErro(context, e);
      // O estoque pode ter mudado (outro pedido): atualiza os disponíveis.
      if (e is ApiException && e.statusCode == 400) _recarregar();
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<MercadoParceiro>, List<SaborComEstoque>)>(
      future: _futuro,
      builder: (context, snap) {
        Widget corpo;
        Widget? rodape;
        if (snap.connectionState != ConnectionState.done) {
          corpo = const Carregando();
        } else if (snap.hasError) {
          corpo = EstadoErro(mensagem: snap.error.toString(), onTentarNovamente: _recarregar);
        } else {
          final (mercados, sabores) = snap.data!;
          // Descarta quantidades acima do novo disponível (após recarregar).
          for (final s in sabores) {
            final q = _quantidades[s.sabor.id];
            if (q != null && q > s.quantidade) _quantidades[s.sabor.id] = s.quantidade;
          }
          if (_idMercado != null && !mercados.any((m) => m.id == _idMercado)) _idMercado = null;
          corpo = _formulario(mercados, sabores);
          rodape = _rodape(sabores);
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Novo pedido')),
          body: corpo,
          bottomNavigationBar: rodape,
        );
      },
    );
  }

  Widget _formulario(List<MercadoParceiro> mercados, List<SaborComEstoque> sabores) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Text('Mercado', style: estiloTitulo(18)),
        const SizedBox(height: 10),
        if (mercados.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Nenhum mercado cadastrado ainda.', style: TextStyle(color: Cores.textoSecundario)),
          )
        else
          DropdownButtonFormField<int>(
            initialValue: _idMercado,
            isExpanded: true,
            decoration: const InputDecoration(hintText: 'Escolha o mercado'),
            items: [
              for (final m in mercados)
                DropdownMenuItem(
                  value: m.id,
                  child: Text(m.nome, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _idMercado = v),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _novoMercado,
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Novo mercado'),
          ),
        ),
        const SizedBox(height: 12),
        Text('Pizzas', style: estiloTitulo(18)),
        const SizedBox(height: 10),
        if (sabores.isEmpty)
          const EstadoVazio(
            icone: Icons.local_pizza_outlined,
            titulo: 'Nenhum sabor cadastrado',
            mensagem: 'Cadastre sabores na aba Pizzas.',
          )
        else
          for (final s in sabores)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LinhaSabor(
                item: s,
                quantidade: _quantidades[s.sabor.id] ?? 0,
                onMenos: () => _alterar(s, -1),
                onMais: () => _alterar(s, 1),
              ),
            ),
      ],
    );
  }

  Widget _rodape(List<SaborComEstoque> sabores) {
    var pizzas = 0;
    var valor = 0.0;
    for (final s in sabores) {
      final q = _quantidades[s.sabor.id] ?? 0;
      pizzas += q;
      valor += q * s.sabor.precoUnitario;
    }
    final podeConfirmar = _idMercado != null && pizzas > 0 && !_enviando;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Cores.bordaCard)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    '$pizzas ${pizzas == 1 ? 'pizza' : 'pizzas'}',
                    style: const TextStyle(color: Cores.textoSecundario, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(formatarMoeda(valor), style: estiloTitulo(24)),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: podeConfirmar ? () => _confirmar(sabores) : null,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _enviando
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(_idMercado == null ? 'Escolha o mercado' : 'Confirmar pedido'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ao confirmar, o estoque de pizzas é baixado automaticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Cores.textoSecundario, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaSabor extends StatelessWidget {
  const _LinhaSabor({required this.item, required this.quantidade, required this.onMenos, required this.onMais});

  final SaborComEstoque item;
  final int quantidade;
  final VoidCallback onMenos;
  final VoidCallback onMais;

  @override
  Widget build(BuildContext context) {
    final disponivel = item.quantidade;
    final esgotado = disponivel == 0;
    return CardBase(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.sabor.nome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: esgotado ? Cores.textoSecundario : Cores.texto,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatarMoeda(item.sabor.precoUnitario)} · '
                  '${esgotado ? 'sem estoque' : '$disponivel ${disponivel == 1 ? 'disponível' : 'disponíveis'}'}',
                  style: TextStyle(color: esgotado ? Cores.primariaEscura : Cores.textoSecundario, fontSize: 13),
                ),
              ],
            ),
          ),
          _BotaoPasso(
            icone: Icons.remove_rounded,
            tooltip: 'Menos ${item.sabor.nome}',
            onPressed: quantidade > 0 ? onMenos : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$quantidade',
              textAlign: TextAlign.center,
              style: estiloTitulo(20, cor: quantidade > 0 ? Cores.texto : Cores.textoSecundario),
            ),
          ),
          _BotaoPasso(
            icone: Icons.add_rounded,
            tooltip: 'Mais ${item.sabor.nome}',
            onPressed: quantidade < disponivel ? onMais : null,
            destaque: true,
          ),
        ],
      ),
    );
  }
}

class _BotaoPasso extends StatelessWidget {
  const _BotaoPasso({required this.icone, required this.tooltip, this.onPressed, this.destaque = false});

  final IconData icone;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style: IconButton.styleFrom(
        backgroundColor: destaque ? Cores.primaria : Colors.white,
        foregroundColor: destaque ? Colors.white : Cores.texto,
        disabledBackgroundColor: Cores.trilho,
        disabledForegroundColor: Cores.bordaInput,
        side: destaque ? null : const BorderSide(color: Cores.bordaInput),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icone),
    );
  }
}
