import 'package:beauty_connect/utils/enlaces.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('enlaces de perfil', () {
    test('arma el enlace con el identificador', () {
      expect(enlaceDePerfil('abc123'), 'beautyconnect://perfil/abc123');
    });

    test('lee de vuelta el identificador', () {
      expect(perfilDesdeEnlace('beautyconnect://perfil/abc123'), 'abc123');
    });

    test('ignora espacios alrededor', () {
      expect(perfilDesdeEnlace('  beautyconnect://perfil/xyz  '), 'xyz');
    });

    test('rechaza un enlace de otra app', () {
      expect(perfilDesdeEnlace('https://instagram.com/alguien'), isNull);
    });

    test('rechaza el esquema correcto con otra ruta', () {
      expect(perfilDesdeEnlace('beautyconnect://cita/abc'), isNull);
    });

    test('rechaza un enlace sin identificador', () {
      expect(perfilDesdeEnlace('beautyconnect://perfil/'), isNull);
    });

    test('rechaza texto que no es un enlace', () {
      expect(perfilDesdeEnlace('hola'), isNull);
    });
  });
}
