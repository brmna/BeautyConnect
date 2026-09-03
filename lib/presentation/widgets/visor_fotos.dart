import 'package:flutter/material.dart';

import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';

class VisorFotos extends StatefulWidget {
  final List<String> fotos;
  final int inicial;

  const VisorFotos({super.key, required this.fotos, this.inicial = 0});

  static Future<void> abrir(
    BuildContext context, {
    required List<String> fotos,
    int inicial = 0,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisorFotos(fotos: fotos, inicial: inicial),
      ),
    );
  }

  @override
  State<VisorFotos> createState() => _VisorFotosState();
}

class _VisorFotosState extends State<VisorFotos> {
  late final PageController _paginas = PageController(
    initialPage: widget.inicial,
  );
  late int _actual = widget.inicial;

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: TemaApp.blanco,
        title: widget.fotos.length == 1
            ? null
            : Text(
                '${_actual + 1} de ${widget.fotos.length}',
                style: const TextStyle(fontSize: 15),
              ),
      ),
      body: PageView.builder(
        controller: _paginas,
        itemCount: widget.fotos.length,
        onPageChanged: (indice) => setState(() => _actual = indice),
        itemBuilder: (context, indice) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: Image.network(
              ServicioSubidaImagenes.miniatura(
                widget.fotos[indice],
                ancho: 1200,
                cuadrada: false,
              ),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: TemaApp.grisTexto,
                size: 56,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
