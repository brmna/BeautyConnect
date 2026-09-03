import 'dart:async';

import 'package:app_links/app_links.dart';
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

  @override
  void initState() {
    super.initState();
    _empezarAEscuchar();
  }

  Future<void> _empezarAEscuchar() async {
    final enlaces = AppLinks();

    try {
      _abrir(await enlaces.getInitialLink());
    } catch (_) {}

    _suscripcion = enlaces.uriLinkStream.listen(_abrir, onError: (_) {});
  }

  void _abrir(Uri? enlace) {
    final id = perfilDesdeEnlace(enlace?.toString());
    if (id == null) return;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
