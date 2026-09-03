import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum EstiloCabecera { destacada, clara }

class CabeceraPantalla extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData? icono;
  final EstiloCabecera estilo;
  final Widget? accion;

  const CabeceraPantalla({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.icono,
    this.estilo = EstiloCabecera.clara,
    this.accion,
  });

  bool get _esRosa => estilo == EstiloCabecera.destacada;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: _esRosa
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7F7F7), Color(0xFFEFEFEF)],
              )
            : null,
        color: _esRosa ? null : TemaApp.blanco,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icono != null) ...[
                        Icon(icono, size: 20, color: TemaApp.textoOscuro),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
                ],
              ),
            ),
            ?accion,
          ],
        ),
      ),
    );
  }
}

class PestanasPildora extends StatelessWidget {
  final List<String> etiquetas;
  final int seleccionada;
  final ValueChanged<int> onCambio;

  const PestanasPildora({
    super.key,
    required this.etiquetas,
    required this.seleccionada,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TemaApp.blanco,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: List.generate(etiquetas.length, (indice) {
          final activa = indice == seleccionada;

          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onCambio(indice),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: activa ? TemaApp.negro : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  etiquetas[indice],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
                    color: activa ? TemaApp.blanco : TemaApp.grisSubtitulo,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
