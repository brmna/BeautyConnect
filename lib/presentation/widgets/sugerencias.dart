import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class Sugerencia {
  final IconData icono;
  final String titulo;
  final String detalle;
  final String accion;
  final Color acento;
  final VoidCallback onTocar;

  const Sugerencia({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.accion,
    required this.acento,
    required this.onTocar,
  });
}

class CarruselSugerencias extends StatelessWidget {
  final List<Sugerencia> sugerencias;

  const CarruselSugerencias({super.key, required this.sugerencias});

  @override
  Widget build(BuildContext context) {
    if (sugerencias.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 17),
              SizedBox(width: 7),
              Text(
                'Para ti',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: sugerencias.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, indice) =>
                _TarjetaSugerencia(sugerencia: sugerencias[indice]),
          ),
        ),
      ],
    );
  }
}

class _TarjetaSugerencia extends StatelessWidget {
  final Sugerencia sugerencia;

  const _TarjetaSugerencia({required this.sugerencia});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 232,
      child: Material(
        color: TemaApp.blanco,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: sugerencia.onTocar,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: sugerencia.acento.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: sugerencia.acento.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    sugerencia.icono,
                    size: 19,
                    color: sugerencia.acento,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  sugerencia.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 3),
                Expanded(
                  child: Text(
                    sugerencia.detalle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      sugerencia.accion,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sugerencia.acento,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward,
                      size: 13,
                      color: sugerencia.acento,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
