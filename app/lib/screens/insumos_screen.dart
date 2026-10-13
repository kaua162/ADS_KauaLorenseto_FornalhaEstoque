import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/barra_nivel.dart';
import '../widgets/chips_filtro.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import '../widgets/mensagens.dart';
import '../widgets/pill.dart';
import 'insumo_form_screen.dart';

/// RF02/RF03 - Estoque de matéria-prima.
class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key, this.barra});

  /// Barra de navegação inferior (vem da HomeScreen).
  final Widget? barra;

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  Future<List<MateriaPrima>>? _futuro;
  bool _apenasCriticos = false;

  @override
  void initState() {
    super.initState();
    _futuro = ApiClient.instance.listarMateriasPrimas();
  }

  Future<void> _recarregar() async {
    final futuro = ApiClient.instance.listarMateriasPrimas();
    setState(() {
      _futuro = futuro;
    });
    await futuro.catchError((_) => <MateriaPrima>[]);
  }

  Future<void> _novo() async {
    final criado = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const InsumoFormScreen()));
    if (criado == true) _recarregar();
  }

  Future<void> _abrir(MateriaPrima insumo) async {
    final alterou = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovimentacaoSheet(insumo: insumo),
    );
    if (alterou == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.barra,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo insumo'),
      ),
      body: FutureBuilder<List<MateriaPrima>>(
        future: _futuro,
        builder: (context, snap) {
          final itens = snap.data;
          final criticos = itens?.where((i) => i.estoqueCritico).length ?? 0;
          return ConteudoAssincrono<List<MateriaPrima>>(
            future: _futuro,
            onRecarregar: _recarregar,
            cabecalho: [
              CabecalhoTela(
                titulo: 'Insumos',
                subtitulo: itens == null
                    ? 'Matéria-prima da cozinha'
                    : '${itens.length} ${itens.length == 1 ? 'insumo' : 'insumos'} · '
                          '$criticos em estoque crítico',
              ),
              ChipsFiltro<bool>(
                opcoes: const [(false, 'Todos'), (true, 'Críticos')],
                selecionado: _apenasCriticos,
                onSelecionar: (v) => setState(() => _apenasCriticos = v),
              ),
              const SizedBox(height: 8),
            ],
            construir: (itens) {
              if (itens.isEmpty) {
                return const [
                  EstadoVazio(
                    icone: Icons.inventory_2_outlined,
                    titulo: 'Nenhum insumo cadastrado',
                    mensagem: 'Toque em "Novo insumo" para começar.',
                  ),
                ];
              }
              final visiveis = _apenasCriticos ? itens.where((i) => i.estoqueCritico).toList() : itens;
              if (visiveis.isEmpty) {
                return const [
                  EstadoVazio(
                    icone: Icons.check_circle_outline_rounded,
                    titulo: 'Nenhum insumo crítico',
                    mensagem: 'Todos os insumos estão acima do mínimo.',
                  ),
                ];
              }
              return [
                for (final i in visiveis)
                  Margem(
                    child: _CardInsumo(insumo: i, onTap: () => _abrir(i)),
                  ),
              ];
            },
          );
        },
      ),
    );
  }
}

class _CardInsumo extends StatelessWidget {
  const _CardInsumo({required this.insumo, required this.onTap});

  final MateriaPrima insumo;
  final VoidCallback onTap;

  /// A barra fica cheia com o dobro do mínimo (ou com a quantidade atual, se o mínimo for 0).
  double get _nivel {
    final referencia = insumo.qtdMinima > 0 ? insumo.qtdMinima * 2 : insumo.qtdAtual;
    if (referencia <= 0) return 0;
    return insumo.qtdAtual / referencia;
  }

  @override
  Widget build(BuildContext context) {
    final un = insumo.unidadeMedida;
    return CardBase(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(insumo.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              Pill.estoque(critico: insumo.estoqueCritico),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatarQuantidade(insumo.qtdAtual), style: estiloTitulo(26)),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  un,
                  style: const TextStyle(color: Cores.textoSecundario, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'mínimo ${formatarQuantidade(insumo.qtdMinima)} $un',
                  style: const TextStyle(color: Cores.textoSecundario, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BarraNivel(fracao: _nivel, cor: insumo.estoqueCritico ? Cores.primaria : Cores.sucesso),
        ],
      ),
    );
  }
}

/// Registrar entrada/saída de um insumo, com acesso a editar e excluir.
class MovimentacaoSheet extends StatefulWidget {
  const MovimentacaoSheet({super.key, required this.insumo});

  final MateriaPrima insumo;

  @override
  State<MovimentacaoSheet> createState() => _MovimentacaoSheetState();
}

class _MovimentacaoSheetState extends State<MovimentacaoSheet> {
  final _form = GlobalKey<FormState>();
  final _quantidade = TextEditingController();
  String _tipo = 'entrada';
  bool _enviando = false;

  MateriaPrima get _insumo => widget.insumo;

  @override
  void dispose() {
    _quantidade.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final atualizado = await ApiClient.instance.registrarMovimentacao(
        _insumo.id,
        tipo: _tipo,
        quantidade: lerNumero(_quantidade.text)!,
      );
      if (!mounted) return;
      mostrarMensagem(
        context,
        '${_tipo == 'entrada' ? 'Entrada' : 'Saída'} registrada. '
        '${_insumo.nome}: ${formatarQuantidade(atualizado.qtdAtual)} ${atualizado.unidadeMedida}',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _editar() async {
    final navigator = Navigator.of(context);
    final salvou = await navigator.push<bool>(MaterialPageRoute(builder: (_) => InsumoFormScreen(insumo: _insumo)));
    if (salvou == true) navigator.pop(true);
  }

  Future<void> _excluir() async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir insumo?',
      mensagem: '"${_insumo.nome}" será removido do cadastro.',
      textoConfirmar: 'Excluir',
    );
    if (!ok || !mounted) return;
    setState(() => _enviando = true);
    try {
      await ApiClient.instance.removerMateriaPrima(_insumo.id);
      if (!mounted) return;
      mostrarMensagem(context, 'Insumo removido.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final un = _insumo.unidadeMedida;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Registrar movimentação', style: estiloTitulo(22)),
            const SizedBox(height: 4),
            Text(
              '${_insumo.nome} · atual ${formatarQuantidade(_insumo.qtdAtual)} $un',
              style: const TextStyle(color: Cores.textoSecundario),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'entrada', label: Text('Entrada'), icon: Icon(Icons.south_west_rounded)),
                ButtonSegment(value: 'saida', label: Text('Saída'), icon: Icon(Icons.north_east_rounded)),
              ],
              selected: {_tipo},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _quantidade,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Quantidade', suffixText: un),
              onFieldSubmitted: (_) => _registrar(),
              validator: (v) {
                final n = lerNumero(v ?? '');
                if (n == null || n <= 0) return 'Informe uma quantidade maior que zero';
                if (_tipo == 'saida' && n > _insumo.qtdAtual) {
                  return 'Saída maior que o estoque (${formatarQuantidade(_insumo.qtdAtual)} $un)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _enviando ? null : _registrar,
              child: Text(_tipo == 'entrada' ? 'Registrar entrada' : 'Registrar saída'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _enviando ? null : _editar,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _enviando ? null : _excluir,
                    style: TextButton.styleFrom(foregroundColor: Cores.primariaEscura),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Excluir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
