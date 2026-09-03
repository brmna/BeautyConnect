import 'package:beauty_connect/utils/validaciones.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validarTelefono', () {
    test('acepta un celular colombiano de diez digitos', () {
      expect(validarTelefono('3001234567'), isNull);
    });

    test('acepta el mismo numero con indicativo y espacios', () {
      expect(validarTelefono('+57 300 123 4567'), isNull);
    });

    test('rechaza un numero corto', () {
      expect(validarTelefono('30012345'), 'Debe tener 10 dígitos');
    });

    test('rechaza un fijo, que no empieza por 3', () {
      expect(validarTelefono('6081234567'), 'Un celular empieza por 3');
    });

    test('vacio se acepta cuando el campo es opcional', () {
      expect(validarTelefono(''), isNull);
    });

    test('vacio se rechaza cuando el campo es obligatorio', () {
      expect(validarTelefono('', obligatorio: true), 'Ingresa tu teléfono');
    });
  });

  group('validarPrecio', () {
    test('acepta un precio normal', () {
      expect(validarPrecio('45000'), isNull);
    });

    test('acepta el precio escrito con puntos', () {
      expect(validarPrecio('150.000'), isNull);
    });

    test('rechaza por debajo del minimo', () {
      expect(validarPrecio('500'), r'Mínimo $1.000');
    });

    test('rechaza por encima del maximo', () {
      expect(validarPrecio('1500000'), r'Máximo $999.999');
    });

    test('acepta justo el maximo', () {
      expect(validarPrecio('999999'), isNull);
    });

    test('rechaza un campo vacio', () {
      expect(validarPrecio(''), 'Ingresa el precio');
    });
  });

  group('validarDuracion', () {
    test('acepta una duracion tipica', () {
      expect(validarDuracion('90'), isNull);
    });

    test('rechaza una duracion de un minuto', () {
      expect(validarDuracion('1'), 'Mínimo 5 minutos');
    });

    test('rechaza una jornada entera', () {
      expect(validarDuracion('600'), 'Máximo 480 minutos');
    });
  });

  group('validarCorreo', () {
    test('acepta un correo normal', () {
      expect(validarCorreo('ana.perez@gmail.com'), isNull);
    });

    test('rechaza uno sin arroba', () {
      expect(validarCorreo('anaperez.com'), 'Correo inválido');
    });

    test('rechaza uno sin dominio', () {
      expect(validarCorreo('ana@gmail'), 'Correo inválido');
    });
  });

  group('validarNombre', () {
    test('rechaza solo espacios', () {
      expect(validarNombre('   '), 'Ingresa tu nombre');
    });

    test('rechaza dos letras', () {
      expect(validarNombre('An'), 'El nombre es muy corto');
    });

    test('acepta un nombre completo', () {
      expect(validarNombre('Ana Pérez'), isNull);
    });
  });

  group('validarAnio', () {
    test('acepta un año reciente', () {
      expect(validarAnio('2022'), isNull);
    });

    test('rechaza un año futuro', () {
      final proximo = DateTime.now().year + 1;
      expect(validarAnio('$proximo'), isNotNull);
    });
  });
}
