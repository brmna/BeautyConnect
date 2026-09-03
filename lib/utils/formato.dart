import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _pesos = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
);

String formatearPrecio(num? valor) => _pesos.format(valor ?? 0);

String formatearFecha(DateTime fecha) => DateFormat.yMMMd().format(fecha);

String formatearFechaHora(DateTime fecha) =>
    '${DateFormat.yMMMd().format(fecha)} - ${formatearHoraDeFecha(fecha)}';

String formatearHora(String hora) {
  final partes = hora.split(':');
  final h = int.tryParse(partes.first.trim()) ?? 0;
  final minutos = partes.length > 1 ? partes[1].trim().padLeft(2, '0') : '00';

  return '${_hora12(h)}:$minutos ${_sufijo(h)}';
}

String formatearHoraDeFecha(DateTime fecha) =>
    '${_hora12(fecha.hour)}:${fecha.minute.toString().padLeft(2, '0')} '
    '${_sufijo(fecha.hour)}';

String formatearHoraDeReloj(TimeOfDay hora) =>
    '${_hora12(hora.hour)}:${hora.minute.toString().padLeft(2, '0')} '
    '${_sufijo(hora.hour)}';

String horaGuardable(TimeOfDay hora) =>
    '${hora.hour.toString().padLeft(2, '0')}:'
    '${hora.minute.toString().padLeft(2, '0')}';

int _hora12(int hora) => hora % 12 == 0 ? 12 : hora % 12;

String _sufijo(int hora) => hora < 12 ? 'AM' : 'PM';

String formatearDuracion(int minutos) {
  if (minutos <= 0) return 'Sin definir';

  final horas = minutos ~/ 60;
  final resto = minutos % 60;

  final textoHoras = horas == 1 ? '1 hora' : '$horas horas';
  final textoMinutos = resto == 1 ? '1 minuto' : '$resto minutos';

  if (horas == 0) return textoMinutos;
  if (resto == 0) return textoHoras;
  return '$textoHoras $textoMinutos';
}

String formatearDuracionCorta(int minutos) {
  if (minutos <= 0) return '--';

  final horas = minutos ~/ 60;
  final resto = minutos % 60;

  if (horas == 0) return '$resto min';
  if (resto == 0) return '$horas h';
  return '$horas h $resto min';
}

String formatearCalificacion(num? valor) {
  final numero = (valor ?? 0).toDouble();
  if (numero <= 0) return '-';
  return numero.toStringAsFixed(1);
}

String contarResenas(int total) => total == 1 ? '1 reseña' : '$total reseñas';
