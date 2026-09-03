import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'estado_vacio.dart';
import '../../data/models/ajustes_profesional.dart';
import '../../data/models/horario.dart';
import 'hoja_modal.dart';
import '../../data/services/servicio_chat.dart';
import '../../data/services/servicio_disponibilidad.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/margenes.dart';
import 'rejilla_opciones.dart';
import 'mensaje.dart';

class HojaReagendar extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> cita;
  final String profesionalId;
  final bool esSolicitud;

  const HojaReagendar({
    super.key,
    required this.cita,
    required this.profesionalId,
    this.esSolicitud = false,
  });

  static Future<bool?> abrir(
    BuildContext context, {
    required QueryDocumentSnapshot<Map<String, dynamic>> cita,
    required String profesionalId,
    bool esSolicitud = false,
  }) {
    return abrirHoja<bool>(
      context,
      hijo: HojaReagendar(
        cita: cita,
        profesionalId: profesionalId,
        esSolicitud: esSolicitud,
      ),
    );
  }

  @override
  State<HojaReagendar> createState() => _HojaReagendarState();
}

class _HojaReagendarState extends State<HojaReagendar> {
  final _servicio = ServicioDisponibilidad();

  HorarioBase? _horario;
  int _anticipacion = 0;
  List<DateTime> _dias = const [];
  DateTime? _fecha;
  String? _hora;
  bool _cargando = true;
  bool _guardando = false;

  Map<String, dynamic> get _datos => widget.cita.data();

  int get _duracion => (_datos['durationMinutes'] as num?)?.toInt() ?? 60;

  @override
  void initState() {
    super.initState();
    _cargarDias();
  }

  Future<void> _cargarDias() async {
    final hoy = DateTime.now();
    final base = DateTime(hoy.year, hoy.month, hoy.day);
    final candidatos = List.generate(30, (i) => base.add(Duration(days: i)));

    try {
      final horario = await _servicio
          .observarHorarioBase(widget.profesionalId)
          .first;
      final ajustes = await _servicio.ajustesEntre(
        widget.profesionalId,
        base,
        candidatos.last,
      );

      final perfil = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profesionalId)
          .get();
      final anticipacion = AjustesProfesional.desdeMapa(
        perfil.data(),
      ).anticipacionMinutos;

      final disponibles = _servicio.diasConCupo(
        horario: horario,
        ajustes: ajustes,
        fechas: candidatos,
        duracionServicio: _duracion,
        anticipacionMinutos: anticipacion,
      );

      if (!mounted) return;
      setState(() {
        _horario = horario;
        _anticipacion = anticipacion;
        _dias = disponibles;
        _fecha = disponibles.isEmpty ? null : disponibles.first;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    final fecha = _fecha;
    final hora = _hora;
    final horario = _horario;
    if (fecha == null || hora == null || horario == null) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    final fechaAnterior = (_datos['date'] as Timestamp?)?.toDate();

    if (widget.esSolicitud) {
      await _pedirCambio(fecha, hora, fechaAnterior);
      return;
    }

    try {
      await _servicio.reagendar(
        citaId: widget.cita.id,
        profesionalId: widget.profesionalId,
        fechaAnterior: fechaAnterior ?? fecha,
        horasAnteriores: List<String>.from(_datos['slots'] ?? const []),
        fechaNueva: fecha,
        horaNueva: hora,
        duracionMinutos: _duracion,
        intervalo: horario.intervaloMinutos,
      );

      final clienteId = _datos['clientId'] as String?;
      if (clienteId != null && fechaAnterior != null) {
        try {
          await ServicioChat().avisarCitaMovida(
            citaId: widget.cita.id,
            clienteId: clienteId,
            profesionalId: widget.profesionalId,
            servicio: _datos['serviceName'] ?? 'Servicio',
            fechaAnterior: fechaAnterior,
            fechaNueva: _servicio.combinar(fecha, hora),
          );
        } catch (_) {}
      }

      navegador.pop(true);
      mensajero.showSnackBar(
        construirMensaje(
          'Cita movida. Al cliente le llegará el aviso',
          tipo: TipoAviso.exito,
        ),
      );
      return;
    } on FranjaNoDisponible catch (e) {
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.error),
      );
    } on FueraDePlazo catch (e) {
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.aviso),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo mover la cita', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _guardando = false);
  }

  Future<void> _pedirCambio(
    DateTime fecha,
    String hora,
    DateTime? fechaAnterior,
  ) async {
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      await _servicio.solicitarCambio(
        citaId: widget.cita.id,
        fecha: fecha,
        hora: hora,
      );

      final clienteId = _datos['clientId'] as String?;
      if (clienteId != null && fechaAnterior != null) {
        try {
          await ServicioChat().avisarCambioPedido(
            citaId: widget.cita.id,
            clienteId: clienteId,
            profesionalId: widget.profesionalId,
            servicio: _datos['serviceName'] ?? 'Servicio',
            fechaActual: fechaAnterior,
            fechaPedida: _servicio.combinar(fecha, hora),
          );
        } catch (_) {}
      }

      navegador.pop(true);
      mensajero.showSnackBar(
        construirMensaje(
          'Le mandamos tu propuesta. Falta que la acepte',
          tipo: TipoAviso.exito,
        ),
      );
      return;
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo enviar la propuesta',
          tipo: TipoAviso.error,
        ),
      );
    }

    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final fechaActual = (_datos['date'] as Timestamp?)?.toDate();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: margenHoja(context, base: 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.esSolicitud ? 'Pedir otro horario' : 'Mover esta cita',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            fechaActual == null
                ? _datos['serviceName'] ?? 'Servicio'
                : '${_datos['serviceName'] ?? 'Servicio'} · '
                      'ahora el ${formatearFechaHora(fechaActual)}',
            style: const TextStyle(
              fontSize: 12.5,
              color: TemaApp.grisSubtitulo,
            ),
          ),
          const SizedBox(height: 18),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_dias.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No tienes días con cupo para este servicio',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TemaApp.grisTexto, fontSize: 13),
                ),
              ),
            )
          else ...[
            if (widget.esSolicitud) ...[
              const _NotaPropuesta(),
              const SizedBox(height: 14),
            ],
            SizedBox(height: 74, child: _tiraDeDias()),
            const SizedBox(height: 16),
            _horas(),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_hora == null || _guardando) ? null : _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.negro,
                foregroundColor: TemaApp.blanco,
              ),
              child: _guardando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.esSolicitud
                          ? 'Enviar la propuesta'
                          : 'Mover la cita',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tiraDeDias() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _dias.length,
      itemBuilder: (context, indice) {
        final dia = _dias[indice];
        final activo = _fecha != null && DateUtils.isSameDay(dia, _fecha!);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _fecha = dia;
            _hora = null;
          }),
          child: Container(
            width: 62,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: activo ? TemaApp.negro : TemaApp.grisClaro,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(dia).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: activo ? TemaApp.blanco : TemaApp.grisTexto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dia.day}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: activo ? TemaApp.blanco : TemaApp.textoOscuro,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _horas() {
    final fecha = _fecha;
    final horario = _horario;
    if (fecha == null || horario == null) return const SizedBox.shrink();

    return StreamBuilder<DisponibilidadDia>(
      stream: _servicio.observarDia(widget.profesionalId, fecha),
      builder: (context, instantanea) {
        if (!instantanea.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final franjas = _servicio.franjasReservables(
          franjas: _servicio.generarFranjas(
            horario: horario,
            dia: instantanea.data!,
            fecha: fecha,
          ),
          fecha: fecha,
          duracionServicio: _duracion,
          intervalo: horario.intervaloMinutos,
          anticipacionMinutos: _anticipacion,
        );

        if (franjas.isEmpty) {
          return const EstadoVacio(
            compacto: true,
            icono: Icons.schedule_outlined,
            titulo: 'No hay horas libres ese día',
            detalle: 'Prueba con otro día de la tira de arriba',
          );
        }

        return RejillaOpciones(
          hijos: franjas
              .map(
                (franja) => CeldaOpcion(
                  etiqueta: formatearHora(franja.hora),
                  activa: _hora == franja.hora,
                  onTocar: () => setState(() => _hora = franja.hora),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _NotaPropuesta extends StatelessWidget {
  const _NotaPropuesta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaApp.infoSuave,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: TemaApp.info),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Tu cita no se mueve todavía. Primero tiene que aceptar el '
              'nuevo horario.',
              style: TextStyle(fontSize: 12, height: 1.35, color: TemaApp.info),
            ),
          ),
        ],
      ),
    );
  }
}
