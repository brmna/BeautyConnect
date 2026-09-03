import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_connect/utils/distancia.dart';

void main() {
  group('distanciaKm', () {
    test('el mismo punto no tiene distancia', () {
      final resultado = distanciaKm(
        latitudA: 4.1420,
        longitudA: -73.6266,
        latitudB: 4.1420,
        longitudB: -73.6266,
      );
      expect(resultado, closeTo(0, 0.001));
    });

    test('un grado de latitud son unos 111 km', () {
      final resultado = distanciaKm(
        latitudA: 4.0,
        longitudA: -73.6,
        latitudB: 5.0,
        longitudB: -73.6,
      );
      expect(resultado, closeTo(111.2, 1));
    });

    test('dos puntos de Villavicencio quedan a pocos kilómetros', () {
      final resultado = distanciaKm(
        latitudA: 4.1420,
        longitudA: -73.6266,
        latitudB: 4.1533,
        longitudB: -73.6350,
      );
      expect(resultado, greaterThan(1));
      expect(resultado, lessThan(3));
    });

    test('la distancia es simétrica', () {
      final ida = distanciaKm(
        latitudA: 4.14,
        longitudA: -73.62,
        latitudB: 4.20,
        longitudB: -73.70,
      );
      final vuelta = distanciaKm(
        latitudA: 4.20,
        longitudA: -73.70,
        latitudB: 4.14,
        longitudB: -73.62,
      );
      expect(ida, closeTo(vuelta, 0.0001));
    });
  });

  group('formatearDistancia', () {
    test('menos de un kilómetro se dice en metros', () {
      expect(formatearDistancia(0.85), '850 m');
    });

    test('las distancias cortas llevan un decimal', () {
      expect(formatearDistancia(3.24), '3,2 km');
    });

    test('las distancias largas se redondean', () {
      expect(formatearDistancia(12.6), '13 km');
    });
  });
}
