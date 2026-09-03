import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/enlaces.dart';
import 'screens/professional_detail_screen.dart';

class EscuchaEnlaces extends StatefulWidget {
  final Widget child;

  const EscuchaEnlaces({super.key, required this.child});

  @override
  State<EscuchaEnlaces> createState() => _EscuchaEnlacesState();
}

class _EscuchaEnlacesState extends State<EscuchaEnlaces> {
  StreamSubscription<Uri>? _suscripcion;
  StreamSubscription<User?>? _sesion;

  String? _pendiente;

  @override
  void initState() {
    super.initState();
    _empezarAEscuchar();
  }

  Future<void> _empezarAEscuchar() async {
    _sesion = FirebaseAuth.instance.authStateChanges().listen((usuario) {
      if (usuario == null) return;

      final guardado = _pendiente;
      if (guardado == null) return;

      _pendiente = null;
      _empujarPerfil(guardado);
    });

    final enlaces = AppLinks();

    try {
      _abrir(await enlaces.getInitialLink());
    } catch (_) {}

    _suscripcion = enlaces.uriLinkStream.listen(_abrir, onError: (_) {});
  }

  void _abrir(Uri? enlace) {
    final id = perfilDesdeEnlace(enlace?.toString());
    if (id == null) return;

    if (FirebaseAuth.instance.currentUser == null) {
      _pendiente = id;
      return;
    }

    _empujarPerfil(id);
  }

  void _empujarPerfil(String id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navegadorGlobal.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ProfessionalDetailScreen(professionalId: id),
        ),
      );
    });
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    _sesion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
