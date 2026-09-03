import 'package:cloud_firestore/cloud_firestore.dart';

class CachePerfiles {
  final FirebaseFirestore? _instanciaInyectada;

  CachePerfiles({FirebaseFirestore? db}) : _instanciaInyectada = db;

  FirebaseFirestore get _db =>
      _instanciaInyectada ?? FirebaseFirestore.instance;

  final _pedidos = <String, Future<DocumentSnapshot<Map<String, dynamic>>>>{};

  Future<DocumentSnapshot<Map<String, dynamic>>> perfil(String uid) =>
      _pedidos[uid] ??= _db.collection('users').doc(uid).get();

  Future<({String nombre, String? foto})> resumen(String uid) async {
    final datos = await this.datos(uid);

    return (
      nombre: (datos['name'] as String?)?.trim() ?? '',
      foto: (datos['photoUrl'] as String?)?.trim(),
    );
  }

  Future<Map<String, dynamic>> datos(String uid) async {
    final documento = await perfil(uid);
    return documento.data() ?? {};
  }

  void limpiar() => _pedidos.clear();
}
