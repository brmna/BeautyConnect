import 'package:beauty_connect/data/models/ubicacion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('zona aproximada', () {
    test('el punto se lleva al centro de su celda', () {
      const punto = Ubicacion(latitud: 4.1423, longitud: -73.6268);

      expect(punto.latitudZona, closeTo(4.140, 0.0001));
      expect(punto.longitudZona, closeTo(-73.625, 0.0001));
    });

    test('dos puntos de la misma celda comparten zona', () {
      const casa = Ubicacion(latitud: 4.1400, longitud: -73.6262);
      const esquina = Ubicacion(latitud: 4.1420, longitud: -73.6259);

      expect(casa.latitudZona, esquina.latitudZona);
      expect(casa.longitudZona, esquina.longitudZona);
    });

    test('dos puntos a lado y lado del borde caen en zonas distintas', () {
      const antes = Ubicacion(latitud: 4.1421, longitud: -73.6262);
      const despues = Ubicacion(latitud: 4.1428, longitud: -73.6262);

      expect(antes.latitudZona, isNot(despues.latitudZona));
    });

    test('dos puntos lejanos caen en zonas distintas', () {
      const norte = Ubicacion(latitud: 4.1600, longitud: -73.6266);
      const sur = Ubicacion(latitud: 4.1200, longitud: -73.6266);

      expect(norte.latitudZona, isNot(sur.latitudZona));
    });

    test('sin punto no hay zona', () {
      const sinMapa = Ubicacion(direccion: 'Calle 40 # 25-30');

      expect(sinMapa.latitudZona, isNull);
      expect(sinMapa.longitudZona, isNull);
    });

    test('la zona nunca coincide exactamente con la direccion real', () {
      const punto = Ubicacion(latitud: 4.14231, longitud: -73.62684);

      expect(punto.latitudZona, isNot(punto.latitud));
      expect(punto.longitudZona, isNot(punto.longitud));
    });
  });
}
