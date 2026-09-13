import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_connect/utils/formato.dart';

void main() {
  group('formatearPrecio', () {
    test('pone el peso adelante y separa los miles', () {
      expect(formatearPrecio(2313), r'$2.313');
      expect(formatearPrecio(125000), r'$125.000');
    });

    test('no muestra decimales ni se cae con nulo', () {
      expect(formatearPrecio(null), r'$0');
      expect(formatearPrecio(1500.7), r'$1.501');
    });
  });

  group('formatearHora', () {
    test('la medianoche se muestra como 12 AM', () {
      expect(formatearHora('00:00'), '12:00 AM');
    });

    test('el mediodia se muestra como 12 PM', () {
      expect(formatearHora('12:00'), '12:00 PM');
    });

    test('la mañana conserva su hora', () {
      expect(formatearHora('09:30'), '9:30 AM');
    });

    test('la tarde se convierte a 12 horas', () {
      expect(formatearHora('14:30'), '2:30 PM');
    });

    test('la ultima hora del dia sigue siendo PM', () {
      expect(formatearHora('23:45'), '11:45 PM');
    });
  });

  group('formatearDuracion', () {
    test('menos de una hora se dice en minutos', () {
      expect(formatearDuracion(45), '45 minutos');
    });

    test('cien minutos son una hora y cuarenta', () {
      expect(formatearDuracion(100), '1 hora 40 minutos');
    });

    test('las horas exactas no mencionan minutos', () {
      expect(formatearDuracion(120), '2 horas');
    });

    test('el singular no se pluraliza', () {
      expect(formatearDuracion(61), '1 hora 1 minuto');
    });

    test('sin duracion no inventa un numero', () {
      expect(formatearDuracion(0), 'Sin definir');
    });
  });

  group('formatearDuracionCorta', () {
    test('abrevia horas y minutos', () {
      expect(formatearDuracionCorta(100), '1 h 40 min');
    });

    test('omite los minutos en punto', () {
      expect(formatearDuracionCorta(180), '3 h');
    });
  });
}
