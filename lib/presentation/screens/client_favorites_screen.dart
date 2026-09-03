import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';
import '../../data/services/servicio_favoritos.dart';
import '../../data/models/diseno.dart';
import '../../data/services/servicio_disenos.dart';
import '../../theme/app_theme.dart';
import '../widgets/cabecera_pantalla.dart';
import '../widgets/tarjeta_diseno.dart';
import '../../data/models/ubicacion.dart';
import 'detalle_diseno_screen.dart';
import 'professional_detail_screen.dart';
import '../widgets/mensaje.dart';
import '../widgets/recarga_manual.dart';
import '../widgets/avatar_persona.dart';
import '../../data/services/cache_perfiles.dart';
import '../../data/models/ajustes_profesional.dart';
import '../../utils/formato.dart';

class ClientFavoritesScreen extends StatelessWidget {
  final ValueChanged<int>? onIrAPestana;

  const ClientFavoritesScreen({super.key, this.onIrAPestana});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: TemaApp.grisClaro,
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(142),
          child: Column(
            children: [
              CabeceraPantalla(
                titulo: 'Favoritos',
                subtitulo: 'Tus diseños y manicuristas guardados',
                icono: Icons.favorite,
                estilo: EstiloCabecera.destacada,
              ),
              TabBar(
                tabs: [
                  Tab(text: 'Diseños'),
                  Tab(text: 'Manicuristas'),
                ],
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GaleriaDisenosFavoritos(onIrAPestana: onIrAPestana),
            _ListaManicuristasFavoritas(onIrAPestana: onIrAPestana),
          ],
        ),
      ),
    );
  }
}

class _GaleriaDisenosFavoritos extends StatefulWidget {
  final ValueChanged<int>? onIrAPestana;

  const _GaleriaDisenosFavoritos({this.onIrAPestana});

  @override
  State<_GaleriaDisenosFavoritos> createState() =>
      _GaleriaDisenosFavoritosState();
}

class _GaleriaDisenosFavoritosState extends State<_GaleriaDisenosFavoritos> {
  final _servicio = ServicioDisenos();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _quitados = <String>{};

  late final Stream<List<Diseno>> _favoritos = _servicio.observarFavoritos(
    _uid,
  );

  @override
  void initState() {
    super.initState();
    _servicio.limpiarFavoritosHuerfanos(_uid).catchError((_) => 0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Diseno>>(
      stream: _favoritos,
      builder: (context, instantanea) {
        if (instantanea.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final disenos = (instantanea.data ?? [])
            .where((diseno) => !_quitados.contains(diseno.id))
            .toList();

        if (disenos.isEmpty) {
          final irAGaleria = widget.onIrAPestana;

          return EstadoVacio(
            icono: Icons.auto_awesome_outlined,
            titulo: 'Aún no guardas diseños',
            detalle: 'Toca el corazón en la galería de inspiración',
            accion: irAGaleria == null ? null : 'Ver la galería',
            onAccion: irAGaleria == null ? null : () => irAGaleria(0),
          );
        }

        return GridView.builder(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: disenos.length,
          itemBuilder: (context, indice) {
            final diseno = disenos[indice];
            return TarjetaDiseno(
              key: ValueKey(diseno.id),
              diseno: diseno,
              esFavorito: true,
              alturaImagen: double.infinity,
              onFavorito: () => _quitar(diseno),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetalleDisenoScreen(diseno: diseno),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _quitar(Diseno diseno) async {
    final mensajero = ScaffoldMessenger.of(context);
    setState(() => _quitados.add(diseno.id));

    try {
      await _servicio.alternarFavorito(
        clienteId: _uid,
        diseno: diseno,
        guardar: false,
      );
    } catch (_) {
      if (mounted) setState(() => _quitados.remove(diseno.id));
      mensajero.showSnackBar(
        construirMensaje('No se pudo quitar el diseño', tipo: TipoAviso.error),
      );
    }
  }
}

class _ListaManicuristasFavoritas extends StatefulWidget {
  final ValueChanged<int>? onIrAPestana;

  const _ListaManicuristasFavoritas({this.onIrAPestana});

  @override
  State<_ListaManicuristasFavoritas> createState() =>
      _ListaManicuristasFavoritasState();
}

class _ListaManicuristasFavoritasState
    extends State<_ListaManicuristasFavoritas>
    with RecargaManual<_ListaManicuristasFavoritas> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _quitadas = <String>{};

  final _perfiles = CachePerfiles();

  late Stream<DocumentSnapshot> _usuario;

  @override
  void initState() {
    super.initState();
    crearConsultas();
  }

  @override
  void crearConsultas() {
    _perfiles.limpiar();
    _usuario = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _usuario,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final favorites = (data['favorites'] as List? ?? [])
            .where((id) => !_quitadas.contains(id))
            .toList();

        if (favorites.isEmpty) {
          final irABuscar = widget.onIrAPestana;

          return EstadoVacio(
            icono: Icons.favorite_border,
            titulo: 'Aún no tienes favoritas',
            detalle: 'Toca el corazón en un perfil para verlo aquí',
            accion: irABuscar == null ? null : 'Buscar manicuristas',
            onAccion: irABuscar == null ? null : () => irABuscar(1),
          );
        }

        return conRecarga(
          hijo: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final profId = favorites[index] as String;

              return FutureBuilder<Map<String, dynamic>>(
                key: ValueKey(profId),
                future: _perfiles.datos(profId),
                builder: (context, profSnap) {
                  if (!profSnap.hasData) {
                    return const SizedBox(height: 80);
                  }

                  return _TarjetaFavorita(
                    profesionalId: profId,
                    datos: profSnap.data!,
                    onQuitar: () => _removeFavorite(context, profId),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _removeFavorite(BuildContext context, String profId) async {
    final mensajero = ScaffoldMessenger.of(context);
    setState(() => _quitadas.add(profId));

    try {
      await ServicioFavoritos().alternar(
        uid: _uid,
        profesionalId: profId,
        marcar: false,
      );
    } catch (_) {
      if (mounted) setState(() => _quitadas.remove(profId));
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo quitar de favoritos',
          tipo: TipoAviso.error,
        ),
      );
    }
  }
}

class _TarjetaFavorita extends StatelessWidget {
  final String profesionalId;
  final Map<String, dynamic> datos;
  final VoidCallback onQuitar;

  const _TarjetaFavorita({
    required this.profesionalId,
    required this.datos,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = (datos['name'] as String?)?.trim() ?? '';
    final zona = Ubicacion.desdeMapa(datos).resumen;
    final resenas = (datos['reviewsCount'] as num?)?.toInt() ?? 0;
    final especialidades = List<String>.from(datos['specialties'] ?? []);
    final aceptaCitas = AjustesProfesional.desdeMapa(datos).aceptandoClientas;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProfessionalDetailScreen(professionalId: profesionalId),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarManicurista(
                nombre: nombre,
                foto: datos['photoUrl'] as String?,
                radio: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (resenas > 0) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            formatearCalificacion(datos['rating'] as num?),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' ($resenas)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: TemaApp.grisTexto,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: zona.isEmpty
                              ? TemaApp.grisBorde
                              : TemaApp.grisTexto,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            zona.isEmpty ? 'Sin ubicación registrada' : zona,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: zona.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: zona.isEmpty
                                  ? TemaApp.grisTexto
                                  : TemaApp.grisSubtitulo,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!aceptaCitas) ...[
                      const SizedBox(height: 5),
                      const Row(
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 13,
                            color: TemaApp.aviso,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'No recibe citas por ahora',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: TemaApp.aviso,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (especialidades.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: especialidades
                            .take(3)
                            .map(
                              (especialidad) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: TemaApp.grisClaro,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  especialidad,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: TemaApp.grisSubtitulo,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Quitar de favoritos',
                icon: const Icon(Icons.favorite, color: Colors.red, size: 22),
                onPressed: onQuitar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
