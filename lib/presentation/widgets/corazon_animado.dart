import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CorazonAnimado extends StatefulWidget {
  final bool activo;
  final double tamano;
  final Color colorInactivo;

  const CorazonAnimado({
    super.key,
    required this.activo,
    this.tamano = 20,
    this.colorInactivo = TemaApp.textoOscuro,
  });

  @override
  State<CorazonAnimado> createState() => _CorazonAnimadoState();
}

class _CorazonAnimadoState extends State<CorazonAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  late final Animation<double> _escala = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1), weight: 60),
  ]).animate(CurvedAnimation(parent: _control, curve: Curves.easeOut));

  @override
  void didUpdateWidget(CorazonAnimado anterior) {
    super.didUpdateWidget(anterior);
    if (widget.activo && !anterior.activo) _control.forward(from: 0);
  }

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _escala,
      child: Icon(
        widget.activo ? Icons.favorite : Icons.favorite_border,
        size: widget.tamano,
        color: widget.activo ? TemaApp.rosa : widget.colorInactivo,
      ),
    );
  }
}
