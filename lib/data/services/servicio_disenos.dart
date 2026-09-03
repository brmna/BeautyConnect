import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diseno.dart';
import 'cache_perfiles.dart';

class ServicioDisenos {
  final FirebaseFirestore? _instanciaInyectada;

  ServicioDisenos({FirebaseFirestore? db}) : _instanciaInyectada = db;

  FirebaseFirestore get _db =>
      _instanciaInyectada ?? FirebaseFirestore.instance;

  late final CachePerfiles _perfiles = CachePerfiles(db: _instanciaInyectada);

  Stream<List<Diseno>> observarGaleria({String? etiqueta, int limite = 60}) {
    Query<Map<String, dynamic>> consulta = _db.collectionGroup('portfolio');

    if (etiqueta != null) {
      consulta = consulta.where('etiquetas', arrayContains: etiqueta);
    }

    return consulta
        .orderBy('createdAt', descending: true)
        .limit(limite)
        .snapshots()
        .asyncMap(
          (instantanea) => _sinDesactivadas(
            instantanea.docs.map(Diseno.desdeDocumento).toList(),
          ),
        );
  }

  Future<List<Diseno>> _sinDesactivadas(List<Diseno> disenos) async {
    _perfiles.limpiar();

    final activas = <String, bool>{};

    for (final diseno in disenos) {
      if (diseno.profesionalId.isEmpty) continue;
      if (activas.containsKey(diseno.profesionalId)) continue;

      try {
        final datos = await _perfiles.datos(diseno.profesionalId);
        activas[diseno.profesionalId] = datos['activo'] != false;
      } catch (_) {
        activas[diseno.profesionalId] = true;
      }
    }

    return disenos.where((d) => activas[d.profesionalId] ?? true).toList();
  }

  CollectionReference<Map<String, dynamic>> _favoritos(String clienteId) =>
      _db.collection('users').doc(clienteId).collection('disenosFavoritos');

  Stream<Set<String>> observarIdsFavoritos(String clienteId) {
    return _favoritos(clienteId).snapshots().map(
      (instantanea) => instantanea.docs.map((d) => d.id).toSet(),
    );
  }

  Stream<List<Diseno>> observarFavoritos(String clienteId) {
    return _favoritos(clienteId)
        .orderBy('guardadoEn', descending: true)
        .snapshots()
        .map(
          (instantanea) => instantanea.docs.map(Diseno.desdeDocumento).toList(),
        );
  }

  Future<int> limpiarFavoritosHuerfanos(String clienteId) async {
    final guardados = await _favoritos(clienteId).get();
    if (guardados.docs.isEmpty) return 0;

    final huerfanos = <String>[];

    for (final documento in guardados.docs) {
      final diseno = Diseno.desdeDocumento(documento);
      if (diseno.profesionalId.isEmpty) continue;

      final original = await _db
          .collection('users')
          .doc(diseno.profesionalId)
          .collection('portfolio')
          .doc(diseno.id)
          .get();

      if (!original.exists) huerfanos.add(documento.id);
    }

    if (huerfanos.isEmpty) return 0;

    final lote = _db.batch();
    for (final id in huerfanos) {
      lote.delete(_favoritos(clienteId).doc(id));
    }
    await lote.commit();

    return huerfanos.length;
  }

  Future<void> alternarFavorito({
    required String clienteId,
    required Diseno diseno,
    required bool guardar,
  }) {
    final referenciaFavorito = _favoritos(clienteId).doc(diseno.id);
    final referenciaFoto = _db
        .collection('users')
        .doc(diseno.profesionalId)
        .collection('portfolio')
        .doc(diseno.id);

    final lote = _db.batch();

    if (guardar) {
      lote.set(referenciaFavorito, diseno.aFavorito());
    } else {
      lote.delete(referenciaFavorito);
    }

    lote.set(referenciaFoto, {
      'favoritos': FieldValue.increment(guardar ? 1 : -1),
    }, SetOptions(merge: true));

    return lote.commit();
  }
}
