import 'package:flutter/material.dart';

import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';

String textoServicio(Object? valor) => (valor as String?)?.trim() ?? '';

String nombreServicio(Map<String, dynamic> servicio) {
  final nombre = textoServicio(servicio['name']);
  return nombre.isEmpty ? 'Servicio' : nombre;
}

class MiniaturaServicio extends StatelessWidget {
  final String foto;
  final double lado;

  const MiniaturaServicio({super.key, required this.foto, this.lado = 56});

  @override
  Widget build(BuildContext context) {
    final vacia = Container(
      color: TemaApp.grisClaro,
      alignment: Alignment.center,
      child: Icon(
        Icons.spa_outlined,
        color: TemaApp.grisTexto,
        size: lado / 2.6,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: lado,
        height: lado,
        child: foto.isEmpty
            ? vacia
            : Image.network(
                ServicioSubidaImagenes.miniatura(
                  foto,
                  ancho: (lado * 3).round(),
                ),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => vacia,
              ),
      ),
    );
  }
}

class DatoServicio extends StatelessWidget {
  final IconData icono;
  final String texto;

  const DatoServicio({super.key, required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 13, color: TemaApp.grisTexto),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
          ),
        ),
      ],
    );
  }
}

class PrecioServicio extends StatelessWidget {
  final num? precio;

  const PrecioServicio({super.key, required this.precio});

  @override
  Widget build(BuildContext context) {
    return Text(
      formatearPrecio(precio),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: TemaApp.textoOscuro,
      ),
    );
  }
}

class TarjetaServicio extends StatelessWidget {
  final Map<String, dynamic> servicio;
  final Widget? accion;
  final Widget? menu;
  final VoidCallback? onTap;

  const TarjetaServicio({
    super.key,
    required this.servicio,
    this.accion,
    this.menu,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final descripcion = textoServicio(servicio['description']);
    final duracion = (servicio['duration'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MiniaturaServicio(foto: textoServicio(servicio['imageUrl'])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nombreServicio(servicio),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        if (descripcion.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: TemaApp.grisSubtitulo,
                            ),
                          ),
                        ],
                        if (duracion > 0) ...[
                          const SizedBox(height: 5),
                          DatoServicio(
                            icono: Icons.schedule,
                            texto: '${formatearDuracionCorta(duracion)} aprox.',
                          ),
                        ],
                      ],
                    ),
                  ),
                  ?menu,
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 9),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: TemaApp.grisClaro,
                ),
              ),
              Row(
                children: [
                  Expanded(child: PrecioServicio(precio: servicio['price'])),
                  if (accion != null) ...[const SizedBox(width: 10), accion!],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BotonReservar extends StatelessWidget {
  final VoidCallback onReservar;

  const BotonReservar({super.key, required this.onReservar});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onReservar,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        minimumSize: const Size(0, 38),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text('Reservar'),
    );
  }
}

class FilaServicio extends StatelessWidget {
  final Map<String, dynamic> servicio;
  final Widget? accion;

  const FilaServicio({super.key, required this.servicio, this.accion});

  @override
  Widget build(BuildContext context) {
    final duracion = (servicio['duration'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          MiniaturaServicio(
            foto: textoServicio(servicio['imageUrl']),
            lado: 46,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreServicio(servicio),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  duracion > 0
                      ? '${formatearPrecio(servicio['price'])}  ·  '
                            '${formatearDuracionCorta(duracion)}'
                      : formatearPrecio(servicio['price']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
              ],
            ),
          ),
          if (accion != null) ...[const SizedBox(width: 8), accion!],
        ],
      ),
    );
  }
}
