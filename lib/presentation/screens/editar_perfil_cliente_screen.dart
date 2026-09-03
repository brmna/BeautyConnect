import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/genero.dart';
import '../widgets/mensaje.dart';
import '../widgets/campo_correo.dart';
import '../widgets/campo_telefono.dart';
import '../widgets/selector_genero.dart';
import '../../utils/margenes.dart';
import '../../utils/validaciones.dart';

class EditarPerfilClienteScreen extends StatefulWidget {
  const EditarPerfilClienteScreen({super.key});

  @override
  State<EditarPerfilClienteScreen> createState() =>
      _EditarPerfilClienteScreenState();
}

class _EditarPerfilClienteScreenState extends State<EditarPerfilClienteScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _formulario = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  final _subida = ServicioSubidaImagenes();
  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;
  String _correo = '';
  String? _fotoUrl;
  Genero _genero = Genero.sinDecir;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final documento = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    final datos = documento.data() ?? {};

    if (!mounted) return;
    setState(() {
      _nombreCtrl.text = datos['name'] ?? '';
      _telefonoCtrl.text = datos['phone'] ?? '';
      _bioCtrl.text = datos['about'] ?? '';
      _correo = datos['email'] ?? '';
      _fotoUrl = datos['photoUrl'];
      _genero = generoDePerfil(datos);
      _cargando = false;
    });
  }

  Future<void> _cambiarFoto() async {
    final mensajero = ScaffoldMessenger.of(context);

    if (!_subida.estaConfigurado) {
      mensajero.showSnackBar(
        construirMensaje(
          'La subida de imágenes no está lista',
          tipo: TipoAviso.info,
        ),
      );
      return;
    }

    try {
      final archivo = await _subida.elegirImagen(desdeCamara: false);
      if (archivo == null) return;

      setState(() => _subiendoFoto = true);
      final imagen = await _subida.subir(archivo);
      if (mounted) setState(() => _fotoUrl = imagen.url);
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo subir la foto', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _subiendoFoto = false);
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'name': _nombreCtrl.text.trim(),
        'phone': _telefonoCtrl.text.trim(),
        'about': _bioCtrl.text.trim(),
        'genero': claveGenero(_genero),
        'photoUrl': _fotoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      navegador.pop();
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo guardar el perfil', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formulario,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  margenInferior(context),
                ),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _subiendoFoto ? null : _cambiarFoto,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: TemaApp.grisClaro,
                                  backgroundImage:
                                      (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                                      ? NetworkImage(
                                          ServicioSubidaImagenes.miniatura(
                                            _fotoUrl!,
                                            ancho: 240,
                                          ),
                                        )
                                      : null,
                                  child: (_fotoUrl == null || _fotoUrl!.isEmpty)
                                      ? Text(
                                          _nombreCtrl.text.isNotEmpty
                                              ? _nombreCtrl.text[0]
                                                    .toUpperCase()
                                              : 'C',
                                          style: const TextStyle(
                                            fontSize: 34,
                                            color: TemaApp.textoOscuro,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                if (_subiendoFoto)
                                  const Positioned.fill(
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black45,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: TemaApp.textoOscuro,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.photo_camera,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Toca para cambiar tu foto',
                            style: TextStyle(
                              fontSize: 12,
                              color: TemaApp.grisSubtitulo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nombreCtrl,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: validarNombre,
                            decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 14),
                          CampoCorreoFijo(correo: _correo),
                          const SizedBox(height: 14),
                          CampoTelefono(controlador: _telefonoCtrl),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _bioCtrl,
                            maxLines: 3,
                            maxLength: maximoSobreMi,
                            textCapitalization: TextCapitalization.sentences,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: validarSobreMi,
                            decoration: const InputDecoration(
                              labelText: 'Sobre mí',
                              hintText: 'Cuéntanos sobre ti...',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SelectorGenero(
                            valor: _genero,
                            onCambio: (valor) =>
                                setState(() => _genero = valor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaApp.negro,
                        foregroundColor: TemaApp.blanco,
                      ),
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
