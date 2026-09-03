import 'package:beauty_connect/utils/mensajes_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mensajeErrorAuth', () {
    test('distingue correo inexistente de contraseña equivocada', () {
      expect(
        mensajeErrorAuth('user-not-found'),
        'No existe una cuenta con ese correo',
      );
      expect(
        mensajeErrorAuth('wrong-password'),
        'La contraseña no es correcta',
      );
    });

    test('cuando Firebase no distingue, el mensaje cubre los dos casos', () {
      expect(
        mensajeErrorAuth('invalid-credential'),
        'Correo o contraseña incorrectos',
      );
    });

    test('un codigo desconocido no deja al usuario sin mensaje', () {
      expect(
        mensajeErrorAuth('algo-raro'),
        'Ocurrió un error, intenta de nuevo',
      );
    });
  });
}
