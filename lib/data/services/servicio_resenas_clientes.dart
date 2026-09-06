import 'package:cloud_firestore/cloud_firestore.dart';

class ResenaCliente {
  final String citaId;
  final String profesionalId;
  final String profesionalNombre;
  final String servicio;
  final int calificacion;
  final String comentario;
  final List<String> fotos;
  final DateTime? fecha;

  bool get tieneFotos => fotos.isNotEmpty;

  const ResenaCliente({
    required this.citaId,
    required this.profesionalId,
    required this.profesionalNombre,
    required this.servicio,
    required this.calificacion,
    required this.comentario,
    this.fotos = const [],
    this.fecha,
  });

  factory ResenaCliente.desdeDocumento(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final datos = documento.data();

    return ResenaCliente(
      citaId: documento.id,
      profesionalId: datos['profesionalId'] ?? '',
      profesionalNombre: datos['profesionalNombre'] ?? '',
      servicio: datos['servicio'] ?? '',
      calificacion: (datos['calificacion'] as num?)?.toInt() ?? 0,
      comentario: datos['comentario'] ?? '',
      fotos: List<String>.from(datos['fotos'] ?? const []),
      fecha: (datos['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ServicioResenasClientes {
  final FirebaseFirestore? _instanciaInyectada;

  ServicioResenasClientes({FirebaseFirestore? db}) : _instanciaInyectada = db;

  FirebaseFirestore get _db =>
      _instanciaInyectada ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _resenas(String clienteId) =>
      _db.collection('users').doc(clienteId).collection('resenasCliente');

  Stream<List<ResenaCliente>> observarDeCliente(String clienteId) {
    return _resenas(clienteId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((i) => i.docs.map(ResenaCliente.desdeDocumento).toList());
  }

  Stream<Set<String>> observarCalificadas(String profesionalId) {
    return _db
        .collectionGroup('resenasCliente')
        .where('profesionalId', isEqualTo: profesionalId)
        .snapshots()
        .map((i) => i.docs.map((d) => d.id).toSet());
  }

  Future<void> publicar({
    required String clienteId,
    required String profesionalId,
    required String profesionalNombre,
    required String citaId,
    required String servicio,
    required int calificacion,
    required String comentario,
    List<String> fotos = const [],
  }) async {
    final refResena = _resenas(clienteId).doc(citaId);
    final refPerfil = _db.collection('users').doc(clienteId);

    await _db.runTransaction((transaccion) async {
      final existente = await transaccion.get(refResena);
      if (existente.exists) throw const ResenaClienteDuplicada();

      final perfil = await transaccion.get(refPerfil);
      final datos = perfil.data() ?? {};
      final totalPrevio = (datos['reviewsCountCliente'] as num?)?.toInt() ?? 0;
      final sumaPrevia =
          (datos['sumaCalificacionesCliente'] as num?)?.toInt() ?? 0;

      final total = totalPrevio + 1;
      final suma = sumaPrevia + calificacion;

      transaccion.set(refResena, {
        'profesionalId': profesionalId,
        'profesionalNombre': profesionalNombre,
        'clienteId': clienteId,
        'servicio': servicio,
        'calificacion': calificacion,
        'comentario': comentario.trim(),
        'fotos': fotos,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaccion.set(refPerfil, {
        'reviewsCountCliente': total,
        'sumaCalificacionesCliente': suma,
        'ratingCliente': double.parse((suma / total).toStringAsFixed(1)),
      }, SetOptions(merge: true));
    });
  }

  Future<void> editar({
    required String clienteId,
    required String citaId,
    required int calificacion,
    required String comentario,
    List<String> fotos = const [],
  }) async {
    final refResena = _resenas(clienteId).doc(citaId);
    final refPerfil = _db.collection('users').doc(clienteId);

    await _db.runTransaction((transaccion) async {
      final actual = await transaccion.get(refResena);
      if (!actual.exists) throw const ResenaClienteNoEncontrada();

      final anterior = (actual.data()?['calificacion'] as num?)?.toInt() ?? 0;

      final perfil = await transaccion.get(refPerfil);
      final datos = perfil.data() ?? {};
      final total = (datos['reviewsCountCliente'] as num?)?.toInt() ?? 1;
      final sumaPrevia =
          (datos['sumaCalificacionesCliente'] as num?)?.toInt() ?? 0;

      final suma = sumaPrevia - anterior + calificacion;

      transaccion.update(refResena, {
        'calificacion': calificacion,
        'comentario': comentario.trim(),
        'fotos': fotos,
        'editadaEn': FieldValue.serverTimestamp(),
      });

      transaccion.set(refPerfil, {
        'sumaCalificacionesCliente': suma,
        'ratingCliente': total <= 0
            ? 0.0
            : double.parse((suma / total).toStringAsFixed(1)),
      }, SetOptions(merge: true));
    });
  }

  Future<void> eliminar({
    required String clienteId,
    required String citaId,
  }) async {
    final refResena = _resenas(clienteId).doc(citaId);
    final refPerfil = _db.collection('users').doc(clienteId);

    await _db.runTransaction((transaccion) async {
      final actual = await transaccion.get(refResena);
      if (!actual.exists) return;

      final calificacion =
          (actual.data()?['calificacion'] as num?)?.toInt() ?? 0;

      final perfil = await transaccion.get(refPerfil);
      final datos = perfil.data() ?? {};
      final totalPrevio = (datos['reviewsCountCliente'] as num?)?.toInt() ?? 0;
      final sumaPrevia =
          (datos['sumaCalificacionesCliente'] as num?)?.toInt() ?? 0;

      final total = totalPrevio > 0 ? totalPrevio - 1 : 0;
      final suma = sumaPrevia - calificacion;

      transaccion.delete(refResena);

      transaccion.set(refPerfil, {
        'reviewsCountCliente': total,
        'sumaCalificacionesCliente': total == 0 ? 0 : suma,
        'ratingCliente': total == 0
            ? 0.0
            : double.parse((suma / total).toStringAsFixed(1)),
      }, SetOptions(merge: true));
    });
  }
}

class ResenaClienteNoEncontrada implements Exception {
  const ResenaClienteNoEncontrada();
}

class ResenaClienteDuplicada implements Exception {
  const ResenaClienteDuplicada();
}
