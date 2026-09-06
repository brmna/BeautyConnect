import 'package:flutter/material.dart';

import '../../data/models/resena.dart';
import '../../data/services/servicio_resenas.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import 'estado_vacio.dart';
import '../../utils/formato.dart';
import '../../utils/margenes.dart';
import 'estrellas.dart';
import 'hoja_responder_resena.dart';
import 'visor_fotos.dart';

enum PerspectivaResena { recibidas, escritas }

class ResumenResenas extends StatelessWidget {
  final ResumenCalificaciones resumen;
  final String subtitulo;

  const ResumenResenas({
    super.key,
    required this.resumen,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TemaApp.blanco,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formatearCalificacion(resumen.promedio),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.star, size: 22, color: Colors.amber),
                ],
              ),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 12,
                  color: TemaApp.grisSubtitulo,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1]
                  .map((estrella) => _Barra(resumen: resumen, valor: estrella))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  final ResumenCalificaciones resumen;
  final int valor;

  const _Barra({required this.resumen, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text('$valor', style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: resumen.proporcion(valor) / 100,
                minHeight: 5,
                backgroundColor: TemaApp.grisClaro,
                valueColor: const AlwaysStoppedAnimation(TemaApp.negro),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 14,
            child: Text(
              '${resumen.conteoPorEstrella[valor] ?? 0}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: TemaApp.grisTexto),
            ),
          ),
        ],
      ),
    );
  }
}

class ListaResenas extends StatelessWidget {
  final List<Resena> resenas;
  final PerspectivaResena perspectiva;
  final String textoVacio;

  final void Function(Resena resena)? onResponder;
  final void Function(Resena resena)? onEditar;
  final void Function(Resena resena)? onEliminar;

  const ListaResenas({
    super.key,
    required this.resenas,
    required this.perspectiva,
    this.textoVacio = 'Nada por aquí todavía',
    this.onResponder,
    this.onEditar,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (resenas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            textoVacio,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TemaApp.grisTexto),
          ),
        ),
      );
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, 16, 16, margenInferior(context)),
      itemCount: resenas.length,
      itemBuilder: (context, indice) => TarjetaResena(
        resena: resenas[indice],
        perspectiva: perspectiva,
        onResponder: onResponder,
        onEditar: onEditar,
        onEliminar: onEliminar,
      ),
    );
  }
}

class TarjetaResena extends StatelessWidget {
  final Resena resena;
  final PerspectivaResena perspectiva;
  final void Function(Resena resena)? onResponder;
  final void Function(Resena resena)? onEditar;
  final void Function(Resena resena)? onEliminar;

  const TarjetaResena({
    super.key,
    required this.resena,
    required this.perspectiva,
    this.onResponder,
    this.onEditar,
    this.onEliminar,
  });

  bool get _puedeGestionar => onEditar != null || onEliminar != null;

  bool get _mirandoRecibidas => perspectiva == PerspectivaResena.recibidas;

  String get _nombre {
    final nombre = _mirandoRecibidas
        ? resena.clienteNombre
        : resena.profesionalNombre;
    if (nombre.trim().isNotEmpty) return nombre.trim();
    return _mirandoRecibidas ? 'Cliente' : 'Manicurista';
  }

  String get _foto =>
      (_mirandoRecibidas ? resena.clienteFoto : resena.profesionalFoto)
          ?.trim() ??
      '';

  @override
  Widget build(BuildContext context) {
    final responder = _botonResponder();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezado(),
            if (resena.comentario.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                resena.comentario,
                style: const TextStyle(height: 1.4, fontSize: 13),
              ),
            ],
            if (resena.tieneFotos) ...[
              const SizedBox(height: 12),
              _fotos(context),
            ],
            if (resena.tieneRespuesta) ...[
              const SizedBox(height: 12),
              _respuesta(),
            ],
            if (_puedeGestionar) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (onEditar != null)
                    TextButton.icon(
                      onPressed: () => onEditar!(resena),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar'),
                    ),
                  if (onEliminar != null)
                    TextButton.icon(
                      onPressed: () => onEliminar!(resena),
                      style: TextButton.styleFrom(
                        foregroundColor: TemaApp.error,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Eliminar'),
                    ),
                ],
              ),
            ],
            ?responder,
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    final foto = _foto;
    final nombre = _nombre;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: TemaApp.grisClaro,
          backgroundImage: foto.isEmpty
              ? null
              : NetworkImage(
                  ServicioSubidaImagenes.miniatura(foto, ancho: 120),
                ),
          child: foto.isEmpty
              ? Text(
                  nombre[0].toUpperCase(),
                  style: const TextStyle(
                    color: TemaApp.textoOscuro,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                resena.servicio,
                style: const TextStyle(
                  fontSize: 12,
                  color: TemaApp.grisSubtitulo,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Estrellas(calificacion: resena.calificacion.toDouble(), tamano: 13),
            const SizedBox(height: 2),
            if (resena.fecha != null)
              Text(
                formatearFecha(resena.fecha!),
                style: const TextStyle(fontSize: 11, color: TemaApp.grisTexto),
              ),
          ],
        ),
      ],
    );
  }

  Widget _fotos(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: resena.fotos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, indice) => GestureDetector(
          onTap: () =>
              VisorFotos.abrir(context, fotos: resena.fotos, inicial: indice),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              ServicioSubidaImagenes.miniatura(
                resena.fotos[indice],
                ancho: 240,
              ),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(width: 96, color: TemaApp.grisBorde),
            ),
          ),
        ),
      ),
    );
  }

  Widget _respuesta() {
    return Container(
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
              const Icon(Icons.reply, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Respuesta de ${resena.profesionalNombre}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onResponder != null)
                TextButton(
                  onPressed: () => onResponder!(resena),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Editar', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            resena.respuesta!,
            style: const TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
          ),
        ],
      ),
    );
  }

  Widget? _botonResponder() {
    if (onResponder == null || resena.tieneRespuesta) return null;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => onResponder!(resena),
          icon: const Icon(Icons.reply, size: 16),
          label: const Text('Responder'),
        ),
      ),
    );
  }
}

class ResenasDeProfesional extends StatelessWidget {
  final String profesionalId;

  final bool puedeResponder;

  const ResenasDeProfesional({
    super.key,
    required this.profesionalId,
    this.puedeResponder = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Resena>>(
      stream: ServicioResenas().observarDeProfesional(profesionalId),
      builder: (context, instantanea) {
        if (instantanea.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (instantanea.hasError) {
          return const EstadoVacio(
            icono: Icons.cloud_off_outlined,
            titulo: 'No se pudieron cargar las reseñas',
          );
        }

        final resenas = instantanea.data ?? [];
        if (resenas.isEmpty) {
          return const EstadoVacio(
            icono: Icons.star_border,
            titulo: 'Aún no tiene reseñas',
            detalle:
                'Las reseñas aparecen cuando sus clientes califican '
                'una cita terminada',
          );
        }

        return Column(
          children: [
            ResumenResenas(
              resumen: ResumenCalificaciones.desde(resenas),
              subtitulo: '${contarResenas(resenas.length)} de clientes reales',
            ),
            Expanded(
              child: ListaResenas(
                resenas: resenas,
                perspectiva: PerspectivaResena.recibidas,
                onResponder: puedeResponder
                    ? (resena) => HojaResponderResena.abrir(
                        context,
                        profesionalId: profesionalId,
                        resena: resena,
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
