import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import '../../utils/mensajes_auth.dart';
import '../../utils/validaciones.dart';
import '../widgets/mensaje.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  final String correoInicial;

  const RecuperarContrasenaScreen({super.key, this.correoInicial = ''});

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _auth = AuthRepository();
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _correoCtrl = TextEditingController(
    text: widget.correoInicial,
  );

  bool _enviando = false;
  bool _enviado = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _enviando = true);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await _auth.enviarRecuperacion(_correoCtrl.text);
      if (mounted) setState(() => _enviado = true);
    } on FirebaseAuthException catch (e) {
      mensajero.showSnackBar(
        construirMensaje(
          mensajeErrorAuth(e.code),
          tipo: e.code == 'too-many-requests'
              ? TipoAviso.aviso
              : TipoAviso.error,
        ),
      );
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo enviar el correo. Revisa tu conexión',
          tipo: TipoAviso.error,
        ),
      );
    }

    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        title: const Text(
          'Recuperar contraseña',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(24, 24, 24, margenInferior(context)),
        children: [_enviado ? _confirmacion() : _formularioCorreo()],
      ),
    );
  }

  Widget _formularioCorreo() {
    return Form(
      key: _formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset, size: 52, color: TemaApp.textoOscuro),
          const SizedBox(height: 16),
          const Text(
            '¿Olvidaste tu contraseña?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Escribe el correo con el que te registraste y te enviamos un '
            'enlace para crear una nueva.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: TemaApp.grisSubtitulo,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validarCorreo,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'tu@email.com',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.negro,
                foregroundColor: TemaApp.blanco,
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Enviar enlace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.mark_email_read_outlined,
          size: 52,
          color: TemaApp.exito,
        ),
        const SizedBox(height: 16),
        const Text(
          'Revisa tu correo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: TemaApp.grisSubtitulo,
            ),
            children: [
              const TextSpan(text: 'Le enviamos un enlace a '),
              TextSpan(
                text: _correoCtrl.text.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
              const TextSpan(
                text:
                    ' para que crees una contraseña nueva. Si no lo ves, '
                    'revisa la carpeta de correo no deseado.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaApp.negro,
              foregroundColor: TemaApp.blanco,
            ),
            child: const Text('Volver al inicio de sesión'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _enviando
                ? null
                : () => setState(() => _enviado = false),
            child: const Text('Usar otro correo'),
          ),
        ),
      ],
    );
  }
}
