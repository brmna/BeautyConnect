import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const double _separacion = 10;

class RejillaOpciones extends StatelessWidget {
  final List<Widget> hijos;
  final double anchoMinimo;

  const RejillaOpciones({
    super.key,
    required this.hijos,
    this.anchoMinimo = 100,
  });

  int _columnas(double disponible) {
    final caben = ((disponible + _separacion) / (anchoMinimo + _separacion))
        .floor();
    return caben.clamp(2, 4);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, medidas) {
        final columnas = _columnas(medidas.maxWidth);
        final ancho =
            (medidas.maxWidth - _separacion * (columnas - 1)) / columnas;

        return Wrap(
          spacing: _separacion,
          runSpacing: _separacion,
          children: hijos
              .map((hijo) => SizedBox(width: ancho, child: hijo))
              .toList(),
        );
      },
    );
  }
}

class CeldaOpcion extends StatelessWidget {
  final String etiqueta;
  final bool activa;
  final VoidCallback onTocar;

  const CeldaOpcion({
    super.key,
    required this.etiqueta,
    required this.activa,
    required this.onTocar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: activa ? TemaApp.negro : TemaApp.blanco,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activa ? TemaApp.negro : TemaApp.grisBorde),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            etiqueta,
            maxLines: 1,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: activa ? TemaApp.blanco : TemaApp.textoOscuro,
            ),
          ),
        ),
      ),
    );
  }
}
