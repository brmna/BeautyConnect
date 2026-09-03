import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/formato.dart';

class Mensaje {
  final String id;
  final String autorId;
  final String texto;
  final DateTime? fecha;
  final bool esAviso;

  const Mensaje({
    required this.id,
    required this.autorId,
    required this.texto,
    this.fecha,
    this.esAviso = false,
  });

  factory Mensaje.desdeDocumento(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final datos = documento.data();

    return Mensaje(
      id: documento.id,
      autorId: datos['autorId'] ?? '',
      texto: datos['texto'] ?? '',
      fecha: (datos['createdAt'] as Timestamp?)?.toDate(),
      esAviso: datos['tipo'] == 'aviso',
    );
  }
}

class ResumenChat {
  final String citaId;
  final String clienteId;
  final String profesionalId;
  final String servicio;
  final String ultimoMensaje;
  final DateTime? ultimoEn;
  final int sinLeer;
  final bool ultimoEsMio;

  const ResumenChat({
    required this.citaId,
    required this.clienteId,
    required this.profesionalId,
    required this.servicio,
    required this.ultimoMensaje,
    required this.sinLeer,
    required this.ultimoEsMio,
    this.ultimoEn,
  });

  String otroId({required bool esProfesional}) =>
      esProfesional ? clienteId : profesionalId;
}

class ServicioChat {
  final FirebaseFirestore? _instanciaInyectada;

  ServicioChat({FirebaseFirestore? db}) : _instanciaInyectada = db;

  FirebaseFirestore get _db =>
      _instanciaInyectada ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _chat(String citaId) =>
      _db.collection('chats').doc(citaId);

  CollectionReference<Map<String, dynamic>> _mensajes(String citaId) =>
      _chat(citaId).collection('mensajes');

  static String campoNoLeidos({required bool esProfesional}) =>
      esProfesional ? 'noLeidosProfesional' : 'noLeidosCliente';

  Stream<DocumentSnapshot<Map<String, dynamic>>> observarChat(String citaId) =>
      _chat(citaId).snapshots();

  Stream<List<Mensaje>> observarMensajes(String citaId) {
    return _mensajes(citaId)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((i) => i.docs.map(Mensaje.desdeDocumento).toList());
  }

  Stream<Map<String, int>> observarNoLeidos({
    required String uid,
    required bool esProfesional,
  }) {
    final campo = campoNoLeidos(esProfesional: esProfesional);

    return _db
        .collection('chats')
        .where('participantes', arrayContains: uid)
        .snapshots()
        .map((instantanea) {
          final conteo = <String, int>{};

          for (final documento in instantanea.docs) {
            final sinLeer = (documento.data()[campo] as num?)?.toInt() ?? 0;
            if (sinLeer > 0) conteo[documento.id] = sinLeer;
          }

          return conteo;
        });
  }

  Stream<List<ResumenChat>> observarConversaciones({
    required String uid,
    required bool esProfesional,
  }) {
    if (uid.isEmpty) return Stream.value(const []);

    final campo = campoNoLeidos(esProfesional: esProfesional);

    return _db
        .collection('chats')
        .where('participantes', arrayContains: uid)
        .snapshots()
        .map((instantanea) {
          final lista = <ResumenChat>[];

          for (final documento in instantanea.docs) {
            final datos = documento.data();
            final ultimo = (datos['ultimoMensaje'] as String?)?.trim() ?? '';
            if (ultimo.isEmpty) continue;

            lista.add(
              ResumenChat(
                citaId: documento.id,
                clienteId: datos['clienteId'] ?? '',
                profesionalId: datos['profesionalId'] ?? '',
                servicio: datos['servicio'] ?? 'Servicio',
                ultimoMensaje: ultimo,
                ultimoEn: (datos['ultimoEn'] as Timestamp?)?.toDate(),
                sinLeer: (datos[campo] as num?)?.toInt() ?? 0,
                ultimoEsMio: datos['ultimoAutorId'] == uid,
              ),
            );
          }

          lista.sort((a, b) {
            final fechaA = a.ultimoEn;
            final fechaB = b.ultimoEn;
            if (fechaA == null && fechaB == null) return 0;
            if (fechaA == null) return 1;
            if (fechaB == null) return -1;
            return fechaB.compareTo(fechaA);
          });

          return lista;
        });
  }

  Future<void> asegurarChat({
    required String citaId,
    required String clienteId,
    required String profesionalId,
    required String servicio,
  }) {
    return _chat(citaId).set({
      'citaId': citaId,
      'clienteId': clienteId,
      'profesionalId': profesionalId,
      'participantes': [clienteId, profesionalId],
      'servicio': servicio,
    }, SetOptions(merge: true));
  }

  Future<void> enviar({
    required String citaId,
    required String autorId,
    required String clienteId,
    required String profesionalId,
    required String servicio,
    required String texto,
    required bool esProfesional,
    bool esAviso = false,
  }) async {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;

    final campoDelOtro = campoNoLeidos(esProfesional: !esProfesional);

    final lote = _db.batch();

    lote.set(_chat(citaId), {
      'citaId': citaId,
      'clienteId': clienteId,
      'profesionalId': profesionalId,
      'participantes': [clienteId, profesionalId],
      'servicio': servicio,
      'ultimoMensaje': limpio,
      'ultimoEn': FieldValue.serverTimestamp(),
      'ultimoAutorId': autorId,
      campoDelOtro: FieldValue.increment(1),
    }, SetOptions(merge: true));

    lote.set(_mensajes(citaId).doc(), {
      'autorId': autorId,
      'texto': limpio,
      if (esAviso) 'tipo': 'aviso',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await lote.commit();
  }

  Future<void> avisarCitaMovida({
    required String citaId,
    required String clienteId,
    required String profesionalId,
    required String servicio,
    required DateTime fechaAnterior,
    required DateTime fechaNueva,
  }) {
    return _avisar(
      citaId: citaId,
      clienteId: clienteId,
      profesionalId: profesionalId,
      servicio: servicio,
      autorId: profesionalId,
      esProfesional: true,
      texto:
          'La cita se movió del ${formatearFechaHora(fechaAnterior)} '
          'al ${formatearFechaHora(fechaNueva)}',
    );
  }

  Future<void> avisarCambioPedido({
    required String citaId,
    required String clienteId,
    required String profesionalId,
    required String servicio,
    required DateTime fechaActual,
    required DateTime fechaPedida,
  }) {
    return _avisar(
      citaId: citaId,
      clienteId: clienteId,
      profesionalId: profesionalId,
      servicio: servicio,
      autorId: clienteId,
      esProfesional: false,
      texto:
          'Pidió mover la cita del ${formatearFechaHora(fechaActual)} '
          'al ${formatearFechaHora(fechaPedida)}',
    );
  }

  Future<void> avisarCambioRechazado({
    required String citaId,
    required String clienteId,
    required String profesionalId,
    required String servicio,
    required DateTime fechaPedida,
  }) {
    return _avisar(
      citaId: citaId,
      clienteId: clienteId,
      profesionalId: profesionalId,
      servicio: servicio,
      autorId: profesionalId,
      esProfesional: true,
      texto:
          'No pudo mover la cita al ${formatearFechaHora(fechaPedida)}. '
          'La cita sigue en su hora original',
    );
  }

  Future<void> avisarCitaCancelada({
    required String citaId,
    required String clienteId,
    required String profesionalId,
    required String servicio,
    required String motivo,
    bool porElCliente = false,
  }) {
    return _avisar(
      citaId: citaId,
      clienteId: clienteId,
      profesionalId: profesionalId,
      servicio: servicio,
      autorId: porElCliente ? clienteId : profesionalId,
      esProfesional: !porElCliente,
      texto: 'Canceló la cita. Motivo: $motivo',
    );
  }

  Future<void> _avisar({
    required String citaId,
    required String clienteId,
    required String profesionalId,
    required String servicio,
    required String autorId,
    required bool esProfesional,
    required String texto,
  }) async {
    await asegurarChat(
      citaId: citaId,
      clienteId: clienteId,
      profesionalId: profesionalId,
      servicio: servicio,
    );

    await enviar(
      citaId: citaId,
      autorId: autorId,
      clienteId: clienteId,
      profesionalId: profesionalId,
      servicio: servicio,
      texto: texto,
      esProfesional: esProfesional,
      esAviso: true,
    );
  }

  Future<void> marcarLeido({
    required String citaId,
    required String clienteId,
    required String profesionalId,
    required bool esProfesional,
  }) {
    return _chat(citaId).set({
      'participantes': [clienteId, profesionalId],
      campoNoLeidos(esProfesional: esProfesional): 0,
    }, SetOptions(merge: true));
  }
}
