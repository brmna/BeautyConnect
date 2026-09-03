import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/ubicacion.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../widgets/campo_correo.dart';
import '../widgets/campo_telefono.dart';
import '../widgets/hoja_modal.dart';
import '../widgets/redes_sociales.dart';
import 'selector_ubicacion_screen.dart';
import '../../utils/genero.dart';
import '../widgets/mensaje.dart';
import '../widgets/selector_genero.dart';
import '../../utils/margenes.dart';
import '../../utils/validaciones.dart';

class EditarPerfilProfesionalScreen extends StatefulWidget {
  const EditarPerfilProfesionalScreen({super.key});

  @override
  State<EditarPerfilProfesionalScreen> createState() =>
      _EditarPerfilProfesionalScreenState();
}

class _EditarPerfilProfesionalScreenState
    extends State<EditarPerfilProfesionalScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _formulario = GlobalKey<FormState>();
  final _subida = ServicioSubidaImagenes();

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _sobreMiCtrl = TextEditingController();
  final _especialidadesCtrl = TextEditingController();
  final _experienciaCtrl = TextEditingController();
  final Map<String, TextEditingController> _redesCtrl = {
    for (final red in RedSocial.values) red.clave: TextEditingController(),
  };

  Ubicacion _ubicacion = const Ubicacion();
  String? _fotoUrl;
  Genero _genero = Genero.sinDecir;
  String _correo = '';

  bool _cargando = true;
  bool _guardando = false;
  bool _subiendoFoto = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _sobreMiCtrl.dispose();
    _especialidadesCtrl.dispose();
    _experienciaCtrl.dispose();
    for (final controlador in _redesCtrl.values) {
      controlador.dispose();
    }
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
      _sobreMiCtrl.text = datos['about'] ?? '';
      _especialidadesCtrl.text =
          (datos['specialties'] as List?)?.join(', ') ?? '';
      _experienciaCtrl.text = datos['aniosExperiencia']?.toString() ?? '';
      _ubicacion = Ubicacion.desdeMapa(datos);
      _fotoUrl = datos['photoUrl'];
      _genero = generoDePerfil(datos);
      leerRedes(
        datos,
      ).forEach((clave, valor) => _redesCtrl[clave]?.text = valor);
      _correo = datos['email'] ?? '';
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

  Future<void> _abrirOpcionesFoto() async {
    final tieneFoto = _fotoUrl != null && _fotoUrl!.isNotEmpty;

    final accion = await abrirHoja<String>(
      context,
      hijo: Builder(
        builder: (contexto) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Cambiar foto'),
                onTap: () => Navigator.pop(contexto, 'cambiar'),
              ),
              if (tieneFoto)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: TemaApp.error,
                  ),
                  title: const Text(
                    'Quitar foto',
                    style: TextStyle(color: TemaApp.error),
                  ),
                  onTap: () => Navigator.pop(contexto, 'quitar'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (accion == 'cambiar') await _cambiarFoto();
    if (accion == 'quitar') setState(() => _fotoUrl = null);
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    final especialidades = _especialidadesCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        ..._ubicacion.aMapa(),
        'name': _nombreCtrl.text.trim(),
        'phone': _telefonoCtrl.text.trim(),
        'about': _sobreMiCtrl.text.trim(),
        'genero': claveGenero(_genero),
        'specialties': especialidades,
        'aniosExperiencia': int.tryParse(_experienciaCtrl.text.trim()),
        'photoUrl': _fotoUrl,
        'redes': {
          for (final entrada in _redesCtrl.entries)
            entrada.key: entrada.value.text.trim(),
        },
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
          'Editar Perfil Profesional',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontSize: 18,
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
                  _tarjetaFoto(),
                  const SizedBox(height: 16),
                  _grupo('INFORMACIÓN PERSONAL', [
                    _campo(
                      controlador: _nombreCtrl,
                      etiqueta: 'Nombre completo',
                      icono: Icons.person_outline,
                      validar: validarNombre,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CampoCorreoFijo(correo: _correo),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CampoTelefono(controlador: _telefonoCtrl),
                    ),
                    _selectorUbicacion(),
                    _campo(
                      controlador: _sobreMiCtrl,
                      etiqueta: 'Sobre mí',
                      ayuda: 'Cuéntale a tus clientes sobre tu experiencia',
                      lineas: 3,
                      largoMaximo: maximoSobreMi,
                      validar: validarSobreMi,
                    ),
                    SelectorGenero(
                      valor: _genero,
                      onCambio: (valor) => setState(() => _genero = valor),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _grupo('INFORMACIÓN PROFESIONAL', [
                    _campo(
                      controlador: _especialidadesCtrl,
                      etiqueta: 'Especialidades',
                      icono: Icons.auto_awesome_outlined,
                      validar: validarEspecialidades,
                      ayuda: 'Separa cada especialidad con comas',
                    ),
                    _campo(
                      controlador: _experienciaCtrl,
                      etiqueta: 'Años de experiencia',
                      icono: Icons.workspace_premium_outlined,
                      teclado: TextInputType.number,
                      validar: validarAniosExperiencia,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _grupo('REDES SOCIALES', [
                    CamposRedes(controladores: _redesCtrl),
                  ]),
                  const SizedBox(height: 24),
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

  Widget _tarjetaFoto() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _subiendoFoto ? null : _abrirOpcionesFoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: TemaApp.grisClaro,
                    backgroundImage: (_fotoUrl != null && _fotoUrl!.isNotEmpty)
                        ? NetworkImage(
                            ServicioSubidaImagenes.miniatura(
                              _fotoUrl!,
                              ancho: 260,
                            ),
                          )
                        : null,
                    child: (_fotoUrl == null || _fotoUrl!.isEmpty)
                        ? Text(
                            _nombreCtrl.text.trim().isEmpty
                                ? 'M'
                                : _nombreCtrl.text.trim()[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
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
                        child: CircularProgressIndicator(color: Colors.white),
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
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Toca para cambiar tu foto de perfil',
              style: TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grupo(String titulo, List<Widget> hijos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: TemaApp.grisTexto,
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: hijos),
          ),
        ),
      ],
    );
  }

  Widget _campo({
    required TextEditingController controlador,
    required String etiqueta,
    IconData? icono,
    String? ayuda,
    int lineas = 1,
    int? largoMaximo,
    TextInputType? teclado,
    String? Function(String?)? validar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controlador,
        validator: validar,
        autovalidateMode: validar == null
            ? AutovalidateMode.disabled
            : AutovalidateMode.onUserInteraction,
        maxLines: lineas,
        maxLength: largoMaximo,
        keyboardType: teclado,
        textCapitalization: lineas > 1
            ? TextCapitalization.sentences
            : TextCapitalization.words,
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          prefixIcon: icono == null ? null : Icon(icono, size: 20),
          alignLabelWithHint: lineas > 1,
        ),
      ),
    );
  }

  Widget _selectorUbicacion() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () async {
          final elegida = await Navigator.push<Ubicacion>(
            context,
            MaterialPageRoute(
              builder: (_) => SelectorUbicacionScreen(inicial: _ubicacion),
            ),
          );
          if (elegida == null) return;
          setState(() => _ubicacion = elegida);
        },
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Ubicación',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            suffixIcon: Icon(
              _ubicacion.tienePunto ? Icons.map : Icons.chevron_right,
              color: _ubicacion.tienePunto ? TemaApp.negro : null,
            ),
          ),
          child: Text(
            _ubicacion.estaDefinida
                ? _ubicacion.resumen
                : 'Toca para marcar donde atiendes',
            style: TextStyle(
              color: _ubicacion.estaDefinida
                  ? TemaApp.textoOscuro
                  : TemaApp.grisTexto,
            ),
          ),
        ),
      ),
    );
  }
}
