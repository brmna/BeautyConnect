import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class SelectorTipoUsuario extends StatelessWidget {
  final bool esProfesional;
  final ValueChanged<bool> onCambio;

  const SelectorTipoUsuario({
    super.key,
    required this.esProfesional,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Container(
      height: r.isMobile ? 44 : 48,
      decoration: BoxDecoration(
        color: TemaApp.grisClaro,
        borderRadius: BorderRadius.circular(50),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: esProfesional
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: TemaApp.blanco,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                _opcion(
                  etiqueta: 'Cliente',
                  seleccionada: !esProfesional,
                  onTap: () => onCambio(false),
                  r: r,
                ),
                _opcion(
                  etiqueta: 'Profesional',
                  seleccionada: esProfesional,
                  onTap: () => onCambio(true),
                  r: r,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcion({
    required String etiqueta,
    required bool seleccionada,
    required VoidCallback onTap,
    required Responsive r,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: seleccionada,
        label: etiqueta,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: r.isMobile ? 13 : 14,
                fontWeight: seleccionada ? FontWeight.w600 : FontWeight.w500,
                color: seleccionada
                    ? TemaApp.textoOscuro
                    : TemaApp.grisSubtitulo,
              ),
              child: Text(etiqueta),
            ),
          ),
        ),
      ),
    );
  }
}
