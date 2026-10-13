import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Linha rolável de chips de escolha única.
class ChipsFiltro<T> extends StatelessWidget {
  const ChipsFiltro({super.key, required this.opcoes, required this.selecionado, required this.onSelecionar});

  /// (valor, rótulo)
  final List<(T, String)> opcoes;
  final T selecionado;
  final ValueChanged<T> onSelecionar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final (valor, rotulo) in opcoes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(rotulo),
                selected: valor == selecionado,
                onSelected: (_) => onSelecionar(valor),
                labelStyle: TextStyle(
                  color: valor == selecionado ? Colors.white : Cores.texto,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
