import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import 'producao_screen.dart';
import 'sabor_form_screen.dart';

/// Sabor do cadastro (preço) + saldo em estoque (resumo).
class SaborComEstoque {
  const SaborComEstoque(this.sabor, this.quantidade, this.loteMaisAntigo);

  final PizzaSabor sabor;
  final int quantidade;
  final DateTime? loteMaisAntigo;
}

/// Junta GET /pizza-sabor (preço) com GET /estoque-pizza/resumo (saldo e lote mais antigo).
Future<List<SaborComEstoque>> carregarSaboresComEstoque() async {
  final api = ApiClient.instance;
  final (sabores, resumo) = await (api.listarSabores(), api.resumoEstoquePizza()).wait;
  final saldo = {for (final s in resumo) s.idSabor: s};
  return [
    for (final s in sabores)
      SaborComEstoque(s, saldo[s.id]?.quantidadeDisponivel ?? 0, saldo[s.id]?.dataLoteMaisAntigo),
  ];
}

/// RF05 - Pizzas congeladas: estoque por sabor.
class PizzasScreen extends StatefulWidget {
  const PizzasScreen({super.key, this.barra});

  /// Barra de navegação inferior (vem da HomeScreen).
  final Widget? barra;

  @override
  State<PizzasScreen> createState() => _PizzasScreenState();
}

class _PizzasScreenState extends State<PizzasScreen> {
  Future<List<SaborComEstoque>>? _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = carregarSaboresComEstoque();
  }

  Future<void> _recarregar() async {
    final futuro = carregarSaboresComEstoque();
    setState(() {
      _futuro = futuro;
    });
    await futuro.catchError((_) => <SaborComEstoque>[]);
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
        onPressed: () => _abrir(const SaborFormScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo sabor'),
      ),
      body: ConteudoAssincrono<List<SaborComEstoque>>(
        future: _futuro,
        onRecarregar: _recarregar,
        cabecalho: const [CabecalhoTela(titulo: 'Pizzas congeladas', subtitulo: 'Estoque por sabor')],
        construir: (itens) {
          final total = itens.fold<int>(0, (soma, i) => soma + i.quantidade);
          return [
            Margem(
              child: CardEscuro(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total em estoque', style: TextStyle(color: Color(0xFFBFB7AF), fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$total', style: estiloTitulo(40, cor: Colors.white)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(total == 1 ? 'pizza' : 'pizzas', style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: itens.isEmpty ? null : () => _abrir(const ProducaoScreen()),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Registrar produção'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (itens.isEmpty)
              const EstadoVazio(
                icone: Icons.local_pizza_outlined,
                titulo: 'Nenhum sabor cadastrado',
                mensagem: 'Cadastre um sabor para registrar a produção.',
              )
            else
              for (final i in itens)
                Margem(
                  child: _CardSabor(
                    item: i,
                    onTap: () => _abrir(SaborFormScreen(sabor: i.sabor)),
                  ),
                ),
          ];
        },
      ),
    );
  }
}

class _CardSabor extends StatelessWidget {
  const _CardSabor({required this.item, required this.onTap});

  final SaborComEstoque item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semEstoque = item.quantidade == 0;
    return CardBase(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.sabor.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  formatarMoeda(item.sabor.precoUnitario),
                  style: const TextStyle(color: Cores.primaria, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  item.loteMaisAntigo == null
                      ? 'Sem lotes em estoque'
                      : 'Lote mais antigo: ${formatarDiaMes(item.loteMaisAntigo!)}',
                  style: const TextStyle(color: Cores.textoSecundario, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantidade}',
                style: estiloTitulo(30, cor: semEstoque ? Cores.textoSecundario : Cores.texto),
              ),
              const Text('em estoque', style: TextStyle(color: Cores.textoSecundario, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
