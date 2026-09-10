import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as datos_zonas;
import 'package:timezone/timezone.dart' as zonas;

import '../../utils/estado_cita.dart';
import '../../utils/texto_aviso.dart';

class RecordatorioCita {
  final String citaId;
  final DateTime fechaCita;
  final Map<String, dynamic> cita;
  final bool esProfesional;
  final String persona;

  const RecordatorioCita({
    required this.citaId,
    required this.fechaCita,
    required this.cita,
    required this.esProfesional,
    this.persona = '',
  });
}

class ServicioNotificaciones {
  ServicioNotificaciones._();
  static final ServicioNotificaciones instancia = ServicioNotificaciones._();

  static const String _idCanal = 'recordatorios_citas';
  static const String _idCanalAvisos = 'avisos_citas';
  static const String _idCanalMensajes = 'mensajes_chat';
  static const List<int> _horasAntes = [24, 2];

  String? chatAbierto;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _idAvisoInicial = 900000;
  static const int _idAvisoFinal = 900099;

  bool _iniciado = false;
  int _siguienteAviso = _idAvisoInicial;
  String? _ultimaTanda;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> iniciar() async {
    if (_iniciado) return;

    datos_zonas.initializeTimeZones();
    zonas.setLocalLocation(zonas.getLocation('America/Bogota'));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _idCanal,
        'Recordatorios de citas',
        description: 'Avisos antes de cada cita agendada',
        importance: Importance.high,
      ),
    );

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _idCanalAvisos,
        'Movimientos de tus citas',
        description: 'Solicitudes nuevas, confirmaciones y cancelaciones',
        importance: Importance.high,
      ),
    );

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _idCanalMensajes,
        'Mensajes',
        description: 'Mensajes nuevos en el chat de una cita',
        importance: Importance.high,
      ),
    );

    _iniciado = true;
  }

  Future<bool> pedirPermiso() async {
    if (!_iniciado) await iniciar();

    final android = _android;
    if (android == null) return false;

    if (await android.areNotificationsEnabled() ?? false) return true;

    return await android.requestNotificationsPermission() ?? false;
  }

  Future<bool> hayPermiso() async {
    if (!_iniciado) await iniciar();

    return await _android?.areNotificationsEnabled() ?? false;
  }

  Future<bool> puedeProgramarExactas() async {
    if (!_iniciado) await iniciar();

    return await _android?.canScheduleExactNotifications() ?? false;
  }

  Future<void> pedirAlarmasExactas() async {
    if (!_iniciado) await iniciar();

    await _android?.requestExactAlarmsPermission();
  }

  Future<void> sincronizar(List<RecordatorioCita> citas) async {
    if (!_iniciado) await iniciar();
    if (!await hayPermiso()) return;

    final tanda = _firma(citas);
    if (tanda == _ultimaTanda) return;

    final exactas = await puedeProgramarExactas();

    for (final pendiente in await _plugin.pendingNotificationRequests()) {
      await _plugin.cancel(pendiente.id);
    }

    final ahora = DateTime.now();

    for (final cita in citas) {
      for (final horas in _horasAntes) {
        final momento = cita.fechaCita.subtract(Duration(hours: horas));
        if (!momento.isAfter(ahora)) continue;

        await _programar(
          exacta: exactas,
          id: _identificador(cita.citaId, horas),
          texto: avisoDeRecordatorio(
            cita.cita,
            horasAntes: horas,
            esProfesional: cita.esProfesional,
            nombre: cita.persona,
          ),
          momento: momento,
        );
      }
    }

    _ultimaTanda = tanda;
  }

  static String _firma(List<RecordatorioCita> citas) {
    final lineas =
        citas
            .map(
              (c) =>
                  '${c.citaId}|${c.fechaCita.toIso8601String()}'
                  '|${c.persona}|${servicioDeCita(c.cita)}',
            )
            .toList()
          ..sort();

    return lineas.join(';');
  }

  Future<void> avisarAhora(TextoAviso texto, {bool esMensaje = false}) async {
    if (!_iniciado) await iniciar();
    if (!await hayPermiso()) return;

    _siguienteAviso = _siguienteAviso >= _idAvisoFinal
        ? _idAvisoInicial
        : _siguienteAviso + 1;

    await _plugin.show(
      _siguienteAviso,
      texto.titulo,
      texto.cuerpo,
      esMensaje
          ? _detalles(
              canal: _idCanalMensajes,
              nombre: 'Mensajes',
              descripcion: 'Mensajes nuevos en el chat de una cita',
              texto: texto,
            )
          : _detalles(
              canal: _idCanalAvisos,
              nombre: 'Movimientos de tus citas',
              descripcion: 'Solicitudes nuevas, confirmaciones y cancelaciones',
              texto: texto,
            ),
    );
  }

  NotificationDetails _detalles({
    required String canal,
    required String nombre,
    required String descripcion,
    required TextoAviso texto,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        canal,
        nombre,
        channelDescription: descripcion,
        importance: Importance.high,
        priority: Priority.high,
        ticker: texto.titulo,
        category: AndroidNotificationCategory.event,
        styleInformation: BigTextStyleInformation(
          texto.detalle.isEmpty ? texto.cuerpo : texto.detalle,
          contentTitle: texto.titulo,
          summaryText: texto.cuerpo,
        ),
      ),
    );
  }

  Future<void> _programar({
    required bool exacta,
    required int id,
    required TextoAviso texto,
    required DateTime momento,
  }) async {
    await _plugin.zonedSchedule(
      id,
      texto.titulo,
      texto.cuerpo,
      zonas.TZDateTime.from(momento, zonas.local),
      _detalles(
        canal: _idCanal,
        nombre: 'Recordatorios de citas',
        descripcion: 'Avisos antes de cada cita agendada',
        texto: texto,
      ),
      androidScheduleMode: exacta
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  int _identificador(String citaId, int horas) =>
      (citaId.hashCode ^ horas.hashCode) & 0x7fffffff;

  static String otraPersona(
    Map<String, dynamic> cita, {
    required bool esProfesional,
  }) =>
      (esProfesional
          ? cita['clientId'] as String?
          : cita['professionalId'] as String?) ??
      '';

  static List<RecordatorioCita> desdeCitas(
    List<QueryDocumentSnapshot> documentos, {
    required bool esProfesional,
    Map<String, String> nombres = const {},
  }) {
    final recordatorios = <RecordatorioCita>[];
    final ahora = DateTime.now();

    for (final documento in documentos) {
      final datos = documento.data() as Map<String, dynamic>;
      if (datos['status'] != 'confirmed') continue;

      final fecha = inicioCita(datos);
      if (fecha == null || !fecha.isAfter(ahora)) continue;

      final persona = otraPersona(datos, esProfesional: esProfesional);

      recordatorios.add(
        RecordatorioCita(
          citaId: documento.id,
          fechaCita: fecha,
          cita: datos,
          esProfesional: esProfesional,
          persona: nombres[persona] ?? '',
        ),
      );
    }

    return recordatorios;
  }
}
