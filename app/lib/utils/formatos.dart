/// Formatação no padrão brasileiro, sem depender do pacote intl.
library;

String _agruparMilhar(String inteiro) {
  final buffer = StringBuffer();
  for (var i = 0; i < inteiro.length; i++) {
    if (i > 0 && (inteiro.length - i) % 3 == 0) buffer.write('.');
    buffer.write(inteiro[i]);
  }
  return buffer.toString();
}

/// 1558 -> "R$ 1.558,00"
String formatarMoeda(num valor) {
  final negativo = valor < 0;
  final partes = valor.abs().toStringAsFixed(2).split('.');
  return '${negativo ? '-' : ''}R\$ ${_agruparMilhar(partes[0])},${partes[1]}';
}

/// 10.0 -> "10", 2.5 -> "2,5", 1500 -> "1.500"
String formatarQuantidade(num valor) {
  final negativo = valor < 0;
  var texto = valor.abs().toStringAsFixed(2);
  texto = texto.replaceFirst(RegExp(r'\.?0+$'), '');
  final partes = texto.split('.');
  final inteiro = _agruparMilhar(partes[0]);
  return '${negativo ? '-' : ''}$inteiro${partes.length > 1 ? ',${partes[1]}' : ''}';
}

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

/// DateTime -> "dd/MM"
String formatarDiaMes(DateTime data) => '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';

/// DateTime -> "dd/MM/aaaa"
String formatarDataCompleta(DateTime data) => '${formatarDiaMes(data)}/${data.year}';

/// DateTime -> "dd/MM às HH:mm"
String formatarDataHora(DateTime data) =>
    '${formatarDiaMes(data)} às ${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

/// DateTime -> "AAAA-MM-DD" (formato aceito pela API)
String formatarDataIso(DateTime data) => '${data.year}-${_doisDigitos(data.month)}-${_doisDigitos(data.day)}';

/// Lê "1.234,56", "1234,56" ou "1234.56" como número. Retorna null se inválido.
double? lerNumero(String texto) {
  var limpo = texto.trim().replaceAll(' ', '');
  if (limpo.isEmpty) return null;
  if (limpo.contains(',')) {
    limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(limpo);
}

/// Remove tudo que não é dígito.
String somenteDigitos(String texto) => texto.replaceAll(RegExp(r'\D'), '');

/// Encaixa os dígitos num padrão onde `#` é um dígito, ex.: '#####-###'.
/// Para quando os dígitos acabam (serve para formatar enquanto o usuário digita).
String aplicarPadrao(String digitos, String padrao) {
  final buffer = StringBuffer();
  var i = 0;
  for (final c in padrao.split('')) {
    if (i >= digitos.length) break;
    if (c == '#') {
      buffer.write(digitos[i++]);
    } else {
      buffer.write(c);
    }
  }
  return buffer.toString();
}

const padraoCpf = '###.###.###-##';
const padraoCnpj = '##.###.###/####-##';
const padraoCep = '#####-###';

String padraoDocumento(String digitos) => digitos.length <= 11 ? padraoCpf : padraoCnpj;

String padraoTelefone(String digitos) => digitos.length <= 10 ? '(##) ####-####' : '(##) #####-####';

/// "12345678000190" -> "12.345.678/0001-90"; "12345678901" -> "123.456.789-01".
String formatarDocumento(String? valor) {
  final d = somenteDigitos(valor ?? '');
  if (d.length != 11 && d.length != 14) return valor ?? '';
  return aplicarPadrao(d, padraoDocumento(d));
}

/// "54999991234" -> "(54) 99999-1234"; "5433110000" -> "(54) 3311-0000". Outros formatos ficam como estão.
String formatarTelefone(String? valor) {
  final d = somenteDigitos(valor ?? '');
  if (d.length != 10 && d.length != 11) return valor ?? '';
  return aplicarPadrao(d, padraoTelefone(d));
}

/// "99010040" -> "99010-040"
String formatarCep(String? valor) {
  final d = somenteDigitos(valor ?? '');
  if (d.length != 8) return valor ?? '';
  return aplicarPadrao(d, padraoCep);
}

/// Minúsculas e sem acentos, para busca.
String normalizarBusca(String texto) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final minusculo = texto.toLowerCase();
  final buffer = StringBuffer();
  for (final c in minusculo.split('')) {
    final i = de.indexOf(c);
    buffer.write(i >= 0 ? para[i] : c);
  }
  return buffer.toString();
}
