import 'package:cloud_firestore/cloud_firestore.dart';

class Resena {
  final String id;
  final String profesionalId;
  final String profesionalNombre;

  final String? profesionalFoto;

  final String clienteId;
  final String clienteNombre;
  final String? clienteFoto;
  final String servicio;
  final int calificacion;
  final String comentario;
  final List<String> fotos;
  final String? respuesta;
  final DateTime? fecha;
  final DateTime? respondidaEn;

  const Resena({
    required this.id,
    required this.profesionalId,
    required this.profesionalNombre,
    required this.profesionalFoto,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteFoto,
    required this.servicio,
    required this.calificacion,
    required this.comentario,
    required this.fotos,
    required this.respuesta,
    required this.fecha,
    required this.respondidaEn,
  });

  bool get tieneFotos => fotos.isNotEmpty;
  bool get tieneRespuesta => respuesta != null && respuesta!.trim().isNotEmpty;

  factory Resena.desdeDocumento(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final datos = documento.data();

    return Resena(
      id: documento.id,
      profesionalId:
          documento.reference.parent.parent?.id ?? datos['profesionalId'] ?? '',
      profesionalNombre: datos['profesionalNombre'] ?? '',
      profesionalFoto: datos['profesionalFoto'],
      clienteId: datos['clienteId'] ?? '',
      clienteNombre: datos['clienteNombre'] ?? 'Cliente',
      clienteFoto: datos['clienteFoto'],
      servicio: datos['servicio'] ?? '',
      calificacion: (datos['calificacion'] as num?)?.toInt() ?? 0,
      comentario: datos['comentario'] ?? '',
      fotos: List<String>.from(datos['fotos'] ?? []),
      respuesta: datos['respuesta'],
      fecha: (datos['createdAt'] as Timestamp?)?.toDate(),
      respondidaEn: (datos['respondidaEn'] as Timestamp?)?.toDate(),
    );
  }
}

class ResumenCalificaciones {
  final int total;
  final double promedio;
  final Map<int, int> conteoPorEstrella;

  const ResumenCalificaciones({
    required this.total,
    required this.promedio,
    required this.conteoPorEstrella,
  });

  factory ResumenCalificaciones.desde(List<Resena> resenas) {
    if (resenas.isEmpty) {
      return const ResumenCalificaciones(
        total: 0,
        promedio: 0,
        conteoPorEstrella: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    final conteo = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    var suma = 0;

    for (final resena in resenas) {
      suma += resena.calificacion;
      conteo[resena.calificacion] = (conteo[resena.calificacion] ?? 0) + 1;
    }

    return ResumenCalificaciones(
      total: resenas.length,
      promedio: suma / resenas.length,
      conteoPorEstrella: conteo,
    );
  }

  int proporcion(int estrellas) {
    if (total == 0) return 0;
    return ((conteoPorEstrella[estrellas] ?? 0) * 100 / total).round();
  }
}
