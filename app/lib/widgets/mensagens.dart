import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';

void mostrarMensagem(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Mostra a mensagem de erro da API ({"erro": ...}) ou de conexão.
void mostrarErro(BuildContext context, Object erro) {
  final texto = erro is ApiException ? erro.mensagem : 'Algo deu errado. Tente novamente.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: Cores.primariaEscura,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
}

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo, style: estiloTitulo(20)),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: TextButton.styleFrom(foregroundColor: Cores.textoSecundario),
          child: const Text('Voltar'),
        ),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(textoConfirmar)),
      ],
    ),
  );
  return resposta ?? false;
}
