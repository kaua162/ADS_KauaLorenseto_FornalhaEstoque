import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Carregando extends StatelessWidget {
  const Carregando({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),
  );
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.icone, required this.titulo, this.mensagem});

  final IconData icone;
  final String titulo;
  final String? mensagem;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 48, color: Cores.bordaInput),
          const SizedBox(height: 12),
          Text(titulo, style: estiloTitulo(18), textAlign: TextAlign.center),
          if (mensagem != null) ...[
            const SizedBox(height: 6),
            Text(
              mensagem!,
              style: const TextStyle(color: Cores.textoSecundario),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class EstadoErro extends StatelessWidget {
  const EstadoErro({super.key, required this.mensagem, required this.onTentarNovamente});

  final String mensagem;
  final VoidCallback onTentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Cores.primaria),
          const SizedBox(height: 12),
          Text(mensagem, style: const TextStyle(fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onTentarNovamente,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

/// Mostra carregando / erro com "Tentar novamente" / conteúdo para um Future.
///
/// O conteúdo fica dentro de um ListView com "puxar para atualizar".
class ConteudoAssincrono<T> extends StatelessWidget {
  const ConteudoAssincrono({
    super.key,
    required this.future,
    required this.onRecarregar,
    required this.construir,
    this.cabecalho = const [],
    this.paddingInferior = 96,
  });

  final Future<T>? future;
  final Future<void> Function() onRecarregar;

  /// Widgets da lista quando os dados chegam.
  final List<Widget> Function(T dados) construir;

  /// Widgets fixos no topo da lista (título, filtros), mostrados também em loading/erro.
  final List<Widget> cabecalho;

  /// Espaço para não ficar atrás do botão flutuante.
  final double paddingInferior;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        final List<Widget> corpo;
        if (snap.connectionState != ConnectionState.done) {
          corpo = const [Carregando()];
        } else if (snap.hasError) {
          corpo = [EstadoErro(mensagem: snap.error.toString(), onTentarNovamente: onRecarregar)];
        } else {
          corpo = construir(snap.data as T);
        }
        return RefreshIndicator(
          onRefresh: onRecarregar,
          color: Cores.primaria,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Respeita a barra de status (as abas não têm AppBar).
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top, bottom: paddingInferior),
            children: [...cabecalho, ...corpo],
          ),
        );
      },
    );
  }
}
