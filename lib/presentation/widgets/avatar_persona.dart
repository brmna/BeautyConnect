import 'package:flutter/material.dart';

import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';

class AvatarPersona extends StatelessWidget {
  final String nombre;
  final String? foto;
  final double radio;

  final String inicialPorDefecto;

  const AvatarPersona({
    super.key,
    required this.nombre,
    required this.foto,
    this.radio = 20,
    this.inicialPorDefecto = 'C',
  });

  String get _inicial {
    final limpio = nombre.trim();
    return limpio.isEmpty ? inicialPorDefecto : limpio[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = foto?.trim() ?? '';

    return CircleAvatar(
      radius: radio,
      backgroundColor: TemaApp.grisClaro,
      backgroundImage: url.isEmpty
          ? null
          : NetworkImage(
              ServicioSubidaImagenes.miniatura(url, ancho: (radio * 6).round()),
            ),
      child: url.isEmpty
          ? Text(
              _inicial,
              style: TextStyle(
                color: TemaApp.textoOscuro,
                fontWeight: FontWeight.bold,
                fontSize: radio * 0.85,
              ),
            )
          : null,
    );
  }
}

class AvatarCliente extends StatelessWidget {
  final String nombre;
  final String? foto;
  final double radio;

  const AvatarCliente({
    super.key,
    required this.nombre,
    required this.foto,
    this.radio = 20,
  });

  @override
  Widget build(BuildContext context) => AvatarPersona(
    nombre: nombre,
    foto: foto,
    radio: radio,
    inicialPorDefecto: 'C',
  );
}

class AvatarManicurista extends StatelessWidget {
  final String nombre;
  final String? foto;
  final double radio;

  const AvatarManicurista({
    super.key,
    required this.nombre,
    required this.foto,
    this.radio = 20,
  });

  @override
  Widget build(BuildContext context) => AvatarPersona(
    nombre: nombre,
    foto: foto,
    radio: radio,
    inicialPorDefecto: 'M',
  );
}
