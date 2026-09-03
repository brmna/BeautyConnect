import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class BotonGoogle extends StatelessWidget {
  final String etiqueta;
  final bool cargando;
  final VoidCallback onPressed;

  const BotonGoogle({
    super.key,
    required this.etiqueta,
    required this.onPressed,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: cargando ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: TemaApp.grisBorde),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _LogoGoogle(),
                  const SizedBox(width: 12),
                  Text(
                    etiqueta,
                    style: const TextStyle(
                      color: TemaApp.textoOscuro,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _PintorG()),
    );
  }
}

class _PintorG extends CustomPainter {
  @override
  void paint(Canvas lienzo, Size medida) {
    final centro = Offset(medida.width / 2, medida.height / 2);
    final radio = medida.width / 2;
    final grosor = medida.width * 0.22;

    final arco = Rect.fromCircle(center: centro, radius: radio - grosor / 2);

    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;

    const tramos = [
      (-0.35, 1.05, Color(0xFF4285F4)),
      (0.70, 1.20, Color(0xFF34A853)),
      (1.90, 1.25, Color(0xFFFBBC05)),
      (3.15, 1.20, Color(0xFFEA4335)),
    ];

    for (final (inicio, barrido, color) in tramos) {
      lienzo.drawArc(arco, inicio, barrido, false, pincel..color = color);
    }

    lienzo.drawLine(
      Offset(centro.dx, centro.dy),
      Offset(medida.width, centro.dy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = grosor,
    );
  }

  @override
  bool shouldRepaint(_PintorG anterior) => false;
}
