import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/models/cambio_solicitado.dart';

enum TipoNovedad {
  solicitudNueva,
  citaNueva,
  cambioPedido,
  confirmada,
  movida,
  cancelada,
  vencida,
}

class Novedad {
  final String citaId;
  final TipoNovedad tipo;
  final String titulo;
  final String detalle;
  final DateTime momento;

  final String personaId;

  final String? plantilla;

  final Map<String, dynamic> cita;

  const Novedad({
    required this.citaId,
    required this.tipo,
    required this.titulo,
    required this.detalle,
    required this.momento,
    this.personaId = '',
    this.plantilla,
    this.cita = const {},
  });

  static const String marcaNombre = '{nombre}';

  String tituloCon(String? nombre) {
    final limpio = nombre?.trim() ?? '';
    final texto = plantilla;
    if (texto == null || limpio.isEmpty) return titulo;

    return texto.replaceAll(marcaNombre, limpio);
  }
}

DateTime? _sello(Object? datos, String clave) {
  if (datos is! Map) return null;
  final valor = datos[clave];
  return valor is Timestamp ? valor.toDate() : null;
}

String _servicio(Map<String, dynamic>? cita) {
  final nombre = (cita?['serviceName'] as String?)?.trim() ?? '';
  return nombre.isEmpty ? 'Servicio' : nombre;
}

String _conMotivo(Map<String, dynamic>? cita) {
  final servicio = _servicio(cita);
  final motivo = (cita?['motivoCancelacion'] as String?)?.trim() ?? '';
  return motivo.isEmpty ? servicio : '$servicio · $motivo';
}

Novedad? novedadDeCita(
  String citaId,
  Map<String, dynamic>? cita, {
  required bool esProfesional,
}) {
  if (cita == null) return null;

  final estado = (cita['status'] as String?) ?? 'pending';
  if (estado == 'completed') return null;

  final personaId =
      (esProfesional
          ? cita['clientId'] as String?
          : cita['professionalId'] as String?) ??
      '';

  Novedad? armar({
    required TipoNovedad tipo,
    required String titulo,
    required String detalle,
    required DateTime? momento,
    String? plantilla,
  }) {
    if (momento == null) return null;

    return Novedad(
      citaId: citaId,
      tipo: tipo,
      titulo: titulo,
      detalle: detalle,
      momento: momento,
      personaId: personaId,
      plantilla: plantilla,
      cita: cita,
    );
  }

  final creada = _sello(cita, 'createdAt');
  final respondida = _sello(cita, 'respondidoEn');
  final movida = _sello(cita, 'reagendadaEn');

  if (estado == 'cancelled') {
    final quien = cita['canceladaPor'] as String?;
    final mia = esProfesional ? 'profesional' : 'cliente';
    if (quien == mia) return null;

    final momento = respondida ?? movida ?? creada;

    if (quien == 'sistema') {
      return armar(
        tipo: TipoNovedad.vencida,
        titulo: esProfesional
            ? 'Una solicitud se venció'
            : 'Tu solicitud venció',
        plantilla: esProfesional ? 'La solicitud de {nombre} se venció' : null,
        detalle: '${_servicio(cita)} · nadie la respondió a tiempo',
        momento: momento,
      );
    }

    return armar(
      tipo: TipoNovedad.cancelada,
      titulo: esProfesional
          ? 'Un cliente canceló su cita'
          : 'Cancelaron tu cita',
      plantilla: esProfesional
          ? '{nombre} canceló su cita'
          : '{nombre} canceló tu cita',
      detalle: _conMotivo(cita),
      momento: momento,
    );
  }

  final cambio = CambioSolicitado.deCita(cita);

  if (esProfesional) {
    if (cambio != null) {
      return armar(
        tipo: TipoNovedad.cambioPedido,
        titulo: 'Te piden otro horario',
        plantilla: '{nombre} pide otro horario',
        detalle: _servicio(cita),
        momento: _sello(cita[CambioSolicitado.clave], 'pedidoEn') ?? creada,
      );
    }

    if (estado == 'pending') {
      return armar(
        tipo: TipoNovedad.solicitudNueva,
        titulo: 'Nueva solicitud de cita',
        plantilla: '{nombre} te pidió una cita',
        detalle: _servicio(cita),
        momento: creada,
      );
    }

    if (estado == 'confirmed' &&
        cita['autoAceptada'] == true &&
        movida == null) {
      return armar(
        tipo: TipoNovedad.citaNueva,
        titulo: 'Tienes una cita nueva',
        plantilla: '{nombre} reservó contigo',
        detalle: '${_servicio(cita)} · se aceptó sola',
        momento: creada,
      );
    }

    return null;
  }

  if (estado != 'confirmed') return null;

  if (movida != null) {
    return armar(
      tipo: TipoNovedad.movida,
      titulo: 'Te movieron la hora',
      plantilla: '{nombre} movió la hora',
      detalle: _servicio(cita),
      momento: movida,
    );
  }

  return armar(
    tipo: TipoNovedad.confirmada,
    titulo: 'Te confirmaron la cita',
    plantilla: '{nombre} confirmó tu cita',
    detalle: _servicio(cita),
    momento: respondida,
  );
}

List<Novedad> novedadesDeCitas(
  Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documentos, {
  required bool esProfesional,
  int limite = 40,
}) {
  final lista = <Novedad>[];

  for (final documento in documentos) {
    final novedad = novedadDeCita(
      documento.id,
      documento.data(),
      esProfesional: esProfesional,
    );
    if (novedad != null) lista.add(novedad);
  }

  lista.sort((a, b) => b.momento.compareTo(a.momento));

  return lista.length <= limite ? lista : lista.sublist(0, limite);
}

int contarSinVer(List<Novedad> novedades, DateTime? vistasEn) {
  if (vistasEn == null) return novedades.length;

  return novedades.where((n) => n.momento.isAfter(vistasEn)).length;
}

String hace(DateTime momento, {DateTime? ahora}) {
  final paso = (ahora ?? DateTime.now()).difference(momento);

  if (paso.isNegative || paso.inMinutes < 1) return 'Ahora';
  if (paso.inMinutes < 60) return 'Hace ${paso.inMinutes} min';
  if (paso.inHours < 24) {
    return paso.inHours == 1 ? 'Hace 1 hora' : 'Hace ${paso.inHours} horas';
  }
  if (paso.inDays == 1) return 'Ayer';
  if (paso.inDays < 7) return 'Hace ${paso.inDays} días';

  final semanas = paso.inDays ~/ 7;
  if (semanas < 5) {
    return semanas == 1 ? 'Hace 1 semana' : 'Hace $semanas semanas';
  }

  final meses = paso.inDays ~/ 30;
  return meses <= 1 ? 'Hace 1 mes' : 'Hace $meses meses';
}
