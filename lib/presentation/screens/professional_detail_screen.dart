import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/estado_vacio.dart';
import '../../data/services/servicio_favoritos.dart';
import '../../data/models/ajustes_profesional.dart';
import '../widgets/hoja_modal.dart';
import '../../data/models/diseno.dart';
import '../../data/models/modalidad_cita.dart';
import '../../data/models/horario.dart';
import '../../data/models/ubicacion.dart';
import '../../data/services/servicio_disponibilidad.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../widgets/lista_certificados.dart';
import '../widgets/redes_sociales.dart';
import '../../theme/app_theme.dart';
import '../widgets/corazon_animado.dart';
import 'chat_screen.dart';
import 'detalle_diseno_screen.dart';
import 'selector_ubicacion_screen.dart';
import '../../utils/formato.dart';
import '../../utils/distancia.dart';
import '../../utils/enlaces.dart';
import '../../utils/genero.dart';
import '../widgets/estrellas.dart';
import '../widgets/cabecera_pantalla.dart';
import '../widgets/fotos_referencia.dart';
import '../widgets/mapa_zonas.dart';
import '../../utils/fotos_referencia.dart';
import '../widgets/tarjeta_servicio.dart';
import '../widgets/mensaje.dart';
import '../widgets/resenas.dart';
import '../widgets/rejilla_opciones.dart';
import '../../utils/margenes.dart';

class ProfessionalDetailScreen extends StatefulWidget {
  final String professionalId;

  const ProfessionalDetailScreen({super.key, required this.professionalId});

  @override
  State<ProfessionalDetailScreen> createState() =>
      _ProfessionalDetailScreenState();
}

class _ProfessionalDetailScreenState extends State<ProfessionalDetailScreen>
    with SingleTickerProviderStateMixin {
  final _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _favoritos = ServicioFavoritos();
  late final TabController _pestanas;

  bool _isFavorite = false;
  bool _aceptaCitas = true;

  @override
  void initState() {
    super.initState();
    _pestanas = TabController(length: 4, vsync: this);
    _revisarFavorito();
  }

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }

  DocumentReference<Map<String, dynamic>> get _refPerfil =>
      FirebaseFirestore.instance.collection('users').doc(widget.professionalId);

  Future<void> _revisarFavorito() async {
    final favoritos = await _favoritos.leer(_currentUid);
    if (!mounted) return;
    setState(() => _isFavorite = favoritos.contains(widget.professionalId));
  }

  Future<void> _alternarFavorito() async {
    final mensajero = ScaffoldMessenger.of(context);
    final marcar = !_isFavorite;

    setState(() => _isFavorite = marcar);

    try {
      await _favoritos.alternar(
        uid: _currentUid,
        profesionalId: widget.professionalId,
        marcar: marcar,
      );
    } catch (_) {
      if (mounted) setState(() => _isFavorite = !marcar);
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo actualizar favoritos',
          tipo: TipoAviso.error,
        ),
      );
    }
  }

  Future<void> _llamar(String telefono) async {
    final numero = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    final mensajero = ScaffoldMessenger.of(context);
    final abierto = await launchUrl(Uri(scheme: 'tel', path: numero));

    if (!abierto) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo abrir el marcador', tipo: TipoAviso.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _refPerfil.snapshots(),
        builder: (context, instantanea) {
          if (instantanea.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!instantanea.hasData || !instantanea.data!.exists) {
            return const Center(child: Text('Profesional no encontrado'));
          }

          final datos = instantanea.data!.data()!;

          if (datos['activo'] == false) {
            return const Center(
              child: Text('Este profesional ya no está disponible'),
            );
          }

          _aceptaCitas = AjustesProfesional.desdeMapa(datos).aceptandoClientas;

          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _barraFija(datos['name'] ?? ''),
              SliverToBoxAdapter(child: _encabezado(datos)),
            ],
            body: Column(
              children: [
                Container(
                  color: TemaApp.blanco,
                  child: TabBar(
                    controller: _pestanas,
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                    tabs: const [
                      Tab(text: 'Info'),
                      Tab(text: 'Servicios'),
                      Tab(text: 'Portafolio'),
                      Tab(text: 'Reseñas'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _pestanas,
                    children: [
                      _PestanaInfo(
                        datos: datos,
                        profesionalId: widget.professionalId,
                        onVerServicios: () => _pestanas.animateTo(1),
                        onVerResenas: _verResenas,
                        onReservar: _abrirHojaReserva,
                      ),
                      _PestanaServicios(
                        profesionalId: widget.professionalId,
                        onReservar: _abrirHojaReserva,
                      ),
                      _PestanaPortafolio(profesionalId: widget.professionalId),
                      ResenasDeProfesional(
                        profesionalId: widget.professionalId,
                        puedeResponder: widget.professionalId == _currentUid,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _barraFija(String nombre) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: TemaApp.blanco,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        tooltip: 'Volver',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          tooltip: 'Compartir perfil',
          onPressed: () => _compartir(nombre),
          icon: const Icon(Icons.share_outlined, size: 22),
        ),
        IconButton(
          tooltip: _isFavorite ? 'Quitar de favoritas' : 'Guardar',
          onPressed: _alternarFavorito,
          icon: CorazonAnimado(activo: _isFavorite, tamano: 24),
        ),
      ],
    );
  }

  Widget _encabezado(Map<String, dynamic> datos) {
    final foto = datos['photoUrl'] as String?;
    final nombre = datos['name'] ?? '';
    final resenas = (datos['reviewsCount'] as num?)?.toInt() ?? 0;
    final telefono = datos['phone'] as String?;

    return Container(
      color: TemaApp.blanco,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: TemaApp.grisClaro,
              backgroundImage: (foto != null && foto.isNotEmpty)
                  ? NetworkImage(
                      ServicioSubidaImagenes.miniatura(foto, ancho: 260),
                    )
                  : null,
              child: (foto == null || foto.isEmpty)
                  ? Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        fontSize: 34,
                        color: TemaApp.textoOscuro,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              conArticuloIndefinido(generoDePerfil(datos), 'manicurista'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: TemaApp.grisSubtitulo,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: resenas == 0 ? null : _verResenas,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: resenas == 0
                    ? const Text(
                        'Todavía sin reseñas',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: TemaApp.grisTexto,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            formatearCalificacion(datos['rating'] as num?),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            contarResenas(resenas),
                            style: const TextStyle(
                              color: TemaApp.info,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: TemaApp.info,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 17,
                            color: TemaApp.info,
                          ),
                        ],
                      ),
              ),
            ),
            if (AjustesProfesional.desdeMapa(datos).soloDomicilio) ...[
              const SizedBox(height: 6),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 15,
                    color: TemaApp.grisTexto,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Solo a domicilio',
                    style: TextStyle(color: TemaApp.grisSubtitulo),
                  ),
                ],
              ),
            ] else if (Ubicacion.desdeMapa(datos).estaDefinida) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: TemaApp.grisTexto,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      Ubicacion.desdeMapa(datos).resumen,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: TemaApp.grisSubtitulo),
                    ),
                  ),
                ],
              ),
            ],
            if (!_aceptaCitas) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TemaApp.avisoSuave,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_busy_outlined,
                      size: 18,
                      color: TemaApp.aviso,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'No está recibiendo citas nuevas por ahora. Puedes '
                        'ver su trabajo y guardarla en favoritos.',
                        style: TextStyle(fontSize: 12.5, color: TemaApp.aviso),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            _contacto(datos, telefono),
          ],
        ),
      ),
    );
  }

  Widget _contacto(Map<String, dynamic> datos, String? telefono) {
    final hayTelefono = telefono != null && telefono.isNotEmpty;
    final miUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (miUid.isEmpty) {
      if (!hayTelefono) return const SizedBox.shrink();
      return _filaContacto(llamar: telefono, chat: null, datos: datos);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('professionalId', isEqualTo: widget.professionalId)
          .where('clientId', isEqualTo: miUid)
          .snapshots(),
      builder: (context, instantanea) {
        final citas = (instantanea.data?.docs ?? const []).toList()
          ..sort((a, b) {
            final fechaA = (a.data()['date'] as Timestamp?)?.toDate();
            final fechaB = (b.data()['date'] as Timestamp?)?.toDate();
            if (fechaA == null || fechaB == null) return 0;
            return fechaB.compareTo(fechaA);
          });

        if (citas.isEmpty && !hayTelefono) return const SizedBox.shrink();

        return _filaContacto(
          llamar: hayTelefono ? telefono : null,
          chat: citas.isEmpty ? null : citas.first,
          datos: datos,
        );
      },
    );
  }

  Widget _filaContacto({
    required String? llamar,
    required QueryDocumentSnapshot<Map<String, dynamic>>? chat,
    required Map<String, dynamic> datos,
  }) {
    final botones = <Widget>[
      if (chat != null)
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _abrirChat(chat, datos),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Escribir'),
          ),
        ),
      if (llamar != null)
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _llamar(llamar),
            icon: const Icon(Icons.phone_outlined, size: 18),
            label: const Text('Llamar'),
          ),
        ),
    ];

    if (botones.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          for (var i = 0; i < botones.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            botones[i],
          ],
        ],
      ),
    );
  }

  void _abrirChat(
    QueryDocumentSnapshot<Map<String, dynamic>> cita,
    Map<String, dynamic> datos,
  ) {
    final nombre = (datos['name'] as String?)?.trim() ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          citaId: cita.id,
          clienteId: cita.data()['clientId'] ?? '',
          profesionalId: widget.professionalId,
          servicio: cita.data()['serviceName'] ?? 'Servicio',
          otroNombre: nombre.isEmpty ? 'Manicurista' : nombre,
          otraFoto: datos['photoUrl'] as String?,
          esProfesional: false,
        ),
      ),
    );
  }

  void _verResenas() => _pestanas.animateTo(3);

  Future<void> _compartir(String nombre) {
    final enlace = enlaceDePerfil(widget.professionalId);
    final quien = nombre.trim().isEmpty ? 'este perfil' : nombre.trim();

    return SharePlus.instance.share(
      ShareParams(
        text: 'Mira el trabajo de $quien en BeautyConnect: $enlace',
        subject: 'Perfil de $quien en BeautyConnect',
      ),
    );
  }

  void _abrirHojaReserva(String servicioId, Map<String, dynamic> servicio) {
    if (!_aceptaCitas) {
      ScaffoldMessenger.of(context).showSnackBar(
        construirMensaje(
          'No está recibiendo citas nuevas por ahora',
          tipo: TipoAviso.aviso,
        ),
      );
      return;
    }

    abrirHoja(
      context,
      hijo: _BookingSheet(
        professionalId: widget.professionalId,
        serviceId: servicioId,
        service: servicio,
      ),
    );
  }
}

class _PestanaInfo extends StatelessWidget {
  final Map<String, dynamic> datos;
  final String profesionalId;
  final VoidCallback onVerServicios;
  final VoidCallback onVerResenas;
  final void Function(String, Map<String, dynamic>) onReservar;

  const _PestanaInfo({
    required this.datos,
    required this.profesionalId,
    required this.onVerServicios,
    required this.onVerResenas,
    required this.onReservar,
  });

  @override
  Widget build(BuildContext context) {
    final sobreMi = datos['about'] as String?;
    final especialidades = List<String>.from(datos['specialties'] ?? []);
    final ubicacion = Ubicacion.desdeMapa(datos);

    final resenas = (datos['reviewsCount'] as num?)?.toInt() ?? 0;
    final ajustes = AjustesProfesional.desdeMapa(datos);

    final bloques = <Widget>[
      if (ajustes.llegaADomicilio)
        _Bloque(
          titulo: ajustes.soloDomicilio
              ? 'Solo va a domicilio'
              : 'Va a domicilio',
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    color: TemaApp.grisSubtitulo,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Puede atenderte donde estés, '
                      '${etiquetaRadio(ajustes.radioCoberturaKm).toLowerCase()}',
                      style: const TextStyle(color: TemaApp.grisSubtitulo),
                    ),
                  ),
                ],
              ),
              if (ajustes.recargoDomicilio > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 15,
                      color: TemaApp.grisTexto,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Cobra ${formatearPrecio(ajustes.recargoDomicilio)} '
                      'adicionales por ir',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: TemaApp.grisTexto,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      _ResumenServicios(
        profesionalId: profesionalId,
        onVerTodos: onVerServicios,
        onReservar: onReservar,
      ),
      if (resenas > 0)
        _AdelantoResenas(
          calificacion: (datos['rating'] as num?)?.toDouble() ?? 0,
          total: resenas,
          onVerTodas: onVerResenas,
        ),
    ];

    if (sobreMi != null && sobreMi.isNotEmpty) {
      bloques.add(
        _Bloque(
          titulo: 'Sobre mi',
          hijo: Text(
            sobreMi,
            style: const TextStyle(color: TemaApp.grisSubtitulo, height: 1.5),
          ),
        ),
      );
    }

    if (especialidades.isNotEmpty) {
      bloques.add(
        _Bloque(
          titulo: 'Especialidades',
          hijo: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: especialidades
                .map(
                  (e) => Chip(
                    label: Text(e),
                    backgroundColor: TemaApp.grisClaro,
                    labelStyle: const TextStyle(color: TemaApp.textoOscuro),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    if (ubicacion.estaDefinida && ajustes.atiendeEnSuLocal) {
      final sector = ubicacion.barrio.trim().isNotEmpty
          ? ubicacion.barrio.trim()
          : 'Villavicencio';

      final enElMapa = ubicacion.tienePunto;

      bloques.add(
        _Bloque(
          titulo: 'Dónde atiende',
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: TemaApp.grisTexto,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Zona de $sector',
                      style: const TextStyle(color: TemaApp.grisSubtitulo),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: TemaApp.grisTexto,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Recibirás la dirección exacta cuando confirme tu cita',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: TemaApp.grisTexto,
                      ),
                    ),
                  ),
                ],
              ),
              if (enElMapa) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => MapaDeZona.abrir(
                      context,
                      nombre: datos['name'] ?? '',
                      ubicacion: ubicacion,
                    ),
                    icon: const Icon(Icons.map_outlined, size: 17),
                    label: const Text('Ver la zona en el mapa'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final redes = leerRedes(datos);
    if (redes.isNotEmpty) {
      bloques.add(
        _Bloque(
          titulo: 'Encuentrala en redes',
          hijo: BotonesRedes(redes: redes),
        ),
      );
    }

    bloques.add(
      _Bloque(
        titulo: 'Certificaciones',
        hijo: ListaCertificados(profesionalId: profesionalId),
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, margenInferior(context)),
      children: bloques,
    );
  }
}

class _AdelantoResenas extends StatelessWidget {
  final double calificacion;
  final int total;
  final VoidCallback onVerTodas;

  const _AdelantoResenas({
    required this.calificacion,
    required this.total,
    required this.onVerTodas,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onVerTodas,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatearCalificacion(calificacion),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  Estrellas(calificacion: calificacion, tamano: 14),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lo que dicen sus clientes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Basado en ${contarResenas(total)} de citas terminadas',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaApp.grisSubtitulo,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: TemaApp.grisTexto),
            ],
          ),
        ),
      ),
    );
  }
}

class _PestanaServicios extends StatelessWidget {
  final String profesionalId;
  final void Function(String, Map<String, dynamic>) onReservar;

  const _PestanaServicios({
    required this.profesionalId,
    required this.onReservar,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(profesionalId)
          .collection('services')
          .snapshots(),
      builder: (context, instantanea) {
        if (!instantanea.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final servicios = instantanea.data!.docs;
        if (servicios.isEmpty) {
          return const EstadoVacio(
            icono: Icons.spa_outlined,
            titulo: 'Aún no ha publicado servicios',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: servicios.length,
          itemBuilder: (context, indice) {
            final documento = servicios[indice];
            final servicio = documento.data();

            return TarjetaServicio(
              servicio: servicio,
              onTap: () => onReservar(documento.id, servicio),
              accion: BotonReservar(
                onReservar: () => onReservar(documento.id, servicio),
              ),
            );
          },
        );
      },
    );
  }
}

class _PestanaPortafolio extends StatelessWidget {
  final String profesionalId;

  const _PestanaPortafolio({required this.profesionalId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(profesionalId)
          .collection('portfolio')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, instantanea) {
        if (!instantanea.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final fotos = instantanea.data!.docs;
        if (fotos.isEmpty) {
          return const EstadoVacio(
            icono: Icons.photo_library_outlined,
            titulo: 'Aún no ha publicado fotos de su trabajo',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: fotos.length,
          itemBuilder: (context, indice) {
            final diseno = Diseno.desdeDocumento(fotos[indice]);
            final titulo = diseno.titulo;

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleDisenoScreen(diseno: diseno),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Hero(
                  tag: 'diseno-${diseno.id}',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        ServicioSubidaImagenes.miniatura(
                          diseno.imagenUrl,
                          ancho: 400,
                        ),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) =>
                            Container(color: TemaApp.grisBorde),
                      ),
                      if (titulo != null && titulo.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black87],
                              ),
                            ),
                            child: Text(
                              titulo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Bloque extends StatelessWidget {
  final String titulo;
  final Widget hijo;

  const _Bloque({required this.titulo, required this.hijo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            hijo,
          ],
        ),
      ),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final String professionalId;
  final String serviceId;
  final Map<String, dynamic> service;

  const _BookingSheet({
    required this.professionalId,
    required this.serviceId,
    required this.service,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  final _servicio = ServicioDisponibilidad();
  final _subida = ServicioSubidaImagenes();
  final List<String> _referencias = [];
  bool _subiendoReferencia = false;

  List<DateTime> _dias = const [];
  DateTime _fecha = DateTime.now();
  String? _hora;
  bool _guardando = false;
  bool _buscandoDias = true;
  int _intervalo = 30;
  int _anticipacion = 0;

  AjustesProfesional _ajustes = const AjustesProfesional();
  Ubicacion? _ubicacionProfesional;
  ModalidadCita _modalidad = ModalidadCita.local;
  Ubicacion? _miUbicacion;

  num get _recargo => _modalidad.esDomicilio ? _ajustes.recargoDomicilio : 0;

  num get _precioServicio => (widget.service['price'] as num?) ?? 0;

  num get _precioTotal => _precioServicio + _recargo;

  double? get _distanciaAlLocal {
    final mia = _miUbicacion;
    final suya = _ubicacionProfesional;
    if (mia == null || !mia.tienePunto) return null;
    if (suya == null || !suya.tienePunto) return null;

    return distanciaKm(
      latitudA: mia.latitud!,
      longitudA: mia.longitud!,
      latitudB: suya.latitud!,
      longitudB: suya.longitud!,
    );
  }

  bool get _fueraDeCobertura {
    if (!_modalidad.esDomicilio) return false;

    final distancia = _distanciaAlLocal;
    return distancia != null && distancia > _ajustes.radioCoberturaKm;
  }

  bool get _faltaDireccion =>
      _modalidad.esDomicilio && !(_miUbicacion?.estaDefinida ?? false);

  int get _duracionServicio =>
      (widget.service['duration'] as num?)?.toInt() ?? 60;

  @override
  void initState() {
    super.initState();
    _buscarDiasConCupo();
  }

  Future<void> _buscarDiasConCupo() async {
    final hoy = DateTime.now();
    final base = DateTime(hoy.year, hoy.month, hoy.day);
    final candidatos = List.generate(30, (i) => base.add(Duration(days: i)));

    try {
      final horario = await _servicio
          .observarHorarioBase(widget.professionalId)
          .first;
      final ajustes = await _servicio.ajustesEntre(
        widget.professionalId,
        base,
        candidatos.last,
      );

      final perfil = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.professionalId)
          .get();
      final ajustesPro = AjustesProfesional.desdeMapa(perfil.data());

      final disponibles = _servicio.diasConCupo(
        horario: horario,
        ajustes: ajustes,
        fechas: candidatos,
        duracionServicio: _duracionServicio,
        anticipacionMinutos: ajustesPro.anticipacionMinutos,
      );

      if (!mounted) return;
      setState(() {
        _dias = disponibles;
        _intervalo = horario.intervaloMinutos;
        _ajustes = ajustesPro;
        if (ajustesPro.soloDomicilio) _modalidad = ModalidadCita.domicilio;
        _anticipacion = ajustesPro.anticipacionMinutos;
        _ubicacionProfesional = Ubicacion.desdeMapa(perfil.data());
        if (disponibles.isNotEmpty) _fecha = disponibles.first;
        _buscandoDias = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dias = candidatos;
        _fecha = base;
        _buscandoDias = false;
      });
    }
  }

  Future<void> _agregarReferencia() async {
    final mensajero = ScaffoldMessenger.of(context);

    try {
      final archivo = await _subida.elegirImagen(desdeCamara: false);
      if (archivo == null) return;

      if (mounted) setState(() => _subiendoReferencia = true);
      final imagen = await _subida.subir(archivo);

      if (mounted) {
        setState(() {
          _referencias
            ..clear()
            ..addAll(limpiarFotosReferencia([..._referencias, imagen.url]));
        });
      }
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo subir la foto. Puedes reservar sin ella',
          tipo: TipoAviso.error,
        ),
      );
    }

    if (mounted) setState(() => _subiendoReferencia = false);
  }

  Widget _bloqueReferencia() {
    if (!_subida.estaConfigurado) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Flexible(
                child: Text(
                  '¿Tienes un diseño en mente?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TemaApp.grisClaro,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Opcional',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Con una foto sabrá exactamente qué quieres',
            style: TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
          ),
          const SizedBox(height: 10),
          SubirReferencia(
            fotos: _referencias,
            subiendo: _subiendoReferencia,
            onAgregar: _agregarReferencia,
            onQuitar: () => setState(_referencias.clear),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmar() async {
    final hora = _hora;
    if (hora == null || _subiendoReferencia) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      await _servicio.reservar(
        profesionalId: widget.professionalId,
        clienteId: FirebaseAuth.instance.currentUser!.uid,
        fecha: _fecha,
        hora: hora,
        servicioId: widget.serviceId,
        servicioNombre: widget.service['name'] ?? 'Servicio',
        servicioPrecio: (widget.service['price'] as num?) ?? 0,
        duracionMinutos: _duracionServicio,
        intervalo: _intervalo,
        modalidad: _modalidad,
        ubicacionCliente: _miUbicacion,
        fotosReferencia: _referencias,
      );
      navegador.pop();
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('Cita solicitada. Espera la confirmación.'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    } on SoloDomicilios catch (e) {
      if (mounted) setState(() => _modalidad = ModalidadCita.domicilio);
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.aviso),
      );
    } on SinDomicilios catch (e) {
      if (mounted && !_ajustes.soloDomicilio) {
        setState(() => _modalidad = ModalidadCita.local);
      }
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.aviso),
      );
    } on FueraDeCobertura catch (e) {
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.aviso),
      );
    } on FueraDePlazo catch (e) {
      if (mounted) setState(() => _hora = null);
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.aviso),
      );
    } on AgendaCerrada catch (e) {
      navegador.pop();
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.aviso),
      );
      return;
    } on FranjaNoDisponible catch (e) {
      if (mounted) setState(() => _hora = null);
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.error),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo solicitar la cita', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: margenHoja(context, base: 24),
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezado(),
            if (_ajustes.soloDomicilio) ...[
              const SizedBox(height: 20),
              const Text(
                '¿Dónde quieres el servicio?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const _SoloDomicilio(),
              _selectorMiDireccion(),
            ] else if (_ajustes.haceDomicilios) ...[
              const SizedBox(height: 20),
              const Text(
                '¿Dónde quieres el servicio?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              PestanasPildora(
                etiquetas: const ['En su local', 'A domicilio'],
                seleccionada: _modalidad.esDomicilio ? 1 : 0,
                onCambio: (indice) => setState(
                  () => _modalidad = indice == 1
                      ? ModalidadCita.domicilio
                      : ModalidadCita.local,
                ),
              ),
              if (_modalidad.esDomicilio) _selectorMiDireccion(),
            ],
            const SizedBox(height: 20),
            const Text(
              'Fecha disponible',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            SizedBox(height: 74, child: _tiraDeDias()),
            const SizedBox(height: 16),
            const Text(
              'Horario disponible',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            _horarios(),
            _bloqueReferencia(),
            if (_modalidad.esDomicilio && _recargo > 0) ...[
              const SizedBox(height: 20),
              _desglosePrecio(),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    (_hora == null ||
                        _guardando ||
                        _subiendoReferencia ||
                        _faltaDireccion ||
                        _fueraDeCobertura)
                    ? null
                    : _confirmar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirmar Reserva'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorMiDireccion() {
    final mia = _miUbicacion;
    final distancia = _distanciaAlLocal;
    final fuera = _fueraDeCobertura;
    final marcada = mia?.estaDefinida ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _elegirMiDireccion,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: TemaApp.grisClaro,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: fuera ? TemaApp.error : TemaApp.grisBorde,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 20,
                    color: fuera ? TemaApp.error : TemaApp.grisTexto,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          marcada
                              ? mia!.resumen
                              : 'Marca dónde quieres que te atienda',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: marcada
                                ? TemaApp.textoOscuro
                                : TemaApp.grisTexto,
                          ),
                        ),
                        if (distancia != null)
                          Text(
                            'A ${formatearDistancia(distancia)} de donde '
                            'atiende',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: fuera
                                  ? TemaApp.error
                                  : TemaApp.grisSubtitulo,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: TemaApp.grisTexto),
                ],
              ),
            ),
          ),
          if (fuera)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Esa dirección queda fuera de su zona. Solo va a domicilio '
                '${etiquetaRadio(_ajustes.radioCoberturaKm).toLowerCase()}.',
                style: const TextStyle(fontSize: 12, color: TemaApp.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _elegirMiDireccion() async {
    final elegida = await Navigator.push<Ubicacion>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectorUbicacionScreen(
          inicial: _miUbicacion ?? const Ubicacion(),
          centroCobertura: _ubicacionProfesional,
          radioCoberturaKm: _ajustes.radioCoberturaKm,
        ),
      ),
    );

    if (elegida == null || !mounted) return;
    setState(() => _miUbicacion = elegida);
  }

  Widget _desglosePrecio() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TemaApp.grisClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _FilaPrecio(
            etiqueta: widget.service['name'] ?? 'Servicio',
            valor: formatearPrecio(_precioServicio),
          ),
          const SizedBox(height: 6),
          _FilaPrecio(
            etiqueta: 'Recargo por domicilio',
            valor: formatearPrecio(_recargo),
          ),
          const Divider(height: 18),
          _FilaPrecio(
            etiqueta: 'Total',
            valor: formatearPrecio(_precioTotal),
            destacado: true,
          ),
        ],
      ),
    );
  }

  Widget _encabezado() {
    final precio = (widget.service['price'] as num?) ?? 0;
    final duracion = (widget.service['duration'] as num?)?.toInt() ?? 0;

    final imagen = (widget.service['imageUrl'] as String?)?.trim() ?? '';

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: imagen.isEmpty
                ? Container(
                    color: TemaApp.grisClaro,
                    child: const Icon(Icons.spa, color: TemaApp.textoOscuro),
                  )
                : Image.network(
                    ServicioSubidaImagenes.miniatura(imagen, ancho: 180),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => Container(
                      color: TemaApp.grisClaro,
                      child: const Icon(Icons.spa, color: TemaApp.textoOscuro),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service['name'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${formatearPrecio(precio)}  -  ${formatearDuracion(duracion)} aprox.',
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

  Widget _tiraDeDias() {
    if (_buscandoDias) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_dias.isEmpty) {
      return const Center(
        child: Text(
          'No hay días disponibles para este servicio',
          style: TextStyle(color: TemaApp.grisTexto, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _dias.length,
      itemBuilder: (context, indice) {
        final dia = _dias[indice];
        final activo = DateUtils.isSameDay(dia, _fecha);

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

  Widget _horarios() {
    return StreamBuilder<HorarioBase>(
      stream: _servicio.observarHorarioBase(widget.professionalId),
      builder: (context, horarioSnap) {
        if (!horarioSnap.hasData) return const _CargandoHorarios();
        _intervalo = horarioSnap.data!.intervaloMinutos;

        return StreamBuilder<DisponibilidadDia>(
          stream: _servicio.observarDia(widget.professionalId, _fecha),
          builder: (context, diaSnap) {
            if (!diaSnap.hasData) return const _CargandoHorarios();

            final franjas = _servicio.franjasReservables(
              franjas: _servicio.generarFranjas(
                horario: horarioSnap.data!,
                dia: diaSnap.data!,
                fecha: _fecha,
              ),
              fecha: _fecha,
              duracionServicio: _duracionServicio,
              intervalo: horarioSnap.data!.intervaloMinutos,
              anticipacionMinutos: _anticipacion,
            );

            if (franjas.isEmpty) {
              return const EstadoVacio(
                compacto: true,
                icono: Icons.schedule_outlined,
                titulo: 'No hay horarios disponibles este día',
                detalle: 'Prueba con otro día',
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
      },
    );
  }
}

class _CargandoHorarios extends StatelessWidget {
  const _CargandoHorarios();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ResumenServicios extends StatelessWidget {
  static const _cuantos = 3;

  final String profesionalId;
  final VoidCallback onVerTodos;
  final void Function(String, Map<String, dynamic>) onReservar;

  const _ResumenServicios({
    required this.profesionalId,
    required this.onVerTodos,
    required this.onReservar,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(profesionalId)
          .collection('services')
          .snapshots(),
      builder: (context, instantanea) {
        final servicios = instantanea.data?.docs ?? [];
        if (servicios.isEmpty) return const SizedBox.shrink();

        final visibles = servicios.take(_cuantos).toList();
        final restantes = servicios.length - visibles.length;

        return _Bloque(
          titulo: 'Servicios',
          hijo: Column(
            children: [
              ...visibles.map(
                (documento) => FilaServicio(
                  servicio: documento.data(),
                  accion: TextButton(
                    onPressed: () => onReservar(documento.id, documento.data()),
                    child: const Text('Reservar'),
                  ),
                ),
              ),
              if (restantes > 0) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onVerTodos,
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: Text(
                      restantes == 1
                          ? 'Ver 1 servicio más'
                          : 'Ver los $restantes servicios restantes',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilaPrecio extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;

  const _FilaPrecio({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: destacado ? 15 : 13,
      fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
      color: destacado ? TemaApp.textoOscuro : TemaApp.grisSubtitulo,
    );

    return Row(
      children: [
        Expanded(child: Text(etiqueta, style: estilo)),
        Text(valor, style: estilo),
      ],
    );
  }
}

class _SoloDomicilio extends StatelessWidget {
  const _SoloDomicilio();

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
          Icon(Icons.directions_car_outlined, size: 16, color: TemaApp.info),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Solo trabaja a domicilio, así que va hasta donde estés.',
              style: TextStyle(fontSize: 12, height: 1.35, color: TemaApp.info),
            ),
          ),
        ],
      ),
    );
  }
}
