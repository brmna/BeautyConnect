import 'package:cloud_firestore/cloud_firestore.dart';

class CambioSolicitado {
  final DateTime fecha;
  final String hora;

  const CambioSolicitado({required this.fecha, required this.hora});

  static const String clave = 'cambioSolicitado';

  static CambioSolicitado? deCita(Map<String, dynamic>? datos) {
    final crudo = datos?[clave];
    if (crudo is! Map) return null;

    final fecha = crudo['fecha'];
    final hora = crudo['hora'];
    if (fecha is! Timestamp || hora is! String || hora.isEmpty) return null;

    return CambioSolicitado(fecha: fecha.toDate(), hora: hora);
  }

  Map<String, dynamic> aMapa() => {
    'fecha': Timestamp.fromDate(fecha),
    'hora': hora,
    'pedidoEn': FieldValue.serverTimestamp(),
  };
}
