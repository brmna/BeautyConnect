import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../widgets/estado_vacio.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../widgets/hoja_modal.dart';
import '../../theme/app_theme.dart';
import '../widgets/cabecera_pantalla.dart';
import '../widgets/hoja_datos_diseno.dart';
import '../../data/models/diseno.dart';
import '../widgets/mensaje.dart';
import 'detalle_diseno_screen.dart';

class ProfessionalPortfolioScreen extends StatefulWidget {
  final bool embebida;

  const ProfessionalPortfolioScreen({super.key, this.embebida = false});

  @override
  State<ProfessionalPortfolioScreen> createState() =>
      _ProfessionalPortfolioScreenState();
}

class _ProfessionalPortfolioScreenState
    extends State<ProfessionalPortfolioScreen> {
  final _subida = ServicioSubidaImagenes();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _subiendo = false;

  CollectionReference<Map<String, dynamic>> get _coleccion => FirebaseFirestore
      .instance
      .collection('users')
      .doc(_uid)
      .collection('portfolio');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _subiendo ? null : _agregarFoto,
        backgroundColor: _subiendo ? TemaApp.grisTexto : TemaApp.negro,
        foregroundColor: TemaApp.blanco,
        icon: Icon(
          _subiendo ? Icons.hourglass_top : Icons.add_photo_alternate_outlined,
        ),
        label: Text(_subiendo ? 'Subiendo...' : 'Agregar foto'),
      ),
      body: Column(
        children: [
          if (!widget.embebida)
            const CabeceraPantalla(
              titulo: 'Mi Portafolio',
              subtitulo: 'Tu trabajo aparece en la galería de inspiración',
              icono: Icons.photo_library_outlined,
              estilo: EstiloCabecera.destacada,
            ),
          if (_subiendo) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _coleccion
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'No se pudo cargar el portafolio',
                      style: TextStyle(color: TemaApp.grisTexto),
                    ),
                  );
                }

                final fotos = snapshot.data?.docs ?? [];
                if (fotos.isEmpty) return _vacio();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: StaggeredGrid.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: List.generate(fotos.length, (indice) {
                      final foto = fotos[indice];
                      final datos = foto.data();
                      final celda = _celdaBento(indice);

                      return StaggeredGridTile.count(
                        crossAxisCellCount: celda.ancho,
                        mainAxisCellCount: celda.alto,
                        child: _Miniatura(
                          url: datos['imageUrl'] ?? '',
                          titulo: datos['titulo'],
                          etiquetas: List<String>.from(
                            datos['etiquetas'] ?? [],
                          ),
                          favoritos: (datos['favoritos'] as num?)?.toInt() ?? 0,
                          destacada: celda.ancho > 2 || celda.alto > 1,
                          onVer: () => _verFoto(foto),
                          onOpciones: () => _abrirOpciones(foto.id, datos),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vacio() {
    return EstadoVacio(
      icono: Icons.photo_library_outlined,
      titulo: 'Tu portafolio está vacío',
      detalle: 'Agrega fotos de tu trabajo para atraer clientes',
      accion: 'Agregar foto',
      onAccion: _subiendo ? null : _agregarFoto,
    );
  }

  _Celda _celdaBento(int indice) {
    switch (indice % 4) {
      case 0:
        return const _Celda(2, 2);
      case 1:
      case 2:
        return const _Celda(2, 1);
      default:
        return const _Celda(4, 2);
    }
  }

  Future<void> _agregarFoto() async {
    final origen = await abrirHoja<bool>(
      context,
      hijo: Builder(
        builder: (contexto) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de la galeria'),
                onTap: () => Navigator.pop(contexto, false),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar una foto'),
                onTap: () => Navigator.pop(contexto, true),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (origen == null || !mounted) return;

    final mensajero = ScaffoldMessenger.of(context);

    if (!_subida.estaConfigurado) {
      mensajero.showSnackBar(
        construirMensaje(
          'La subida de imágenes aún no está configurada',
          tipo: TipoAviso.aviso,
        ),
      );
      return;
    }

    try {
      final archivo = await _subida.elegirImagen(desdeCamara: origen);
      if (archivo == null || !mounted) return;

      final datos = await abrirHoja<DatosDiseno>(
        context,
        hijo: const HojaDatosDiseno(),
      );
      if (datos == null) return;

      setState(() => _subiendo = true);

      final imagen = await _subida.subir(archivo);
      final perfil = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();

      await _coleccion.add({
        'imageUrl': imagen.url,
        'publicId': imagen.identificador,
        'titulo': datos.titulo,
        'etiquetas': datos.etiquetas,
        'favoritos': 0,
        'profesionalId': _uid,
        'profesionalNombre': perfil.data()?['name'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on ErrorDeSubida catch (e) {
      mensajero.showSnackBar(
        construirMensaje(e.mensaje, tipo: TipoAviso.error),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo agregar la foto', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _subiendo = false);
  }

  void _verFoto(QueryDocumentSnapshot<Map<String, dynamic>> foto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DetalleDisenoScreen(diseno: Diseno.desdeDocumento(foto)),
      ),
    );
  }

  Future<void> _abrirOpciones(String id, Map<String, dynamic> datos) async {
    final accion = await abrirHoja<String>(
      context,
      hijo: Builder(
        builder: (hoja) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar título y etiquetas'),
                onTap: () => Navigator.pop(hoja, 'editar'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: TemaApp.error),
                title: const Text(
                  'Eliminar del portafolio',
                  style: TextStyle(color: TemaApp.error),
                ),
                onTap: () => Navigator.pop(hoja, 'eliminar'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (accion == 'editar') await _editarDatos(id, datos);
    if (accion == 'eliminar') await _confirmarEliminar(id);
  }

  Future<void> _editarDatos(String id, Map<String, dynamic> datos) async {
    final actualizados = await abrirHoja<DatosDiseno>(
      context,
      hijo: HojaDatosDiseno(
        tituloInicial: datos['titulo'],
        etiquetasIniciales: List<String>.from(datos['etiquetas'] ?? []),
        textoBoton: 'Guardar cambios',
      ),
    );
    if (actualizados == null || !mounted) return;

    final mensajero = ScaffoldMessenger.of(context);
    try {
      await _coleccion.doc(id).update({
        'titulo': actualizados.titulo,
        'etiquetas': actualizados.etiquetas,
      });
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo guardar', tipo: TipoAviso.error),
      );
    }
  }

  Future<void> _confirmarEliminar(String id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('Se quitará esta foto de tu portafolio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final mensajero = ScaffoldMessenger.of(context);
    try {
      await _coleccion.doc(id).delete();
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo eliminar la foto', tipo: TipoAviso.error),
      );
    }
  }
}

class _Celda {
  final int ancho;
  final int alto;

  const _Celda(this.ancho, this.alto);
}

class _Miniatura extends StatelessWidget {
  final String url;
  final String? titulo;
  final List<String> etiquetas;
  final int favoritos;
  final bool destacada;
  final VoidCallback onVer;
  final VoidCallback onOpciones;

  const _Miniatura({
    required this.url,
    required this.titulo,
    required this.etiquetas,
    required this.favoritos,
    this.destacada = false,
    required this.onVer,
    required this.onOpciones,
  });

  @override
  Widget build(BuildContext context) {
    final tieneTitulo = titulo != null && titulo!.isNotEmpty;

    return GestureDetector(
      onTap: onVer,
      onLongPress: onOpciones,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              ServicioSubidaImagenes.miniatura(
                url,
                ancho: destacada ? 700 : 400,
                cuadrada: false,
              ),
              fit: BoxFit.cover,
              loadingBuilder: (contexto, hijo, progreso) {
                if (progreso == null) return hijo;
                return Container(color: TemaApp.grisBorde);
              },
              errorBuilder: (_, _, _) => Container(
                color: TemaApp.grisBorde,
                child: const Icon(Icons.broken_image, color: TemaApp.grisTexto),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Tooltip(
                message: 'Más opciones',
                child: Material(
                  color: Colors.black38,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onOpciones,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.more_vert,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (tieneTitulo || etiquetas.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tieneTitulo)
                        Text(
                          titulo!,
                          maxLines: destacada ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: destacada ? 13 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (etiquetas.isNotEmpty)
                        Text(
                          etiquetas.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (favoritos > 0)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      Text(
                        '$favoritos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
