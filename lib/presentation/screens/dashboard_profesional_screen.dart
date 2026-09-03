import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/ajustes_profesional.dart';
import '../../theme/app_theme.dart';
import '../../utils/estado_cita.dart';
import '../../utils/formato.dart';
import '../../utils/genero.dart';
import '../widgets/aviso.dart';
import '../widgets/boton_novedades.dart';
import '../widgets/recarga_manual.dart';
import '../widgets/sugerencias.dart';
import 'mis_resenas_screen.dart';
import 'professional_home.dart';

class DashboardProfesionalScreen extends StatefulWidget {
  final ValueChanged<DestinoProfesional> onIr;

  const DashboardProfesionalScreen({super.key, required this.onIr});

  @override
  State<DashboardProfesionalScreen> createState() =>
      _DashboardProfesionalScreenState();
}

class _DashboardProfesionalScreenState extends State<DashboardProfesionalScreen>
    with RecargaManual<DashboardProfesionalScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late Stream<DocumentSnapshot<Map<String, dynamic>>> _perfil;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _citas;

  @override
  void initState() {
    super.initState();
    crearConsultas();
  }

  @override
  void crearConsultas() {
    _perfil = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots();
    _citas = FirebaseFirestore.instance
        .collection('bookings')
        .where('professionalId', isEqualTo: _uid)
        .snapshots();
  }

  ValueChanged<DestinoProfesional> get onIr => widget.onIr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _perfil,
          builder: (context, perfil) {
            final datos = perfil.data?.data() ?? {};

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _citas,
              builder: (context, citasSnap) {
                if (citasSnap.hasError) {
                  return _errorCitas();
                }

                if (citasSnap.connectionState == ConnectionState.waiting &&
                    !citasSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final citas = citasSnap.data?.docs ?? [];
                final resumen = _Resumen.desde(citas);

                return conRecarga(
                  hijo: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _saludo(datos['name'] ?? '', generoDePerfil(datos)),
                      const SizedBox(height: 16),
                      _reputacion(datos),
                      const SizedBox(height: 16),
                      if (resumen.pendientes > 0) ...[
                        _avisoSolicitudes(resumen.pendientes),
                        const SizedBox(height: 16),
                      ],
                      _Sugerencias(
                        uid: _uid,
                        perfil: datos,
                        resumen: resumen,
                        onIr: onIr,
                      ),
                      _proximasCitas(resumen.proximas),
                      const SizedBox(height: 16),
                      _rendimiento(resumen),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _errorCitas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: TemaApp.grisTexto,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudieron cargar tus citas',
              style: TextStyle(color: TemaApp.grisTexto, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Revisa tu conexión e inténtalo de nuevo',
              textAlign: TextAlign.center,
              style: TextStyle(color: TemaApp.grisTexto, fontSize: 13),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saludo(String nombre, Genero genero) {
    final primerNombre = nombre.trim().isEmpty ? '' : nombre.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  saludoBienvenida(genero, nombre: primerNombre),
                  style: const TextStyle(
                    fontSize: 13,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
              ],
            ),
          ),
          BotonNovedades(
            uid: _uid,
            esProfesional: true,
            onVerCitas: () => onIr(DestinoProfesional.citas),
          ),
        ],
      ),
    );
  }

  Widget _reputacion(Map<String, dynamic> datos) {
    final calificacion = (datos['rating'] as num?)?.toDouble() ?? 0;
    final resenas = (datos['reviewsCount'] as num?)?.toInt() ?? 0;

    void verResenas() => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MisResenasScreen(profesionalId: _uid)),
    );

    return Row(
      children: [
        Expanded(
          child: _TarjetaMetrica(
            icono: Icons.star_border,
            etiqueta: 'Calificación',
            valor: resenas == 0 ? '-' : formatearCalificacion(calificacion),
            complemento: resenas == 0 ? 'Sin reseñas' : '/ 5.0',
            onTap: resenas == 0 ? null : verResenas,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TarjetaMetrica(
            icono: Icons.rate_review_outlined,
            etiqueta: 'Reseñas',
            valor: '$resenas',
            complemento: 'totales',
            onTap: resenas == 0 ? null : verResenas,
          ),
        ),
      ],
    );
  }

  Widget _avisoSolicitudes(int pendientes) {
    return Aviso(
      tipo: TipoAviso.aviso,
      icono: Icons.notifications_active_outlined,
      titulo: pendientes == 1
          ? '1 solicitud pendiente'
          : '$pendientes solicitudes pendientes',
      detalle: 'Revisa y responde las solicitudes de cita',
      accion: TextButton(
        onPressed: () => onIr(DestinoProfesional.citas),
        child: const Text('Ver'),
      ),
    );
  }

  Widget _proximasCitas(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> proximas,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Próximas citas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: TemaApp.grisClaro,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    proximas.length == 1
                        ? '1 cita'
                        : '${proximas.length} citas',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (proximas.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No tienes citas confirmadas',
                    style: TextStyle(color: TemaApp.grisTexto, fontSize: 13),
                  ),
                ),
              )
            else
              ...proximas.take(3).map((cita) {
                final datos = cita.data();
                final fecha = inicioCita(datos);
                final enCurso = clasificarCita(datos) == EstadoCita.enCurso;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TemaApp.grisClaro,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: TemaApp.grisClaro,
                        child: Icon(
                          Icons.person,
                          color: TemaApp.textoOscuro,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              datos['serviceName'] ?? 'Servicio',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (fecha != null)
                              Text(
                                formatearFechaHora(fecha),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: TemaApp.grisSubtitulo,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (enCurso)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: TemaApp.exito.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'En curso',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: TemaApp.exito,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _rendimiento(_Resumen resumen) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, size: 18),
                SizedBox(width: 8),
                Text(
                  'Tu actividad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Fila(
              etiqueta: 'Servicios completados',
              valor: '${resumen.completadas}',
            ),
            _Fila(
              etiqueta: 'Clientes atendidos',
              valor: '${resumen.clientesUnicos}',
            ),
            _Fila(
              etiqueta: 'Tasa de aceptacion',
              valor: resumen.tasaAceptacion,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _Resumen {
  final int pendientes;
  final int vencidas;
  final int completadas;
  final int canceladas;
  final int clientesUnicos;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> proximas;

  const _Resumen({
    required this.pendientes,
    required this.vencidas,
    required this.completadas,
    required this.canceladas,
    required this.clientesUnicos,
    required this.proximas,
  });

  String get tasaAceptacion {
    final decididas = completadas + canceladas;
    if (decididas == 0) return '-';
    return '${(completadas * 100 / decididas).round()}%';
  }

  factory _Resumen.desde(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> citas,
  ) {
    var pendientes = 0;
    var vencidas = 0;
    var completadas = 0;
    var canceladas = 0;
    final clientes = <String>{};
    final proximas = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final cita in citas) {
      final datos = cita.data();
      final estado = datos['status'];

      switch (clasificarCita(datos)) {
        case EstadoCita.porResponder:
          pendientes++;
        case EstadoCita.vencida:
          pendientes++;
          vencidas++;
        case EstadoCita.proxima:
        case EstadoCita.enCurso:
          proximas.add(cita);
        case EstadoCita.pasada:
          break;
      }

      if (estado == 'completed') {
        completadas++;
        final clienteId = datos['clientId'] as String?;
        if (clienteId != null) clientes.add(clienteId);
      }
      if (estado == 'cancelled' && datos['motivoCancelacion'] == null) {
        canceladas++;
      }
    }

    proximas.sort((a, b) {
      final fechaA = inicioCita(a.data());
      final fechaB = inicioCita(b.data());
      if (fechaA == null || fechaB == null) return 0;
      return fechaA.compareTo(fechaB);
    });

    return _Resumen(
      pendientes: pendientes,
      vencidas: vencidas,
      completadas: completadas,
      canceladas: canceladas,
      clientesUnicos: clientes.length,
      proximas: proximas,
    );
  }
}

class _TarjetaMetrica extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final String complemento;
  final VoidCallback? onTap;

  const _TarjetaMetrica({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.complemento,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icono, size: 16, color: TemaApp.grisTexto),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      etiqueta,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaApp.grisSubtitulo,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 15,
                      color: TemaApp.grisTexto,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    complemento,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaApp.grisTexto,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? color;

  const _Fila({required this.etiqueta, required this.valor, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: const TextStyle(fontSize: 13))),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sugerencias extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> perfil;
  final _Resumen resumen;
  final ValueChanged<DestinoProfesional> onIr;

  const _Sugerencias({
    required this.uid,
    required this.perfil,
    required this.resumen,
    required this.onIr,
  });

  CollectionReference<Map<String, dynamic>> _sub(String nombre) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection(nombre);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _sub('services').limit(1).snapshots(),
      builder: (context, servicios) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _sub('portfolio').limit(3).snapshots(),
          builder: (context, portafolio) {
            final lista = _armar(
              servicios: servicios.data?.docs.length ?? 0,
              fotos: portafolio.data?.docs.length ?? 0,
            );

            if (lista.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CarruselSugerencias(sugerencias: lista),
            );
          },
        );
      },
    );
  }

  List<Sugerencia> _armar({required int servicios, required int fotos}) {
    final lista = <Sugerencia>[];

    if (resumen.vencidas > 0) {
      lista.add(
        Sugerencia(
          icono: Icons.running_with_errors_outlined,
          titulo: 'Citas sin responder',
          detalle: resumen.vencidas == 1
              ? 'Una solicitud se venció sin respuesta'
              : '${resumen.vencidas} solicitudes se vencieron sin respuesta',
          accion: 'Revisar',
          acento: TemaApp.error,
          onTocar: () => onIr(DestinoProfesional.citas),
        ),
      );
    }

    if (resumen.pendientes > resumen.vencidas) {
      lista.add(
        Sugerencia(
          icono: Icons.mark_email_unread_outlined,
          titulo: 'Tienes solicitudes',
          detalle: 'Responder rápido mejora tu tasa de aceptación',
          accion: 'Responder',
          acento: TemaApp.aviso,
          onTocar: () => onIr(DestinoProfesional.citas),
        ),
      );
    }

    if (servicios == 0) {
      lista.add(
        Sugerencia(
          icono: Icons.spa_outlined,
          titulo: 'Crea tu primer servicio',
          detalle: 'Sin servicios nadie puede reservarte una cita',
          accion: 'Crear',
          acento: TemaApp.negro,
          onTocar: () => onIr(DestinoProfesional.servicios),
        ),
      );
    }

    if (fotos < 3) {
      lista.add(
        Sugerencia(
          icono: Icons.add_photo_alternate_outlined,
          titulo: fotos == 0 ? 'Muestra tu trabajo' : 'Suma más fotos',
          detalle: 'Los perfiles con portafolio reciben más solicitudes',
          accion: 'Agregar fotos',
          acento: TemaApp.info,
          onTocar: () => onIr(DestinoProfesional.portafolio),
        ),
      );
    }

    if (_vacio('photoUrl')) {
      lista.add(
        Sugerencia(
          icono: Icons.face_retouching_natural_outlined,
          titulo: 'Ponte una foto',
          detalle: 'Un rostro genera más confianza que una inicial',
          accion: 'Editar perfil',
          acento: TemaApp.negro,
          onTocar: () => onIr(DestinoProfesional.perfil),
        ),
      );
    }

    if (_vacio('about')) {
      lista.add(
        Sugerencia(
          icono: Icons.edit_note_outlined,
          titulo: 'Cuenta quién eres',
          detalle: 'Una descripción corta ayuda a que te elijan',
          accion: 'Editar perfil',
          acento: TemaApp.info,
          onTocar: () => onIr(DestinoProfesional.perfil),
        ),
      );
    }

    if (_vacio('direccion') &&
        _vacio('location') &&
        !AjustesProfesional.desdeMapa(perfil).soloDomicilio) {
      lista.add(
        Sugerencia(
          icono: Icons.place_outlined,
          titulo: 'Indica dónde atiendes',
          detalle: 'Sin ubicación no apareces en las búsquedas por zona',
          accion: 'Editar perfil',
          acento: TemaApp.aviso,
          onTocar: () => onIr(DestinoProfesional.perfil),
        ),
      );
    }

    if (lista.isEmpty) {
      lista.add(
        Sugerencia(
          icono: Icons.event_available_outlined,
          titulo: 'Revisa tu agenda',
          detalle: 'Bloquea las horas en que no vas a atender',
          accion: 'Ver horarios',
          acento: TemaApp.exito,
          onTocar: () => onIr(DestinoProfesional.horarios),
        ),
      );
    }

    return lista;
  }

  bool _vacio(String campo) =>
      (perfil[campo] as String?)?.trim().isEmpty ?? true;
}
