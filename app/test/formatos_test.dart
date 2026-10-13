import 'package:fornalha_app/utils/formatos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moeda no padrão brasileiro', () {
    expect(formatarMoeda(1558), 'R\$ 1.558,00');
    expect(formatarMoeda(0), 'R\$ 0,00');
    expect(formatarMoeda(25.5), 'R\$ 25,50');
    expect(formatarMoeda(1234567.891), 'R\$ 1.234.567,89');
    expect(formatarMoeda(-12.3), '-R\$ 12,30');
  });

  test('quantidade sem zeros sobrando', () {
    expect(formatarQuantidade(10.0), '10');
    expect(formatarQuantidade(2.5), '2,5');
    expect(formatarQuantidade(0.25), '0,25');
    expect(formatarQuantidade(1500), '1.500');
  });

  test('datas', () {
    final d = DateTime(2026, 3, 7, 9, 5);
    expect(formatarDiaMes(d), '07/03');
    expect(formatarDataCompleta(d), '07/03/2026');
    expect(formatarDataHora(d), '07/03 às 09:05');
    expect(formatarDataIso(d), '2026-03-07');
    expect(formatarDiaMes(DateTime.parse('2026-10-09T05:04:13.777660')), '09/10');
  });

  test('leitura de números digitados', () {
    expect(lerNumero('1.234,56'), 1234.56);
    expect(lerNumero('2,5'), 2.5);
    expect(lerNumero('2.5'), 2.5);
    expect(lerNumero(' 10 '), 10);
    expect(lerNumero(''), isNull);
    expect(lerNumero('abc'), isNull);
  });
}
