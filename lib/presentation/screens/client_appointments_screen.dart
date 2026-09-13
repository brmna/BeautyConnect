import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';
import '../../data/models/cambio_solicitado.dart';
import '../../data/models/modalidad_cita.dart';
import '../../data/services/cache_perfiles.dart';
import '../widgets/hoja_modal.dart';
import '../../data/services/servicio_disponibilidad.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/estado_cita.dart';
import '../../utils/formato.dart';
import '../../utils/franjas_cita.dart';
import '../widgets/boton_novedades.dart';
import '../widgets/cabecera_pantalla.dart';
import '../widgets/confirmacion.dart';
import '../../data/services/servicio_chat.dart';
import '../widgets/hoja_calificar.dart';
import '../widgets/hoja_reagendar.dart';
import 'bandeja_chats_screen.dart';
import 'chat_screen.dart';
import '../widgets/bloque_lugar.dart';
import '../widgets/fotos_referencia.dart';
import '../widgets/datos_cita.dart';
import '../widgets/mensaje.dart';
import '../widgets/recarga_manual.dart';
import 'professional_detail_screen.dart';

enum _Grupo { pendientes, proximas, pasadas }

extension _NombreGrupo on _Grupo {
  String get titulo => switch (this) {
    _Grupo.pendientes => 'Pendientes de confirmar',
    _Grupo.proximas => 'Próximas',
    _Grupo.pasadas => 'Pasadas',
  };

  IconData get icono => switch (this) {
    _Grupo.pendientes => Icons.hourglass_empty,
    _Grupo.proximas => Icons.event_available_outlined,
    _Grupo.pasadas => Icons.history,
  };
}

class ClientAppointmentsScreen extends StatefulWidget {
  final ValueChanged<int>? onIrAPestana;

  const ClientAppointmentsScreen({super.key, this.onIrAPestana});

  @override
  State<ClientAppointmentsScreen> createState() =>
      _ClientAppointmentsScreenState();
}

class _ClientAppointmentsScreenState extends State<ClientAppointmentsScreen>
    with RecargaManual<ClientAppointmentsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _perfiles = CachePerfiles();

  late Stream<QuerySnapshot<Map<String, dynamic>>> _citas;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _resenas;
  late Stream<Map<String, int>> _noLeidos;

  @override
  void initState() {
    super.initState();
    crearConsultas();
  }

  @override
  void crearConsultas() {
    _perfiles.limpiar();

    _citas = FirebaseFirestore.instance
        .collection('bookings')
        .where('clientId', isEqualTo: _uid)
        .snapshots();
    _resenas = FirebaseFirestore.instance
        .collectionGroup('resenas')
        .where('clienteId', isEqualTo: _uid)
        .snapshots();
    _noLeidos = ServicioChat().observarNoLeidos(
      uid: _uid,
      esProfesional: false,
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
              subtitulo: 'Administra tus reservaciones',
              icono: Icons.calendar_month_outlined,
              accion: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BotonNovedades(uid: _uid, esProfesional: false),
                  _botonMensajes(),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _citas,
                builder: (context, citasSnap) {
                  if (citasSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (citasSnap.hasError) {
                    return const Center(
                      child: Text(
                        'No se pudieron cargar tus citas',
                        style: TextStyle(color: TemaApp.grisTexto),
                      ),
                    );
                  }

                  final citas = citasSnap.data?.docs ?? [];
                  if (citas.isEmpty) return _vacio();

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _resenas,
                    builder: (context, resenasSnap) {
                      final calificadas = (resenasSnap.data?.docs ?? [])
                          .map((d) => d.id)
                          .toSet();

                      return StreamBuilder<Map<String, int>>(
                        stream: _noLeidos,
                        builder: (context, noLeidosSnap) {
                          return conRecarga(
                            hijo: CustomScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              slivers: _construirSecciones(
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

  Future<void> _abrirChat(
    QueryDocumentSnapshot<Map<String, dynamic>> cita,
  ) async {
    final datos = cita.data();
    final profesionalId = datos['professionalId'] as String?;
    if (profesionalId == null) return;

    final perfil = await _perfiles.resumen(profesionalId);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          citaId: cita.id,
          clienteId: _uid,
          profesionalId: profesionalId,
          servicio: datos['serviceName'] ?? 'Servicio',
          otroNombre: perfil.nombre.isEmpty ? 'Manicurista' : perfil.nombre,
          otraFoto: perfil.foto,
          esProfesional: false,
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
              BandejaChatsScreen.abrir(context, esProfesional: false),
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

  void _pedirCambio(QueryDocumentSnapshot<Map<String, dynamic>> cita) {
    final profesionalId = cita.data()['professionalId'] as String?;
    if (profesionalId == null) return;

    HojaReagendar.abrir(
      context,
      cita: cita,
      profesionalId: profesionalId,
      esSolicitud: true,
    );
  }

  Future<void> _calificar(
    QueryDocumentSnapshot<Map<String, dynamic>> cita,
  ) async {
    final datos = cita.data();
    final profesionalId = datos['professionalId'] as String?;
    if (profesionalId == null) return;

    final profesional = await _perfiles.resumen(profesionalId);
    final cliente = await _perfiles.resumen(_uid);

    if (!mounted) return;

    abrirHoja(
      context,
      hijo: HojaCalificar(
        profesionalId: profesionalId,
        profesionalNombre: profesional.nombre.isEmpty
            ? 'tu manicurista'
            : profesional.nombre,
        profesionalFoto: profesional.foto,
        citaId: cita.id,
        clienteId: _uid,
        clienteNombre: cliente.nombre.isEmpty ? 'Cliente' : cliente.nombre,
        clienteFoto: cliente.foto,
        servicio: datos['serviceName'] ?? 'Servicio',
      ),
    );
  }

  List<Widget> _construirSecciones(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> citas,
    Set<String> calificadas,
    Map<String, int> noLeidos,
  ) {
    final secciones = <Widget>[];

    for (final grupo in _Grupo.values) {
      final delGrupo = _agrupar(citas, grupo);
      if (delGrupo.isEmpty) continue;

      secciones.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _EncabezadoSeccion(
            titulo: grupo.titulo,
            icono: grupo.icono,
            cantidad: delGrupo.length,
          ),
        ),
      );
      secciones.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          sliver: SliverList.builder(
            itemCount: delGrupo.length,
            itemBuilder: (context, indice) => _TarjetaCita(
              cita: delGrupo[indice],
              perfiles: _perfiles,
              yaCalificada: calificadas.contains(delGrupo[indice].id),
              sinLeer: noLeidos[delGrupo[indice].id] ?? 0,
              onChat: () => _abrirChat(delGrupo[indice]),
              onCalificar: () => _calificar(delGrupo[indice]),
              onPedirCambio: () => _pedirCambio(delGrupo[indice]),
            ),
          ),
        ),
      );
    }

    secciones.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    return secciones;
  }

  Widget _vacio() {
    final irABuscar = widget.onIrAPestana;

    return EstadoVacio(
      icono: Icons.event_available_outlined,
      titulo: 'Aún no tienes citas',
      detalle: 'Busca tu manicurista y reserva tu cita',
      accion: irABuscar == null ? null : 'Buscar manicurista',
      onAccion: irABuscar == null ? null : () => irABuscar(1),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _agrupar(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> citas,
    _Grupo grupo,
  ) {
    final filtradas = citas.where((cita) {
      final estado = clasificarCita(cita.data());

      switch (grupo) {
        case _Grupo.pendientes:
          return estado.esperaRespuesta;
        case _Grupo.proximas:
          return estado.estaPorVenir;
        case _Grupo.pasadas:
          return estado == EstadoCita.pasada;
      }
    }).toList();

    filtradas.sort((a, b) {
      final fechaA = inicioCita(a.data());
      final fechaB = inicioCita(b.data());
      if (fechaA == null || fechaB == null) return 0;
      return grupo == _Grupo.pasadas
          ? fechaB.compareTo(fechaA)
          : fechaA.compareTo(fechaB);
    });

    return filtradas;
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

class _TarjetaCita extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> cita;
  final CachePerfiles perfiles;
  final bool yaCalificada;
  final int sinLeer;
  final VoidCallback onChat;
  final VoidCallback onCalificar;
  final VoidCallback onPedirCambio;

  const _TarjetaCita({
    required this.cita,
    required this.perfiles,
    required this.yaCalificada,
    required this.sinLeer,
    required this.onChat,
    required this.onCalificar,
    required this.onPedirCambio,
  });

  @override
  Widget build(BuildContext context) {
    final datos = cita.data();
    final estado = datos['status'] ?? 'pending';
    final fecha = (datos['date'] as Timestamp?)?.toDate();
    final profesionalId = datos['professionalId'] as String?;
    final activa = estado == 'pending' || estado == 'confirmed';
    final calificable = sePuedeCalificar(datos);
    final propuesta = CambioSolicitado.deCita(datos);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: profesionalId == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfessionalDetailScreen(professionalId: profesionalId),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Manicurista(
                    profesionalId: profesionalId,
                    perfiles: perfiles,
                    servicio: datos['serviceName'] ?? 'Servicio',
                    precio: precioTotalFormateado(datos),
                  ),
                  _Estado(estado: estado),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TemaApp.grisClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 15,
                      color: TemaApp.grisTexto,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      fecha == null
                          ? 'Fecha no definida'
                          : formatearFechaHora(fecha),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              FilaDuracionCita(
                minutos: (datos['durationMinutes'] as num?)?.toInt(),
              ),
              FilaTiempoRestante(cita: datos),
              if (modalidadDeCita(datos).esDomicilio)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_car_outlined,
                        size: 15,
                        color: TemaApp.grisSubtitulo,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'A domicilio, va hasta donde estás',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: TemaApp.grisSubtitulo,
                        ),
                      ),
                    ],
                  ),
                )
              else
                BloqueLocal(
                  profesionalId: profesionalId,
                  cita: datos,
                  perfiles: perfiles,
                  confirmada: estado == 'confirmed' || estado == 'completed',
                  finalizada: estado == 'completed' || estado == 'cancelled',
                ),
              BloqueReferencia(cita: datos, titulo: 'Tu diseño de referencia'),
              if (calificable && !yaCalificada) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCalificar,
                    icon: const Icon(Icons.star_border, size: 18),
                    label: const Text('Calificar esta cita'),
                  ),
                ),
              ],
              if (calificable && yaCalificada) ...[
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 15,
                      color: TemaApp.exito,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ya calificaste esta cita',
                      style: TextStyle(fontSize: 12, color: TemaApp.exito),
                    ),
                  ],
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
              if (activa) ...[
                if (propuesta != null)
                  _PropuestaPendiente(propuesta: propuesta)
                else ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onPedirCambio,
                      icon: const Icon(Icons.edit_calendar_outlined, size: 17),
                      label: const Text('Pedir otro horario'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (profesionalId != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfessionalDetailScreen(
                                professionalId: profesionalId,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: const Text('Ver perfil'),
                        ),
                      ),
                    if (profesionalId != null) const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _cancelar(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TemaApp.error,
                          side: const BorderSide(color: TemaApp.error),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancelar(BuildContext context) async {
    final datos = cita.data();
    final eraConfirmada = datos['status'] == 'confirmed';

    String? motivo;

    if (eraConfirmada) {
      final elegido = await pedirMotivoCancelacion(
        context,
        titulo: 'Cancelar tu cita',
        mensaje:
            'Ya estaba confirmada. Le avisaremos a tu manicurista con el '
            'motivo y se liberará el horario.',
        sugeridos: MotivoCancelacion.sugeridosCliente,
      );
      if (elegido == null) return;
      motivo = elegido.texto;
    } else {
      final seguro = await confirmar(
        context,
        titulo: 'Cancelar la solicitud',
        mensaje: 'Se liberará el horario para otra persona.',
        siga: 'Sí, cancelar',
        destructiva: true,
      );
      if (!seguro) return;
    }

    if (!context.mounted) return;
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await cita.reference.update({
        'status': 'cancelled',
        'canceladaPor': 'cliente',
        'motivoCancelacion': ?motivo,
        'respondidoEn': FieldValue.serverTimestamp(),
        'avisoVisto': false,
        CambioSolicitado.clave: FieldValue.delete(),
      });
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo cancelar la cita', tipo: TipoAviso.error),
      );
      return;
    }

    mensajero.showSnackBar(
      construirMensaje('Cita cancelada', tipo: TipoAviso.exito),
    );

    final fecha = (datos['date'] as Timestamp?)?.toDate();
    final profesionalId = datos['professionalId'] as String?;
    if (fecha == null || profesionalId == null) return;

    if (motivo != null) {
      final clienteId = datos['clientId'] as String?;
      if (clienteId != null) {
        try {
          await ServicioChat().avisarCitaCancelada(
            citaId: cita.id,
            clienteId: clienteId,
            profesionalId: profesionalId,
            servicio: datos['serviceName'] ?? 'Servicio',
            motivo: motivo,
            porElCliente: true,
          );
        } catch (_) {}
      }
    }

    try {
      await ServicioDisponibilidad().liberarReserva(
        profesionalId: profesionalId,
        fecha: fecha,
        horas: franjasDeLaCita(datos),
        citaId: cita.id,
      );
    } catch (_) {}
  }
}

class _Estado extends StatelessWidget {
  final String estado;

  const _Estado({required this.estado});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String etiqueta;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etiqueta,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Manicurista extends StatelessWidget {
  final String? profesionalId;
  final CachePerfiles perfiles;
  final String servicio;
  final String precio;

  const _Manicurista({
    required this.profesionalId,
    required this.perfiles,
    required this.servicio,
    required this.precio,
  });

  @override
  Widget build(BuildContext context) {
    final id = profesionalId;

    if (id == null) {
      return Expanded(child: _datos(nombre: null, foto: null));
    }

    return Expanded(
      child: FutureBuilder<({String nombre, String? foto})>(
        future: perfiles.resumen(id),
        builder: (context, instantanea) {
          final nombre = instantanea.data?.nombre ?? '';

          return _datos(
            nombre: nombre.isEmpty ? null : nombre,
            foto: instantanea.data?.foto,
          );
        },
      ),
    );
  }

  Widget _datos({required String? nombre, required String? foto}) {
    final tieneFoto = foto != null && foto.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: TemaApp.grisClaro,
          backgroundImage: tieneFoto
              ? NetworkImage(ServicioSubidaImagenes.miniatura(foto, ancho: 140))
              : null,
          child: tieneFoto
              ? null
              : Text(
                  (nombre?.trim().isNotEmpty ?? false)
                      ? nombre!.trim()[0].toUpperCase()
                      : 'M',
                  style: const TextStyle(
                    color: TemaApp.textoOscuro,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                servicio,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                nombre == null ? 'Manicurista' : 'con $nombre',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: TemaApp.grisSubtitulo,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                precio,
                style: const TextStyle(
                  color: TemaApp.grisSubtitulo,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PropuestaPendiente extends StatelessWidget {
  final CambioSolicitado propuesta;

  const _PropuestaPendiente({required this.propuesta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TemaApp.infoSuave,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top, size: 16, color: TemaApp.info),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'Pediste moverla al ${formatearFechaHora(propuesta.fecha)}. '
                'Esperando su respuesta',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: TemaApp.info,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
