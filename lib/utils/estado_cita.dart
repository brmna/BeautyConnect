import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoCita { porResponder, vencida, proxima, enCurso, pasada }

extension AtributosEstadoCita on EstadoCita {
  bool get esperaRespuesta =>
      this == EstadoCita.porResponder || this == EstadoCita.vencida;

  bool get estaPorVenir =>
      this == EstadoCita.proxima || this == EstadoCita.enCurso;
}

DateTime? inicioCita(Map<String, dynamic>? cita) =>
    (cita?['date'] as Timestamp?)?.toDate();

DateTime? finCita(Map<String, dynamic>? cita) {
  final inicio = inicioCita(cita);
  if (inicio == null) return null;

  final minutos = (cita?['durationMinutes'] as num?)?.toInt() ?? 0;
  return inicio.add(Duration(minutes: minutos > 0 ? minutos : 60));
}

bool sePuedeCalificar(Map<String, dynamic>? cita, {DateTime? ahora}) {
  final estado = cita?['status'];
  if (estado == 'cancelled') return false;
  if (estado == 'completed') return true;
  if (estado != 'confirmed') return false;

  return clasificarCita(cita, ahora: ahora) == EstadoCita.pasada;
}

EstadoCita clasificarCita(Map<String, dynamic>? cita, {DateTime? ahora}) {
  final estado = cita?['status'] ?? 'pending';
  final momento = ahora ?? DateTime.now();
  final inicio = inicioCita(cita);
  final fin = finCita(cita);

  if (estado == 'completed' || estado == 'cancelled') return EstadoCita.pasada;

  if (inicio == null || fin == null) {
    return estado == 'pending' ? EstadoCita.porResponder : EstadoCita.proxima;
  }

  if (estado == 'pending') {
    return fin.isAfter(momento) ? EstadoCita.porResponder : EstadoCita.vencida;
  }

  if (!fin.isAfter(momento)) return EstadoCita.pasada;
  return inicio.isAfter(momento) ? EstadoCita.proxima : EstadoCita.enCurso;
}

String? tiempoHastaCita(Map<String, dynamic>? cita, {DateTime? ahora}) {
  final estado = clasificarCita(cita, ahora: ahora);
  if (estado == EstadoCita.enCurso) return 'En curso ahora';
  if (estado != EstadoCita.proxima && estado != EstadoCita.porResponder) {
    return null;
  }

  final inicio = inicioCita(cita);
  if (inicio == null) return null;

  final falta = inicio.difference(ahora ?? DateTime.now());
  if (falta.isNegative) return null;

  if (falta.inMinutes < 1) return 'Empieza en menos de un minuto';

  if (falta.inMinutes < 60) {
    final minutos = falta.inMinutes;
    return minutos == 1 ? 'Falta 1 minuto' : 'Faltan $minutos minutos';
  }

  if (falta.inHours < 24) {
    final horas = falta.inHours;
    final minutos = falta.inMinutes % 60;
    final verbo = horas == 1 ? 'Falta' : 'Faltan';
    final texto = horas == 1 ? '1 hora' : '$horas horas';
    return minutos == 0 ? '$verbo $texto' : '$verbo $texto y $minutos min';
  }

  final dias = falta.inDays;
  if (dias == 1) return 'Falta 1 día';
  if (dias < 7) return 'Faltan $dias días';

  final semanas = dias ~/ 7;
  return semanas == 1 ? 'Falta 1 semana' : 'Faltan $semanas semanas';
}
