import 'package:cloud_firestore/cloud_firestore.dart';

class Certificado {
  final String id;
  final String titulo;
  final String institucion;
  final String anio;

  final String? imagenUrl;

  const Certificado({
    required this.id,
    required this.titulo,
    required this.institucion,
    required this.anio,
    this.imagenUrl,
  });

  bool get tieneImagen => imagenUrl != null && imagenUrl!.isNotEmpty;

  factory Certificado.desdeDocumento(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final datos = documento.data();
    return Certificado(
      id: documento.id,
      titulo: datos['titulo'] ?? '',
      institucion: datos['institucion'] ?? '',
      anio: datos['anio']?.toString() ?? '',
      imagenUrl: datos['imagenUrl'] as String?,
    );
  }
}

class ServicioCertificados {
  final FirebaseFirestore? _instanciaInyectada;

  ServicioCertificados({FirebaseFirestore? db}) : _instanciaInyectada = db;

  FirebaseFirestore get _db =>
      _instanciaInyectada ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _coleccion(String uid) =>
      _db.collection('users').doc(uid).collection('certificados');

  Stream<List<Certificado>> observar(String uid) {
    return _coleccion(uid)
        .orderBy('anio', descending: true)
        .snapshots()
        .map((i) => i.docs.map(Certificado.desdeDocumento).toList());
  }

  Future<void> agregar({
    required String uid,
    required String titulo,
    required String institucion,
    required String anio,
    String? imagenUrl,
  }) {
    return _coleccion(uid).add({
      'titulo': titulo.trim(),
      'institucion': institucion.trim(),
      'anio': anio.trim(),
      'imagenUrl': imagenUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> actualizar({
    required String uid,
    required String id,
    required String titulo,
    required String institucion,
    required String anio,
    String? imagenUrl,
  }) {
    return _coleccion(uid).doc(id).update({
      'titulo': titulo.trim(),
      'institucion': institucion.trim(),
      'anio': anio.trim(),
      'imagenUrl': imagenUrl,
    });
  }

  Future<void> eliminar({required String uid, required String id}) {
    return _coleccion(uid).doc(id).delete();
  }
}
