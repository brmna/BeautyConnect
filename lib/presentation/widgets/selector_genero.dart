import 'package:flutter/material.dart';

import 'etiqueta_chip.dart';
import '../../theme/app_theme.dart';
import '../../utils/genero.dart';

class SelectorGenero extends StatelessWidget {
  final Genero valor;
  final ValueChanged<Genero> onCambio;

  const SelectorGenero({
    super.key,
    required this.valor,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cómo prefieres que te nombremos',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        const Text(
          'Solo se usa para escribir bien los textos de la app',
          style: TextStyle(fontSize: 11.5, color: TemaApp.grisSubtitulo),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Genero.values.map((genero) {
            final activo = genero == valor;

            return ChoiceChip(
              label: EtiquetaChip(
                texto: etiquetaGenero(genero),
                activo: activo,
              ),
              selected: activo,
              showCheckmark: false,
              onSelected: (_) => onCambio(genero),
              labelStyle: TextStyle(
                color: activo ? TemaApp.blanco : TemaApp.textoOscuro,
              ),
              selectedColor: TemaApp.negro,
              backgroundColor: TemaApp.blanco,
              side: const BorderSide(color: TemaApp.grisBorde),
            );
          }).toList(),
        ),
      ],
    );
  }
}
