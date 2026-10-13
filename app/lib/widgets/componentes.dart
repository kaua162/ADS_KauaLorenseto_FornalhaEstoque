import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Título grande + subtítulo no topo de cada aba.
class CabecalhoTela extends StatelessWidget {
  const CabecalhoTela({super.key, required this.titulo, this.subtitulo, this.acao});

  final String titulo;
  final String? subtitulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: estiloTitulo(28)),
                if (subtitulo != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitulo!, style: const TextStyle(color: Cores.textoSecundario, fontSize: 15)),
                ],
              ],
            ),
          ),
          ?acao,
        ],
      ),
    );
  }
}

/// Card branco padrão (borda #E4E0DA, raio 16) com área de toque opcional.
class CardBase extends StatelessWidget {
  const CardBase({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Card escuro de destaque (#1F1B18).
class CardEscuro extends StatelessWidget {
  const CardEscuro({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Cores.cardEscuro, borderRadius: BorderRadius.circular(Raios.card)),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }
}

/// Espaçamento lateral padrão das listas.
class Margem extends StatelessWidget {
  const Margem({super.key, required this.child, this.vertical = 6});

  final Widget child;
  final double vertical;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: vertical),
    child: child,
  );
}

/// Logo: arco de forno vermelho com chama.
class LogoFornalha extends StatelessWidget {
  const LogoFornalha({super.key, this.tamanho = 96});

  final double tamanho;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: tamanho,
    child: CustomPaint(painter: _LogoPainter()),
  );
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final traco = w * 0.11;

    // Arco do forno
    final arco = Paint()
      ..color = Cores.primaria
      ..style = PaintingStyle.stroke
      ..strokeWidth = traco
      ..strokeCap = StrokeCap.round;
    final raio = w / 2 - traco / 2;
    final centro = Offset(w / 2, h * 0.62);
    canvas.drawArc(Rect.fromCircle(center: centro, radius: raio), math.pi, math.pi, false, arco);
    canvas.drawLine(Offset(traco / 2, centro.dy), Offset(traco / 2, h * 0.9), arco);
    canvas.drawLine(Offset(w - traco / 2, centro.dy), Offset(w - traco / 2, h * 0.9), arco);

    // Base
    final base = Paint()
      ..color = Cores.primariaEscura
      ..strokeWidth = traco * 0.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(traco / 2, h * 0.94), Offset(w - traco / 2, h * 0.94), base);

    // Chama
    final chama = Path()
      ..moveTo(w * 0.5, h * 0.38)
      ..cubicTo(w * 0.62, h * 0.52, w * 0.66, h * 0.62, w * 0.62, h * 0.74)
      ..cubicTo(w * 0.58, h * 0.84, w * 0.42, h * 0.84, w * 0.38, h * 0.74)
      ..cubicTo(w * 0.35, h * 0.65, w * 0.42, h * 0.6, w * 0.45, h * 0.52)
      ..cubicTo(w * 0.47, h * 0.58, w * 0.5, h * 0.6, w * 0.52, h * 0.58)
      ..cubicTo(w * 0.54, h * 0.5, w * 0.52, h * 0.44, w * 0.5, h * 0.38)
      ..close();
    canvas.drawPath(chama, Paint()..color = const Color(0xFFE8892B));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
