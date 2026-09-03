import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_connect/data/models/cambio_solicitado.dart';

void main() {
  final fecha = DateTime(2026, 9, 14, 15, 30);

  group('CambioSolicitado.deCita', () {
    test('lee una propuesta bien formada', () {
      final propuesta = CambioSolicitado.deCita({
        CambioSolicitado.clave: {
          'fecha': Timestamp.fromDate(fecha),
          'hora': '15:30',
        },
      });

      expect(propuesta, isNotNull);
      expect(propuesta!.hora, '15:30');
      expect(propuesta.fecha, fecha);
    });

    test('una cita sin propuesta devuelve null', () {
      expect(CambioSolicitado.deCita({'status': 'confirmed'}), isNull);
      expect(CambioSolicitado.deCita(null), isNull);
    });

    test('ignora una propuesta a medias en vez de reventar', () {
      expect(
        CambioSolicitado.deCita({
          CambioSolicitado.clave: {'hora': '15:30'},
        }),
        isNull,
      );

      expect(
        CambioSolicitado.deCita({
          CambioSolicitado.clave: {
            'fecha': Timestamp.fromDate(fecha),
            'hora': '',
          },
        }),
        isNull,
      );

      expect(
        CambioSolicitado.deCita({CambioSolicitado.clave: 'mañana'}),
        isNull,
      );
    });
  });
}
