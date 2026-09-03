import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_connect/data/models/ajustes_profesional.dart';
import 'package:beauty_connect/data/models/professional_model.dart';

Professional profesional({
  double? latitud,
  double? longitud,
  bool soloDomicilio = false,
}) => Professional(
  id: 'p1',
  name: 'Ana',
  location: 'Villavicencio',
  about: '',
  specialties: const [],
  services: const [],
  rating: 0,
  reviewsCount: 0,
  latitude: latitud,
  longitude: longitud,
  soloDomicilio: soloDomicilio,
);

void main() {
  group('AjustesProfesional', () {
    test('por defecto atiende en su local y no va a domicilio', () {
      const ajustes = AjustesProfesional();

      expect(ajustes.atiendeEnSuLocal, isTrue);
      expect(ajustes.llegaADomicilio, isFalse);
    });

    test('solo domicilio implica que llega a domicilio', () {
      final ajustes = AjustesProfesional.desdeMapa({
        'ajustes': {AjustesProfesional.claveSoloDomicilio: true},
      });

      expect(ajustes.soloDomicilio, isTrue);
      expect(ajustes.llegaADomicilio, isTrue);
      expect(ajustes.atiendeEnSuLocal, isFalse);
    });

    test('un perfil viejo sin la clave sigue atendiendo en su local', () {
      final ajustes = AjustesProfesional.desdeMapa({
        'ajustes': {AjustesProfesional.claveDomicilios: true},
      });

      expect(ajustes.soloDomicilio, isFalse);
      expect(ajustes.atiendeEnSuLocal, isTrue);
      expect(ajustes.llegaADomicilio, isTrue);
    });
  });

  group('Professional.apareceEnElMapa', () {
    test('con punto marcado y local propio aparece', () {
      expect(
        profesional(latitud: 4.1, longitud: -73.6).apareceEnElMapa,
        isTrue,
      );
    });

    test('sin punto marcado no aparece', () {
      expect(profesional().apareceEnElMapa, isFalse);
    });

    test('si solo hace domicilio no aparece aunque tenga punto', () {
      expect(
        profesional(
          latitud: 4.1,
          longitud: -73.6,
          soloDomicilio: true,
        ).apareceEnElMapa,
        isFalse,
      );
    });
  });
}
