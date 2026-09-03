import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;

import '../../data/models/diseno.dart';
import '../../data/services/servicio_disenos.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../widgets/corazon_animado.dart';
import '../widgets/favoritos_optimistas.dart';
import 'professional_detail_screen.dart';
import '../widgets/mensaje.dart';
import '../widgets/visor_fotos.dart';

class DetalleDisenoScreen extends StatefulWidget {
  final Diseno diseno;

  const DetalleDisenoScreen({super.key, required this.diseno});

  @override
  State<DetalleDisenoScreen> createState() => _DetalleDisenoScreenState();
}

class _DetalleDisenoScreenState extends State<DetalleDisenoScreen>
    with FavoritosOptimistas<DetalleDisenoScreen> {
  final _servicio = ServicioDisenos();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late final Stream<Set<String>> _guardados = _servicio.observarIdsFavoritos(
    _uid,
  );

  bool _descargando = false;

  Future<void> _descargar(Diseno diseno) async {
    setState(() => _descargando = true);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      final respuesta = await http.get(Uri.parse(diseno.imagenUrl));
      if (respuesta.statusCode != 200) throw Exception('descarga fallida');

      await Gal.putImageBytes(
        respuesta.bodyBytes,
        album: 'BeautyConnect',
        name: 'diseno-${diseno.id}',
      );

      mensajero.showSnackBar(
        construirMensaje(
          'Diseño guardado en tu galería',
          tipo: TipoAviso.exito,
        ),
      );
    } on GalException catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'Necesitamos permiso para guardar en tu galería',
          tipo: TipoAviso.aviso,
        ),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo guardar la imagen', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _descargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final diseno = widget.diseno;

    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: TemaApp.blanco,
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () =>
                    VisorFotos.abrir(context, fotos: [diseno.imagenUrl]),
                child: Hero(
                  tag: 'diseno-${diseno.id}',
                  child: Image.network(
                    ServicioSubidaImagenes.miniatura(
                      diseno.imagenUrl,
                      ancho: 900,
                      cuadrada: false,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: TemaApp.grisBorde),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  backgroundColor: TemaApp.blanco,
                  child: IconButton(
                    tooltip: 'Guardar en mi galería',
                    icon: _descargando
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.download_outlined,
                            size: 20,
                            color: TemaApp.textoOscuro,
                          ),
                    onPressed: _descargando ? null : () => _descargar(diseno),
                  ),
                ),
              ),
              StreamBuilder<Set<String>>(
                stream: _guardados,
                builder: (context, favoritos) {
                  final confirmados = favoritos.data ?? const <String>{};
                  sincronizarFavoritos(confirmados);
                  final guardado = esFavorito(diseno.id, confirmados);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundColor: TemaApp.blanco,
                      child: IconButton(
                        icon: CorazonAnimado(activo: guardado, tamano: 20),
                        onPressed: () => _guardar(diseno, !guardado),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _encabezado(diseno),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (diseno.favoritos > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 14,
                          color: TemaApp.textoOscuro,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          diseno.favoritos == 1
                              ? '1 persona guardó este diseño'
                              : '${diseno.favoritos} personas guardaron este diseño',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TemaApp.grisSubtitulo,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (diseno.etiquetas.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: diseno.etiquetas
                          .map(
                            (etiqueta) => Chip(
                              label: Text(etiqueta),
                              backgroundColor: TemaApp.blanco,
                              labelStyle: const TextStyle(fontSize: 12),
                              side: const BorderSide(color: TemaApp.grisBorde),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _TarjetaAutora(diseno: diseno),
                  const SizedBox(height: 20),
                  _MasTrabajos(diseno: diseno),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _encabezado(Diseno diseno) {
    final titulo = diseno.titulo;
    if (titulo != null && titulo.trim().isNotEmpty) return titulo;

    if (diseno.etiquetas.isNotEmpty) {
      return diseno.etiquetas.take(2).join(' · ');
    }

    return 'Diseño de uñas';
  }

  Future<void> _guardar(Diseno diseno, bool guardar) {
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

class _TarjetaAutora extends StatelessWidget {
  final Diseno diseno;

  const _TarjetaAutora({required this.diseno});

  @override
  Widget build(BuildContext context) {
    if (diseno.profesionalId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(diseno.profesionalId)
          .snapshots(),
      builder: (context, instantanea) {
        final datos = instantanea.data?.data() ?? {};
        final nombre = datos['name'] ?? diseno.profesionalNombre;
        final foto = datos['photoUrl'] as String?;
        final resenas = (datos['reviewsCount'] as num?)?.toInt() ?? 0;
        final zona = (datos['direccion'] as String?)?.trim().isNotEmpty ?? false
            ? datos['direccion']
            : datos['location'] ?? '';

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfessionalDetailScreen(
                  professionalId: diseno.profesionalId,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: TemaApp.grisClaro,
                    backgroundImage: (foto != null && foto.isNotEmpty)
                        ? NetworkImage(
                            ServicioSubidaImagenes.miniatura(foto, ancho: 160),
                          )
                        : null,
                    child: (foto == null || foto.isEmpty)
                        ? Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'M',
                            style: const TextStyle(
                              color: TemaApp.textoOscuro,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Trabajo de',
                          style: TextStyle(
                            fontSize: 11,
                            color: TemaApp.grisTexto,
                          ),
                        ),
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (resenas > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 13,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${datos['rating'] ?? 0}  ($resenas reseñas)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: TemaApp.grisSubtitulo,
                                ),
                              ),
                            ],
                          )
                        else if (zona.toString().isNotEmpty)
                          Text(
                            zona,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
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
      },
    );
  }
}

class _MasTrabajos extends StatelessWidget {
  final Diseno diseno;

  const _MasTrabajos({required this.diseno});

  @override
  Widget build(BuildContext context) {
    if (diseno.profesionalId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(diseno.profesionalId)
          .collection('portfolio')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get(),
      builder: (context, instantanea) {
        final otros = (instantanea.data?.docs ?? [])
            .where((documento) => documento.id != diseno.id)
            .take(6)
            .toList();

        if (otros.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Más de este portafolio',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 130,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: otros.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, indice) {
                  final otro = Diseno.desdeDocumento(otros[indice]);

                  return GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetalleDisenoScreen(diseno: otro),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        ServicioSubidaImagenes.miniatura(
                          otro.imagenUrl,
                          ancho: 300,
                        ),
                        width: 110,
                        height: 130,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) =>
                            Container(width: 110, color: TemaApp.grisBorde),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
