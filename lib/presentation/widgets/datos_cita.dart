import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/estado_cita.dart';
import '../../utils/formato.dart';

class FilaDuracionCita extends StatelessWidget {
  final int? minutos;

  const FilaDuracionCita({super.key, required this.minutos});

  @override
  Widget build(BuildContext context) {
    final duracion = minutos;
    if (duracion == null || duracion <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(
            Icons.timelapse_outlined,
            size: 15,
            color: TemaApp.grisSubtitulo,
          ),
          const SizedBox(width: 8),
          Text(
            'Tiempo estimado: ${formatearDuracion(duracion)}',
            style: const TextStyle(
              fontSize: 12.5,
              color: TemaApp.grisSubtitulo,
            ),
          ),
        ],
      ),
    );
  }
}

class FilaTiempoRestante extends StatefulWidget {
  final Map<String, dynamic> cita;

  const FilaTiempoRestante({super.key, required this.cita});

  @override
  State<FilaTiempoRestante> createState() => _FilaTiempoRestanteState();
}

class _FilaTiempoRestanteState extends State<FilaTiempoRestante> {
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texto = tiempoHastaCita(widget.cita);
    if (texto == null) return const SizedBox.shrink();

    final enCurso = clasificarCita(widget.cita) == EstadoCita.enCurso;
    final color = enCurso ? TemaApp.exito : TemaApp.info;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enCurso ? Icons.play_circle_outline : Icons.hourglass_bottom,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
