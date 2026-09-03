import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as datos_zonas;
import 'package:timezone/timezone.dart' as zonas;

class RecordatorioCita {
  final String citaId;
  final String titulo;
  final String cuerpo;
  final DateTime fechaCita;

  const RecordatorioCita({
    required this.citaId,
    required this.titulo,
    required this.cuerpo,
    required this.fechaCita,
  });
}

class ServicioNotificaciones {
  ServicioNotificaciones._();
  static final ServicioNotificaciones instancia = ServicioNotificaciones._();

  static const String _idCanal = 'recordatorios_citas';
  static const String _idCanalAvisos = 'avisos_citas';
  static const List<int> _horasAntes = [24, 2];

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
          titulo: cita.titulo,
          cuerpo: horas >= 24
              ? 'Mañana ${DateFormat.jm().format(cita.fechaCita)} - ${cita.cuerpo}'
              : 'En $horas horas - ${cita.cuerpo}',
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
                  '|${c.titulo}|${c.cuerpo}',
            )
            .toList()
          ..sort();

    return lineas.join(';');
  }

  Future<void> avisarAhora({
    required String titulo,
    required String cuerpo,
  }) async {
    if (!_iniciado) await iniciar();
    if (!await hayPermiso()) return;

    _siguienteAviso = _siguienteAviso >= _idAvisoFinal
        ? _idAvisoInicial
        : _siguienteAviso + 1;

    await _plugin.show(
      _siguienteAviso,
      titulo,
      cuerpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _idCanalAvisos,
          'Movimientos de tus citas',
          channelDescription:
              'Solicitudes nuevas, confirmaciones y cancelaciones',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> _programar({
    required bool exacta,
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime momento,
  }) async {
    await _plugin.zonedSchedule(
      id,
      titulo,
      cuerpo,
      zonas.TZDateTime.from(momento, zonas.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _idCanal,
          'Recordatorios de citas',
          channelDescription: 'Avisos antes de cada cita agendada',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: exacta
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  int _identificador(String citaId, int horas) =>
      (citaId.hashCode ^ horas.hashCode) & 0x7fffffff;

  static List<RecordatorioCita> desdeCitas(
    List<QueryDocumentSnapshot> documentos, {
    required bool esProfesional,
  }) {
    final recordatorios = <RecordatorioCita>[];
    final ahora = DateTime.now();

    for (final documento in documentos) {
      final datos = documento.data() as Map<String, dynamic>;
      if (datos['status'] != 'confirmed') continue;

      final fecha = (datos['date'] as Timestamp?)?.toDate();
      if (fecha == null || !fecha.isAfter(ahora)) continue;

      recordatorios.add(
        RecordatorioCita(
          citaId: documento.id,
          titulo: esProfesional
              ? 'Tienes una cita agendada'
              : 'Recordatorio de tu cita',
          cuerpo: datos['serviceName'] ?? 'Cita agendada',
          fechaCita: fecha,
        ),
      );
    }

    return recordatorios;
  }
}
