import 'package:flutter/material.dart';

import '../utils/formatos.dart';

/// Layout padrão das telas de cadastro: AppBar, campos e botão fixo no rodapé.
class TelaFormulario extends StatelessWidget {
  const TelaFormulario({
    super.key,
    required this.titulo,
    required this.formKey,
    required this.campos,
    required this.textoBotao,
    required this.onSalvar,
    this.enviando = false,
    this.acoes,
  });

  final String titulo;
  final GlobalKey<FormState> formKey;
  final List<Widget> campos;
  final String textoBotao;
  final VoidCallback onSalvar;
  final bool enviando;
  final List<Widget>? acoes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo), actions: acoes),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [for (final c in campos) Padding(padding: const EdgeInsets.only(bottom: 14), child: c)],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: enviando ? null : onSalvar,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: enviando
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(textoBotao),
          ),
        ),
      ),
    );
  }
}

FormFieldValidator<String> obrigatorio(String mensagem) =>
    (v) => (v == null || v.trim().isEmpty) ? mensagem : null;

String? numeroOpcionalNaoNegativo(String? v) {
  if (v == null || v.trim().isEmpty) return null;
  final n = lerNumero(v);
  if (n == null) return 'Número inválido';
  if (n < 0) return 'Não pode ser negativo';
  return null;
}
