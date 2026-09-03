import 'package:flutter/material.dart';

import '../../data/models/diseno.dart';
import '../../utils/validaciones.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import 'mensaje.dart';

class DatosDiseno {
  final String titulo;
  final List<String> etiquetas;

  const DatosDiseno({required this.titulo, required this.etiquetas});
}

class HojaDatosDiseno extends StatefulWidget {
  final String? tituloInicial;
  final List<String> etiquetasIniciales;
  final String textoBoton;

  const HojaDatosDiseno({
    super.key,
    this.tituloInicial,
    this.etiquetasIniciales = const [],
    this.textoBoton = 'Publicar',
  });

  @override
  State<HojaDatosDiseno> createState() => _HojaDatosDisenoState();
}

class _HojaDatosDisenoState extends State<HojaDatosDiseno> {
  late final TextEditingController _tituloCtrl;
  late final Set<String> _seleccionadas;
  final _otraCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.tituloInicial ?? '');
    _seleccionadas = {...widget.etiquetasIniciales};
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _otraCtrl.dispose();
    super.dispose();
  }

  void _agregarPersonalizada() {
    final texto = _otraCtrl.text.trim();
    if (texto.isEmpty) return;

    if (_seleccionadas.length >= maximoEtiquetasDiseno) {
      ScaffoldMessenger.of(context).showSnackBar(
        construirMensaje(
          'Máximo $maximoEtiquetasDiseno etiquetas por diseño',
          tipo: TipoAviso.aviso,
        ),
      );
      return;
    }

    setState(() {
      _seleccionadas.add(texto);
      _otraCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final personalizadas = _seleccionadas
        .where((e) => !CatalogoEtiquetas.sugeridas.contains(e))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: margenHoja(context),
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuéntanos del diseño',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Las etiquetas hacen que tu trabajo aparezca en la galeria de inspiracion.',
              style: TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLength: maximoTituloDiseno,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validarTituloDiseno,
              decoration: const InputDecoration(
                labelText: 'Título (opcional)',
                hintText: 'Francesa con glitter dorado',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Etiquetas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final etiqueta in CatalogoEtiquetas.sugeridas)
                  FilterChip(
                    label: Text(etiqueta),
                    selected: _seleccionadas.contains(etiqueta),
                    onSelected: (activa) => setState(() {
                      activa
                          ? _seleccionadas.add(etiqueta)
                          : _seleccionadas.remove(etiqueta);
                    }),
                  ),
                for (final etiqueta in personalizadas)
                  InputChip(
                    label: Text(etiqueta),
                    selected: true,
                    onDeleted: () =>
                        setState(() => _seleccionadas.remove(etiqueta)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _otraCtrl,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Otra etiqueta',
                      counterText: '',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _agregarPersonalizada(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _agregarPersonalizada,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(
                  context,
                  DatosDiseno(
                    titulo: _tituloCtrl.text.trim(),
                    etiquetas: _seleccionadas.toList(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                ),
                child: Text(widget.textoBoton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
