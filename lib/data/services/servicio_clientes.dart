import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/estado_cita.dart';

class VisitaCliente {
  final String servicio;
  final DateTime fecha;
  final num precio;
  final String estado;

  final bool caducada;

  const VisitaCliente({
    required this.servicio,
    required this.fecha,
    required this.precio,
    required this.estado,
    this.caducada = false,
  });
}

class ResumenCliente {
  final String id;
  final String nombre;
  final String? telefono;
  final String? correo;

  final String? foto;

  final List<VisitaCliente> visitas;

  const ResumenCliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.correo,
    required this.visitas,
    this.foto,
  });

  int get atendidas => visitas.where((v) => v.estado == 'completed').length;

  int get canceladas =>
      visitas.where((v) => v.estado == 'cancelled' && !v.caducada).length;

  num get totalGastado => visitas
      .where((v) => v.estado == 'completed')
      .fold<num>(0, (suma, v) => suma + v.precio);

  DateTime? get ultimaVisita {
    final completadas = visitas.where((v) => v.estado == 'completed').toList();
    if (completadas.isEmpty) return null;
    completadas.sort((a, b) => b.fecha.compareTo(a.fecha));
    return completadas.first.fecha;
  }

  DateTime? get proximaCita {
    final ahora = DateTime.now();
    final futuras = visitas
        .where((v) => v.estado == 'confirmed' && v.fecha.isAfter(ahora))
        .toList();
    if (futuras.isEmpty) return null;
    futuras.sort((a, b) => a.fecha.compareTo(b.fecha));
    return futuras.first.fecha;
  }
}

class ServicioClientes {
  final FirebaseFirestore _db;

  ServicioClientes({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> observarCitas(
    String profesionalId,
  ) {
    return _db
        .collection('bookings')
        .where('professionalId', isEqualTo: profesionalId)
        .snapshots();
  }

  Future<ResumenCliente?> resumenDeCliente({
    required String profesionalId,
    required String clienteId,
  }) async {
    final consulta = await _db
        .collection('bookings')
        .where('professionalId', isEqualTo: profesionalId)
        .where('clientId', isEqualTo: clienteId)
        .get();

    if (consulta.docs.isEmpty) return null;

    final resumenes = await agrupar(consulta.docs);
    return resumenes.isEmpty ? null : resumenes.first;
  }

  Future<List<ResumenCliente>> agrupar(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> citas,
  ) async {
    final visitasPorCliente = <String, List<VisitaCliente>>{};

    for (final cita in citas) {
      final datos = cita.data();
      final clienteId = datos['clientId'] as String?;
      final fecha = (datos['date'] as Timestamp?)?.toDate();
      if (clienteId == null || fecha == null) continue;

      visitasPorCliente
          .putIfAbsent(clienteId, () => [])
          .add(
            VisitaCliente(
              servicio: datos['serviceName'] ?? 'Servicio',
              fecha: fecha,
              precio: (datos['servicePrice'] as num?) ?? 0,
              estado: datos['status'] ?? 'pending',
              caducada: datos['canceladaPor'] == canceladaPorSistema,
            ),
          );
    }

    if (visitasPorCliente.isEmpty) return [];

    final perfiles = await _obtenerPerfiles(visitasPorCliente.keys.toList());
    final resumenes = <ResumenCliente>[];

    visitasPorCliente.forEach((id, visitas) {
      final perfil = perfiles[id] ?? const {};
      resumenes.add(
        ResumenCliente(
          id: id,
          nombre: perfil['name'] ?? 'Cliente',
          telefono: perfil['phone'],
          correo: perfil['email'],
          foto: perfil['photoUrl'],
          visitas: visitas,
        ),
      );
    });

    resumenes.sort((a, b) {
      final fechaA = a.ultimaVisita ?? a.proximaCita;
      final fechaB = b.ultimaVisita ?? b.proximaCita;
      if (fechaA == null && fechaB == null) return a.nombre.compareTo(b.nombre);
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaB.compareTo(fechaA);
    });

    return resumenes;
  }

  Future<Map<String, Map<String, dynamic>>> _obtenerPerfiles(
    List<String> ids,
  ) async {
    final perfiles = <String, Map<String, dynamic>>{};

    for (var i = 0; i < ids.length; i += 10) {
      final bloque = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final consulta = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: bloque)
          .get();

      for (final documento in consulta.docs) {
        perfiles[documento.id] = documento.data();
      }
    }

    return perfiles;
  }
}
