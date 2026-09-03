import 'package:beauty_connect/utils/novedades.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> cita({
  required String estado,
  String? canceladaPor,
  String? motivo,
  DateTime? creada,
  DateTime? respondida,
  DateTime? movida,
  bool autoAceptada = false,
  String servicio = 'Manicure',
}) => {
  'status': estado,
  'serviceName': servicio,
  'canceladaPor': ?canceladaPor,
  'motivoCancelacion': ?motivo,
  if (creada != null) 'createdAt': Timestamp.fromDate(creada),
  if (respondida != null) 'respondidoEn': Timestamp.fromDate(respondida),
  if (movida != null) 'reagendadaEn': Timestamp.fromDate(movida),
  if (autoAceptada) 'autoAceptada': true,
};

void main() {
  final ahora = DateTime(2026, 9, 3, 10, 0);
  final antes = ahora.subtract(const Duration(hours: 2));

  group('novedadDeCita para el cliente', () {
    test('una cita confirmada avisa que se la confirmaron', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'confirmed', respondida: antes),
        esProfesional: false,
      );

      expect(novedad?.tipo, TipoNovedad.confirmada);
      expect(novedad?.momento, antes);
    });

    test('si la reagendaron avisa que la movieron, no que la confirmaron', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'confirmed', respondida: antes, movida: ahora),
        esProfesional: false,
      );

      expect(novedad?.tipo, TipoNovedad.movida);
      expect(novedad?.momento, ahora);
    });

    test('su propia cancelacion no le aparece como novedad', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'cancelled', canceladaPor: 'cliente', respondida: antes),
        esProfesional: false,
      );

      expect(novedad, isNull);
    });

    test('la cancelacion de la manicurista si aparece, con el motivo', () {
      final novedad = novedadDeCita(
        'c1',
        cita(
          estado: 'cancelled',
          canceladaPor: 'profesional',
          motivo: 'Me enfermé',
          respondida: antes,
        ),
        esProfesional: false,
      );

      expect(novedad?.tipo, TipoNovedad.cancelada);
      expect(novedad?.detalle, contains('Me enfermé'));
    });

    test('una solicitud que vencio sola se avisa como vencida', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'cancelled', canceladaPor: 'sistema', respondida: antes),
        esProfesional: false,
      );

      expect(novedad?.tipo, TipoNovedad.vencida);
    });

    test('su propia solicitud pendiente no es novedad', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'pending', creada: antes),
        esProfesional: false,
      );

      expect(novedad, isNull);
    });
  });

  group('novedadDeCita para la manicurista', () {
    test('una solicitud pendiente es novedad', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'pending', creada: antes),
        esProfesional: true,
      );

      expect(novedad?.tipo, TipoNovedad.solicitudNueva);
      expect(novedad?.momento, antes);
    });

    test('una cita que ella confirmo no le vuelve como novedad', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'confirmed', respondida: antes),
        esProfesional: true,
      );

      expect(novedad, isNull);
    });

    test('una cita auto-aceptada si le avisa, porque nunca la respondio', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'confirmed', creada: antes, autoAceptada: true),
        esProfesional: true,
      );

      expect(novedad?.tipo, TipoNovedad.citaNueva);
    });

    test('su propia cancelacion no le aparece', () {
      final novedad = novedadDeCita(
        'c1',
        cita(
          estado: 'cancelled',
          canceladaPor: 'profesional',
          respondida: antes,
        ),
        esProfesional: true,
      );

      expect(novedad, isNull);
    });

    test('la cancelacion del cliente si le aparece', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'cancelled', canceladaPor: 'cliente', respondida: antes),
        esProfesional: true,
      );

      expect(novedad?.tipo, TipoNovedad.cancelada);
    });
  });

  group('reglas generales', () {
    test('una cita completada no genera novedad para nadie', () {
      final datos = cita(estado: 'completed', respondida: antes);

      expect(novedadDeCita('c1', datos, esProfesional: true), isNull);
      expect(novedadDeCita('c1', datos, esProfesional: false), isNull);
    });

    test('sin sello de tiempo no se inventa una novedad', () {
      final novedad = novedadDeCita(
        'c1',
        cita(estado: 'confirmed'),
        esProfesional: false,
      );

      expect(novedad, isNull);
    });
  });

  group('contarSinVer', () {
    Novedad enTal(DateTime momento) => Novedad(
      citaId: 'c',
      tipo: TipoNovedad.confirmada,
      titulo: 't',
      detalle: 'd',
      momento: momento,
    );

    test('sin marca previa cuenta todas', () {
      final lista = [enTal(antes), enTal(ahora)];

      expect(contarSinVer(lista, null), 2);
    });

    test('solo cuenta las posteriores a la ultima visita', () {
      final lista = [enTal(antes), enTal(ahora)];

      expect(contarSinVer(lista, antes), 1);
    });

    test('si ya vio todo no queda ninguna', () {
      final lista = [enTal(antes), enTal(ahora)];

      expect(contarSinVer(lista, ahora), 0);
    });
  });

  group('hace', () {
    test('lo recien pasado se lee como ahora', () {
      expect(hace(ahora, ahora: ahora), 'Ahora');
    });

    test('minutos', () {
      final momento = ahora.subtract(const Duration(minutes: 5));
      expect(hace(momento, ahora: ahora), 'Hace 5 min');
    });

    test('una hora en singular', () {
      final momento = ahora.subtract(const Duration(hours: 1));
      expect(hace(momento, ahora: ahora), 'Hace 1 hora');
    });

    test('el dia anterior se lee como ayer', () {
      final momento = ahora.subtract(const Duration(days: 1));
      expect(hace(momento, ahora: ahora), 'Ayer');
    });

    test('semanas', () {
      final momento = ahora.subtract(const Duration(days: 14));
      expect(hace(momento, ahora: ahora), 'Hace 2 semanas');
    });

    test('una fecha futura no dice tonterias', () {
      final momento = ahora.add(const Duration(hours: 3));
      expect(hace(momento, ahora: ahora), 'Ahora');
    });
  });
}
