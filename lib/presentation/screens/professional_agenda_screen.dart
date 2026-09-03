import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';
import '../../data/models/cambio_solicitado.dart';
import '../../data/models/modalidad_cita.dart';
import '../../data/services/cache_perfiles.dart';
import '../widgets/hoja_modal.dart';
import '../../data/services/servicio_disponibilidad.dart';
import '../../theme/app_theme.dart';
import '../../utils/estado_cita.dart';
import '../../utils/formato.dart';
import '../../utils/franjas_cita.dart';
import '../../data/services/servicio_resenas_clientes.dart';
import '../widgets/avatar_persona.dart';
import '../widgets/bloque_domicilio.dart';
import '../widgets/cabecera_pantalla.dart';
import '../widgets/confirmacion.dart';
import '../widgets/hoja_calificar_cliente.dart';
import '../widgets/hoja_perfil_cliente.dart';
import '../../data/services/servicio_chat.dart';
import '../widgets/hoja_reagendar.dart';
import 'bandeja_chats_screen.dart';
import 'chat_screen.dart';
import '../widgets/datos_cita.dart';
import '../widgets/mensaje.dart';
import '../widgets/recarga_manual.dart';
import '../../data/models/ubicacion.dart';

enum _GrupoSolicitud { pendientes, proximas, pasadas }

extension _NombreGrupoSolicitud on _GrupoSolicitud {
  String get titulo => switch (this) {
    _GrupoSolicitud.pendientes => 'Por responder',
    _GrupoSolicitud.proximas => 'Próximas',
    _GrupoSolicitud.pasadas => 'Pasadas',
  };

  IconData get icono => switch (this) {
    _GrupoSolicitud.pendientes => Icons.hourglass_empty,
    _GrupoSolicitud.proximas => Icons.event_available_outlined,
    _GrupoSolicitud.pasadas => Icons.history,
  };
}

class ProfessionalAgendaScreen extends StatefulWidget {
  const ProfessionalAgendaScreen({super.key});

  @override
  State<ProfessionalAgendaScreen> createState() =>
      _ProfessionalAgendaScreenState();
}

class _ProfessionalAgendaScreenState extends State<ProfessionalAgendaScreen>
    with RecargaManual<ProfessionalAgendaScreen> {
  final _disponibilidad = ServicioDisponibilidad();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _perfiles = CachePerfiles();

  late Stream<QuerySnapshot<Map<String, dynamic>>> _citas;

  @override
  void initState() {
    super.initState();
    crearConsultas();
  }

  late Stream<Set<String>> _calificadas;
  late Stream<Map<String, int>> _noLeidos;

  @override
  void crearConsultas() {
    _perfiles.limpiar();

    _citas = FirebaseFirestore.instance
        .collection('bookings')
        .where('professionalId', isEqualTo: _uid)
        .snapshots();
    _calificadas = ServicioResenasClientes().observarCalificadas(_uid);
    _noLeidos = ServicioChat().observarNoLeidos(uid: _uid, esProfesional: true);
  }

  Future<void> _abrirChat(
    QueryDocumentSnapshot<Map<String, dynamic>> cita,
  ) async {
    final datos = cita.data();
    final clienteId = datos['clientId'] as String?;
    if (clienteId == null) return;

    final perfil = await _perfiles.resumen(clienteId);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          citaId: cita.id,
          clienteId: clienteId,
          profesionalId: _uid,
          servicio: datos['serviceName'] ?? 'Servicio',
          otroNombre: perfil.nombre.isEmpty ? 'Cliente' : perfil.nombre,
          otraFoto: perfil.foto,
          esProfesional: true,
        ),
      ),
    );
  }

  Widget _botonMensajes() {
    return StreamBuilder<Map<String, int>>(
      stream: _noLeidos,
      builder: (context, instantanea) {
        final total = (instantanea.data ?? const <String, int>{}).values.fold(
          0,
          (suma, cuantos) => suma + cuantos,
        );

        return IconButton(
          tooltip: 'Mensajes',
          onPressed: () =>
              BandejaChatsScreen.abrir(context, esProfesional: true),
          icon: Badge.count(
            count: total,
            isLabelVisible: total > 0,
            backgroundColor: TemaApp.rosa,
            child: const Icon(Icons.forum_outlined),
          ),
        );
      },
    );
  }

  Future<void> _responderCambio(
    QueryDocumentSnapshot<Map<String, dynamic>> cita,
    bool aceptar,
  ) async {
    final datos = cita.data();
    final propuesta = CambioSolicitado.deCita(datos);
    if (propuesta == null) return;

    final mensajero = ScaffoldMessenger.of(context);
    final clienteId = datos['clientId'] as String?;
    final servicio = datos['serviceName'] ?? 'Servicio';
    final fechaAnterior = (datos['date'] as Timestamp?)?.toDate();

    if (!aceptar) {
      try {
        await _disponibilidad.descartarCambio(cita.id);

        if (clienteId != null) {
          try {
            await ServicioChat().avisarCambioRechazado(
              citaId: cita.id,
              clienteId: clienteId,
              profesionalId: _uid,
              servicio: servicio,
              fechaPedida: propuesta.fecha,
            );
          } catch (_) {}
        }

        mensajero.showSnackBar(
          construirMensaje(
            'Le avisamos que no puedes en ese horario',
            tipo: TipoAviso.info,
          ),
        );
      } catch (_) {
        mensajero.showSnackBar(
          construirMensaje(
            'No se pudo responder la propuesta',
            tipo: TipoAviso.error,
          ),
        );
      }
      return;
    }

    try {
      final horario = await _disponibilidad.observarHorarioBase(_uid).first;

      await _disponibilidad.reagendar(
        citaId: cita.id,
        profesionalId: _uid,
        fechaAnterior: fechaAnterior ?? propuesta.fecha,
        horasAnteriores: List<String>.from(datos['slots'] ?? const []),
        fechaNueva: propuesta.fecha,
        horaNueva: propuesta.hora,
        duracionMinutos: (datos['durationMinutes'] as num?)?.toInt() ?? 60,
        intervalo: horario.intervaloMinutos,
      );

      if (clienteId != null && fechaAnterior != null) {
        try {
          await ServicioChat().avisarCitaMovida(
            citaId: cita.id,
            clienteId: clienteId,
            profesionalId: _uid,
            servicio: servicio,
            fechaAnterior: fechaAnterior,
            fechaNueva: propuesta.fecha,
          );
        } catch (_) {}
      }

      mensajero.showSnackBar(
        construirMensaje('Cita movida', tipo: TipoAviso.exito),
      );
    } on FranjaNoDisponible catch (e) {
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.error),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo mover la cita', tipo: TipoAviso.error),
      );
    }
  }

  Future<void> _calificarCliente(
    QueryDocumentSnapshot<Map<String, dynamic>> cita,
  ) async {
    final datos = cita.data();
    final clienteId = datos['clientId'] as String?;
    if (clienteId == null) return;

    final cliente = await _perfiles.resumen(clienteId);
    final propio = await _perfiles.resumen(_uid);

    if (!mounted) return;

    abrirHoja(
      context,
      hijo: HojaCalificarCliente(
        citaId: cita.id,
        clienteId: clienteId,
        clienteNombre: cliente.nombre.isEmpty ? 'este cliente' : cliente.nombre,
        profesionalId: _uid,
        profesionalNombre: propio.nombre,
        servicio: datos['serviceName'] ?? 'Servicio',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CabeceraPantalla(
              titulo: 'Mis Citas',
              subtitulo: 'Solicitudes, próximas y pasadas',
              icono: Icons.calendar_month_outlined,
              estilo: EstiloCabecera.destacada,
              accion: _botonMensajes(),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _citas,
                builder: (context, instantanea) {
                  if (instantanea.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (instantanea.hasError) {
                    return const Center(
                      child: Text(
                        'No se pudieron cargar las citas',
                        style: TextStyle(color: TemaApp.grisTexto),
                      ),
                    );
                  }

                  final citas = instantanea.data?.docs ?? [];
                  if (citas.isEmpty) return _vacio();

                  return StreamBuilder<Set<String>>(
                    stream: _calificadas,
                    builder: (context, calificadasSnap) {
                      final calificadas =
                          calificadasSnap.data ?? const <String>{};

                      return StreamBuilder<Map<String, int>>(
                        stream: _noLeidos,
                        builder: (context, noLeidosSnap) {
                          return conRecarga(
                            hijo: CustomScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              slivers: _secciones(
                                citas,
                                calificadas,
                                noLeidosSnap.data ?? const {},
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _secciones(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> citas,
    Set<String> calificadas,
    Map<String, int> noLeidos,
  ) {
    final resultado = <Widget>[];

    for (final grupo in _GrupoSolicitud.values) {
      final delGrupo = _agrupar(citas, grupo);
      if (delGrupo.isEmpty) continue;

      final esHistorial = grupo == _GrupoSolicitud.pasadas;
      final porCliente = esHistorial
          ? _porCliente(delGrupo)
          : const <_HistorialCliente>[];

      resultado.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _EncabezadoSeccion(
            titulo: grupo.titulo,
            icono: grupo.icono,
            cantidad: esHistorial ? porCliente.length : delGrupo.length,
          ),
        ),
      );
      if (esHistorial) {
        resultado.add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            sliver: SliverList.builder(
              itemCount: porCliente.length,
              itemBuilder: (context, indice) => _TarjetaHistorial(
                clienteId: porCliente[indice].clienteId,
                citas: porCliente[indice].citas,
                perfiles: _perfiles,
                sinCalificar: porCliente[indice].citas
                    .where(
                      (c) =>
                          !calificadas.contains(c.id) &&
                          sePuedeCalificar(c.data()),
                    )
                    .length,
                onTocar: (nombre) =>
                    _abrirHistorial(porCliente[indice].clienteId, nombre),
              ),
            ),
          ),
        );
        continue;
      }

      resultado.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          sliver: SliverList.builder(
            itemCount: delGrupo.length,
            itemBuilder: (context, indice) =>
                _tarjeta(delGrupo[indice], calificadas, noLeidos),
          ),
        ),
      );
    }

    resultado.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    return resultado;
  }

  Widget _tarjeta(
    QueryDocumentSnapshot<Map<String, dynamic>> cita,
    Set<String> calificadas,
    Map<String, int> noLeidos,
  ) {
    return _TarjetaSolicitud(
      cita: cita,
      perfiles: _perfiles,
      yaCalificado: calificadas.contains(cita.id),
      onCambiarEstado: (estado) => _pedirYCambiar(cita, estado),
      onCalificar: () => _calificarCliente(cita),
      onReagendar: () =>
          HojaReagendar.abrir(context, cita: cita, profesionalId: _uid),
      onChat: () => _abrirChat(cita),
      onResponderCambio: (aceptar) => _responderCambio(cita, aceptar),
      sinLeer: noLeidos[cita.id] ?? 0,
    );
  }

  List<_HistorialCliente> _porCliente(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> citas,
  ) {
    final porCliente =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final cita in citas) {
      final clienteId = cita.data()['clientId'] as String?;
      if (clienteId == null || clienteId.isEmpty) continue;
      porCliente.putIfAbsent(clienteId, () => []).add(cita);
    }

    return porCliente.entries
        .map((entrada) => _HistorialCliente(entrada.key, entrada.value))
        .toList();
  }

  void _abrirHistorial(String clienteId, String nombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: TemaApp.grisClaro,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Historial de citas',
                  style: TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Ver su perfil',
                onPressed: () => HojaPerfilCliente.abrir(
                  context,
                  clienteId: clienteId,
                  profesionalId: _uid,
                ),
                icon: const Icon(Icons.person_outline),
              ),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _citas,
            builder: (context, citasSnap) {
              if (!citasSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final suyas = _agrupar(
                citasSnap.data!.docs,
                _GrupoSolicitud.pasadas,
              ).where((c) => c.data()['clientId'] == clienteId).toList();

              if (suyas.isEmpty) {
                return const EstadoVacio(
                  icono: Icons.history,
                  titulo: 'No quedan citas en el historial',
                );
              }

              return StreamBuilder<Set<String>>(
                stream: _calificadas,
                builder: (context, calificadasSnap) {
                  return StreamBuilder<Map<String, int>>(
                    stream: _noLeidos,
                    builder: (context, noLeidosSnap) {
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: suyas.length,
                        itemBuilder: (context, indice) => _tarjeta(
                          suyas[indice],
                          calificadasSnap.data ?? const <String>{},
                          noLeidosSnap.data ?? const {},
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _agrupar(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> citas,
    _GrupoSolicitud grupo,
  ) {
    final filtradas = citas.where((cita) {
      final estado = clasificarCita(cita.data());

      switch (grupo) {
        case _GrupoSolicitud.pendientes:
          return estado.esperaRespuesta;
        case _GrupoSolicitud.proximas:
          return estado.estaPorVenir;
        case _GrupoSolicitud.pasadas:
          return estado == EstadoCita.pasada;
      }
    }).toList();

    filtradas.sort((a, b) {
      final fechaA = inicioCita(a.data());
      final fechaB = inicioCita(b.data());
      if (fechaA == null || fechaB == null) return 0;
      return grupo == _GrupoSolicitud.pasadas
          ? fechaB.compareTo(fechaA)
          : fechaA.compareTo(fechaB);
    });

    return filtradas;
  }

  Widget _vacio() {
    return const EstadoVacio(
      icono: Icons.assignment_outlined,
      titulo: 'Aún no tienes citas',
      detalle: 'Aparecerán cuando alguien reserve contigo',
    );
  }

  Future<void> _pedirYCambiar(
    QueryDocumentSnapshot<Map<String, dynamic>> cita,
    String nuevoEstado,
  ) async {
    final datos = cita.data();
    final servicio = datos['serviceName'] ?? 'la cita';
    final fecha = (datos['date'] as Timestamp?)?.toDate();
    final cuando = fecha == null ? '' : ' del ${formatearFechaHora(fecha)}';
    final eraConfirmada = datos['status'] == 'confirmed';

    String? motivo;

    if (nuevoEstado == 'cancelled') {
      if (eraConfirmada) {
        final elegido = await pedirMotivoCancelacion(
          context,
          titulo: 'Cancelar esta cita',
          mensaje:
              'Ya la habías confirmado. Le avisaremos al cliente con el '
              'motivo y se liberará el horario.',
          sugeridos: MotivoCancelacion.sugeridosProfesional,
        );
        if (elegido == null) return;
        motivo = elegido.texto;
      } else {
        final seguro = await confirmar(
          context,
          titulo: 'Rechazar la solicitud',
          mensaje:
              'Se liberará el horario de $servicio$cuando y el cliente '
              'quedará avisado.',
          siga: 'Rechazar',
          destructiva: true,
        );
        if (!seguro) return;
      }
    } else if (nuevoEstado == 'confirmed') {
      final seguro = await confirmar(
        context,
        titulo: 'Confirmar la cita',
        mensaje:
            'Aceptas $servicio$cuando. El cliente verá tu dirección exacta '
            'y podrá escribirte.',
        siga: 'Confirmar',
      );
      if (!seguro) return;
    } else if (nuevoEstado == 'completed') {
      final seguro = await confirmar(
        context,
        titulo: 'Marcar como completada',
        mensaje:
            'Das $servicio por atendida. Podrás calificar al cliente y la '
            'cita pasará a tu historial.',
        siga: 'Sí, la atendí',
      );
      if (!seguro) return;
    }

    if (!mounted) return;
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await _cambiarEstado(cita.id, nuevoEstado, motivo: motivo);

      if (motivo != null) {
        final clienteId = datos['clientId'] as String?;
        if (clienteId != null) {
          try {
            await ServicioChat().avisarCitaCancelada(
              citaId: cita.id,
              clienteId: clienteId,
              profesionalId: _uid,
              servicio: servicio,
              motivo: motivo,
            );
          } catch (_) {}
        }
      }
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo actualizar la cita',
          tipo: TipoAviso.error,
        ),
      );
    }
  }

  Future<void> _cambiarEstado(
    String citaId,
    String nuevoEstado, {
    String? motivo,
  }) async {
    final referencia = FirebaseFirestore.instance
        .collection('bookings')
        .doc(citaId);

    final respuestaAlCliente =
        nuevoEstado == 'confirmed' || nuevoEstado == 'cancelled';

    String? direccion;
    if (nuevoEstado == 'confirmed') {
      final perfil = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      direccion = Ubicacion.desdeMapa(perfil.data()).resumen;
    }

    await referencia.update({
      'status': nuevoEstado,
      if (direccion != null && direccion.isNotEmpty)
        'direccionProfesional': direccion,
      if (nuevoEstado == 'cancelled') ...{
        'canceladaPor': 'profesional',
        if (motivo != null && motivo.isNotEmpty) 'motivoCancelacion': motivo,
      },
      if (respuestaAlCliente) ...{
        'respondidoEn': FieldValue.serverTimestamp(),
        'avisoVisto': false,
      },
      CambioSolicitado.clave: FieldValue.delete(),
    });

    if (nuevoEstado != 'cancelled') return;

    final cita = (await referencia.get()).data();
    final fecha = (cita?['date'] as Timestamp?)?.toDate();
    if (fecha == null) return;

    await _disponibilidad.liberarReserva(
      profesionalId: _uid,
      fecha: fecha,
      horas: franjasDeLaCita(cita),
      citaId: citaId,
    );
  }
}

class _EncabezadoSeccion extends SliverPersistentHeaderDelegate {
  final String titulo;
  final IconData icono;
  final int cantidad;

  _EncabezadoSeccion({
    required this.titulo,
    required this.icono,
    required this.cantidad,
  });

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double desplazamiento, bool superpuesto) {
    return Container(
      color: TemaApp.grisClaro,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(icono, size: 15, color: TemaApp.grisTexto),
          const SizedBox(width: 7),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: TemaApp.grisSubtitulo,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: TemaApp.blanco,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$cantidad',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_EncabezadoSeccion anterior) =>
      anterior.cantidad != cantidad || anterior.titulo != titulo;
}

class _TarjetaSolicitud extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> cita;
  final CachePerfiles perfiles;
  final bool yaCalificado;
  final Future<void> Function(String) onCambiarEstado;
  final VoidCallback onCalificar;
  final VoidCallback onReagendar;
  final ValueChanged<bool> onResponderCambio;
  final VoidCallback onChat;
  final int sinLeer;

  const _TarjetaSolicitud({
    required this.cita,
    required this.perfiles,
    required this.yaCalificado,
    required this.onCambiarEstado,
    required this.onCalificar,
    required this.onReagendar,
    required this.onResponderCambio,
    required this.onChat,
    required this.sinLeer,
  });

  @override
  Widget build(BuildContext context) {
    final datos = cita.data();
    final estado = datos['status'] ?? 'pending';
    final fecha = (datos['date'] as Timestamp?)?.toDate();
    final vencida = clasificarCita(datos) == EstadoCita.vencida;
    final propuesta = CambioSolicitado.deCita(datos);
    final calificable = sePuedeCalificar(datos);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: vencida
            ? const BorderSide(color: TemaApp.error, width: 1.2)
            : propuesta != null
            ? const BorderSide(color: TemaApp.info, width: 1.2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: datos['clientId'] == null
                  ? null
                  : () => HojaPerfilCliente.abrir(
                      context,
                      clienteId: datos['clientId'],
                      profesionalId: datos['professionalId'] ?? '',
                    ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AvatarCliente(
                    clienteId: datos['clientId'],
                    perfiles: perfiles,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NombreCliente(
                      clienteId: datos['clientId'],
                      perfiles: perfiles,
                      servicio: datos['serviceName'] ?? 'Servicio',
                    ),
                  ),
                  _Estado(estado: estado, vencida: vencida),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: TemaApp.grisTexto,
                  ),
                ],
              ),
            ),
            if (propuesta != null) ...[
              const SizedBox(height: 12),
              _PropuestaCliente(
                propuesta: propuesta,
                onResponder: onResponderCambio,
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TemaApp.grisClaro,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 15,
                    color: TemaApp.grisTexto,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fecha == null
                          ? 'Fecha no definida'
                          : formatearFechaHora(fecha),
                      style: TextStyle(
                        fontSize: 13,
                        color: vencida ? TemaApp.error : TemaApp.textoOscuro,
                        decoration: vencida ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Text(
                    precioTotalFormateado(datos),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            FilaDuracionCita(
              minutos: (datos['durationMinutes'] as num?)?.toInt(),
            ),
            FilaTiempoRestante(cita: datos),
            if (modalidadDeCita(datos).esDomicilio)
              BloqueDomicilio(
                citaId: cita.id,
                cita: datos,
                confirmada: estado == 'confirmed' || estado == 'completed',
                finalizada: estado == 'completed' || estado == 'cancelled',
              ),
            if (vencida) ...[
              const SizedBox(height: 12),
              const Text(
                'La hora ya pasó, así que esta cita no se puede confirmar. '
                'Descártala para liberar el horario.',
                style: TextStyle(fontSize: 12, color: TemaApp.error),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onCambiarEstado('cancelled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TemaApp.error,
                    side: const BorderSide(color: TemaApp.error),
                  ),
                  icon: const Icon(Icons.event_busy_outlined, size: 17),
                  label: const Text('Descartar'),
                ),
              ),
            ] else if (estado == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onCambiarEstado('cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TemaApp.error,
                        side: const BorderSide(color: TemaApp.error),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => onCambiarEstado('confirmed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaApp.negro,
                        foregroundColor: TemaApp.blanco,
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
            if (calificable) ...[
              const SizedBox(height: 12),
              if (yaCalificado)
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 15,
                      color: TemaApp.exito,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ya calificaste a este cliente',
                      style: TextStyle(fontSize: 12, color: TemaApp.exito),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCalificar,
                    icon: const Icon(Icons.star_border, size: 18),
                    label: const Text('Calificar al cliente'),
                  ),
                ),
            ],
            ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onChat,
                  icon: Badge.count(
                    count: sinLeer,
                    isLabelVisible: sinLeer > 0,
                    backgroundColor: TemaApp.rosa,
                    child: const Icon(Icons.chat_bubble_outline, size: 17),
                  ),
                  label: Text(
                    estado == 'confirmed' ? 'Mensajes' : 'Ver conversación',
                  ),
                ),
              ),
            ],
            if (estado == 'confirmed') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReagendar,
                      icon: const Icon(Icons.edit_calendar_outlined, size: 17),
                      label: const Text('Mover'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onCambiarEstado('completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaApp.exito,
                        foregroundColor: TemaApp.blanco,
                      ),
                      icon: const Icon(Icons.check, size: 17),
                      label: const Text('Completada'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => onCambiarEstado('cancelled'),
                  style: TextButton.styleFrom(foregroundColor: TemaApp.error),
                  icon: const Icon(Icons.event_busy_outlined, size: 17),
                  label: const Text('Cancelar la cita'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NombreCliente extends StatelessWidget {
  final String? clienteId;
  final CachePerfiles perfiles;
  final String servicio;

  const _NombreCliente({
    required this.clienteId,
    required this.perfiles,
    required this.servicio,
  });

  @override
  Widget build(BuildContext context) {
    final id = clienteId;
    if (id == null) return const Text('Cliente');

    return FutureBuilder<({String nombre, String? foto})>(
      future: perfiles.resumen(id),
      builder: (context, instantanea) {
        final leido = instantanea.data?.nombre ?? '';
        final nombre = leido.isEmpty ? 'Cliente' : leido;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              servicio,
              style: const TextStyle(
                fontSize: 12,
                color: TemaApp.grisSubtitulo,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Estado extends StatelessWidget {
  final String estado;
  final bool vencida;

  const _Estado({required this.estado, this.vencida = false});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String etiqueta;

    if (vencida) {
      return const _Etiqueta(color: TemaApp.error, texto: 'Vencida');
    }

    switch (estado) {
      case 'confirmed':
        color = TemaApp.exito;
        etiqueta = 'Confirmada';
      case 'cancelled':
        color = TemaApp.error;
        etiqueta = 'Cancelada';
      case 'completed':
        color = TemaApp.info;
        etiqueta = 'Completada';
      default:
        color = TemaApp.aviso;
        etiqueta = 'Pendiente';
    }

    return _Etiqueta(color: color, texto: etiqueta);
  }
}

class _Etiqueta extends StatelessWidget {
  final Color color;
  final String texto;

  const _Etiqueta({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvatarCliente extends StatelessWidget {
  final String? clienteId;
  final CachePerfiles perfiles;

  const _AvatarCliente({required this.clienteId, required this.perfiles});

  @override
  Widget build(BuildContext context) {
    final id = clienteId;
    if (id == null) return const AvatarCliente(nombre: '', foto: null);

    return FutureBuilder<({String nombre, String? foto})>(
      future: perfiles.resumen(id),
      builder: (context, instantanea) => AvatarCliente(
        nombre: instantanea.data?.nombre ?? '',
        foto: instantanea.data?.foto,
      ),
    );
  }
}

class _PropuestaCliente extends StatelessWidget {
  final CambioSolicitado propuesta;
  final ValueChanged<bool> onResponder;

  const _PropuestaCliente({required this.propuesta, required this.onResponder});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaApp.infoSuave,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_calendar_outlined,
                size: 16,
                color: TemaApp.info,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Pidió mover la cita al '
                  '${formatearFechaHora(propuesta.fecha)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: TemaApp.info,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onResponder(false),
                  child: const Text('No puedo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onResponder(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaApp.info,
                    foregroundColor: TemaApp.blanco,
                  ),
                  child: const Text('Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistorialCliente {
  final String clienteId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> citas;

  const _HistorialCliente(this.clienteId, this.citas);
}

class _TarjetaHistorial extends StatelessWidget {
  final String clienteId;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> citas;
  final CachePerfiles perfiles;
  final int sinCalificar;
  final ValueChanged<String> onTocar;

  const _TarjetaHistorial({
    required this.clienteId,
    required this.citas,
    required this.perfiles,
    required this.sinCalificar,
    required this.onTocar,
  });

  String get _resumen {
    final cuantas = citas.length == 1 ? '1 cita' : '${citas.length} citas';
    final ultima = inicioCita(citas.first.data());

    return ultima == null
        ? cuantas
        : '$cuantas · última el ${formatearFecha(ultima)}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String nombre, String? foto})>(
      future: perfiles.resumen(clienteId),
      builder: (context, instantanea) {
        final perfil = instantanea.data;
        final nombre = (perfil?.nombre.trim().isNotEmpty ?? false)
            ? perfil!.nombre
            : 'Cliente';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => onTocar(nombre),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: AvatarPersona(
              nombre: nombre,
              foto: perfil?.foto,
              radio: 22,
            ),
            title: Text(
              nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _resumen,
                style: const TextStyle(
                  fontSize: 12,
                  color: TemaApp.grisSubtitulo,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sinCalificar > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: TemaApp.avisoSuave,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      sinCalificar == 1
                          ? 'Sin calificar'
                          : '$sinCalificar sin calificar',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: TemaApp.aviso,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: TemaApp.grisTexto,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
