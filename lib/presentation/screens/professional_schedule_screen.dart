import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/horario.dart';
import '../widgets/hoja_modal.dart';
import '../../data/services/servicio_disponibilidad.dart';
import '../../theme/app_theme.dart';
import '../widgets/cabecera_pantalla.dart';
import '../widgets/calendario_mes.dart';
import '../../utils/formato.dart';
import '../widgets/hoja_hora.dart';
import '../widgets/mensaje.dart';
import '../widgets/rejilla_opciones.dart';
import '../../utils/margenes.dart';

class PantallaAgendaProfesional extends StatefulWidget {
  final bool embebida;

  const PantallaAgendaProfesional({super.key, this.embebida = false});

  @override
  State<PantallaAgendaProfesional> createState() =>
      _PantallaAgendaProfesionalState();
}

class _PantallaAgendaProfesionalState extends State<PantallaAgendaProfesional> {
  final _servicio = ServicioDisponibilidad();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late DateTime _fechaSeleccionada;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fechaSeleccionada = DateTime(hoy.year, hoy.month, hoy.day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: StreamBuilder<HorarioBase>(
        stream: _servicio.observarHorarioBase(_uid),
        builder: (context, horarioSnap) {
          if (!horarioSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final horario = horarioSnap.data!;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (!widget.embebida)
                CabeceraPantalla(
                  titulo: 'Mi Agenda',
                  subtitulo: 'Gestiona tu disponibilidad y citas',
                  icono: Icons.calendar_month_outlined,
                  estilo: EstiloCabecera.destacada,
                  accion: IconButton(
                    tooltip: 'Horario base',
                    icon: const Icon(Icons.tune),
                    onPressed: _abrirHorarioBase,
                  ),
                ),
              if (widget.embebida)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _abrirHorarioBase,
                      icon: const Icon(Icons.tune, size: 17),
                      label: const Text('Horario base'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: CalendarioMes(
                  seleccionada: _fechaSeleccionada,
                  onSeleccionar: (fecha) =>
                      setState(() => _fechaSeleccionada = fecha),
                ),
              ),
              if (!horario.estaConfigurado)
                _AvisoSinHorario(onConfigurar: _abrirHorarioBase),
              StreamBuilder<DisponibilidadDia>(
                stream: _servicio.observarDia(_uid, _fechaSeleccionada),
                builder: (context, diaSnap) {
                  if (!diaSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final franjas = _servicio.generarFranjas(
                    horario: horario,
                    dia: diaSnap.data!,
                    fecha: _fechaSeleccionada,
                  );

                  return _ListaFranjas(
                    franjas: franjas,
                    fecha: _fechaSeleccionada,
                    intervalo: horario.intervaloMinutos,
                    onAlternar: _alternarFranja,
                    onAgregar: _agregarFranja,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _alternarFranja(FranjaHoraria franja) async {
    final mensajero = ScaffoldMessenger.of(context);

    if (franja.esExtra && franja.estado != EstadoFranja.reservada) {
      await _confirmarEliminarExtra(franja);
      return;
    }

    if (franja.estado == EstadoFranja.reservada) {
      mensajero.showSnackBar(
        construirMensaje(
          'Esa franja tiene una cita. Gestiónala en Citas',
          tipo: TipoAviso.aviso,
        ),
      );
      return;
    }

    try {
      if (franja.estado == EstadoFranja.bloqueada) {
        await _servicio.liberarFranja(_uid, _fechaSeleccionada, franja.hora);
      } else {
        await _servicio.bloquearFranja(_uid, _fechaSeleccionada, franja.hora);
      }
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo actualizar la franja',
          tipo: TipoAviso.error,
        ),
      );
    }
  }

  Future<void> _confirmarEliminarExtra(FranjaHoraria franja) async {
    final mensajero = ScaffoldMessenger.of(context);

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Quitar esta franja'),
        content: Text(
          'La franja de las ${formatearHora(franja.hora)} la agregaste a mano '
          'para este día. ¿Quieres quitarla?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: TemaApp.error),
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _servicio.eliminarFranjaExtra(
        _uid,
        _fechaSeleccionada,
        franja.hora,
      );
      mensajero.showSnackBar(
        construirMensaje('Franja eliminada', tipo: TipoAviso.exito),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo quitar la franja', tipo: TipoAviso.error),
      );
    }
  }

  Future<void> _agregarFranja() async {
    final hora = await elegirHora(
      context,
      inicial: const TimeOfDay(hour: 9, minute: 0),
      ayuda: 'Agregar franja',
    );
    if (hora == null || !mounted) return;

    final texto = horaGuardable(hora);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await _servicio.agregarFranjaExtra(_uid, _fechaSeleccionada, texto);
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo agregar la franja', tipo: TipoAviso.error),
      );
    }
  }

  void _abrirHorarioBase() {
    abrirHoja(
      context,
      hijo: _HojaHorarioBase(uid: _uid, servicio: _servicio),
    );
  }
}

TimeOfDay _aTimeOfDay(String hora) => TimeOfDay(
  hour: int.parse(hora.substring(0, 2)),
  minute: int.parse(hora.substring(3, 5)),
);

class _AvisoSinHorario extends StatelessWidget {
  final VoidCallback onConfigurar;

  const _AvisoSinHorario({required this.onConfigurar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.grisClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aún no defines tu horario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configura tu jornada habitual una vez y la agenda se genera sola.',
            style: TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onConfigurar,
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaApp.negro,
              foregroundColor: TemaApp.blanco,
            ),
            child: const Text('Configurar horario'),
          ),
        ],
      ),
    );
  }
}

class _ListaFranjas extends StatelessWidget {
  final List<FranjaHoraria> franjas;
  final DateTime fecha;
  final int intervalo;
  final ValueChanged<FranjaHoraria> onAlternar;
  final VoidCallback onAgregar;

  const _ListaFranjas({
    required this.franjas,
    required this.fecha,
    required this.intervalo,
    required this.onAlternar,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final libres = franjas.where((f) => f.estaLibre).length;
    final reservadas = franjas
        .where((f) => f.estado == EstadoFranja.reservada)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.MMMMEEEEd().format(fecha),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAgregar,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar'),
              ),
            ],
          ),
          Text(
            '$libres libres  -  $reservadas reservadas',
            style: const TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
          ),
          const SizedBox(height: 16),
          if (franjas.isEmpty)
            const SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 56,
                      color: TemaApp.grisTexto,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No atiendes este día',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: TemaApp.grisTexto),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Puedes agregar una franja puntual',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: TemaApp.grisTexto),
                    ),
                  ],
                ),
              ),
            )
          else
            RejillaOpciones(
              hijos: franjas
                  .map(
                    (franja) => _ChipFranja(
                      franja: franja,
                      enCurso: franjaEnCurso(
                        fecha: fecha,
                        hora: franja.hora,
                        intervalo: intervalo,
                      ),
                      onTap: () => onAlternar(franja),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ChipFranja extends StatelessWidget {
  final FranjaHoraria franja;
  final bool enCurso;
  final VoidCallback onTap;

  const _ChipFranja({
    required this.franja,
    required this.enCurso,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    late final Color fondo;
    late final Color texto;
    late final String etiqueta;

    switch (franja.estado) {
      case EstadoFranja.reservada:
        fondo = enCurso ? TemaApp.exitoSuave : TemaApp.infoSuave;
        texto = enCurso ? TemaApp.exito : TemaApp.info;
        etiqueta = enCurso ? 'En proceso' : 'Reservada';
      case EstadoFranja.bloqueada:
        fondo = TemaApp.grisBorde;
        texto = TemaApp.grisSubtitulo;
        etiqueta = 'Bloqueada';
      case EstadoFranja.libre:
        fondo = TemaApp.blanco;
        texto = TemaApp.textoOscuro;
        etiqueta = 'Disponible';
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: franja.estaLibre ? TemaApp.grisBorde : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatearHora(franja.hora),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: texto,
                  decoration: franja.estado == EstadoFranja.bloqueada
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (franja.esExtra) ...[
                  Icon(Icons.add_circle_outline, size: 11, color: texto),
                  const SizedBox(width: 3),
                ],
                Expanded(
                  child: Text(
                    franja.esExtra ? 'Agregada' : etiqueta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: texto),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HojaHorarioBase extends StatefulWidget {
  final String uid;
  final ServicioDisponibilidad servicio;

  const _HojaHorarioBase({required this.uid, required this.servicio});

  @override
  State<_HojaHorarioBase> createState() => _HojaHorarioBaseState();
}

class _HojaHorarioBaseState extends State<_HojaHorarioBase> {
  HorarioBase? _horario;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    widget.servicio.observarHorarioBase(widget.uid).first.then((horario) {
      if (!mounted) return;
      setState(() {
        _horario = horario.estaConfigurado ? horario : HorarioBase.porDefecto();
      });
    });
  }

  Future<void> _guardar() async {
    final horario = _horario;
    if (horario == null) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      await widget.servicio.guardarHorarioBase(widget.uid, horario);
      navegador.pop();
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('Horario guardado'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo guardar el horario',
          tipo: TipoAviso.error,
        ),
      );
    }

    if (mounted) setState(() => _guardando = false);
  }

  Future<void> _editarDia(int dia) async {
    final horario = _horario!;
    final actual = horario.dias[dia];

    final inicio = await elegirHora(
      context,
      ayuda: 'Hora de inicio',
      inicial: _aTimeOfDay(actual?.inicio ?? '09:00'),
    );
    if (inicio == null || !mounted) return;

    final fin = await elegirHora(
      context,
      ayuda: 'Hora de cierre',
      inicial: _aTimeOfDay(actual?.fin ?? '18:00'),
    );
    if (fin == null || !mounted) return;

    final minutosInicio = inicio.hour * 60 + inicio.minute;
    final minutosFin = fin.hour * 60 + fin.minute;
    if (minutosFin <= minutosInicio) {
      ScaffoldMessenger.of(context).showSnackBar(
        construirMensaje(
          'La hora de cierre debe ser después de la de inicio',
          tipo: TipoAviso.error,
        ),
      );
      return;
    }

    final dias = Map<int, RangoHorario>.from(horario.dias);
    dias[dia] = RangoHorario(
      inicio: horaGuardable(inicio),
      fin: horaGuardable(fin),
    );
    setState(() => _horario = horario.copiarCon(dias: dias));
  }

  @override
  Widget build(BuildContext context) {
    final horario = _horario;

    if (horario == null) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: margenHoja(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Horario base',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Define tu jornada habitual. La agenda se genera sola cada día. '
              'Cada servicio ocupara las franjas que necesite segun su duración.',
              style: TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('Cada cuánto puede empezar una cita'),
                ),
                DropdownButton<int>(
                  value: horario.intervaloMinutos,
                  items: const [15, 20, 30, 45, 60]
                      .map(
                        (minutos) => DropdownMenuItem(
                          value: minutos,
                          child: Text(formatearDuracionCorta(minutos)),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) {
                    if (valor == null) return;
                    setState(
                      () =>
                          _horario = horario.copiarCon(intervaloMinutos: valor),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            for (var dia = 1; dia <= 7; dia++)
              _FilaDia(
                nombre: HorarioBase.nombresDias[dia - 1],
                rango: horario.dias[dia],
                onAlternar: (activo) {
                  final dias = Map<int, RangoHorario>.from(horario.dias);
                  if (activo) {
                    dias[dia] = const RangoHorario(
                      inicio: '09:00',
                      fin: '18:00',
                    );
                  } else {
                    dias.remove(dia);
                  }
                  setState(() => _horario = horario.copiarCon(dias: dias));
                },
                onEditar: () => _editarDia(dia),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar horario'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDia extends StatelessWidget {
  final String nombre;
  final RangoHorario? rango;
  final ValueChanged<bool> onAlternar;
  final VoidCallback onEditar;

  const _FilaDia({
    required this.nombre,
    required this.rango,
    required this.onAlternar,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final activo = rango != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              nombre,
              style: TextStyle(
                fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                color: activo ? TemaApp.textoOscuro : TemaApp.grisTexto,
              ),
            ),
          ),
          Switch(value: activo, onChanged: onAlternar),
          const Spacer(),
          if (activo)
            TextButton(
              onPressed: onEditar,
              child: Text(
                '${formatearHora(rango!.inicio)} - '
                '${formatearHora(rango!.fin)}',
              ),
            )
          else
            const Text(
              'Cerrado',
              style: TextStyle(color: TemaApp.grisTexto, fontSize: 13),
            ),
        ],
      ),
    );
  }
}
