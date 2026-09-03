import 'package:beauty_connect/presentation/widgets/redes_sociales.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('enlace de red social', () {
    test('un usuario suelto arma la direccion completa', () {
      expect(
        RedSocial.instagram.enlace('mi_usuario').toString(),
        'https://instagram.com/mi_usuario',
      );
    });

    test('ignora la arroba que la gente escribe de mas', () {
      expect(
        RedSocial.tiktok.enlace('@mi_usuario').toString(),
        'https://tiktok.com/@mi_usuario',
      );
    });

    test('una URL pegada se respeta tal cual', () {
      const url = 'https://facebook.com/profile.php?id=61550';
      expect(RedSocial.facebook.enlace(url).toString(), url);
    });

    test('una URL con www le pone https', () {
      expect(
        RedSocial.facebook.enlace('www.facebook.com/ana').toString(),
        'https://www.facebook.com/ana',
      );
    });

    test('whatsapp arma wa.me con el indicativo', () {
      expect(
        RedSocial.whatsapp.enlace('300 123 4567').toString(),
        'https://wa.me/573001234567',
      );
    });

    test('whatsapp no trata el numero como enlace', () {
      expect(
        RedSocial.whatsapp.enlace('3001234567').toString(),
        'https://wa.me/573001234567',
      );
    });
  });
}
