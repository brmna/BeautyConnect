import 'package:flutter/material.dart';

class EtiquetaChip extends StatelessWidget {
  final String texto;
  final bool activo;
  final double tamano;

  const EtiquetaChip({
    super.key,
    required this.texto,
    required this.activo,
    this.tamano = 12.5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0,
          child: Text(
            texto,
            style: TextStyle(fontSize: tamano, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          texto,
          style: TextStyle(
            fontSize: tamano,
            fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
