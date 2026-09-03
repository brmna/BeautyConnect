import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum TipoAviso { info, aviso, exito, error }

class Aviso extends StatelessWidget {
  final TipoAviso tipo;
  final IconData icono;
  final String titulo;
  final String? detalle;
  final Widget? accion;
  final VoidCallback? onCerrar;

  const Aviso({
    super.key,
    this.tipo = TipoAviso.info,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.accion,
    this.onCerrar,
  });

  Color get _fondo => switch (tipo) {
    TipoAviso.info => TemaApp.infoSuave,
    TipoAviso.aviso => TemaApp.avisoSuave,
    TipoAviso.exito => TemaApp.exitoSuave,
    TipoAviso.error => TemaApp.errorSuave,
  };

  Color get _acento => switch (tipo) {
    TipoAviso.info => TemaApp.info,
    TipoAviso.aviso => TemaApp.aviso,
    TipoAviso.exito => TemaApp.exito,
    TipoAviso.error => TemaApp.error,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: _fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _acento.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icono, color: _acento, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _acento,
                  ),
                ),
                if (detalle != null)
                  Text(
                    detalle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
              ],
            ),
          ),
          ?accion,
          if (onCerrar != null)
            IconButton(
              tooltip: 'Ocultar',
              icon: Icon(Icons.close, size: 17, color: _acento),
              visualDensity: VisualDensity.compact,
              onPressed: onCerrar,
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}
