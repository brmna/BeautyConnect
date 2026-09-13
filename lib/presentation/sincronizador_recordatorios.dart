import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/models/cambio_solicitado.dart';
import '../data/services/cache_perfiles.dart';
import '../data/services/servicio_disponibilidad.dart';
import '../data/services/servicio_notificaciones.dart';
import '../utils/estado_cita.dart';
import '../utils/franjas_cita.dart';
import '../utils/novedades.dart';
import '../utils/texto_aviso.dart';

class SincronizadorRecordatorios extends StatefulWidget {
  final String uid;
  final bool esProfesional;
  final Widget child;

  const SincronizadorRecordatorios({
    super.key,
    required this.uid,
    required this.esProfesional,
    required this.child,
  });

  @override
  State<SincronizadorRecordatorios> createState() =>
      _SincronizadorRecordatoriosState();
}

class _SincronizadorRecordatoriosState
    extends State<SincronizadorRecordatorios> {
  StreamSubscription<QuerySnapshot>? _suscripcion;
  StreamSubscription<QuerySnapshot>? _suscripcionChats;

  final _firmaPrevia = <String, String>{};
  final _firmaChat = <String, String>{};
  bool _primerosChats = true;
  final _caducando = <String>{};
  final _perfiles = CachePerfiles();
  final _inicio = DateTime.now();
  bool _primeraCarga = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pedirPermiso());
    _escuchar();
    _escucharChats();
  }

  Future<void> _pedirPermiso() async {
    try {
      await ServicioNotificaciones.instancia.pedirPermiso();
    } catch (_) {}
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _suscripcionChats?.cancel();
    super.dispose();
  }

  void _escuchar() {
    final campo = widget.esProfesional ? 'professionalId' : 'clientId';

    _suscripcion = FirebaseFirestore.instance
        .collection('bookings')
        .where(campo, isEqualTo: widget.uid)
        .snapshots()
        .listen((consulta) async {
          _caducarAbandonadas(consulta.docs);
          await _avisarDeLosCambios(consulta.docs);
          await _programarRecordatorios(consulta.docs);
        }, onError: (_) {});
  }

  void _escucharChats() {
    if (widget.uid.isEmpty) return;

    _suscripcionChats = FirebaseFirestore.instance
        .collection('chats')
        .where('participantes', arrayContains: widget.uid)
        .snapshots()
        .listen((consulta) async {
          await _avisarDeLosMensajes(consulta.docs);
        }, onError: (_) {});
  }

  Future<void> _avisarDeLosMensajes(
    List<QueryDocumentSnapshot> documentos,
  ) async {
    final nuevos = <Map<String, dynamic>>[];

    for (final documento in documentos) {
      final datos = documento.data() as Map<String, dynamic>;
      final momento = (datos['ultimoEn'] as Timestamp?)?.toDate();
      final firma = momento?.toIso8601String() ?? '';

      final anterior = _firmaChat[documento.id];
      _firmaChat[documento.id] = firma;

      if (_primerosChats || firma.isEmpty || anterior == firma) continue;
      if (!avisoVigente(momento, desde: _inicio)) continue;
      if (datos['ultimoAutorId'] == widget.uid) continue;
      if (datos['ultimoEsAviso'] == true) continue;
      if (_mirandoElChat(documento.id)) continue;

      nuevos.add(datos);
    }

    _primerosChats = false;

    for (final chat in nuevos.take(3)) {
      await ServicioNotificaciones.instancia.avisarAhora(
        avisoDeMensaje(
          chat,
          nombre: await _nombre(chat['ultimoAutorId'] as String? ?? ''),
        ),
        esMensaje: true,
      );
    }
  }

  bool _mirandoElChat(String citaId) {
    if (ServicioNotificaciones.instancia.chatAbierto != citaId) return false;

    return WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _caducarAbandonadas(List<QueryDocumentSnapshot> documentos) {
    for (final documento in documentos) {
      final datos = documento.data() as Map<String, dynamic>;

      if (!solicitudAbandonada(datos)) continue;
      if (!_caducando.add(documento.id)) continue;

      _caducar(documento.id, datos);
    }
  }

  Future<void> _caducar(String citaId, Map<String, dynamic> cita) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(citaId)
          .update({
            'status': 'cancelled',
            'canceladaPor': canceladaPorSistema,
            'motivoCancelacion': 'La solicitud se venció sin respuesta',
            'respondidoEn': FieldValue.serverTimestamp(),
            'avisoVisto': false,
            CambioSolicitado.clave: FieldValue.delete(),
          });

      final fecha = inicioCita(cita);
      final profesionalId = cita['professionalId'] as String?;
      if (fecha == null || profesionalId == null) return;

      await ServicioDisponibilidad().liberarReserva(
        profesionalId: profesionalId,
        fecha: fecha,
        horas: franjasDeLaCita(cita),
        citaId: citaId,
      );
    } catch (_) {
      _caducando.remove(citaId);
    }
  }

  Future<void> _avisarDeLosCambios(
    List<QueryDocumentSnapshot> documentos,
  ) async {
    final nuevas = <Novedad>[];

    for (final documento in documentos) {
      final datos = documento.data() as Map<String, dynamic>;
      final novedad = novedadDeCita(
        documento.id,
        datos,
        esProfesional: widget.esProfesional,
      );

      final firma = novedad == null
          ? ''
          : '${novedad.tipo.name}|${novedad.momento.toIso8601String()}';

      final anterior = _firmaPrevia[documento.id];
      _firmaPrevia[documento.id] = firma;

      if (_primeraCarga || novedad == null || anterior == firma) continue;
      if (!avisoVigente(novedad.momento, desde: _inicio)) continue;
      nuevas.add(novedad);
    }

    _primeraCarga = false;

    for (final novedad in nuevas.take(3)) {
      await ServicioNotificaciones.instancia.avisarAhora(
        avisoDeNovedad(
          novedad,
          esProfesional: widget.esProfesional,
          nombre: await _nombre(novedad.personaId),
        ),
      );
    }
  }

  Future<void> _programarRecordatorios(
    List<QueryDocumentSnapshot> documentos,
  ) async {
    final nombres = <String, String>{};
    final ahora = DateTime.now();

    for (final documento in documentos) {
      final datos = documento.data() as Map<String, dynamic>;
      if (datos['status'] != 'confirmed') continue;

      final fecha = inicioCita(datos);
      if (fecha == null || !fecha.isAfter(ahora)) continue;

      final uid = ServicioNotificaciones.otraPersona(
        datos,
        esProfesional: widget.esProfesional,
      );
      if (uid.isEmpty || nombres.containsKey(uid)) continue;

      nombres[uid] = await _nombre(uid);
    }

    await ServicioNotificaciones.instancia.sincronizar(
      ServicioNotificaciones.desdeCitas(
        documentos,
        esProfesional: widget.esProfesional,
        nombres: nombres,
      ),
    );
  }

  Future<String> _nombre(String uid) async {
    if (uid.isEmpty) return '';

    try {
      return (await _perfiles.resumen(uid)).nombre;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
