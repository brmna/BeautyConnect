import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class Estrellas extends StatelessWidget {
  final double calificacion;
  final double tamano;
  final Color color;

  const Estrellas({
    super.key,
    required this.calificacion,
    this.tamano = 16,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (indice) {
        final valor = indice + 1;
        final llena = calificacion >= valor;
        final media = !llena && calificacion > indice;

        return Icon(
          llena
              ? Icons.star
              : media
              ? Icons.star_half
              : Icons.star_border,
          size: tamano,
          color: llena || media ? color : TemaApp.grisBorde,
        );
      }),
    );
  }
}

class SelectorEstrellas extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onCambio;

  const SelectorEstrellas({
    super.key,
    required this.valor,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (indice) {
        final estrella = indice + 1;

        return IconButton(
          onPressed: () => onCambio(estrella),
          iconSize: 40,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          icon: Icon(
            valor >= estrella ? Icons.star : Icons.star_border,
            color: valor >= estrella ? Colors.amber : TemaApp.grisBorde,
          ),
        );
      }),
    );
  }
}
