import 'package:flutter/services.dart';

import 'formatos.dart';

/// Máscara de digitação: aceita só dígitos e formata conforme o padrão.
///
/// O cursor vai para o fim do texto a cada alteração (simples e suficiente
/// para campos curtos como CPF, telefone e CEP).
class MascaraDigitos extends TextInputFormatter {
  MascaraDigitos({required this.maxDigitos, required this.padrao});

  /// CPF (até 11 dígitos) ou CNPJ (14), decidido pela quantidade digitada.
  factory MascaraDigitos.documento() => MascaraDigitos(maxDigitos: 14, padrao: padraoDocumento);

  /// (00) 0000-0000 ou (00) 00000-0000.
  factory MascaraDigitos.telefone() => MascaraDigitos(maxDigitos: 11, padrao: padraoTelefone);

  factory MascaraDigitos.cep() => MascaraDigitos(maxDigitos: 8, padrao: (_) => padraoCep);

  final int maxDigitos;
  final String Function(String digitos) padrao;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digitos = somenteDigitos(newValue.text);
    // Apagou só um separador (".", "-", "/")? Apaga também o dígito anterior,
    // senão a máscara recolocaria o separador e o backspace pareceria travado.
    final apagou = newValue.text.length < oldValue.text.length;
    if (apagou && digitos == somenteDigitos(oldValue.text)) {
      var i = 0; // posição do caractere apagado
      while (i < newValue.text.length && newValue.text[i] == oldValue.text[i]) {
        i++;
      }
      final digitosAntes = somenteDigitos(oldValue.text.substring(0, i)).length;
      if (digitosAntes > 0) {
        digitos = digitos.substring(0, digitosAntes - 1) + digitos.substring(digitosAntes);
      }
    }
    if (digitos.length > maxDigitos) digitos = digitos.substring(0, maxDigitos);
    final texto = aplicarPadrao(digitos, padrao(digitos));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
