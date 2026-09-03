import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> cerrarSesion(BuildContext context) async {
  final navegador = Navigator.of(context);

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Deseas salir de tu cuenta?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogo, true),
          child: const Text('Salir', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmado != true) return;

  navegador.popUntil((ruta) => ruta.isFirst);
  await salirDeLaSesion();
}

Future<void> salirDeLaSesion() async {
  try {
    await GoogleSignIn.instance.signOut();
  } catch (_) {}
  await FirebaseAuth.instance.signOut();
}
