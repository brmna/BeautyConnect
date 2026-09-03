import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'aviso.dart';

export 'aviso.dart' show TipoAviso;

void mostrarMensaje(
  BuildContext context,
  String texto, {
  TipoAviso tipo = TipoAviso.info,
  Duration duracion = const Duration(seconds: 3),
  SnackBarAction? accion,
}) {
  final mensajero = ScaffoldMessenger.maybeOf(context);
  if (mensajero == null) return;

  mensajero
    ..hideCurrentSnackBar()
    ..showSnackBar(
      construirMensaje(texto, tipo: tipo, duracion: duracion, accion: accion),
    );
}

void mostrarExito(BuildContext context, String texto) =>
    mostrarMensaje(context, texto, tipo: TipoAviso.exito);

void mostrarError(BuildContext context, String texto) =>
    mostrarMensaje(context, texto, tipo: TipoAviso.error);

SnackBar construirMensaje(
  String texto, {
  TipoAviso tipo = TipoAviso.info,
  Duration duracion = const Duration(seconds: 3),
  SnackBarAction? accion,
}) {
  return SnackBar(
    duration: duracion,
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    dismissDirection: DismissDirection.horizontal,
    content: _Burbuja(texto: texto, tipo: tipo, accion: accion),
  );
}

class _Burbuja extends StatelessWidget {
  final String texto;
  final TipoAviso tipo;
  final SnackBarAction? accion;

  const _Burbuja({required this.texto, required this.tipo, this.accion});

  Color get _acento => switch (tipo) {
    TipoAviso.info => TemaApp.info,
    TipoAviso.aviso => TemaApp.aviso,
    TipoAviso.exito => TemaApp.exito,
    TipoAviso.error => TemaApp.error,
  };

  IconData get _icono => switch (tipo) {
    TipoAviso.info => Icons.info_outline,
    TipoAviso.aviso => Icons.warning_amber_rounded,
    TipoAviso.exito => Icons.check_circle_outline,
    TipoAviso.error => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(6, 6, accion == null ? 16 : 6, 6),
      decoration: BoxDecoration(
        color: TemaApp.blanco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _acento.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: TemaApp.negro.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _acento.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icono, color: _acento, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontFamily: 'Gelasio',
                fontSize: 13.5,
                height: 1.35,
                color: TemaApp.textoOscuro,
              ),
            ),
          ),
          if (accion != null)
            TextButton(
              onPressed: accion!.onPressed,
              style: TextButton.styleFrom(foregroundColor: _acento),
              child: Text(
                accion!.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
