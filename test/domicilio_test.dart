import 'package:beauty_connect/data/models/ajustes_profesional.dart';
import 'package:beauty_connect/data/models/modalidad_cita.dart';
import 'package:beauty_connect/data/services/servicio_ubicacion_cita.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ajustes de domicilio', () {
    test('un perfil sin nada no hace domicilios', () {
      final ajustes = AjustesProfesional.desdeMapa({'name': 'Ana'});
      expect(ajustes.haceDomicilios, isFalse);
      expect(ajustes.radioCoberturaKm, AjustesProfesional.radioPorDefecto);
      expect(ajustes.recargoDomicilio, 0);
    });

    test('lee radio y recargo guardados', () {
      final ajustes = AjustesProfesional.desdeMapa({
        'ajustes': {
          'haceDomicilios': true,
          'radioCoberturaKm': 8,
          'recargoDomicilio': 12000,
        },
      });
      expect(ajustes.haceDomicilios, isTrue);
      expect(ajustes.radioCoberturaKm, 8);
      expect(ajustes.recargoDomicilio, 12000);
    });
  });

  group('modalidad de la cita', () {
    test('una cita vieja sin campo es en el local', () {
      expect(modalidadDeCita({'status': 'confirmed'}), ModalidadCita.local);
    });

    test('reconoce el domicilio', () {
      expect(
        modalidadDeCita({'modalidad': 'domicilio'}),
        ModalidadCita.domicilio,
      );
    });

    test('el total suma el recargo solo si existe', () {
      expect(precioTotalDeCita({'servicePrice': 50000}), 50000);
      expect(
        precioTotalDeCita({'servicePrice': 50000, 'recargoDomicilio': 12000}),
        62000,
      );
    });
  });

  group('ruta en Google Maps', () {
    test('con coordenadas arma la navegacion directa', () {
      final url = rutaEnGoogleMaps(latitud: 4.142, longitud: -73.6266);
      expect(url.toString(), contains('destination=4.142,-73.6266'));
      expect(url.toString(), contains('travelmode=driving'));
    });

    test('sin coordenadas busca por direccion y ciudad', () {
      final url = buscarEnGoogleMaps('Calle 40 # 25-30');
      expect(url.toString(), contains('Villavicencio'));
      expect(url.toString(), contains('Calle%2040'));
    });
  });
}
