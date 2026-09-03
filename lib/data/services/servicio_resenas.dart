import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/resena.dart';

class ServicioResenas {
  final FirebaseFirestore? _instanciaInyectada;

  ServicioResenas({FirebaseFirestore? db}) : _instanciaInyectada = db;

  FirebaseFirestore get _db =>
      _instanciaInyectada ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _resenas(String profesionalId) =>
      _db.collection('users').doc(profesionalId).collection('resenas');

  Stream<List<Resena>> observarDeProfesional(String profesionalId) {
    return _resenas(profesionalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((i) => i.docs.map(Resena.desdeDocumento).toList());
  }

  Stream<List<Resena>> observarDeCliente(String clienteId) {
    return _db
        .collectionGroup('resenas')
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map((i) {
          final lista = i.docs.map(Resena.desdeDocumento).toList();
          lista.sort((a, b) {
            if (a.fecha == null || b.fecha == null) return 0;
            return b.fecha!.compareTo(a.fecha!);
          });
          return lista;
        });
  }

  Future<bool> yaCalifico({
    required String profesionalId,
    required String citaId,
  }) async {
    final documento = await _resenas(profesionalId).doc(citaId).get();
    return documento.exists;
  }

  Future<void> publicar({
    required String profesionalId,
    required String profesionalNombre,
    required String citaId,
    required String clienteId,
    required String clienteNombre,
    required String servicio,
    required int calificacion,
    required String comentario,
    String? profesionalFoto,
    String? clienteFoto,
    List<String> fotos = const [],
  }) async {
    final refResena = _resenas(profesionalId).doc(citaId);
    final refPerfil = _db.collection('users').doc(profesionalId);

    await _db.runTransaction((transaccion) async {
      final existente = await transaccion.get(refResena);
      if (existente.exists) {
        throw const ResenaDuplicada();
      }

      final perfil = await transaccion.get(refPerfil);
      final datos = perfil.data() ?? {};
      final totalPrevio = (datos['reviewsCount'] as num?)?.toInt() ?? 0;
      final sumaPrevia = (datos['sumaCalificaciones'] as num?)?.toInt() ?? 0;

      final total = totalPrevio + 1;
      final suma = sumaPrevia + calificacion;

      transaccion.set(refResena, {
        'profesionalId': profesionalId,
        'profesionalNombre': profesionalNombre,
        'profesionalFoto': profesionalFoto,
        'clienteId': clienteId,
        'clienteNombre': clienteNombre,
        'clienteFoto': clienteFoto,
        'servicio': servicio,
        'calificacion': calificacion,
        'comentario': comentario.trim(),
        'fotos': fotos,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaccion.set(refPerfil, {
        'reviewsCount': total,
        'sumaCalificaciones': suma,
        'rating': double.parse((suma / total).toStringAsFixed(1)),
      }, SetOptions(merge: true));
    });
  }

  Future<void> responder({
    required String profesionalId,
    required String resenaId,
    required String respuesta,
  }) {
    final texto = respuesta.trim();

    return _resenas(profesionalId).doc(resenaId).update({
      'respuesta': texto.isEmpty ? FieldValue.delete() : texto,
      'respondidaEn': texto.isEmpty
          ? FieldValue.delete()
          : FieldValue.serverTimestamp(),
    });
  }
}

class ResenaDuplicada implements Exception {
  const ResenaDuplicada();
}
