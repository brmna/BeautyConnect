import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../widgets/estado_vacio.dart';
import '../widgets/corazon_animado.dart';
import '../../data/services/servicio_favoritos.dart';
import '../../data/models/professional_model.dart';
import '../../data/services/profesional_service.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/distancia.dart';
import '../../utils/formato.dart';
import '../widgets/barra_ocultable.dart';
import '../widgets/cabecera_pantalla.dart';
import '../widgets/mensaje.dart';
import '../widgets/recarga_manual.dart';
import '../widgets/mapa_zonas.dart';
import 'escanear_qr_screen.dart';
import 'professional_detail_screen.dart';

enum OrdenBusqueda { relevancia, calificacion, resenas, distancia }

enum FiltroModalidad { todas, domicilio, local }

extension _EtiquetaModalidad on FiltroModalidad {
  String get etiqueta => switch (this) {
    FiltroModalidad.todas => 'Todas',
    FiltroModalidad.domicilio => 'Domicilio',
    FiltroModalidad.local => 'En su local',
  };

  IconData get icono => switch (this) {
    FiltroModalidad.todas => Icons.people_outline,
    FiltroModalidad.domicilio => Icons.directions_car_outlined,
    FiltroModalidad.local => Icons.storefront_outlined,
  };
}

extension _EtiquetaOrden on OrdenBusqueda {
  String get etiqueta => switch (this) {
    OrdenBusqueda.relevancia => 'Sugeridas',
    OrdenBusqueda.calificacion => 'Mejor calificación',
    OrdenBusqueda.resenas => 'Más reseñas',
    OrdenBusqueda.distancia => 'Cerca de mí',
  };

  IconData get icono => switch (this) {
    OrdenBusqueda.relevancia => Icons.tune,
    OrdenBusqueda.calificacion => Icons.star_outline,
    OrdenBusqueda.resenas => Icons.reviews_outlined,
    OrdenBusqueda.distancia => Icons.near_me_outlined,
  };
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with CabeceraSegunScroll<SearchScreen>, RecargaManual<SearchScreen> {
  final _servicio = ProfessionalService();
  final _favoritos = ServicioFavoritos();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _controlador = TextEditingController();

  late Stream<List<Professional>> _profesionales;
  late Stream<Set<String>> _misFavoritos;
  bool _enMapa = false;

  @override
  void initState() {
    super.initState();
    crearConsultas();
  }

  @override
  void crearConsultas() {
    _profesionales = _servicio.getProfessionals();
    _misFavoritos = _favoritos.observar(_uid);
  }

  String _busqueda = '';
  OrdenBusqueda _orden = OrdenBusqueda.relevancia;
  FiltroModalidad _modalidad = FiltroModalidad.todas;
  Position? _miUbicacion;
  bool _buscandoUbicacion = false;
  int _peticionUbicacion = 0;

  @override
  bool get anclarCabecera => _busqueda.isNotEmpty || _enMapa;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: SafeArea(
        child: Column(
          children: [
            BarraOcultable(visible: cabeceraVisible, child: _cabecera()),
            _filtros(),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: alDesplazar,
                child: StreamBuilder<List<Professional>>(
                  stream: _profesionales,
                  builder: (context, instantanea) {
                    if (instantanea.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (instantanea.hasError) {
                      return _mensaje(
                        Icons.cloud_off_outlined,
                        'No se pudo cargar la busqueda',
                      );
                    }

                    final todas = (instantanea.data ?? [])
                        .where((p) => p.name.trim().isNotEmpty)
                        .toList();
                    final resultados = _ordenar(_filtrar(todas));

                    if (todas.isEmpty) {
                      return _mensaje(
                        Icons.people_outline,
                        'Todavía no hay manicuristas en la app',
                      );
                    }

                    if (resultados.isEmpty) {
                      return _mensaje(
                        Icons.search_off,
                        'Sin resultados para "$_busqueda"',
                        detalle: 'Prueba con otro nombre o zona',
                      );
                    }

                    if (_enMapa) {
                      return MapaZonas(
                        profesionales: resultados,
                        onTocar: (profesional) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfessionalDetailScreen(
                              professionalId: profesional.id,
                            ),
                          ),
                        ),
                      );
                    }

                    return StreamBuilder<Set<String>>(
                      stream: _misFavoritos,
                      builder: (context, favoritasSnap) {
                        final favoritas =
                            favoritasSnap.data ?? const <String>{};

                        return conRecarga(
                          hijo: ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: resultados.length + 1,
                            itemBuilder: (context, indice) {
                              if (indice == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 12,
                                    top: 4,
                                  ),
                                  child: Text(
                                    resultados.length == 1
                                        ? '1 manicurista disponible'
                                        : '${resultados.length} manicuristas disponibles',
                                    style: const TextStyle(
                                      color: TemaApp.grisSubtitulo,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }

                              final profesional = resultados[indice - 1];
                              return _TarjetaProfesional(
                                profesional: profesional,
                                distancia: _distanciaA(profesional),
                                favorita: favoritas.contains(profesional.id),
                                onFavorita: _uid.isEmpty
                                    ? null
                                    : (marcar) => _alternarFavorita(
                                        profesional,
                                        marcar,
                                      ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfessionalDetailScreen(
                                      professionalId: profesional.id,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _alternarFavorita(Professional profesional, bool marcar) async {
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await _favoritos.alternar(
        uid: _uid,
        profesionalId: profesional.id,
        marcar: marcar,
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo actualizar favoritos',
          tipo: TipoAviso.error,
        ),
      );
    }
  }

  bool _cumpleModalidad(Professional p) => switch (_modalidad) {
    FiltroModalidad.todas => true,
    FiltroModalidad.domicilio => p.vaADomicilio,
    FiltroModalidad.local => p.atiendeEnSuLocal,
  };

  List<Professional> _filtrar(List<Professional> todas) {
    final porModalidad = todas.where(_cumpleModalidad).toList();

    final consulta = _busqueda.trim().toLowerCase();
    if (consulta.isEmpty) return porModalidad;

    return porModalidad.where((p) {
      final enNombre = p.name.toLowerCase().contains(consulta);
      final enZona =
          !p.soloDomicilio && p.zona.toLowerCase().contains(consulta);
      final enEspecialidad = p.specialties.any(
        (e) => e.toLowerCase().contains(consulta),
      );
      return enNombre || enZona || enEspecialidad;
    }).toList();
  }

  Future<void> _cambiarOrden(OrdenBusqueda orden) async {
    mostrarCabecera();

    if (orden != OrdenBusqueda.distancia) {
      _peticionUbicacion++;
      setState(() {
        _orden = orden;
        _buscandoUbicacion = false;
      });
      return;
    }

    if (_miUbicacion != null) {
      setState(() => _orden = orden);
      return;
    }

    if (_buscandoUbicacion) return;

    final peticion = ++_peticionUbicacion;
    setState(() => _buscandoUbicacion = true);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        if (peticion == _peticionUbicacion) {
          mensajero.showSnackBar(
            construirMensaje(
              'Necesitamos tu ubicación para ordenar por cercanía',
              tipo: TipoAviso.aviso,
            ),
          );
        }
      } else {
        final posicion = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
        if (mounted && peticion == _peticionUbicacion) {
          setState(() {
            _miUbicacion = posicion;
            _orden = OrdenBusqueda.distancia;
          });
        }
      }
    } catch (_) {
      if (peticion == _peticionUbicacion) {
        mensajero.showSnackBar(
          construirMensaje(
            'No se pudo obtener tu ubicación',
            tipo: TipoAviso.error,
          ),
        );
      }
    }

    if (mounted && peticion == _peticionUbicacion) {
      setState(() => _buscandoUbicacion = false);
    }
  }

  double? _distanciaA(Professional profesional) {
    final yo = _miUbicacion;
    final lat = profesional.latitude;
    final lon = profesional.longitude;
    if (yo == null || lat == null || lon == null) return null;

    return distanciaKm(
      latitudA: yo.latitude,
      longitudA: yo.longitude,
      latitudB: lat,
      longitudB: lon,
    );
  }

  List<Professional> _ordenar(List<Professional> lista) {
    final ordenada = [...lista];

    switch (_orden) {
      case OrdenBusqueda.relevancia:
        break;
      case OrdenBusqueda.calificacion:
        ordenada.sort((a, b) {
          if (a.reviewsCount == 0 && b.reviewsCount > 0) return 1;
          if (b.reviewsCount == 0 && a.reviewsCount > 0) return -1;
          return b.rating.compareTo(a.rating);
        });
      case OrdenBusqueda.resenas:
        ordenada.sort((a, b) => b.reviewsCount.compareTo(a.reviewsCount));
      case OrdenBusqueda.distancia:
        ordenada.sort((a, b) {
          final da = _distanciaA(a);
          final db = _distanciaA(b);
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
    }

    return ordenada;
  }

  Widget _filtros() {
    return Column(
      children: [
        PestanasPildora(
          etiquetas: const ['Lista', 'Mapa'],
          seleccionada: _enMapa ? 1 : 0,
          onCambio: (indice) {
            mostrarCabecera();
            setState(() => _enMapa = indice == 1);
          },
        ),
        if (!_enMapa)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...FiltroModalidad.values.map(_chipModalidad),
                ...OrdenBusqueda.values.map(_chipOrden),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chipModalidad(FiltroModalidad filtro) {
    final activo = filtro == _modalidad;

    return ChoiceChip(
      selected: activo,
      showCheckmark: false,
      onSelected: (_) {
        mostrarCabecera();
        setState(() => _modalidad = filtro);
      },
      avatar: Icon(
        filtro.icono,
        size: 15,
        color: activo ? TemaApp.blanco : TemaApp.grisSubtitulo,
      ),
      label: Text(filtro.etiqueta),
      labelStyle: TextStyle(
        fontSize: 12,
        color: activo ? TemaApp.blanco : TemaApp.textoOscuro,
        fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: TemaApp.negro,
      backgroundColor: TemaApp.blanco,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  Widget _chipOrden(OrdenBusqueda orden) {
    final activo = orden == _orden;
    final cargando = _buscandoUbicacion && orden == OrdenBusqueda.distancia;

    return ChoiceChip(
      selected: activo,
      showCheckmark: false,
      onSelected: (_) => _cambiarOrden(orden),
      avatar: cargando
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              orden.icono,
              size: 15,
              color: activo ? TemaApp.blanco : TemaApp.grisSubtitulo,
            ),
      label: Text(orden.etiqueta),
      labelStyle: TextStyle(
        fontSize: 12,
        color: activo ? TemaApp.blanco : TemaApp.textoOscuro,
        fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
      ),
      selectedColor: TemaApp.negro,
      backgroundColor: TemaApp.blanco,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  Widget _cabecera() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: TemaApp.blanco,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 20),
              SizedBox(width: 8),
              Text(
                'Encuentra tu Profesional',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Manicuristas de Villavicencio cerca de ti',
            style: TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controlador,
            onChanged: (valor) => setState(() => _busqueda = valor),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, zona o especialidad...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 19),
              suffixIcon: _busqueda.isEmpty
                  ? IconButton(
                      tooltip: 'Escanear código',
                      icon: const Icon(Icons.qr_code_scanner, size: 20),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EscanearQrScreen(),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controlador.clear();
                        setState(() => _busqueda = '');
                      },
                    ),
              filled: true,
              fillColor: TemaApp.grisClaro,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensaje(IconData icono, String texto, {String? detalle}) {
    return EstadoVacio(icono: icono, titulo: texto, detalle: detalle);
  }
}

class _TarjetaProfesional extends StatelessWidget {
  final Professional profesional;
  final double? distancia;
  final VoidCallback onTap;
  final bool favorita;
  final ValueChanged<bool>? onFavorita;

  const _TarjetaProfesional({
    required this.profesional,
    required this.onTap,
    this.distancia,
    this.favorita = false,
    this.onFavorita,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(url: profesional.photoUrl, nombre: profesional.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profesional.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (profesional.reviewsCount > 0) ...[
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            formatearCalificacion(profesional.rating),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            ' (${profesional.reviewsCount})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: TemaApp.grisTexto,
                            ),
                          ),
                        ],
                        if (distancia != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.near_me,
                            size: 12,
                            color: TemaApp.grisSubtitulo,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            formatearDistancia(distancia!),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: TemaApp.grisSubtitulo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (profesional.soloDomicilio) ...[
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 13,
                            color: TemaApp.grisTexto,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Solo a domicilio',
                            style: TextStyle(
                              fontSize: 12,
                              color: TemaApp.grisSubtitulo,
                            ),
                          ),
                        ],
                      ),
                    ] else if (profesional.zona.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: TemaApp.grisTexto,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              profesional.zona,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: TemaApp.grisSubtitulo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!profesional.aceptaCitas) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_busy_outlined,
                            size: 13,
                            color: TemaApp.aviso,
                          ),
                          const SizedBox(width: 4),
                          const Text(
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
                    if (profesional.specialties.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: profesional.specialties
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
              if (onFavorita != null)
                IconButton(
                  tooltip: favorita ? 'Quitar de favoritas' : 'Guardar',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onFavorita!(!favorita),
                  icon: CorazonAnimado(activo: favorita, tamano: 21),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String nombre;

  const _Avatar({required this.url, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'M';

    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: TemaApp.grisClaro,
        child: Text(
          inicial,
          style: const TextStyle(
            color: TemaApp.textoOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: TemaApp.grisClaro,
      backgroundImage: NetworkImage(
        ServicioSubidaImagenes.miniatura(url!, ancho: 160),
      ),
    );
  }
}
