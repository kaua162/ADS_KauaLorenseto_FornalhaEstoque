import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra horizontal proporcional (0 a 1) sobre o trilho cinza.
class BarraNivel extends StatelessWidget {
  const BarraNivel({super.key, required this.fracao, required this.cor, this.altura = 8});

  final double fracao;
  final Color cor;
  final double altura;

  @override
  Widget build(BuildContext context) {
    final valor = fracao.isNaN ? 0.0 : fracao.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(altura),
      child: Container(
        height: altura,
        color: Cores.trilho,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: valor,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(altura)),
          ),
        ),
      ),
    );
  }
}
