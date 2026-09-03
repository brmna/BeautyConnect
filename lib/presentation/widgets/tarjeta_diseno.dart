import 'package:flutter/material.dart';

import '../../data/models/diseno.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import 'corazon_animado.dart';

class TarjetaDiseno extends StatelessWidget {
  final Diseno diseno;
  final bool esFavorito;
  final double alturaImagen;
  final VoidCallback onFavorito;
  final VoidCallback onTap;

  const TarjetaDiseno({
    super.key,
    required this.diseno,
    required this.esFavorito,
    required this.alturaImagen,
    required this.onFavorito,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tieneTitulo = diseno.titulo != null && diseno.titulo!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.network(
              ServicioSubidaImagenes.miniatura(
                diseno.imagenUrl,
                ancho: 500,
                cuadrada: false,
              ),
              height: alturaImagen,
              width: double.infinity,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              loadingBuilder: (contexto, hijo, progreso) {
                if (progreso == null) return hijo;
                return Container(
                  height: alturaImagen,
                  color: TemaApp.grisBorde,
                );
              },
              errorBuilder: (_, _, _) => Container(
                height: alturaImagen,
                color: TemaApp.grisBorde,
                child: const Icon(Icons.broken_image, color: TemaApp.grisTexto),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 26, 12, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tieneTitulo)
                      Text(
                        diseno.titulo!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            diseno.etiquetaPrincipal.isNotEmpty
                                ? diseno.etiquetaPrincipal
                                : diseno.profesionalNombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (diseno.favoritos > 0) ...[
                          const Icon(
                            Icons.favorite,
                            color: Colors.white70,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${diseno.favoritos}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: esFavorito ? 'Quitar de favoritos' : 'Guardar',
                child: GestureDetector(
                  onTap: onFavorito,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CorazonAnimado(activo: esFavorito, tamano: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
