import 'package:cloud_firestore/cloud_firestore.dart';

class ServicioFavoritos {
  final FirebaseFirestore _db;

  ServicioFavoritos({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _perfil(String uid) =>
      _db.collection('users').doc(uid);

  Stream<Set<String>> observar(String uid) {
    if (uid.isEmpty) return Stream.value(const <String>{});

    return _perfil(uid).snapshots().map(desdePerfil);
  }

  Future<Set<String>> leer(String uid) async {
    if (uid.isEmpty) return const <String>{};

    return desdePerfil(await _perfil(uid).get());
  }

  Future<void> alternar({
    required String uid,
    required String profesionalId,
    required bool marcar,
  }) {
    return _perfil(uid).set({
      'favorites': marcar
          ? FieldValue.arrayUnion([profesionalId])
          : FieldValue.arrayRemove([profesionalId]),
    }, SetOptions(merge: true));
  }

  static Set<String> desdePerfil(
    DocumentSnapshot<Map<String, dynamic>> documento,
  ) => desdeMapa(documento.data());

  static Set<String> desdeMapa(Map<String, dynamic>? datos) {
    final lista = datos?['favorites'];
    if (lista is! List) return const <String>{};

    return lista.whereType<String>().toSet();
  }
}
