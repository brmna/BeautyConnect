import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main_screen.dart';
import 'screens/bienvenida_profesional_screen.dart';
import '../theme/app_theme.dart';
import '../utils/sesion.dart';
import 'widgets/marca_app.dart';
import '../data/auth_repository.dart';
import 'screens/login_screen.dart';
import 'screens/professional_home.dart';
import 'screens/verificar_correo_screen.dart';
import 'sincronizador_recordatorios.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _uidPreparado;
  Future<void>? _preparacion;

  Future<void> _prepararPerfil(String uid) {
    if (_uidPreparado == uid && _preparacion != null) return _preparacion!;

    _uidPreparado = uid;
    return _preparacion = _crearPerfilSiFalta(uid);
  }

  Future<void> _crearPerfilSiFalta(String uid) async {
    final referencia = FirebaseFirestore.instance.collection('users').doc(uid);
    if ((await referencia.get()).exists) return;

    await referencia.set({
      'email': FirebaseAuth.instance.currentUser?.email,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _reintentarPreparacion() {
    setState(() {
      _uidPreparado = null;
      _preparacion = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, sesion) {
        if (sesion.connectionState == ConnectionState.waiting) {
          return const PantallaCargando();
        }

        final usuario = sesion.data;
        if (usuario == null) return const LoginScreen();

        if (AuthRepository().correoNecesitaVerificacion) {
          return const VerificarCorreoScreen();
        }

        return FutureBuilder<void>(
          future: _prepararPerfil(usuario.uid),
          builder: (context, creacion) {
            if (creacion.connectionState == ConnectionState.waiting) {
              return const PantallaCargando();
            }

            if (creacion.hasError) {
              return _PantallaError(
                mensaje: 'No se pudo preparar tu cuenta',
                onReintentar: _reintentarPreparacion,
              );
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(usuario.uid)
                  .snapshots(),
              builder: (context, perfil) {
                if (perfil.hasError) {
                  return _PantallaError(
                    mensaje: 'No se pudo cargar tu perfil',
                    onReintentar: _reintentarPreparacion,
                  );
                }

                if (!perfil.hasData) return const PantallaCargando();

                final datos = perfil.data!.data() ?? {};
                final correoAuth = usuario.email;
                if (correoAuth != null &&
                    correoAuth.isNotEmpty &&
                    datos['email'] != correoAuth) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(usuario.uid)
                      .set({
                        'email': correoAuth,
                        'correoPendiente': FieldValue.delete(),
                      }, SetOptions(merge: true));
                }

                final esProfesional = datos['role'] == 'professional';

                if (datos['activo'] == false) {
                  return _PantallaDesactivada(uid: usuario.uid);
                }

                if (esProfesional && datos['onboardingCompleto'] != true) {
                  return BienvenidaProfesionalScreen(
                    uid: usuario.uid,
                    nombre: datos['name'] ?? '',
                  );
                }

                return SincronizadorRecordatorios(
                  uid: usuario.uid,
                  esProfesional: esProfesional,
                  child: esProfesional
                      ? const ProfessionalHome()
                      : const MainScreen(),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PantallaDesactivada extends StatelessWidget {
  final String uid;

  const _PantallaDesactivada({required this.uid});

  Future<void> _reactivar() {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'activo': true,
      'desactivadaEn': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_off_outlined,
                size: 60,
                color: TemaApp.grisTexto,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tu cuenta está desactivada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tus datos siguen guardados. Puedes volver cuando quieras.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _reactivar,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reactivar mi cuenta'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: salirDeLaSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantallaError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _PantallaError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: TemaApp.grisTexto,
              ),
              const SizedBox(height: 12),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Revisa tu conexión e inténtalo de nuevo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onReintentar,
                icon: const Icon(Icons.refresh, size: 17),
                label: const Text('Reintentar'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: salirDeLaSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
