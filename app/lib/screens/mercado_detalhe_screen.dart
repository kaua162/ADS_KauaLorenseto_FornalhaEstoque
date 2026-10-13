import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/mensagens.dart';
import '../widgets/pill.dart';
import 'mercado_form_screen.dart';
import 'pedido_detalhe_screen.dart';

/// RF06 - HU07: detalhe do mercado parceiro com os últimos pedidos.
class MercadoDetalheScreen extends StatefulWidget {
  const MercadoDetalheScreen({super.key, required this.idMercado});

  final int idMercado;

  /// Quantos pedidos mostrar em "Últimos pedidos".
  static const limitePedidos = 5;

  @override
  State<MercadoDetalheScreen> createState() => _MercadoDetalheScreenState();
}

class _MercadoDetalheScreenState extends State<MercadoDetalheScreen> {
  late Future<(MercadoParceiro, List<Pedido>)> _futuro = _carregar();
  bool _alterou = false;
  bool _enviando = false;

  /// `GET /mercado-parceiro/<id>` + `GET /pedido-revenda?id_mercado=` (a API já ordena do mais recente).
  Future<(MercadoParceiro, List<Pedido>)> _carregar() {
    final api = ApiClient.instance;
    return (api.detalharMercado(widget.idMercado), api.listarPedidos(idMercado: widget.idMercado)).wait;
  }

  void _recarregar() => setState(() {
    _futuro = _carregar();
  });

  Future<void> _editar(MercadoParceiro mercado) async {
    final salvo = await Navigator.push<MercadoParceiro>(
      context,
      MaterialPageRoute(builder: (_) => MercadoFormScreen(mercado: mercado)),
    );
    if (salvo != null) {
      _alterou = true;
      _recarregar();
    }
  }

  Future<void> _excluir(MercadoParceiro mercado) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir mercado?',
      // Quem decide é a API: mercado com pedidos volta 409 e a mensagem aparece no SnackBar.
      mensagem: '"${mercado.nome}" será removido do cadastro. Mercados com pedidos não podem ser excluídos.',
      textoConfirmar: 'Excluir',
    );
    if (!ok || !mounted) return;
    setState(() => _enviando = true);
    try {
      await ApiClient.instance.removerMercado(mercado.id);
      if (!mounted) return;
      mostrarMensagem(context, 'Mercado removido.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _abrirPedido(Pedido p) async {
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PedidoDetalheScreen(idPedido: p.id)),
    );
    if (alterou == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _alterou);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Mercado parceiro')),
        body: FutureBuilder<(MercadoParceiro, List<Pedido>)>(
          future: _futuro,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Carregando();
            if (snap.hasError) return EstadoErro(mensagem: snap.error.toString(), onTentarNovamente: _recarregar);
            final (mercado, pedidos) = snap.data!;
            return _conteudo(mercado, pedidos);
          },
        ),
      ),
    );
  }

  Widget _conteudo(MercadoParceiro m, List<Pedido> pedidos) {
    final ultimos = pedidos.take(MercadoDetalheScreen.limitePedidos).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(m.nome, style: estiloTitulo(26)),
        const SizedBox(height: 4),
        Text(formatarDocumento(m.cnpjCpf), style: const TextStyle(color: Cores.textoSecundario, fontSize: 15)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _enviando ? null : () => _editar(m),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _enviando ? null : () => _excluir(m),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Cores.primariaEscura,
                  side: const BorderSide(color: Cores.primariaEscura),
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Excluir'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SecaoDados(
          titulo: 'Identificação',
          linhas: [('Nome', m.nome), (m.cnpjCpf.length == 11 ? 'CPF' : 'CNPJ', formatarDocumento(m.cnpjCpf))],
        ),
        _SecaoDados(
          titulo: 'Contato',
          linhas: [
            ('Responsável', m.nomeContato),
            ('Telefone', m.telefone == null ? null : formatarTelefone(m.telefone)),
            ('E-mail', m.email),
          ],
        ),
        _SecaoDados(
          titulo: 'Endereço',
          linhas: [
            ('Logradouro', m.logradouroNumero),
            ('Bairro', m.bairro),
            ('Cidade/UF', m.cidadeUf),
            ('CEP', m.cep == null ? null : formatarCep(m.cep)),
          ],
        ),
        _SecaoTexto(titulo: 'Observações', texto: m.observacoes),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text('Últimos pedidos', style: estiloTitulo(20))),
            if (pedidos.isNotEmpty)
              Text(
                '${pedidos.length} ${pedidos.length == 1 ? 'pedido' : 'pedidos'} no total',
                style: const TextStyle(color: Cores.textoSecundario, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (ultimos.isEmpty)
          const CardBase(
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: Cores.bordaInput),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Nenhum pedido para este mercado ainda.', style: TextStyle(color: Cores.textoSecundario)),
                ),
              ],
            ),
          )
        else
          for (final p in ultimos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CardPedidoResumo(pedido: p, onTap: () => _abrirPedido(p)),
            ),
      ],
    );
  }
}

/// Card com título e pares rótulo/valor. Valores vazios aparecem como "Não informado".
class _SecaoDados extends StatelessWidget {
  const _SecaoDados({required this.titulo, required this.linhas});

  final String titulo;
  final List<(String, String?)> linhas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardBase(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: estiloTitulo(17)),
            const SizedBox(height: 6),
            for (final (rotulo, valor) in linhas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(rotulo, style: const TextStyle(color: Cores.textoSecundario, fontSize: 13.5)),
                    ),
                    Expanded(
                      child: SelectableText(
                        valor == null || valor.isEmpty ? 'Não informado' : valor,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: valor == null || valor.isEmpty ? Cores.bordaInput : Cores.texto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SecaoTexto extends StatelessWidget {
  const _SecaoTexto({required this.titulo, this.texto});

  final String titulo;
  final String? texto;

  @override
  Widget build(BuildContext context) {
    final vazio = texto == null || texto!.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardBase(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: estiloTitulo(17)),
            const SizedBox(height: 8),
            SelectableText(
              vazio ? 'Nenhuma observação.' : texto!,
              style: TextStyle(color: vazio ? Cores.bordaInput : Cores.texto, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPedidoResumo extends StatelessWidget {
  const _CardPedidoResumo({required this.pedido, required this.onTap});

  final Pedido pedido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cancelado = pedido.status == StatusPedido.cancelado;
    final data = pedido.dataPedido == null ? '' : ' · ${formatarDiaMes(pedido.dataPedido!)}';
    return CardBase(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pedido #${pedido.id}$data', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${pedido.quantidadePizzas} ${pedido.quantidadePizzas == 1 ? 'pizza' : 'pizzas'}',
                  style: const TextStyle(color: Cores.textoSecundario, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Pill.status(statusApi: pedido.statusApi),
              const SizedBox(height: 4),
              Text(
                formatarMoeda(pedido.valorTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: cancelado ? Cores.textoSecundario : Cores.texto,
                  decoration: cancelado ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
