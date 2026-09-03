import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ubicacion.dart';

class ServicioUbicacionCita {
  final FirebaseFirestore? _instanciaInyectada;

  ServicioUbicacionCita({FirebaseFirestore? db}) : _instanciaInyectada = db;

  FirebaseFirestore get _db =>
      _instanciaInyectada ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _ref(String citaId) => _db
      .collection('bookings')
      .doc(citaId)
      .collection('privado')
      .doc('ubicacion');

  Future<Ubicacion?> exacta(String citaId) async {
    try {
      final documento = await _ref(citaId).get();
      final datos = documento.data();
      if (datos == null) return null;

      return Ubicacion(
        direccion: datos['direccion'] ?? '',
        latitud: (datos['latitud'] as num?)?.toDouble(),
        longitud: (datos['longitud'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

Uri rutaEnGoogleMaps({required double latitud, required double longitud}) {
  return Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$latitud,$longitud'
    '&travelmode=driving',
  );
}

Uri buscarEnGoogleMaps(String direccion) {
  final consulta = Uri.encodeComponent('$direccion, Villavicencio, Meta');
  return Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$consulta',
  );
}
