import 'package:beauty_connect/data/models/horario.dart';
import 'package:beauty_connect/data/services/servicio_disponibilidad.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  pruebasDeTramosOcupados();

  final servicio = ServicioDisponibilidad();

  final miercoles = DateTime(2026, 9, 2);

  HorarioBase horarioDe({
    required String inicio,
    required String fin,
    required int intervalo,
  }) {
    return HorarioBase(
      intervaloMinutos: intervalo,
      dias: {miercoles.weekday: RangoHorario(inicio: inicio, fin: fin)},
    );
  }

  group('generarFranjas', () {
    test('crea las franjas del rango segun el intervalo', () {
      final franjas = servicio.generarFranjas(
        horario: horarioDe(inicio: '09:00', fin: '12:00', intervalo: 60),
        dia: DisponibilidadDia.vacia(),
        fecha: miercoles,
      );

      expect(franjas.map((f) => f.hora), ['09:00', '10:00', '11:00']);
    });

    test('no genera franjas en un dia sin jornada', () {
      final franjas = servicio.generarFranjas(
        horario: horarioDe(inicio: '09:00', fin: '12:00', intervalo: 60),
        dia: DisponibilidadDia.vacia(),
        fecha: miercoles.add(const Duration(days: 1)),
      );

      expect(franjas, isEmpty);
    });

    test('marca reservadas y bloqueadas, e incluye las extras', () {
      final franjas = servicio.generarFranjas(
        horario: horarioDe(inicio: '09:00', fin: '12:00', intervalo: 60),
        dia: const DisponibilidadDia(
          bloqueadas: ['10:00'],
          extras: ['18:00'],
          reservadas: {'09:00': 'cita-1'},
        ),
        fecha: miercoles,
      );

      final porHora = {for (final f in franjas) f.hora: f.estado};

      expect(porHora['09:00'], EstadoFranja.reservada);
      expect(porHora['10:00'], EstadoFranja.bloqueada);
      expect(porHora['11:00'], EstadoFranja.libre);
      expect(porHora['18:00'], EstadoFranja.libre);
    });
  });

  group('franjasNecesarias', () {
    test('redondea hacia arriba cuando no es multiplo exacto', () {
      expect(servicio.franjasNecesarias(90, 30), 3);
      expect(servicio.franjasNecesarias(45, 30), 2);
      expect(servicio.franjasNecesarias(30, 30), 1);
      expect(servicio.franjasNecesarias(20, 30), 1);
    });
  });

  group('horasOcupadas', () {
    test('encadena las franjas que ocupa el servicio', () {
      final horas = servicio.horasOcupadas(
        horaInicio: '09:30',
        duracionServicio: 90,
        intervalo: 30,
      );

      expect(horas, ['09:30', '10:00', '10:30']);
    });

    test('un servicio corto ocupa una sola franja', () {
      final horas = servicio.horasOcupadas(
        horaInicio: '09:00',
        duracionServicio: 30,
        intervalo: 30,
      );

      expect(horas, ['09:00']);
    });
  });

  group('franjasReservables', () {
    final futuro = DateTime.now().add(const Duration(days: 30));
    final fecha = DateTime(futuro.year, futuro.month, futuro.day);

    List<FranjaHoraria> franjasDesde(DisponibilidadDia dia) {
      return servicio.generarFranjas(
        horario: HorarioBase(
          intervaloMinutos: 30,
          dias: {
            fecha.weekday: const RangoHorario(inicio: '09:00', fin: '12:00'),
          },
        ),
        dia: dia,
        fecha: fecha,
      );
    }

    test('un servicio largo no cabe si no hay franjas seguidas libres', () {
      final franjas = franjasDesde(
        const DisponibilidadDia(
          bloqueadas: [],
          extras: [],
          reservadas: {'10:30': 'cita-1'},
        ),
      );

      final reservables = servicio.franjasReservables(
        franjas: franjas,
        fecha: fecha,
        duracionServicio: 90,
        intervalo: 30,
      );

      expect(reservables.map((f) => f.hora), ['09:00']);
    });

    test('un servicio corto usa cualquier franja libre', () {
      final franjas = franjasDesde(
        const DisponibilidadDia(
          bloqueadas: [],
          extras: [],
          reservadas: {'10:30': 'cita-1'},
        ),
      );

      final reservables = servicio.franjasReservables(
        franjas: franjas,
        fecha: fecha,
        duracionServicio: 30,
        intervalo: 30,
      );

      expect(reservables.map((f) => f.hora), [
        '09:00',
        '09:30',
        '10:00',
        '11:00',
        '11:30',
      ]);
    });

    test('una franja extra separada no sirve para servicios largos', () {
      final franjas = franjasDesde(
        const DisponibilidadDia(
          bloqueadas: [],
          extras: ['18:00'],
          reservadas: {},
        ),
      );

      final reservables = servicio.franjasReservables(
        franjas: franjas,
        fecha: fecha,
        duracionServicio: 60,
        intervalo: 30,
      );

      expect(reservables.map((f) => f.hora).contains('18:00'), isFalse);
    });

    test('descarta las franjas que ya pasaron', () {
      final hoy = DateTime.now();
      final soloHoy = DateTime(hoy.year, hoy.month, hoy.day);

      final franjas = servicio.generarFranjas(
        horario: HorarioBase(
          intervaloMinutos: 30,
          dias: {
            soloHoy.weekday: const RangoHorario(inicio: '00:00', fin: '23:30'),
          },
        ),
        dia: DisponibilidadDia.vacia(),
        fecha: soloHoy,
      );

      final reservables = servicio.franjasReservables(
        franjas: franjas,
        fecha: soloHoy,
        duracionServicio: 30,
        intervalo: 30,
      );

      for (final franja in reservables) {
        expect(
          servicio.combinar(soloHoy, franja.hora).isAfter(DateTime.now()),
          isTrue,
        );
      }
    });
  });

  group('franjasReservables respeta la anticipacion minima', () {
    List<String> horasLibres({
      required int anticipacionMinutos,
      required DateTime ahora,
    }) {
      final horario = horarioDe(inicio: '09:00', fin: '18:00', intervalo: 60);
      final franjas = servicio.generarFranjas(
        horario: horario,
        dia: DisponibilidadDia.vacia(),
        fecha: miercoles,
      );

      return servicio
          .franjasReservables(
            franjas: franjas,
            fecha: miercoles,
            duracionServicio: 60,
            intervalo: 60,
            anticipacionMinutos: anticipacionMinutos,
            ahora: ahora,
          )
          .map((f) => f.hora)
          .toList();
    }

    test('sin anticipacion solo descarta lo ya pasado', () {
      final libres = horasLibres(
        anticipacionMinutos: 0,
        ahora: DateTime(2026, 9, 2, 12, 30),
      );

      expect(libres, isNot(contains('12:00')));
      expect(libres.first, '13:00');
    });

    test('con dos horas de anticipacion corre el limite', () {
      final libres = horasLibres(
        anticipacionMinutos: 120,
        ahora: DateTime(2026, 9, 2, 12, 30),
      );

      expect(libres, isNot(contains('13:00')));
      expect(libres, isNot(contains('14:00')));
      expect(libres.first, '15:00');
    });

    test('si la anticipacion tapa el dia entero no queda nada', () {
      final libres = horasLibres(
        anticipacionMinutos: 1440,
        ahora: DateTime(2026, 9, 2, 8, 0),
      );

      expect(libres, isEmpty);
    });
  });
}

void pruebasDeTramosOcupados() {
  final servicio = ServicioDisponibilidad();
  final miercoles = DateTime(2026, 9, 2);

  HorarioBase horarioDe(int intervalo) => HorarioBase(
    intervaloMinutos: intervalo,
    dias: {
      miercoles.weekday: const RangoHorario(inicio: '09:00', fin: '13:00'),
    },
  );

  final diaConCita = DisponibilidadDia(
    bloqueadas: const [],
    extras: const [],
    reservadas: const {'10:00': 'cita1', '11:00': 'cita1'},
    ocupadas: const [
      TramoOcupado(inicio: '10:00', fin: '12:00', citaId: 'cita1'),
    ],
  );

  group('tramos ocupados', () {
    test(
      'con el intervalo original las franjas de la cita salen reservadas',
      () {
        final franjas = servicio.generarFranjas(
          horario: horarioDe(60),
          dia: diaConCita,
          fecha: miercoles,
        );

        final reservadas = franjas
            .where((f) => f.estado == EstadoFranja.reservada)
            .map((f) => f.hora);

        expect(reservadas, ['10:00', '11:00']);
      },
    );

    test('al bajar el intervalo no quedan huecos libres dentro de la cita', () {
      final franjas = servicio.generarFranjas(
        horario: horarioDe(30),
        dia: diaConCita,
        fecha: miercoles,
      );

      final reservadas = franjas
          .where((f) => f.estado == EstadoFranja.reservada)
          .map((f) => f.hora);

      expect(reservadas, ['10:00', '10:30', '11:00', '11:30']);
    });

    test('las franjas fuera del tramo siguen libres', () {
      final franjas = servicio.generarFranjas(
        horario: horarioDe(30),
        dia: diaConCita,
        fecha: miercoles,
      );

      final libres = franjas.where((f) => f.estaLibre).map((f) => f.hora);

      expect(libres, contains('09:30'));
      expect(libres, contains('12:00'));
      expect(libres, isNot(contains('11:30')));
    });

    test('una franja que empieza antes pero se cruza queda reservada', () {
      final dia = DisponibilidadDia(
        bloqueadas: const [],
        extras: const [],
        reservadas: const {},
        ocupadas: const [
          TramoOcupado(inicio: '10:15', fin: '11:00', citaId: 'cita2'),
        ],
      );

      final franjas = servicio.generarFranjas(
        horario: horarioDe(60),
        dia: dia,
        fecha: miercoles,
      );

      final reservadas = franjas
          .where((f) => f.estado == EstadoFranja.reservada)
          .map((f) => f.hora);

      expect(reservadas, ['10:00']);
    });

    test('un dia sin tramos no reserva nada', () {
      final franjas = servicio.generarFranjas(
        horario: horarioDe(60),
        dia: DisponibilidadDia.vacia(),
        fecha: miercoles,
      );

      expect(franjas.every((f) => f.estaLibre), isTrue);
    });
  });

  group('franjaEnCurso', () {
    final dia = DateTime(2026, 9, 3);

    test('la franja que contiene el momento actual esta en curso', () {
      final enCurso = franjaEnCurso(
        fecha: dia,
        hora: '10:00',
        intervalo: 60,
        ahora: DateTime(2026, 9, 3, 10, 30),
      );

      expect(enCurso, isTrue);
    });

    test('justo al empezar ya cuenta como en curso', () {
      final enCurso = franjaEnCurso(
        fecha: dia,
        hora: '10:00',
        intervalo: 60,
        ahora: DateTime(2026, 9, 3, 10, 0),
      );

      expect(enCurso, isTrue);
    });

    test('justo al terminar ya no esta en curso', () {
      final enCurso = franjaEnCurso(
        fecha: dia,
        hora: '10:00',
        intervalo: 60,
        ahora: DateTime(2026, 9, 3, 11, 0),
      );

      expect(enCurso, isFalse);
    });

    test('una franja que todavia no empieza no esta en curso', () {
      final enCurso = franjaEnCurso(
        fecha: dia,
        hora: '15:00',
        intervalo: 60,
        ahora: DateTime(2026, 9, 3, 10, 30),
      );

      expect(enCurso, isFalse);
    });

    test('otro dia a la misma hora no esta en curso', () {
      final enCurso = franjaEnCurso(
        fecha: dia.add(const Duration(days: 1)),
        hora: '10:00',
        intervalo: 60,
        ahora: DateTime(2026, 9, 3, 10, 30),
      );

      expect(enCurso, isFalse);
    });

    test('sin intervalo valido se asume media hora', () {
      final dentro = franjaEnCurso(
        fecha: dia,
        hora: '10:00',
        intervalo: 0,
        ahora: DateTime(2026, 9, 3, 10, 20),
      );
      final fuera = franjaEnCurso(
        fecha: dia,
        hora: '10:00',
        intervalo: 0,
        ahora: DateTime(2026, 9, 3, 10, 40),
      );

      expect(dentro, isTrue);
      expect(fuera, isFalse);
    });

    test('una hora con formato roto no rompe nada', () {
      final enCurso = franjaEnCurso(
        fecha: dia,
        hora: 'abc',
        intervalo: 60,
        ahora: DateTime(2026, 9, 3, 10, 30),
      );

      expect(enCurso, isFalse);
    });
  });
}
