import 'package:flutter/material.dart';

import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/fotos_referencia.dart';
import 'visor_fotos.dart';

class BloqueReferencia extends StatelessWidget {
  final Map<String, dynamic> cita;
  final String titulo;

  const BloqueReferencia({
    super.key,
    required this.cita,
    this.titulo = 'Diseño de referencia',
  });

  @override
  Widget build(BuildContext context) {
    final fotos = fotosReferenciaDeCita(cita);
    if (fotos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TemaApp.grisClaro,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: TemaApp.grisSubtitulo,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var indice = 0; indice < fotos.length; indice++)
                  GestureDetector(
                    onTap: () => VisorFotos.abrir(
                      context,
                      fotos: fotos,
                      inicial: indice,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ServicioSubidaImagenes.miniatura(
                          fotos[indice],
                          ancho: 240,
                        ),
                        width: 74,
                        height: 74,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => Container(
                          width: 74,
                          height: 74,
                          color: TemaApp.grisBorde,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 20,
                            color: TemaApp.grisTexto,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SubirReferencia extends StatelessWidget {
  final List<String> fotos;
  final bool subiendo;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;

  const SubirReferencia({
    super.key,
    required this.fotos,
    required this.subiendo,
    required this.onAgregar,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final foto = fotos.isEmpty ? '' : fotos.first;
    final llena = foto.isNotEmpty;

    return Material(
      color: TemaApp.blanco,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: (subiendo || llena) ? null : onAgregar,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: llena ? TemaApp.grisBorde : TemaApp.negro,
              width: llena ? 1 : 1.4,
            ),
          ),
          child: Row(
            children: [
              _Recuadro(foto: foto, subiendo: subiendo),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subiendo
                          ? 'Subiendo tu foto...'
                          : llena
                          ? 'Listo, ya tiene tu referencia'
                          : 'Sube tu foto de referencia',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subiendo
                          ? 'Un momento'
                          : llena
                          ? 'La verá junto con tu solicitud'
                          : 'Tócalo y elígela de tu galería',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.3,
                        color: TemaApp.grisSubtitulo,
                      ),
                    ),
                  ],
                ),
              ),
              if (llena && !subiendo)
                IconButton(
                  tooltip: 'Quitar la foto',
                  onPressed: onQuitar,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Recuadro extends StatelessWidget {
  final String foto;
  final bool subiendo;

  const _Recuadro({required this.foto, required this.subiendo});

  @override
  Widget build(BuildContext context) {
    if (foto.isEmpty || subiendo) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: TemaApp.grisClaro,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: subiendo
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 24,
                  color: TemaApp.textoOscuro,
                ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        ServicioSubidaImagenes.miniatura(foto, ancho: 200),
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Container(
          width: 54,
          height: 54,
          color: TemaApp.grisBorde,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 20,
            color: TemaApp.grisTexto,
          ),
        ),
      ),
    );
  }
}
