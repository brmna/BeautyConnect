import '../data/models/cambio_solicitado.dart';
import '../data/models/modalidad_cita.dart';
import 'estado_cita.dart';
import 'formato.dart';
import 'novedades.dart';

class TextoAviso {
  final String titulo;
  final String cuerpo;
  final String detalle;

  const TextoAviso({
    required this.titulo,
    required this.cuerpo,
    required this.detalle,
  });
}

const List<String> _dias = [
  '',
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

const List<String> _meses = [
  '',
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

String diaHablado(DateTime fecha, {DateTime? ahora}) {
  final hoy = ahora ?? DateTime.now();
  final cuando = DateTime(fecha.year, fecha.month, fecha.day);
  final base = DateTime(hoy.year, hoy.month, hoy.day);
  final faltan = cuando.difference(base).inDays;

  if (faltan == 0) return 'hoy';
  if (faltan == 1) return 'mañana';
  if (faltan > 1 && faltan < 7) return 'el ${_dias[fecha.weekday]}';

  return 'el ${fecha.day} de ${_meses[fecha.month]}';
}

String momentoHablado(DateTime? fecha, {DateTime? ahora}) {
  if (fecha == null) return '';

  return '${diaHablado(fecha, ahora: ahora)} a las '
      '${formatearHoraDeFecha(fecha)}';
}

String servicioDeCita(Map<String, dynamic>? cita) {
  final nombre = (cita?['serviceName'] as String?)?.trim() ?? '';
  return nombre.isEmpty ? 'Servicio' : nombre;
}

String lugarDeCita(Map<String, dynamic>? cita, {required bool esProfesional}) {
  if (!modalidadDeCita(cita).esDomicilio) {
    return esProfesional ? 'En tu local' : 'En su local';
  }

  final barrio = (cita?['barrioCliente'] as String?)?.trim() ?? '';
  return barrio.isEmpty ? 'A domicilio' : 'A domicilio · $barrio';
}

String totalDeCita(Map<String, dynamic>? cita) {
  final precio = (cita?['servicePrice'] as num?) ?? 0;
  final recargo = modalidadDeCita(cita).esDomicilio ? recargoDeCita(cita) : 0;

  return formatearPrecio(precio + recargo);
}

DateTime? horaPropuesta(Map<String, dynamic>? cita) {
  final cambio = CambioSolicitado.deCita(cita);
  if (cambio == null) return null;

  final partes = cambio.hora.split(':');
  final hora = int.tryParse(partes.first.trim()) ?? 0;
  final minutos = partes.length > 1 ? int.tryParse(partes[1].trim()) ?? 0 : 0;

  return DateTime(
    cambio.fecha.year,
    cambio.fecha.month,
    cambio.fecha.day,
    hora,
    minutos,
  );
}

String _mayuscula(String texto) =>
    texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

String _juntar(List<String> lineas) =>
    lineas.where((l) => l.trim().isNotEmpty).join('\n');

TextoAviso avisoDeNovedad(
  Novedad novedad, {
  required bool esProfesional,
  String? nombre,
  DateTime? ahora,
}) {
  final cita = novedad.cita;
  final servicio = servicioDeCita(cita);
  final cuando = momentoHablado(inicioCita(cita), ahora: ahora);
  final lugar = lugarDeCita(cita, esProfesional: esProfesional);
  final total = totalDeCita(cita);
  final motivo = (cita['motivoCancelacion'] as String?)?.trim() ?? '';
  final propuesta = momentoHablado(horaPropuesta(cita), ahora: ahora);

  final titulo = novedad.tituloCon(nombre);

  String cuerpo;
  List<String> detalle;

  switch (novedad.tipo) {
    case TipoNovedad.cambioPedido:
      cuerpo = propuesta.isEmpty
          ? servicio
          : '$servicio · quiere moverla para $propuesta';
      detalle = [
        servicio,
        if (cuando.isNotEmpty) 'Ahora: ${_mayuscula(cuando)}',
        if (propuesta.isNotEmpty) 'Pide: ${_mayuscula(propuesta)}',
        lugar,
      ];

    case TipoNovedad.cancelada:
      cuerpo = motivo.isEmpty ? '$servicio · $cuando' : '$servicio · $motivo';
      detalle = [
        servicio,
        _mayuscula(cuando),
        if (motivo.isNotEmpty) 'Motivo: $motivo',
      ];

    case TipoNovedad.vencida:
      cuerpo = '$servicio · nadie la respondió a tiempo';
      detalle = [servicio, _mayuscula(cuando), 'Se venció sin respuesta'];

    case TipoNovedad.movida:
      cuerpo = cuando.isEmpty ? servicio : '$servicio · ahora es $cuando';
      detalle = [servicio, _mayuscula(cuando), lugar, total];

    case TipoNovedad.solicitudNueva:
    case TipoNovedad.citaNueva:
    case TipoNovedad.confirmada:
      cuerpo = cuando.isEmpty ? servicio : '$servicio · $cuando';
      detalle = [servicio, _mayuscula(cuando), lugar, total];
  }

  return TextoAviso(
    titulo: titulo,
    cuerpo: cuerpo.trim(),
    detalle: _juntar(detalle),
  );
}

TextoAviso avisoDeRecordatorio(
  Map<String, dynamic> cita, {
  required int horasAntes,
  required bool esProfesional,
  String? nombre,
}) {
  final fecha = inicioCita(cita);
  final hora = fecha == null ? '' : formatearHoraDeFecha(fecha);
  final servicio = servicioDeCita(cita);
  final lugar = lugarDeCita(cita, esProfesional: esProfesional);
  final persona = nombre?.trim() ?? '';

  final String titulo;
  if (horasAntes >= 24) {
    if (persona.isEmpty) {
      titulo = esProfesional
          ? 'Mañana atiendes una cita'
          : 'Mañana tienes cita';
    } else {
      titulo = esProfesional
          ? 'Mañana atiendes a $persona'
          : 'Mañana tienes cita con $persona';
    }
  } else {
    final cuantas = horasAntes == 1 ? '1 hora' : '$horasAntes horas';
    titulo = esProfesional ? 'Atiendes en $cuantas' : 'Tu cita es en $cuantas';
  }

  final cuerpo = hora.isEmpty ? servicio : '$hora · $servicio';
  final disparo = fecha?.subtract(Duration(hours: horasAntes));

  return TextoAviso(
    titulo: titulo,
    cuerpo: cuerpo,
    detalle: _juntar([
      servicio,
      if (fecha != null && disparo != null)
        '${_mayuscula(diaHablado(fecha, ahora: disparo))} a las $hora',
      lugar,
      if (persona.isNotEmpty)
        esProfesional ? 'Cliente: $persona' : 'Con $persona',
      totalDeCita(cita),
    ]),
  );
}
