import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../theme/app_theme.dart';

/// Etiqueta arredondada de status.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.texto, required this.fundo, required this.cor});

  /// Estoque crítico (quantidade <= mínimo) ou em dia.
  factory Pill.estoque({Key? key, required bool critico}) => critico
      ? Pill(key: key, texto: 'Estoque crítico', fundo: Cores.criticoFundo, cor: Cores.primariaEscura)
      : Pill(key: key, texto: 'Em dia', fundo: Cores.sucessoFundo, cor: Cores.sucesso);

  factory Pill.status({Key? key, required String statusApi}) {
    final (fundo, cor) = switch (StatusPedido.daApi(statusApi)) {
      StatusPedido.pendente => (const Color(0xFFFCE8C8), const Color(0xFF7A3E00)),
      StatusPedido.emProducao => (const Color(0xFFDCE8F7), const Color(0xFF1F4E8C)),
      StatusPedido.entregue => (Cores.sucessoFundo, Cores.sucesso),
      StatusPedido.cancelado || null => (Cores.trilho, Cores.textoSecundario),
    };
    return Pill(key: key, texto: StatusPedido.daApi(statusApi)?.rotulo ?? statusApi, fundo: fundo, cor: cor);
  }

  final String texto;
  final Color fundo;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(Raios.chip)),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3),
      ),
    );
  }
}
