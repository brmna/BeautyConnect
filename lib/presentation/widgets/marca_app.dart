import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class MarcaBeautyConnect extends StatelessWidget {
  final double tamano;
  final Color color;

  const MarcaBeautyConnect({
    super.key,
    this.tamano = 64,
    this.color = TemaApp.blanco,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamano,
      height: tamano,
      child: CustomPaint(painter: _PintorMarca(color: color)),
    );
  }
}

class _PintorMarca extends CustomPainter {
  final Color color;

  const _PintorMarca({required this.color});

  @override
  void paint(Canvas lienzo, Size medida) {
    final lado = medida.shortestSide;
    final pincel = Paint()..color = color;

    final cx = lado / 2 - lado * 0.045;
    final cy = lado / 2 + lado * 0.025;
    final alto = lado * 0.58;

    _frasco(lienzo, pincel, cx, cy, alto);

    _destello(
      lienzo,
      pincel,
      cx + lado * 0.225,
      cy - lado * 0.185,
      lado * 0.10,
    );
    _destello(
      lienzo,
      Paint()..color = color.withValues(alpha: color.a * 0.9),
      cx + lado * 0.285,
      cy - lado * 0.015,
      lado * 0.052,
    );
  }

  void _frasco(Canvas lienzo, Paint pincel, double cx, double cy, double alto) {
    final anchoCuerpo = alto * 0.58;
    final altoCuerpo = alto * 0.50;
    final anchoTapa = alto * 0.27;
    final altoTapa = alto * 0.34;
    final altoCuello = alto * 0.10;

    final arriba = cy - alto / 2;

    lienzo.drawRRect(
      RRect.fromLTRBR(
        cx - anchoTapa / 2,
        arriba,
        cx + anchoTapa / 2,
        arriba + altoTapa,
        Radius.circular(anchoTapa * 0.36),
      ),
      pincel,
    );

    lienzo.drawRect(
      Rect.fromLTRB(
        cx - anchoTapa * 0.20,
        arriba + altoTapa,
        cx + anchoTapa * 0.20,
        arriba + altoTapa + altoCuello,
      ),
      pincel,
    );

    final cuerpoArriba = arriba + altoTapa + altoCuello;
    lienzo.drawRRect(
      RRect.fromLTRBR(
        cx - anchoCuerpo / 2,
        cuerpoArriba,
        cx + anchoCuerpo / 2,
        cuerpoArriba + altoCuerpo,
        Radius.circular(anchoCuerpo * 0.24),
      ),
      pincel,
    );
  }

  void _destello(
    Canvas lienzo,
    Paint pincel,
    double cx,
    double cy,
    double radio,
  ) {
    final ancho = radio * 0.24;

    final trazo = Path()
      ..moveTo(cx, cy - radio)
      ..lineTo(cx + ancho, cy - ancho)
      ..lineTo(cx + radio, cy)
      ..lineTo(cx + ancho, cy + ancho)
      ..lineTo(cx, cy + radio)
      ..lineTo(cx - ancho, cy + ancho)
      ..lineTo(cx - radio, cy)
      ..lineTo(cx - ancho, cy - ancho)
      ..close();

    lienzo.drawPath(trazo, pincel);
  }

  @override
  bool shouldRepaint(_PintorMarca anterior) => anterior.color != color;
}

class PantallaCargando extends StatefulWidget {
  final String? mensaje;

  const PantallaCargando({super.key, this.mensaje});

  @override
  State<PantallaCargando> createState() => _PantallaCargandoState();
}

class _PantallaCargandoState extends State<PantallaCargando>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _respiracion = Tween<double>(
    begin: 0.92,
    end: 1.06,
  ).animate(CurvedAnimation(parent: _control, curve: Curves.easeInOut));

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B2B2B), Color(0xFF0F0F0F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _respiracion,
                child: const MarcaBeautyConnect(tamano: 108),
              ),
              const SizedBox(height: 10),
              const Text(
                'BeautyConnect',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: TemaApp.blanco,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.mensaje ?? 'Manicuristas de Villavicencio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: TemaApp.blanco.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: TemaApp.blanco.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(TemaApp.blanco),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
