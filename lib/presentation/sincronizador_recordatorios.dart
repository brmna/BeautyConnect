import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/models/cambio_solicitado.dart';
import '../data/services/servicio_disponibilidad.dart';
import '../data/services/servicio_notificaciones.dart';
import '../utils/estado_cita.dart';
import '../utils/franjas_cita.dart';

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

  final _estadoPrevio = <String, String>{};
  final _caducando = <String>{};
  bool _primeraCarga = true;

  @override
  void initState() {
    super.initState();
    ServicioNotificaciones.instancia.pedirPermiso();
    _escuchar();
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  void _escuchar() {
    final campo = widget.esProfesional ? 'professionalId' : 'clientId';

    _suscripcion = FirebaseFirestore.instance
        .collection('bookings')
        .where(campo, isEqualTo: widget.uid)
        .snapshots()
        .listen((consulta) {
          _caducarAbandonadas(consulta.docs);
          _avisarDeLosCambios(consulta.docs);

          final recordatorios = ServicioNotificaciones.desdeCitas(
            consulta.docs,
            esProfesional: widget.esProfesional,
          );
          ServicioNotificaciones.instancia.sincronizar(recordatorios);
        }, onError: (_) {});
  }

  // Las dos partes escuchan sus propias citas, asi que a la larga alguna de
  // las dos abre la app y cierra la solicitud abandonada. Escribir lo mismo
  // dos veces no hace daño: el estado deja de ser 'pending' y no vuelve a
  // entrar aqui.
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

  void _avisarDeLosCambios(List<QueryDocumentSnapshot> documentos) {
    final avisos = <({String titulo, String cuerpo})>[];

    for (final documento in documentos) {
      final datos = documento.data() as Map<String, dynamic>;
      final estado = (datos['status'] as String?) ?? 'pending';
      final anterior = _estadoPrevio[documento.id];
      _estadoPrevio[documento.id] = estado;

      if (_primeraCarga || anterior == estado) continue;

      final servicio = (datos['serviceName'] as String?) ?? 'una cita';
      final texto = _texto(
        nuevo: estado,
        esNueva: anterior == null,
        canceladaPor: datos['canceladaPor'] as String?,
      );
      if (texto != null) avisos.add((titulo: texto, cuerpo: servicio));
    }

    _primeraCarga = false;

    for (final aviso in avisos.take(3)) {
      ServicioNotificaciones.instancia.avisarAhora(
        titulo: aviso.titulo,
        cuerpo: aviso.cuerpo,
      );
    }
  }

  String? _texto({
    required String nuevo,
    required bool esNueva,
    required String? canceladaPor,
  }) {
    // Cancelar es lo unico que hacen las dos partes, asi que es lo unico que
    // hay que atribuir: si el movimiento fue tuyo, no te lo avisas a ti mismo.
    if (nuevo == 'cancelled') {
      if (canceladaPor == canceladaPorSistema) {
        return widget.esProfesional
            ? 'Una solicitud se venció sin respuesta'
            : 'Tu solicitud venció sin respuesta';
      }

      final mio = widget.esProfesional ? 'profesional' : 'cliente';
      if (canceladaPor == mio) return null;

      return widget.esProfesional
          ? 'Un cliente canceló su cita'
          : 'Cancelaron tu cita';
    }

    if (widget.esProfesional) {
      if (!esNueva) return null;
      if (nuevo == 'pending') return 'Nueva solicitud de cita';
      // Con auto-aceptar la cita nace confirmada, sin pasar por 'pending'.
      if (nuevo == 'confirmed') return 'Tienes una cita nueva';
      return null;
    }

    return nuevo == 'confirmed' ? 'Confirmaron tu cita' : null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
