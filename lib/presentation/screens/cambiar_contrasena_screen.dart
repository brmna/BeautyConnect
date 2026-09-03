import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/mensajes_auth.dart';
import '../widgets/mensaje.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() =>
      _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _formulario = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _guardando = false;

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final usuario = FirebaseAuth.instance.currentUser;

    try {
      final credencial = EmailAuthProvider.credential(
        email: usuario!.email!,
        password: _actualCtrl.text,
      );
      await usuario.reauthenticateWithCredential(credencial);
      await usuario.updatePassword(_nuevaCtrl.text);

      navegador.pop();
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    } on FirebaseAuthException catch (e) {
      final mensaje =
          e.code == 'invalid-credential' || e.code == 'wrong-password'
          ? 'La contraseña actual no es correcta'
          : mensajeErrorAuth(e.code);
      mensajero.showSnackBar(construirMensaje(mensaje, tipo: TipoAviso.error));
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo cambiar la contraseña',
          tipo: TipoAviso.error,
        ),
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
          'Cambiar Contraseña',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaApp.blanco,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TemaApp.grisBorde),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seguridad de tu cuenta',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tu contraseña debe tener al menos 6 caracteres.',
                          style: TextStyle(
                            fontSize: 12,
                            color: TemaApp.grisSubtitulo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _campo(
                      controlador: _actualCtrl,
                      etiqueta: 'Contraseña actual',
                      validador: (v) => (v == null || v.isEmpty)
                          ? 'Ingresa tu contraseña actual'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _campo(
                      controlador: _nuevaCtrl,
                      etiqueta: 'Nueva contraseña',
                      validador: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _campo(
                      controlador: _confirmarCtrl,
                      etiqueta: 'Confirmar nueva contraseña',
                      validador: (v) => v != _nuevaCtrl.text
                          ? 'Las contraseñas no coinciden'
                          : null,
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
                label: const Text('Guardar Contraseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controlador,
    required String etiqueta,
    required String? Function(String?) validador,
  }) {
    return TextFormField(
      controller: controlador,
      obscureText: true,
      validator: validador,
      decoration: InputDecoration(labelText: etiqueta),
    );
  }
}
