import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../widgets/estado_vacio.dart';
import '../../data/services/servicio_vision.dart';
import '../../utils/similitud.dart';
import '../widgets/hoja_modal.dart';
import '../../data/models/diseno.dart';
import '../../data/services/servicio_disenos.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/estado_cita.dart';
import '../widgets/aviso.dart';
import '../widgets/barra_ocultable.dart';
import '../widgets/recarga_manual.dart';
import '../widgets/favoritos_optimistas.dart';
import '../widgets/tarjeta_diseno.dart';
import 'detalle_diseno_screen.dart';
import '../widgets/mensaje.dart';

class ClientHome extends StatefulWidget {
  final ValueChanged<int> onIrAPestana;

  const ClientHome({super.key, required this.onIrAPestana});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome>
    with
        FavoritosOptimistas<ClientHome>,
        CabeceraSegunScroll<ClientHome>,
        RecargaManual<ClientHome> {
  final _servicio = ServicioDisenos();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _buscadorCtrl = TextEditingController();

  String? _etiquetaActiva;
  String _busqueda = '';
  List<String> _etiquetasFoto = const [];
  bool _analizando = false;

  late Stream<Set<String>> _guardados;
  late Stream<List<Diseno>> _galeriaStream;

  @override
  void initState() {
    super.initState();
    crearConsultas();
  }

  @override
  void crearConsultas() {
    _guardados = _servicio.observarIdsFavoritos(_uid);
    _galeriaStream = _servicio.observarGaleria();
  }

  @override
  bool get anclarCabecera => _busqueda.isNotEmpty;

  void _cambiarEtiqueta(String? etiqueta) {
    mostrarCabecera();
    setState(() {
      _etiquetaActiva = etiqueta;
      _etiquetasFoto = const [];
    });
  }

  void _limpiarFoto() {
    mostrarCabecera();
    setState(() => _etiquetasFoto = const []);
  }

  Future<void> _buscarConFoto() async {
    final vision = ServicioVision();
    final mensajero = ScaffoldMessenger.of(context);

    if (!vision.estaConfigurado) {
      mensajero.showSnackBar(
        construirMensaje(
          'La búsqueda por foto aún no está configurada',
          tipo: TipoAviso.aviso,
        ),
      );
      return;
    }

    final desdeCamara = await abrirHoja<bool>(
      context,
      hijo: Builder(
        builder: (contexto) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Text(
                  'Busca con una foto',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una foto'),
                onTap: () => Navigator.pop(contexto, true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(contexto, false),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (desdeCamara == null || !mounted) return;

    final archivo = await ServicioSubidaImagenes().elegirImagen(
      desdeCamara: desdeCamara,
    );
    if (archivo == null || !mounted) return;

    setState(() => _analizando = true);

    try {
      final lectura = await vision.leerUnas(archivo);

      if (!lectura.sonUnas) {
        mensajero.showSnackBar(
          construirMensaje(
            'Eso no parece unas uñas. Prueba con otra foto',
            tipo: TipoAviso.aviso,
          ),
        );
      } else if (lectura.etiquetas.isEmpty) {
        mensajero.showSnackBar(
          construirMensaje(
            'No logramos identificar el estilo de ese diseño',
            tipo: TipoAviso.aviso,
          ),
        );
      } else {
        mostrarCabecera();
        setState(() {
          _etiquetasFoto = lectura.etiquetas;
          _etiquetaActiva = null;
        });
      }
    } on VisionNoConfigurada {
      mensajero.showSnackBar(
        construirMensaje(
          'La búsqueda por foto aún no está configurada',
          tipo: TipoAviso.aviso,
        ),
      );
    } on ErrorDeVision catch (e) {
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.error),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo analizar la foto', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _analizando = false);
  }

  List<String> _etiquetasDisponibles(List<Diseno> disenos) {
    final conteo = <String, int>{};

    for (final diseno in disenos) {
      for (final etiqueta in diseno.etiquetas) {
        final limpia = etiqueta.trim();
        if (limpia.isEmpty) continue;
        conteo[limpia] = (conteo[limpia] ?? 0) + 1;
      }
    }

    final etiquetas = conteo.keys.toList()
      ..sort((a, b) {
        final porUso = conteo[b]!.compareTo(conteo[a]!);
        return porUso != 0 ? porUso : a.compareTo(b);
      });

    return etiquetas;
  }

  @override
  void dispose() {
    _buscadorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BarraOcultable(
              visible: cabeceraVisible,
              child: Column(
                children: [
                  _cabecera(),
                  _RecordatorioCitas(
                    uid: _uid,
                    onVerCitas: () => widget.onIrAPestana(3),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: alDesplazar,
                child: _galeria(),
              ),
            ),
          ],
        ),
      ),
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
          const Icon(Icons.auto_awesome, size: 22),
          const SizedBox(height: 6),
          const Text(
            'Galería de Inspiración',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Explora diseños reales de uñas para tu próxima cita',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _buscadorCtrl,
            onChanged: (valor) => setState(() => _busqueda = valor),
            decoration: InputDecoration(
              hintText: 'Buscar diseños elegantes...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, size: 19),
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 17),
                      onPressed: () {
                        _buscadorCtrl.clear();
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
          const SizedBox(height: 10),
          _BotonFoto(analizando: _analizando, onTocar: _buscarConFoto),
        ],
      ),
    );
  }

  Widget _filtros(List<Diseno> disenos) {
    final disponibles = _etiquetasDisponibles(disenos);
    if (disponibles.isEmpty) return const SizedBox(height: 4);

    final etiquetas = <String?>[null, ...disponibles];

    return SizedBox(
      height: 46,
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: etiquetas.length,
        itemBuilder: (context, indice) {
          final etiqueta = etiquetas[indice];
          final activa = _etiquetaActiva == etiqueta;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: ChoiceChip(
              label: Text(etiqueta ?? 'Todos'),
              selected: activa,
              showCheckmark: false,
              labelStyle: TextStyle(
                fontSize: 12,
                color: activa ? TemaApp.blanco : TemaApp.textoOscuro,
                fontWeight: activa ? FontWeight.w600 : FontWeight.normal,
              ),
              selectedColor: TemaApp.negro,
              backgroundColor: TemaApp.blanco,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (_) => _cambiarEtiqueta(etiqueta),
            ),
          );
        },
      ),
    );
  }

  Widget _galeria() {
    return StreamBuilder<Set<String>>(
      stream: _guardados,
      builder: (context, favoritos) {
        final guardados = favoritos.data ?? const <String>{};
        sincronizarFavoritos(guardados);

        return StreamBuilder<List<Diseno>>(
          stream: _galeriaStream,
          builder: (context, galeria) {
            if (galeria.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (galeria.hasError) {
              return _mensaje(
                Icons.cloud_off_outlined,
                'No se pudo cargar la galería',
              );
            }

            final todos = galeria.data ?? [];
            final disenos = _filtrar(todos);

            if (disenos.isEmpty) {
              return Column(
                children: [
                  if (_etiquetasFoto.isNotEmpty)
                    _AvisoFoto(
                      etiquetas: _etiquetasFoto,
                      onQuitar: _limpiarFoto,
                    )
                  else
                    _filtros(todos),
                  Expanded(child: _vacio()),
                ],
              );
            }

            return Column(
              children: [
                if (_etiquetasFoto.isNotEmpty)
                  _AvisoFoto(etiquetas: _etiquetasFoto, onQuitar: _limpiarFoto)
                else
                  _filtros(todos),
                Expanded(
                  child: conRecarga(
                    hijo: CustomScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
                            child: Row(
                              children: [
                                Icon(Icons.trending_up, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Tendencias Populares',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          sliver: SliverMasonryGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childCount: disenos.length,
                            itemBuilder: (context, indice) {
                              final diseno = disenos[indice];
                              final guardado = esFavorito(diseno.id, guardados);

                              return TarjetaDiseno(
                                key: ValueKey(diseno.id),
                                diseno: diseno,
                                esFavorito: guardado,
                                alturaImagen: _altura(indice),
                                onFavorito: () =>
                                    _guardarDiseno(diseno, !guardado),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetalleDisenoScreen(diseno: diseno),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Diseno> _filtrar(List<Diseno> disenos) {
    if (_etiquetasFoto.isNotEmpty) {
      return ordenarPorParecido(disenos, _etiquetasFoto);
    }

    final etiqueta = _etiquetaActiva;
    final porEtiqueta = etiqueta == null
        ? disenos
        : disenos.where((d) => d.etiquetas.contains(etiqueta)).toList();

    final consulta = _busqueda.trim().toLowerCase();
    if (consulta.isEmpty) return porEtiqueta;

    return porEtiqueta.where((diseno) {
      final enTitulo = (diseno.titulo ?? '').toLowerCase().contains(consulta);
      final enEtiquetas = diseno.etiquetas.any(
        (e) => e.toLowerCase().contains(consulta),
      );
      final enAutora = diseno.profesionalNombre.toLowerCase().contains(
        consulta,
      );
      return enTitulo || enEtiquetas || enAutora;
    }).toList();
  }

  double _altura(int indice) {
    const alturas = [200.0, 260.0, 230.0, 290.0];
    return alturas[indice % alturas.length];
  }

  Widget _vacio() {
    if (_etiquetasFoto.isNotEmpty) {
      return _mensaje(
        Icons.image_search_outlined,
        'Nada parecido a tu foto todavía',
        detalle:
            'Buscamos ${_etiquetasFoto.join(', ')}. Prueba con otra foto '
            'o mira la galería completa',
      );
    }

    if (_busqueda.trim().isNotEmpty) {
      return _mensaje(
        Icons.search_off,
        'Ningún diseño coincide con "$_busqueda"',
      );
    }

    return _mensaje(
      Icons.auto_awesome_outlined,
      _etiquetaActiva == null
          ? 'Aún no hay diseños publicados'
          : 'No hay diseños con esa etiqueta',
      detalle: _etiquetaActiva == null
          ? 'Cuando las manicuristas suban su trabajo, aparecerá aquí'
          : null,
    );
  }

  Widget _mensaje(IconData icono, String texto, {String? detalle}) {
    return EstadoVacio(icono: icono, titulo: texto, detalle: detalle);
  }

  Future<void> _guardarDiseno(Diseno diseno, bool guardar) {
    final mensajero = ScaffoldMessenger.of(context);

    return alternarFavorito(
      id: diseno.id,
      guardar: guardar,
      accion: () => _servicio.alternarFavorito(
        clienteId: _uid,
        diseno: diseno,
        guardar: guardar,
      ),
      alFallar: (mensaje) => mensajero.showSnackBar(
        construirMensaje(mensaje, tipo: TipoAviso.error),
      ),
    );
  }
}

class _RecordatorioCitas extends StatefulWidget {
  final String uid;
  final VoidCallback onVerCitas;

  const _RecordatorioCitas({required this.uid, required this.onVerCitas});

  @override
  State<_RecordatorioCitas> createState() => _RecordatorioCitasState();
}

class _RecordatorioCitasState extends State<_RecordatorioCitas> {
  bool _oculto = false;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _citas =
      FirebaseFirestore.instance
          .collection('bookings')
          .where('clientId', isEqualTo: widget.uid)
          .snapshots();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _resenas =
      FirebaseFirestore.instance
          .collectionGroup('resenas')
          .where('clienteId', isEqualTo: widget.uid)
          .snapshots();

  Future<void> _abrirCitas(List<String> novedades) async {
    widget.onVerCitas();

    final lote = FirebaseFirestore.instance.batch();
    for (final id in novedades) {
      lote.update(FirebaseFirestore.instance.collection('bookings').doc(id), {
        'avisoVisto': true,
      });
    }

    try {
      await lote.commit();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_oculto) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _citas,
      builder: (context, citasSnap) {
        if (!citasSnap.hasData) return const SizedBox.shrink();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _resenas,
          builder: (context, resenasSnap) {
            final calificadas = (resenasSnap.data?.docs ?? [])
                .map((d) => d.id)
                .toSet();

            var proximas = 0;
            var porCalificar = 0;
            final confirmadas = <String>[];
            final movidas = <String>[];
            final rechazadas = <String>[];

            for (final cita in citasSnap.data!.docs) {
              final datos = cita.data();
              final estado = datos['status'];
              final sinVer = datos['avisoVisto'] == false;

              if (clasificarCita(datos).estaPorVenir) proximas++;

              if (sePuedeCalificar(datos) && !calificadas.contains(cita.id)) {
                porCalificar++;
              }
              if (sinVer && estado == 'confirmed') {
                if (datos['reagendadaEn'] != null) {
                  movidas.add(cita.id);
                } else {
                  confirmadas.add(cita.id);
                }
              }
              if (sinVer && estado == 'cancelled') rechazadas.add(cita.id);
            }

            final novedades = [...confirmadas, ...movidas, ...rechazadas];

            if (novedades.isEmpty && proximas == 0 && porCalificar == 0) {
              return const SizedBox.shrink();
            }

            final aviso = _elegirAviso(
              confirmadas: confirmadas,
              movidas: movidas,
              rechazadas: rechazadas,
              proximas: proximas,
              porCalificar: porCalificar,
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: Aviso(
                tipo: aviso.tipo,
                icono: aviso.icono,
                titulo: aviso.titulo,
                detalle: aviso.detalle,
                accion: TextButton(
                  onPressed: () => _abrirCitas(novedades),
                  child: Text(aviso.etiquetaAccion),
                ),
                onCerrar: () => setState(() => _oculto = true),
              ),
            );
          },
        );
      },
    );
  }

  _Novedad _elegirAviso({
    required List<String> confirmadas,
    required List<String> movidas,
    required List<String> rechazadas,
    required int proximas,
    required int porCalificar,
  }) {
    if (movidas.isNotEmpty) {
      return _Novedad(
        tipo: TipoAviso.aviso,
        icono: Icons.edit_calendar_outlined,
        titulo: movidas.length == 1
            ? 'Te movieron la hora de una cita'
            : 'Te movieron la hora de ${movidas.length} citas',
        detalle: 'Revisa la nueva fecha antes de que llegue',
        etiquetaAccion: 'Ver',
      );
    }

    if (confirmadas.isNotEmpty) {
      return _Novedad(
        tipo: TipoAviso.exito,
        icono: Icons.check_circle_outline,
        titulo: confirmadas.length == 1
            ? '¡Te confirmaron una cita!'
            : '¡Te confirmaron ${confirmadas.length} citas!',
        detalle: 'Toca para ver la fecha y la hora',
        etiquetaAccion: 'Ver',
      );
    }

    if (rechazadas.isNotEmpty) {
      return _Novedad(
        tipo: TipoAviso.aviso,
        icono: Icons.event_busy_outlined,
        titulo: rechazadas.length == 1
            ? 'Una cita no fue aceptada'
            : '${rechazadas.length} citas no fueron aceptadas',
        detalle: 'Puedes buscar otro horario',
        etiquetaAccion: 'Ver',
      );
    }

    if (proximas > 0) {
      return _Novedad(
        tipo: TipoAviso.exito,
        icono: Icons.event_available_outlined,
        titulo: proximas == 1
            ? 'Tienes 1 cita próxima'
            : 'Tienes $proximas citas próximas',
        detalle: 'Revisa la fecha y la hora en Mis Citas',
        etiquetaAccion: 'Ver',
      );
    }

    return _Novedad(
      tipo: TipoAviso.info,
      icono: Icons.star_border,
      titulo: porCalificar == 1
          ? 'Tienes 1 cita por calificar'
          : 'Tienes $porCalificar citas por calificar',
      detalle: 'Tu opinión ayuda a otros clientes',
      etiquetaAccion: 'Calificar',
    );
  }
}

class _Novedad {
  final TipoAviso tipo;
  final IconData icono;
  final String titulo;
  final String detalle;
  final String etiquetaAccion;

  const _Novedad({
    required this.tipo,
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.etiquetaAccion,
  });
}

class _BotonFoto extends StatelessWidget {
  final bool analizando;
  final VoidCallback onTocar;

  const _BotonFoto({required this.analizando, required this.onTocar});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: analizando ? null : onTocar,
        style: OutlinedButton.styleFrom(
          foregroundColor: TemaApp.textoOscuro,
          side: const BorderSide(color: TemaApp.grisBorde),
          shape: const StadiumBorder(),
        ),
        icon: analizando
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome, size: 16),
        label: Text(
          analizando ? 'Mirando tu foto...' : 'Buscar con una foto',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _AvisoFoto extends StatelessWidget {
  final List<String> etiquetas;
  final VoidCallback onQuitar;

  const _AvisoFoto({required this.etiquetas, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: TemaApp.infoSuave,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: TemaApp.info),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parecidos a tu foto',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: TemaApp.info,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  etiquetas.join(' · '),
                  style: const TextStyle(fontSize: 11.5, color: TemaApp.info),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitar el filtro de la foto',
            visualDensity: VisualDensity.compact,
            onPressed: onQuitar,
            icon: const Icon(Icons.close, size: 17, color: TemaApp.info),
          ),
        ],
      ),
    );
  }
}
