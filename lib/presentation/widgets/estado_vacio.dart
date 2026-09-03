import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final String? accion;
  final VoidCallback? onAccion;
  final bool compacto;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
    this.onAccion,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final tieneBoton = accion != null && onAccion != null;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: compacto ? 24 : 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: compacto ? 44 : 56, color: TemaApp.grisTexto),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compacto ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: TemaApp.grisSubtitulo,
              ),
            ),
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: TemaApp.grisTexto,
                ),
              ),
            ],
            if (tieneBoton) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onAccion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: Text(accion!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
