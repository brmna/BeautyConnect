import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import '../../utils/mensajes_auth.dart';
import '../../utils/validaciones.dart';
import '../widgets/aviso.dart';
import '../widgets/mensaje.dart';

class CambiarCorreoScreen extends StatefulWidget {
  const CambiarCorreoScreen({super.key});

  @override
  State<CambiarCorreoScreen> createState() => _CambiarCorreoScreenState();
}

class _CambiarCorreoScreenState extends State<CambiarCorreoScreen> {
  final _auth = AuthRepository();
  final _formulario = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();

  bool _guardando = false;
  bool _oculta = true;

  String get _correoActual => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void dispose() {
    _correoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    final nuevo = _correoCtrl.text.trim();
    if (nuevo.toLowerCase() == _correoActual.toLowerCase()) {
      mostrarMensaje(
        context,
        'Ese ya es tu correo actual',
        tipo: TipoAviso.aviso,
      );
      return;
    }

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      await _auth.cambiarCorreo(
        contrasenaActual: _contrasenaCtrl.text,
        correoNuevo: nuevo,
      );

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'correoPendiente': nuevo,
        }, SetOptions(merge: true));
      }

      navegador.pop();
      mensajero.showSnackBar(
        construirMensaje(
          'Te enviamos un enlace a $nuevo. Ábrelo para completar el cambio',
          tipo: TipoAviso.exito,
          duracion: const Duration(seconds: 6),
        ),
      );
      return;
    } on FirebaseAuthException catch (e) {
      mensajero.showSnackBar(
        construirMensaje(mensajeErrorAuth(e.code), tipo: TipoAviso.error),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo cambiar el correo', tipo: TipoAviso.error),
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
          'Cambiar correo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            margenInferior(context, base: 16),
          ),
          children: [
            const Aviso(
              tipo: TipoAviso.info,
              icono: Icons.mark_email_unread_outlined,
              titulo: 'El cambio se confirma por correo',
              detalle:
                  'Tu correo actual sigue funcionando hasta que abras el '
                  'enlace que te llegue al nuevo.',
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Correo actual',
                      style: TextStyle(
                        fontSize: 12,
                        color: TemaApp.grisSubtitulo,
                      ),
                    ),
                    Text(
                      _correoActual,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: validarCorreo,
                      decoration: const InputDecoration(
                        labelText: 'Correo nuevo',
                        hintText: 'tu@correo.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _contrasenaCtrl,
                      obscureText: _oculta,
                      validator: validarContrasena,
                      decoration: InputDecoration(
                        labelText: 'Tu contraseña actual',
                        helperText: 'La pedimos para confirmar que eres tú',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _oculta
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _oculta = !_oculta),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enviar el enlace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
