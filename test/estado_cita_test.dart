import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_connect/utils/estado_cita.dart';

Map<String, dynamic> cita({
  required String estado,
  DateTime? fecha,
  int duracion = 60,
}) => {
  'status': estado,
  'date': fecha == null ? null : Timestamp.fromDate(fecha),
  'durationMinutes': duracion,
};

void main() {
  final ahora = DateTime(2026, 8, 29, 10, 0);

  group('clasificarCita', () {
    test('una solicitud para más tarde espera respuesta', () {
      final resultado = clasificarCita(
        cita(estado: 'pending', fecha: ahora.add(const Duration(hours: 3))),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.porResponder);
    });

    test('una solicitud cuya hora ya pasó queda vencida', () {
      final resultado = clasificarCita(
        cita(estado: 'pending', fecha: ahora.subtract(const Duration(days: 1))),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.vencida);
    });

    test('una confirmada de dentro de unas horas es próxima', () {
      final resultado = clasificarCita(
        cita(estado: 'confirmed', fecha: ahora.add(const Duration(hours: 4))),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.proxima);
      expect(resultado.estaPorVenir, isTrue);
    });

    test('una confirmada que ya empezó pero no termina sigue por venir', () {
      final resultado = clasificarCita(
        cita(
          estado: 'confirmed',
          fecha: ahora.subtract(const Duration(minutes: 20)),
          duracion: 90,
        ),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.enCurso);
      expect(resultado.estaPorVenir, isTrue);
    });

    test('una confirmada que ya terminó es pasada', () {
      final resultado = clasificarCita(
        cita(
          estado: 'confirmed',
          fecha: ahora.subtract(const Duration(hours: 3)),
          duracion: 60,
        ),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.pasada);
    });

    test('la duración cuenta: 100 minutos aún no terminan a los 90', () {
      final resultado = clasificarCita(
        cita(
          estado: 'confirmed',
          fecha: ahora.subtract(const Duration(minutes: 90)),
          duracion: 100,
        ),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.enCurso);
    });

    test('una cancelada es pasada aunque sea a futuro', () {
      final resultado = clasificarCita(
        cita(estado: 'cancelled', fecha: ahora.add(const Duration(days: 2))),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.pasada);
    });

    test('una completada es pasada', () {
      final resultado = clasificarCita(
        cita(estado: 'completed', fecha: ahora),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.pasada);
    });

    test('sin fecha no se pierde: sigue esperando respuesta', () {
      final resultado = clasificarCita(
        cita(estado: 'pending', fecha: null),
        ahora: ahora,
      );
      expect(resultado, EstadoCita.porResponder);
    });

    test('sin duración se asume una hora', () {
      final resultado = clasificarCita({
        'status': 'confirmed',
        'date': Timestamp.fromDate(ahora.subtract(const Duration(minutes: 30))),
      }, ahora: ahora);
      expect(resultado, EstadoCita.enCurso);
    });
  });
}
