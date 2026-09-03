import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_connect/data/services/servicio_chat.dart';
import 'package:beauty_connect/data/services/servicio_favoritos.dart';

void main() {
  group('ServicioFavoritos.desdeMapa', () {
    test('lee la lista de favoritas', () {
      expect(
        ServicioFavoritos.desdeMapa({
          'favorites': ['uno', 'dos'],
        }),
        {'uno', 'dos'},
      );
    });

    test('un perfil sin favoritas devuelve un conjunto vacío', () {
      expect(ServicioFavoritos.desdeMapa(null), isEmpty);
      expect(ServicioFavoritos.desdeMapa({}), isEmpty);
      expect(ServicioFavoritos.desdeMapa({'favorites': null}), isEmpty);
    });

    test('descarta lo que no sea texto en vez de reventar', () {
      expect(
        ServicioFavoritos.desdeMapa({
          'favorites': ['uno', 7, null, 'dos'],
        }),
        {'uno', 'dos'},
      );
    });
  });

  group('ResumenChat.otroId', () {
    const resumen = ResumenChat(
      citaId: 'cita1',
      clienteId: 'cliente1',
      profesionalId: 'profesional1',
      servicio: 'Manicure',
      ultimoMensaje: 'Hola',
      sinLeer: 0,
      ultimoEsMio: false,
    );

    test('la manicurista ve al cliente', () {
      expect(resumen.otroId(esProfesional: true), 'cliente1');
    });

    test('la clienta ve a la manicurista', () {
      expect(resumen.otroId(esProfesional: false), 'profesional1');
    });
  });
}
