import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/services/servicio_notificaciones.dart';

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
          _avisarDeLosCambios(consulta.docs);

          final recordatorios = ServicioNotificaciones.desdeCitas(
            consulta.docs,
            esProfesional: widget.esProfesional,
          );
          ServicioNotificaciones.instancia.sincronizar(recordatorios);
        }, onError: (_) {});
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
      final texto = _texto(nuevo: estado, esNueva: anterior == null);
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

  String? _texto({required String nuevo, required bool esNueva}) {
    if (widget.esProfesional) {
      if (esNueva && nuevo == 'pending') return 'Nueva solicitud de cita';
      if (nuevo == 'cancelled') return 'Un cliente canceló su cita';
      return null;
    }

    switch (nuevo) {
      case 'confirmed':
        return 'Confirmaron tu cita';
      case 'cancelled':
        return 'Cancelaron tu cita';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
