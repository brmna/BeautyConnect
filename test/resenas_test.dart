import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:beauty_connect/data/models/ajustes_profesional.dart';
import 'package:beauty_connect/data/models/horario.dart';
import 'package:beauty_connect/data/services/servicio_disponibilidad.dart';
import 'package:beauty_connect/utils/estado_cita.dart';
import 'package:beauty_connect/utils/formato.dart';
import 'package:beauty_connect/utils/validaciones.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sePuedeCalificar', () {
    final ahora = DateTime(2026, 9, 1, 15, 0);

    Map<String, dynamic> cita({
      required String estado,
      required DateTime fecha,
      int duracion = 60,
    }) => {
      'status': estado,
      'date': Timestamp.fromDate(fecha),
      'durationMinutes': duracion,
    };

    test('una cita completada se puede calificar', () {
      final datos = cita(
        estado: 'completed',
        fecha: ahora.subtract(const Duration(days: 1)),
      );
      expect(sePuedeCalificar(datos, ahora: ahora), isTrue);
    });

    test('una confirmada que ya terminó se puede calificar', () {
      final datos = cita(
        estado: 'confirmed',
        fecha: ahora.subtract(const Duration(hours: 3)),
      );
      expect(sePuedeCalificar(datos, ahora: ahora), isTrue);
    });

    test('una confirmada que todavía no termina no se puede calificar', () {
      final datos = cita(
        estado: 'confirmed',
        fecha: ahora.add(const Duration(hours: 2)),
      );
      expect(sePuedeCalificar(datos, ahora: ahora), isFalse);
    });

    test('una confirmada en curso no se puede calificar todavía', () {
      final datos = cita(
        estado: 'confirmed',
        fecha: ahora.subtract(const Duration(minutes: 20)),
      );
      expect(sePuedeCalificar(datos, ahora: ahora), isFalse);
    });

    test('una cancelada nunca se califica', () {
      final datos = cita(
        estado: 'cancelled',
        fecha: ahora.subtract(const Duration(days: 2)),
      );
      expect(sePuedeCalificar(datos, ahora: ahora), isFalse);
    });

    test('una solicitud sin responder no se califica', () {
      final datos = cita(
        estado: 'pending',
        fecha: ahora.subtract(const Duration(days: 2)),
      );
      expect(sePuedeCalificar(datos, ahora: ahora), isFalse);
    });
  });

  group('formatearCalificacion', () {
    test('siempre lleva un decimal', () {
      expect(formatearCalificacion(4), '4.0');
      expect(formatearCalificacion(4.25), '4.3');
      expect(formatearCalificacion(5.0), '5.0');
    });

    test('sin calificación devuelve un guion', () {
      expect(formatearCalificacion(null), '-');
      expect(formatearCalificacion(0), '-');
    });
  });

  group('contarResenas', () {
    test('no escribe "1 reseñas"', () {
      expect(contarResenas(1), '1 reseña');
      expect(contarResenas(0), '0 reseñas');
      expect(contarResenas(7), '7 reseñas');
    });
  });

  group('AjustesProfesional', () {
    test('un perfil sin ajustes acepta clientes y no auto-acepta', () {
      final ajustes = AjustesProfesional.desdeMapa({'name': 'Ana'});
      expect(ajustes.aceptandoClientas, isTrue);
      expect(ajustes.autoAceptar, isFalse);
    });

    test('lee los interruptores guardados', () {
      final ajustes = AjustesProfesional.desdeMapa({
        'ajustes': {'aceptandoClientas': false, 'autoAceptar': true},
      });
      expect(ajustes.aceptandoClientas, isFalse);
      expect(ajustes.autoAceptar, isTrue);
    });

    test('un perfil nulo usa los valores por defecto', () {
      final ajustes = AjustesProfesional.desdeMapa(null);
      expect(ajustes.aceptandoClientas, isTrue);
    });
  });

  group('validadores de texto', () {
    test('un comentario en blanco es válido, uno kilométrico no', () {
      expect(validarComentarioResena(''), isNull);
      expect(validarComentarioResena('Quedaron divinas'), isNull);
      expect(validarComentarioResena('a' * 501), isNotNull);
    });

    test('una respuesta vacía no se publica', () {
      expect(validarRespuestaResena('  '), isNotNull);
      expect(validarRespuestaResena('Gracias por venir'), isNull);
    });

    test('las especialidades tienen tope de cantidad', () {
      expect(validarEspecialidades('Gel, Acrilicas'), isNull);
      expect(
        validarEspecialidades(List.filled(11, 'Gel').join(', ')),
        isNotNull,
      );
    });

    test('un usuario de red social no lleva espacios', () {
      expect(validarUsuarioRed('mi_usuario'), isNull);
      expect(validarUsuarioRed('mi usuario'), isNotNull);
      expect(validarUsuarioRed(''), isNull);
    });

    test('separarPorComas ignora los vacíos', () {
      expect(separarPorComas('Gel, , Acrilicas ,'), ['Gel', 'Acrilicas']);
      expect(separarPorComas('  '), isEmpty);
    });
  });

  group('tiempoHastaCita', () {
    final ahora = DateTime(2026, 9, 1, 12, 0);

    Map<String, dynamic> cita(DateTime fecha, {String estado = 'confirmed'}) =>
        {
          'status': estado,
          'date': Timestamp.fromDate(fecha),
          'durationMinutes': 60,
        };

    test('minutos', () {
      final t = tiempoHastaCita(
        cita(ahora.add(const Duration(minutes: 40))),
        ahora: ahora,
      );
      expect(t, 'Faltan 40 minutos');
    });

    test('una hora exacta no dice minutos', () {
      final t = tiempoHastaCita(
        cita(ahora.add(const Duration(hours: 1))),
        ahora: ahora,
      );
      expect(t, 'Falta 1 hora');
    });

    test('horas con minutos', () {
      final t = tiempoHastaCita(
        cita(ahora.add(const Duration(hours: 3, minutes: 20))),
        ahora: ahora,
      );
      expect(t, 'Faltan 3 horas y 20 min');
    });

    test('dias', () {
      final t = tiempoHastaCita(
        cita(ahora.add(const Duration(days: 3))),
        ahora: ahora,
      );
      expect(t, 'Faltan 3 días');
    });

    test('una cita en curso lo dice', () {
      final t = tiempoHastaCita(
        cita(ahora.subtract(const Duration(minutes: 10))),
        ahora: ahora,
      );
      expect(t, 'En curso ahora');
    });

    test('una cita pasada no muestra contador', () {
      final t = tiempoHastaCita(
        cita(ahora.subtract(const Duration(days: 2))),
        ahora: ahora,
      );
      expect(t, isNull);
    });

    test('una solicitud sin responder tambien cuenta', () {
      final t = tiempoHastaCita(
        cita(ahora.add(const Duration(hours: 5)), estado: 'pending'),
        ahora: ahora,
      );
      expect(t, 'Faltan 5 horas');
    });
  });

  group('anticipacion minima', () {
    final servicio = ServicioDisponibilidad();
    final hoy = DateTime(2026, 9, 1);
    final ahora = DateTime(2026, 9, 1, 13, 40);

    List<FranjaHoraria> franjas(List<String> horas) => horas
        .map((h) => FranjaHoraria(hora: h, estado: EstadoFranja.libre))
        .toList();

    test('sin anticipacion solo descarta lo que ya paso', () {
      final libres = servicio.franjasReservables(
        franjas: franjas(['13:00', '14:00', '15:00']),
        fecha: hoy,
        duracionServicio: 60,
        intervalo: 60,
        ahora: ahora,
      );
      expect(libres.map((f) => f.hora), ['14:00', '15:00']);
    });

    test('con dos horas de plazo, las 2pm ya no sirven a la 1:40pm', () {
      final libres = servicio.franjasReservables(
        franjas: franjas(['14:00', '15:00', '16:00']),
        fecha: hoy,
        duracionServicio: 60,
        intervalo: 60,
        anticipacionMinutos: 120,
        ahora: ahora,
      );
      expect(libres.map((f) => f.hora), ['16:00']);
    });

    test('un dia de plazo deja el dia siguiente fuera si es muy temprano', () {
      final libres = servicio.franjasReservables(
        franjas: franjas(['09:00', '18:00']),
        fecha: DateTime(2026, 9, 2),
        duracionServicio: 60,
        intervalo: 60,
        anticipacionMinutos: 1440,
        ahora: ahora,
      );
      expect(libres.map((f) => f.hora), ['18:00']);
    });
  });

  group('etiquetaAnticipacion', () {
    test('lee natural en cada tramo', () {
      expect(etiquetaAnticipacion(0), 'Sin anticipación');
      expect(etiquetaAnticipacion(60), '1 hora antes');
      expect(etiquetaAnticipacion(180), '3 horas antes');
      expect(etiquetaAnticipacion(1440), '1 día antes');
      expect(etiquetaAnticipacion(2880), '2 días antes');
    });
  });
}
