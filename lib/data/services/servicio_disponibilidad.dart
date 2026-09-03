import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../utils/distancia.dart';
import '../../utils/estado_cita.dart';
import '../../utils/franjas_cita.dart';
import '../models/ajustes_profesional.dart';
import '../models/cambio_solicitado.dart';
import '../models/modalidad_cita.dart';
import '../models/horario.dart';
import '../models/ubicacion.dart';

class FranjaNoDisponible implements Exception {
  final String mensaje;
  const FranjaNoDisponible([this.mensaje = 'Esa hora ya fue reservada']);
}

class AgendaCerrada implements Exception {
  final String mensaje;
  const AgendaCerrada([
    this.mensaje = 'No está recibiendo citas nuevas por ahora',
  ]);
}

class SoloDomicilios implements Exception {
  final String mensaje;

  const SoloDomicilios([
    this.mensaje = 'Solo atiende a domicilio. Marca tu dirección',
  ]);
}

class SinDomicilios implements Exception {
  final String mensaje;
  const SinDomicilios([this.mensaje = 'No está haciendo domicilios']);
}

class FueraDeCobertura implements Exception {
  final double radioKm;

  const FueraDeCobertura(this.radioKm);

  String get mensaje =>
      'Esa dirección queda fuera de su zona. Solo va a domicilio '
      '${etiquetaRadio(radioKm).toLowerCase()}';
}

class FueraDePlazo implements Exception {
  final int anticipacionMinutos;

  const FueraDePlazo(this.anticipacionMinutos);

  String get mensaje =>
      'Esa hora ya está muy cerca. Pide con al menos '
      '${etiquetaAnticipacion(anticipacionMinutos).replaceAll(' antes', '')} '
      'de anticipación';
}

class ServicioDisponibilidad {
  final FirebaseFirestore? _instanciaInyectada;

  ServicioDisponibilidad({FirebaseFirestore? db}) : _instanciaInyectada = db;

  FirebaseFirestore get _db =>
      _instanciaInyectada ?? FirebaseFirestore.instance;

  static final DateFormat _formatoId = DateFormat('yyyy-MM-dd');

  String idFecha(DateTime fecha) => _formatoId.format(fecha);

  DocumentReference<Map<String, dynamic>> _refDia(String uid, DateTime fecha) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('disponibilidad')
          .doc(idFecha(fecha));

  Stream<HorarioBase> observarHorarioBase(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final datos = doc.data()?['horarioBase'];
      return HorarioBase.desdeMapa(
        datos == null ? null : Map<String, dynamic>.from(datos),
      );
    });
  }

  Future<void> guardarHorarioBase(String uid, HorarioBase horario) {
    return _db.collection('users').doc(uid).set({
      'horarioBase': horario.aMapa(),
    }, SetOptions(mergeFields: ['horarioBase']));
  }

  Future<Map<String, DisponibilidadDia>> ajustesEntre(
    String uid,
    DateTime desde,
    DateTime hasta,
  ) async {
    final instantanea = await _db
        .collection('users')
        .doc(uid)
        .collection('disponibilidad')
        .orderBy(FieldPath.documentId)
        .startAt([idFecha(desde)])
        .endAt([idFecha(hasta)])
        .get();

    return {
      for (final documento in instantanea.docs)
        documento.id: DisponibilidadDia.desdeMapa(documento.data()),
    };
  }

  List<DateTime> diasConCupo({
    required HorarioBase horario,
    required Map<String, DisponibilidadDia> ajustes,
    required List<DateTime> fechas,
    required int duracionServicio,
    int anticipacionMinutos = 0,
    DateTime? ahora,
  }) {
    return fechas.where((fecha) {
      final dia = ajustes[idFecha(fecha)] ?? DisponibilidadDia.vacia();

      final franjas = generarFranjas(horario: horario, dia: dia, fecha: fecha);
      if (franjas.isEmpty) return false;

      return franjasReservables(
        franjas: franjas,
        fecha: fecha,
        duracionServicio: duracionServicio,
        intervalo: horario.intervaloMinutos,
        anticipacionMinutos: anticipacionMinutos,
        ahora: ahora,
      ).isNotEmpty;
    }).toList();
  }

  Stream<DisponibilidadDia> observarDia(String uid, DateTime fecha) {
    return _refDia(
      uid,
      fecha,
    ).snapshots().map((doc) => DisponibilidadDia.desdeMapa(doc.data()));
  }

  List<FranjaHoraria> generarFranjas({
    required HorarioBase horario,
    required DisponibilidadDia dia,
    required DateTime fecha,
  }) {
    final horas = <String>{};

    final rango = horario.dias[fecha.weekday];
    if (rango != null) {
      horas.addAll(_horasDelRango(rango, horario.intervaloMinutos));
    }
    horas.addAll(dia.extras);

    final ordenadas = horas.toList()..sort();

    return ordenadas.map((hora) {
      final esExtra = dia.extras.contains(hora);
      final tramo = _tramoQueCubre(dia, hora, horario.intervaloMinutos);

      if (tramo != null || dia.reservadas.containsKey(hora)) {
        return FranjaHoraria(
          hora: hora,
          estado: EstadoFranja.reservada,
          citaId: tramo?.citaId ?? dia.reservadas[hora],
          esExtra: esExtra,
        );
      }
      if (dia.bloqueadas.contains(hora)) {
        return FranjaHoraria(
          hora: hora,
          estado: EstadoFranja.bloqueada,
          esExtra: esExtra,
        );
      }
      return FranjaHoraria(
        hora: hora,
        estado: EstadoFranja.libre,
        esExtra: esExtra,
      );
    }).toList();
  }

  TramoOcupado? _tramoQueCubre(
    DisponibilidadDia dia,
    String hora,
    int intervalo,
  ) {
    final inicioFranja = _aMinutos(hora);
    final finFranja = inicioFranja + (intervalo > 0 ? intervalo : 30);

    for (final tramo in dia.ocupadas) {
      final inicio = _aMinutos(tramo.inicio);
      final fin = _aMinutos(tramo.fin);
      if (inicioFranja < fin && finFranja > inicio) return tramo;
    }

    return null;
  }

  int franjasNecesarias(int duracionServicio, int intervalo) {
    if (intervalo <= 0) return 1;
    final necesarias = (duracionServicio / intervalo).ceil();
    return necesarias < 1 ? 1 : necesarias;
  }

  List<FranjaHoraria> franjasReservables({
    required List<FranjaHoraria> franjas,
    required DateTime fecha,
    required int duracionServicio,
    required int intervalo,
    int anticipacionMinutos = 0,
    DateTime? ahora,
  }) {
    final necesarias = franjasNecesarias(duracionServicio, intervalo);
    final momento = ahora ?? DateTime.now();
    final limite = momento.add(Duration(minutes: anticipacionMinutos));
    final disponibles = <FranjaHoraria>[];

    for (var i = 0; i + necesarias <= franjas.length; i++) {
      final bloque = franjas.sublist(i, i + necesarias);

      if (!bloque.every((f) => f.estaLibre)) continue;
      if (!_sonSeguidas(bloque, intervalo)) continue;
      if (!combinar(fecha, bloque.first.hora).isAfter(limite)) continue;

      disponibles.add(bloque.first);
    }

    return disponibles;
  }

  List<String> horasOcupadas({
    required String horaInicio,
    required int duracionServicio,
    required int intervalo,
  }) {
    final necesarias = franjasNecesarias(duracionServicio, intervalo);
    final inicio = _aMinutos(horaInicio);
    return List.generate(necesarias, (i) => _aTexto(inicio + i * intervalo));
  }

  bool _fueraDelRadio({
    required Ubicacion profesional,
    required Ubicacion? cliente,
    required double radioKm,
  }) {
    if (!profesional.tienePunto) return false;
    if (cliente == null || !cliente.tienePunto) return false;

    return distanciaKm(
          latitudA: profesional.latitud!,
          longitudA: profesional.longitud!,
          latitudB: cliente.latitud!,
          longitudB: cliente.longitud!,
        ) >
        radioKm;
  }

  bool _sonSeguidas(List<FranjaHoraria> bloque, int intervalo) {
    for (var i = 1; i < bloque.length; i++) {
      final anterior = _aMinutos(bloque[i - 1].hora);
      final actual = _aMinutos(bloque[i].hora);
      if (actual - anterior != intervalo) return false;
    }
    return true;
  }

  DateTime combinar(DateTime fecha, String hora) {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      int.parse(hora.substring(0, 2)),
      int.parse(hora.substring(3, 5)),
    );
  }

  Future<void> bloquearFranja(String uid, DateTime fecha, String hora) {
    return _refDia(uid, fecha).set({
      'bloqueadas': FieldValue.arrayUnion([hora]),
      'extras': FieldValue.arrayRemove([hora]),
    }, SetOptions(merge: true));
  }

  Future<void> liberarFranja(String uid, DateTime fecha, String hora) {
    return _refDia(uid, fecha).set({
      'bloqueadas': FieldValue.arrayRemove([hora]),
    }, SetOptions(merge: true));
  }

  Future<void> eliminarFranjaExtra(String uid, DateTime fecha, String hora) {
    return _refDia(uid, fecha).set({
      'extras': FieldValue.arrayRemove([hora]),
      'bloqueadas': FieldValue.arrayRemove([hora]),
    }, SetOptions(merge: true));
  }

  Future<void> agregarFranjaExtra(String uid, DateTime fecha, String hora) {
    return _refDia(uid, fecha).set({
      'extras': FieldValue.arrayUnion([hora]),
      'bloqueadas': FieldValue.arrayRemove([hora]),
    }, SetOptions(merge: true));
  }

  Future<String> reservar({
    required String profesionalId,
    required String clienteId,
    required DateTime fecha,
    required String hora,
    required String servicioId,
    required String servicioNombre,
    required num servicioPrecio,
    required int duracionMinutos,
    required int intervalo,
    ModalidadCita modalidad = ModalidadCita.local,
    Ubicacion? ubicacionCliente,
  }) async {
    final refDia = _refDia(profesionalId, fecha);
    final refCita = _db.collection('bookings').doc();
    final horas = horasOcupadas(
      horaInicio: hora,
      duracionServicio: duracionMinutos,
      intervalo: intervalo,
    );

    final tramo = TramoOcupado(
      inicio: horas.first,
      fin: _aTexto(_aMinutos(horas.last) + intervalo),
      citaId: refCita.id,
    );

    final refPerfil = _db.collection('users').doc(profesionalId);

    await _db.runTransaction((transaccion) async {
      final documento = await transaccion.get(refDia);
      final dia = DisponibilidadDia.desdeMapa(documento.data());

      final perfil = await transaccion.get(refPerfil);
      final ajustes = AjustesProfesional.desdeMapa(perfil.data());

      if (perfil.data()?['activo'] == false || !ajustes.aceptandoClientas) {
        throw const AgendaCerrada();
      }

      final limite = DateTime.now().add(
        Duration(minutes: ajustes.anticipacionMinutos),
      );
      if (!combinar(fecha, hora).isAfter(limite)) {
        throw FueraDePlazo(ajustes.anticipacionMinutos);
      }

      final aDomicilio = modalidad.esDomicilio;
      final ubicacionProfesional = Ubicacion.desdeMapa(perfil.data());

      if (aDomicilio && !ajustes.llegaADomicilio) {
        throw const SinDomicilios();
      }

      if (!aDomicilio && ajustes.soloDomicilio) {
        throw const SoloDomicilios();
      }

      if (aDomicilio &&
          _fueraDelRadio(
            profesional: ubicacionProfesional,
            cliente: ubicacionCliente,
            radioKm: ajustes.radioCoberturaKm,
          )) {
        throw FueraDeCobertura(ajustes.radioCoberturaKm);
      }

      for (final franja in horas) {
        if (dia.reservadas.containsKey(franja)) {
          throw const FranjaNoDisponible();
        }
        if (_tramoQueCubre(dia, franja, intervalo) != null) {
          throw const FranjaNoDisponible();
        }
        if (dia.bloqueadas.contains(franja)) {
          throw const FranjaNoDisponible('Esa hora ya no está disponible');
        }
      }

      transaccion.set(refDia, {
        'reservadas': {for (final franja in horas) franja: refCita.id},
        'ocupadas': [...dia.ocupadas.map((t) => t.aMapa()), tramo.aMapa()],
      }, SetOptions(merge: true));

      final confirmada = ajustes.autoAceptar;
      final direccion = confirmada ? ubicacionProfesional.resumen : '';

      final zonaCliente = aDomicilio ? ubicacionCliente : null;

      transaccion.set(refCita, {
        'professionalId': profesionalId,
        'clientId': clienteId,
        'serviceId': servicioId,
        'serviceName': servicioNombre,
        'servicePrice': servicioPrecio,
        'durationMinutes': duracionMinutos,
        'date': Timestamp.fromDate(combinar(fecha, hora)),
        'slot': hora,
        'slots': horas,
        'status': confirmada ? 'confirmed' : 'pending',
        'modalidad': modalidad.clave,
        if (aDomicilio) ...{
          'recargoDomicilio': ajustes.recargoDomicilio,
          'barrioCliente': zonaCliente?.barrio ?? '',
          if (zonaCliente?.latitudZona != null)
            'latitudZonaCliente': zonaCliente!.latitudZona,
          if (zonaCliente?.longitudZona != null)
            'longitudZonaCliente': zonaCliente!.longitudZona,
        },
        if (confirmada) ...{
          'autoAceptada': true,
          'respondidoEn': FieldValue.serverTimestamp(),
          'avisoVisto': false,
          if (!aDomicilio && direccion.isNotEmpty)
            'direccionProfesional': direccion,
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (aDomicilio && zonaCliente != null) {
        transaccion.set(refCita.collection('privado').doc('ubicacion'), {
          'clienteId': clienteId,
          'direccion': zonaCliente.direccion,
          'latitud': zonaCliente.latitud,
          'longitud': zonaCliente.longitud,
        });
      }
    });

    return refCita.id;
  }

  Future<void> reagendar({
    required String citaId,
    required String profesionalId,
    required DateTime fechaAnterior,
    required List<String> horasAnteriores,
    required DateTime fechaNueva,
    required String horaNueva,
    required int duracionMinutos,
    required int intervalo,
  }) async {
    final mismoDia = idFecha(fechaAnterior) == idFecha(fechaNueva);

    final refNueva = _refDia(profesionalId, fechaNueva);
    final refAnterior = _refDia(profesionalId, fechaAnterior);
    final refCita = _db.collection('bookings').doc(citaId);
    final refPerfil = _db.collection('users').doc(profesionalId);

    final horas = horasOcupadas(
      horaInicio: horaNueva,
      duracionServicio: duracionMinutos,
      intervalo: intervalo,
    );
    final tramo = TramoOcupado(
      inicio: horas.first,
      fin: _aTexto(_aMinutos(horas.last) + intervalo),
      citaId: citaId,
    );

    await _db.runTransaction((transaccion) async {
      final documento = await transaccion.get(refNueva);
      final perfil = await transaccion.get(refPerfil);
      final anterior = mismoDia ? null : await transaccion.get(refAnterior);

      final dia = DisponibilidadDia.desdeMapa(documento.data());
      final ajustes = AjustesProfesional.desdeMapa(perfil.data());

      final limite = DateTime.now().add(
        Duration(minutes: ajustes.anticipacionMinutos),
      );
      if (!combinar(fechaNueva, horaNueva).isAfter(limite)) {
        throw FueraDePlazo(ajustes.anticipacionMinutos);
      }

      for (final franja in horas) {
        final duena = dia.reservadas[franja];
        if (duena != null && duena != citaId) {
          throw const FranjaNoDisponible();
        }

        final cruce = _tramoQueCubre(dia, franja, intervalo);
        if (cruce != null && cruce.citaId != citaId) {
          throw const FranjaNoDisponible();
        }

        if (dia.bloqueadas.contains(franja)) {
          throw const FranjaNoDisponible('Esa hora ya no está disponible');
        }
      }

      final otrosTramos = dia.ocupadas
          .where((t) => t.citaId != citaId)
          .map((t) => t.aMapa())
          .toList();

      final sobran = mismoDia
          ? horasAnteriores.where((h) => !horas.contains(h))
          : const <String>[];

      transaccion.set(refNueva, {
        'reservadas': {
          for (final franja in horas) franja: citaId,
          for (final hora in sobran) hora: FieldValue.delete(),
        },
        'ocupadas': [...otrosTramos, tramo.aMapa()],
      }, SetOptions(merge: true));

      if (anterior != null && anterior.exists) {
        final diaAnterior = DisponibilidadDia.desdeMapa(anterior.data());

        transaccion.set(refAnterior, {
          if (horasAnteriores.isNotEmpty)
            'reservadas': {
              for (final hora in horasAnteriores) hora: FieldValue.delete(),
            },
          'ocupadas': diaAnterior.ocupadas
              .where((t) => t.citaId != citaId)
              .map((t) => t.aMapa())
              .toList(),
        }, SetOptions(merge: true));
      }

      transaccion.update(refCita, {
        'date': Timestamp.fromDate(combinar(fechaNueva, horaNueva)),
        'slot': horaNueva,
        'slots': horas,
        'reagendadaEn': FieldValue.serverTimestamp(),
        'avisoVisto': false,
        CambioSolicitado.clave: FieldValue.delete(),
      });
    });
  }

  Future<void> solicitarCambio({
    required String citaId,
    required DateTime fecha,
    required String hora,
  }) {
    final propuesta = CambioSolicitado(
      fecha: combinar(fecha, hora),
      hora: hora,
    );

    return _db.collection('bookings').doc(citaId).update({
      CambioSolicitado.clave: propuesta.aMapa(),
    });
  }

  Future<void> descartarCambio(String citaId) {
    return _db.collection('bookings').doc(citaId).update({
      CambioSolicitado.clave: FieldValue.delete(),
    });
  }

  Future<int> cancelarActivas({
    required String uid,
    required bool esProfesional,
    required String motivo,
  }) async {
    final campo = esProfesional ? 'professionalId' : 'clientId';

    final consulta = await _db
        .collection('bookings')
        .where(campo, isEqualTo: uid)
        .get();

    var cerradas = 0;

    for (final documento in consulta.docs) {
      final datos = documento.data();

      if (clasificarCita(datos) == EstadoCita.pasada) continue;

      await documento.reference.update({
        'status': 'cancelled',
        'canceladaPor': esProfesional ? 'profesional' : 'cliente',
        'motivoCancelacion': motivo,
        'respondidoEn': FieldValue.serverTimestamp(),
        'avisoVisto': false,
        CambioSolicitado.clave: FieldValue.delete(),
      });

      cerradas++;

      final fecha = inicioCita(datos);
      final profesionalId = datos['professionalId'] as String?;
      if (fecha == null || profesionalId == null) continue;

      await liberarReserva(
        profesionalId: profesionalId,
        fecha: fecha,
        horas: franjasDeLaCita(datos),
        citaId: documento.id,
      );
    }

    return cerradas;
  }

  Future<void> liberarReserva({
    required String profesionalId,
    required DateTime fecha,
    required List<String> horas,
    String? citaId,
  }) async {
    final referencia = _refDia(profesionalId, fecha);

    await _db.runTransaction((transaccion) async {
      final documento = await transaccion.get(referencia);
      if (!documento.exists) return;

      final dia = DisponibilidadDia.desdeMapa(documento.data());
      final quedan = dia.ocupadas
          .where((tramo) => citaId == null || tramo.citaId != citaId)
          .map((tramo) => tramo.aMapa())
          .toList();

      transaccion.set(referencia, {
        if (horas.isNotEmpty)
          'reservadas': {for (final hora in horas) hora: FieldValue.delete()},
        'ocupadas': quedan,
      }, SetOptions(merge: true));
    });
  }

  List<String> _horasDelRango(RangoHorario rango, int duracion) {
    final inicio = _aMinutos(rango.inicio);
    final fin = _aMinutos(rango.fin);
    final horas = <String>[];

    for (var minuto = inicio; minuto + duracion <= fin; minuto += duracion) {
      horas.add(_aTexto(minuto));
    }
    return horas;
  }

  int _aMinutos(String hora) =>
      int.parse(hora.substring(0, 2)) * 60 + int.parse(hora.substring(3, 5));

  String _aTexto(int minutos) =>
      '${(minutos ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutos % 60).toString().padLeft(2, '0')}';
}
