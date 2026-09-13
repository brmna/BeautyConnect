import 'package:beauty_connect/data/models/cambio_solicitado.dart';
import 'package:beauty_connect/utils/formato.dart';
import 'package:beauty_connect/utils/novedades.dart';
import 'package:beauty_connect/utils/texto_aviso.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

final _ahora = DateTime(2026, 9, 9, 10);
final _cita = DateTime(2026, 9, 10, 15, 30);

Map<String, dynamic> citaBase({
  String estado = 'pending',
  bool domicilio = false,
  Map<String, dynamic> extra = const {},
}) => {
  'clientId': 'cliente1',
  'professionalId': 'pro1',
  'serviceName': 'Uñas acrílicas',
  'servicePrice': 60000,
  'durationMinutes': 90,
  'date': Timestamp.fromDate(_cita),
  'status': estado,
  'modalidad': domicilio ? 'domicilio' : 'local',
  if (domicilio) ...{
    'recargoDomicilio': 10000,
    'barrioCliente': 'La Esperanza',
  },
  'createdAt': Timestamp.fromDate(_ahora),
  ...extra,
};

TextoAviso aviso(
  Map<String, dynamic> cita, {
  required bool esProfesional,
  String? nombre,
}) {
  final novedad = novedadDeCita('cita1', cita, esProfesional: esProfesional);
  expect(novedad, isNotNull);

  return avisoDeNovedad(
    novedad!,
    esProfesional: esProfesional,
    nombre: nombre,
    ahora: _ahora,
  );
}

void main() {
  group('diaHablado', () {
    test('dice hoy y mañana', () {
      expect(diaHablado(DateTime(2026, 9, 9, 20), ahora: _ahora), 'hoy');
      expect(diaHablado(DateTime(2026, 9, 10, 8), ahora: _ahora), 'mañana');
    });

    test('usa el día de la semana dentro de la semana', () {
      expect(diaHablado(DateTime(2026, 9, 12), ahora: _ahora), 'el sábado');
    });

    test('usa la fecha cuando falta más de una semana', () {
      expect(
        diaHablado(DateTime(2026, 10, 3), ahora: _ahora),
        'el 3 de octubre',
      );
    });
  });

  group('avisoVigente', () {
    test('un evento posterior al arranque sí avisa', () {
      expect(
        avisoVigente(_ahora.add(const Duration(seconds: 5)), desde: _ahora),
        isTrue,
      );
    });

    test('un evento viejo no avisa', () {
      expect(
        avisoVigente(_ahora.subtract(const Duration(hours: 3)), desde: _ahora),
        isFalse,
      );
    });

    test('tolera un desfase pequeño de reloj', () {
      expect(
        avisoVigente(
          _ahora.subtract(const Duration(seconds: 30)),
          desde: _ahora,
        ),
        isTrue,
      );
    });

    test('sin sello de tiempo no avisa', () {
      expect(avisoVigente(null, desde: _ahora), isFalse);
    });
  });

  group('avisos de novedades', () {
    test('una solicitud nueva nombra al cliente, el servicio y la hora', () {
      final texto = aviso(citaBase(), esProfesional: true, nombre: 'Daniela');

      expect(texto.titulo, 'Daniela te pidió una cita');
      expect(texto.cuerpo, 'Uñas acrílicas · mañana a las 3:30 PM');
      expect(texto.detalle, contains('Mañana a las 3:30 PM'));
      expect(texto.detalle, contains('En tu local'));
      expect(texto.detalle, contains(formatearPrecio(60000)));
    });

    test('sin nombre conocido el título no queda a medias', () {
      final texto = aviso(citaBase(), esProfesional: true);

      expect(texto.titulo, 'Nueva solicitud de cita');
    });

    test('una cita a domicilio suma el recargo y muestra el barrio', () {
      final texto = aviso(
        citaBase(domicilio: true),
        esProfesional: true,
        nombre: 'Daniela',
      );

      expect(texto.detalle, contains('A domicilio · La Esperanza'));
      expect(texto.detalle, contains(formatearPrecio(70000)));
    });

    test('el cliente ve quién le confirmó y cuándo', () {
      final texto = aviso(
        citaBase(
          estado: 'confirmed',
          extra: {'respondidoEn': Timestamp.fromDate(_ahora)},
        ),
        esProfesional: false,
        nombre: 'Laura',
      );

      expect(texto.titulo, 'Laura confirmó tu cita');
      expect(texto.cuerpo, 'Uñas acrílicas · mañana a las 3:30 PM');
      expect(texto.detalle, contains('En su local'));
    });

    test('un cambio de hora dice la hora vieja y la nueva', () {
      final texto = aviso(
        citaBase(
          extra: {
            CambioSolicitado.clave: {
              'fecha': Timestamp.fromDate(DateTime(2026, 9, 11)),
              'hora': '09:00',
              'pedidoEn': Timestamp.fromDate(_ahora),
            },
          },
        ),
        esProfesional: true,
        nombre: 'Daniela',
      );

      expect(texto.titulo, 'Daniela pide otro horario');
      expect(
        texto.cuerpo,
        contains('quiere moverla para el viernes a las 9:00 AM'),
      );
      expect(texto.detalle, contains('Ahora: Mañana a las 3:30 PM'));
      expect(texto.detalle, contains('Pide: El viernes a las 9:00 AM'));
    });

    test('una cancelación explica el motivo', () {
      final texto = aviso(
        citaBase(
          estado: 'cancelled',
          extra: {
            'canceladaPor': 'cliente',
            'motivoCancelacion': 'Me surgió un imprevisto',
            'respondidoEn': Timestamp.fromDate(_ahora),
          },
        ),
        esProfesional: true,
        nombre: 'Daniela',
      );

      expect(texto.titulo, 'Daniela canceló su cita');
      expect(texto.cuerpo, contains('Me surgió un imprevisto'));
      expect(texto.detalle, contains('Motivo: Me surgió un imprevisto'));
    });
    test('un rechazo de cambio dice que la cita sigue igual', () {
      final texto = aviso(
        citaBase(
          estado: 'confirmed',
          extra: {
            'respondidoEn': Timestamp.fromDate(
              _ahora.subtract(const Duration(hours: 3)),
            ),
            'cambioRechazadoEn': Timestamp.fromDate(_ahora),
          },
        ),
        esProfesional: false,
        nombre: 'Laura',
      );

      expect(texto.titulo, 'Laura no pudo mover tu cita');
      expect(texto.cuerpo, 'Uñas acrílicas · sigue mañana a las 3:30 PM');
      expect(texto.detalle, contains('Sigue mañana a las 3:30 PM'));
    });

    test('al terminar la cita se invita a dejar reseña', () {
      final texto = aviso(
        citaBase(
          estado: 'completed',
          extra: {'completadaEn': Timestamp.fromDate(_ahora)},
        ),
        esProfesional: false,
        nombre: 'Laura',
      );

      expect(texto.titulo, 'Laura dio tu cita por atendida');
      expect(texto.cuerpo, contains('¿cómo te fue?'));
      expect(texto.detalle, contains('Deja tu reseña'));
    });
  });

  group('mensajes del chat', () {
    test('el aviso lleva quién escribe, el texto y sobre qué cita', () {
      final texto = avisoDeMensaje(const {
        'ultimoMensaje': '¿Puedo llegar 10 minutos tarde?',
        'servicio': 'Uñas acrílicas',
      }, nombre: 'Daniela');

      expect(texto.titulo, 'Mensaje de Daniela');
      expect(texto.cuerpo, '¿Puedo llegar 10 minutos tarde?');
      expect(texto.detalle, contains('Sobre: Uñas acrílicas'));
    });

    test('sin nombre sigue diciendo que hay un mensaje', () {
      final texto = avisoDeMensaje(const {'ultimoMensaje': 'Hola'});

      expect(texto.titulo, 'Mensaje nuevo');
      expect(texto.cuerpo, 'Hola');
    });
  });

  group('recordatorios', () {
    test('el de un día antes anuncia la hora y con quién es', () {
      final texto = avisoDeRecordatorio(
        citaBase(estado: 'confirmed'),
        horasAntes: 24,
        esProfesional: false,
        nombre: 'Laura',
      );

      expect(texto.titulo, 'Mañana tienes cita con Laura');
      expect(texto.cuerpo, '3:30 PM · Uñas acrílicas');
      expect(texto.detalle, contains('Mañana a las 3:30 PM'));
      expect(texto.detalle, contains('Con Laura'));
    });

    test('el de dos horas antes avisa cuánto falta', () {
      final texto = avisoDeRecordatorio(
        citaBase(estado: 'confirmed'),
        horasAntes: 2,
        esProfesional: true,
        nombre: 'Daniela',
      );

      expect(texto.titulo, 'Atiendes en 2 horas');
      expect(texto.detalle, contains('Cliente: Daniela'));
      expect(texto.detalle, contains('Hoy a las 3:30 PM'));
    });

    test('un recordatorio que cruza la medianoche dice mañana', () {
      final texto = avisoDeRecordatorio(
        citaBase(
          estado: 'confirmed',
          extra: {'date': Timestamp.fromDate(DateTime(2026, 9, 11, 1))},
        ),
        horasAntes: 2,
        esProfesional: false,
        nombre: 'Laura',
      );

      expect(texto.detalle, contains('Mañana a las 1:00 AM'));
    });

    test('sin nombre el recordatorio sigue teniendo sentido', () {
      final texto = avisoDeRecordatorio(
        citaBase(estado: 'confirmed'),
        horasAntes: 24,
        esProfesional: false,
      );

      expect(texto.titulo, 'Mañana tienes cita');
      expect(texto.detalle, isNot(contains('Con ')));
    });
  });
}
