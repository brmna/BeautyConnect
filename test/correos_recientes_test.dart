import 'package:beauty_connect/data/services/servicio_correos_recientes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('correosCon', () {
    test('el correo nuevo queda de primero', () {
      final lista = correosCon(['ana@mail.com'], 'sara@mail.com');

      expect(lista, ['sara@mail.com', 'ana@mail.com']);
    });

    test('entrar de nuevo con uno guardado lo sube, no lo duplica', () {
      final lista = correosCon([
        'ana@mail.com',
        'sara@mail.com',
      ], 'sara@mail.com');

      expect(lista, ['sara@mail.com', 'ana@mail.com']);
    });

    test('no distingue mayusculas al comparar', () {
      final lista = correosCon(['sara@mail.com'], 'SARA@Mail.com');

      expect(lista, ['sara@mail.com']);
    });

    test('guarda el correo normalizado', () {
      final lista = correosCon(const [], '  Sara@Mail.COM  ');

      expect(lista, ['sara@mail.com']);
    });

    test('no guarda mas del maximo, y bota el mas viejo', () {
      final lista = correosCon(
        ['c@mail.com', 'b@mail.com', 'a@mail.com'],
        'd@mail.com',
        maximo: 3,
      );

      expect(lista, ['d@mail.com', 'c@mail.com', 'b@mail.com']);
    });

    test('un correo vacio no cambia nada', () {
      final lista = correosCon(['ana@mail.com'], '   ');

      expect(lista, ['ana@mail.com']);
    });
  });

  group('correosSin', () {
    test('quita el correo pedido', () {
      final lista = correosSin([
        'ana@mail.com',
        'sara@mail.com',
      ], 'ana@mail.com');

      expect(lista, ['sara@mail.com']);
    });

    test('tampoco distingue mayusculas al olvidar', () {
      final lista = correosSin(['Ana@Mail.com'], 'ana@mail.com');

      expect(lista, isEmpty);
    });

    test('olvidar uno que no esta no rompe nada', () {
      final lista = correosSin(['ana@mail.com'], 'otro@mail.com');

      expect(lista, ['ana@mail.com']);
    });
  });
}
