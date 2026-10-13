import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/componentes.dart';
import '../widgets/estados.dart';
import 'mercado_detalhe_screen.dart';
import 'mercado_form_screen.dart';

/// RF06 - HU07: mercados parceiros.
class MercadosScreen extends StatefulWidget {
  const MercadosScreen({super.key, this.barra});

  /// Barra de navegação inferior (vem da HomeScreen).
  final Widget? barra;

  @override
  State<MercadosScreen> createState() => _MercadosScreenState();
}

class _MercadosScreenState extends State<MercadosScreen> {
  final _busca = TextEditingController();
  Future<List<MercadoParceiro>>? _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = ApiClient.instance.listarMercados();
  }

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  Future<void> _recarregar() async {
    final futuro = ApiClient.instance.listarMercados();
    setState(() {
      _futuro = futuro;
    });
    await futuro.then((_) {}, onError: (_) {});
  }

  /// Busca por nome (sem diferenciar acentos/maiúsculas) ou por dígitos do CNPJ/CPF.
  List<MercadoParceiro> _filtrar(List<MercadoParceiro> mercados) {
    final termo = normalizarBusca(_busca.text.trim());
    if (termo.isEmpty) return mercados;
    final digitos = somenteDigitos(termo);
    return [
      for (final m in mercados)
        if (normalizarBusca(m.nome).contains(termo) || (digitos.isNotEmpty && m.cnpjCpf.contains(digitos))) m,
    ];
  }

  Future<void> _novo() async {
    final criado = await Navigator.push<MercadoParceiro>(
      context,
      MaterialPageRoute(builder: (_) => const MercadoFormScreen()),
    );
    if (criado != null) _recarregar();
  }

  Future<void> _abrir(MercadoParceiro m) async {
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MercadoDetalheScreen(idMercado: m.id)),
    );
    if (alterou == true) _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.barra,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Novo mercado'),
      ),
      body: FutureBuilder<List<MercadoParceiro>>(
        future: _futuro,
        builder: (context, snap) {
          final total = snap.data?.length;
          return ConteudoAssincrono<List<MercadoParceiro>>(
            future: _futuro,
            onRecarregar: _recarregar,
            cabecalho: [
              CabecalhoTela(
                titulo: 'Mercados parceiros',
                subtitulo: total == null
                    ? 'Clientes da revenda de pizzas'
                    : '$total ${total == 1 ? 'mercado cadastrado' : 'mercados cadastrados'}',
              ),
              Margem(
                vertical: 0,
                child: TextField(
                  controller: _busca,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou CNPJ/CPF',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _busca.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(_busca.clear),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            construir: (mercados) {
              if (mercados.isEmpty) {
                return const [
                  EstadoVazio(
                    icone: Icons.storefront_outlined,
                    titulo: 'Nenhum mercado cadastrado',
                    mensagem: 'Toque em "Novo mercado" para cadastrar o primeiro.',
                  ),
                ];
              }
              final visiveis = _filtrar(mercados);
              if (visiveis.isEmpty) {
                return [
                  EstadoVazio(
                    icone: Icons.search_off_rounded,
                    titulo: 'Nenhum mercado encontrado',
                    mensagem: 'Nada corresponde a "${_busca.text.trim()}".',
                  ),
                ];
              }
              return [
                for (final m in visiveis)
                  Margem(
                    child: _CardMercado(mercado: m, onTap: () => _abrir(m)),
                  ),
              ];
            },
          );
        },
      ),
    );
  }
}

class _CardMercado extends StatelessWidget {
  const _CardMercado({required this.mercado, required this.onTap});

  final MercadoParceiro mercado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const secundario = TextStyle(color: Cores.textoSecundario, fontSize: 13.5);
    final local = mercado.cidadeUf;
    final telefone = mercado.telefone;
    return CardBase(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mercado.nome,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Cores.textoSecundario),
            ],
          ),
          const SizedBox(height: 2),
          Text(formatarDocumento(mercado.cnpjCpf), style: secundario),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Info(icone: Icons.place_outlined, texto: local ?? 'Cidade não informada', apagado: local == null),
              _Info(
                icone: Icons.phone_outlined,
                texto: telefone == null ? 'Sem telefone' : formatarTelefone(telefone),
                apagado: telefone == null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icone, required this.texto, this.apagado = false});

  final IconData icone;
  final String texto;
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final cor = apagado ? Cores.bordaInput : Cores.textoSecundario;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 16, color: cor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(texto, style: TextStyle(color: apagado ? Cores.textoSecundario : Cores.texto, fontSize: 13.5)),
        ),
      ],
    );
  }
}
