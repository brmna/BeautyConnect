import 'package:flutter/material.dart';

import '../../data/models/resena.dart';
import '../../data/services/servicio_resenas.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import 'adjuntar_fotos.dart';
import 'estrellas.dart';
import 'mensaje.dart';
import '../../utils/margenes.dart';
import '../../utils/validaciones.dart';

class HojaCalificar extends StatefulWidget {
  final String profesionalId;
  final String profesionalNombre;
  final String citaId;
  final String clienteId;
  final String clienteNombre;
  final String servicio;

  final String? profesionalFoto;
  final String? clienteFoto;

  final Resena? existente;

  const HojaCalificar({
    super.key,
    required this.profesionalId,
    required this.profesionalNombre,
    required this.citaId,
    required this.clienteId,
    required this.clienteNombre,
    required this.servicio,
    this.profesionalFoto,
    this.clienteFoto,
    this.existente,
  });

  @override
  State<HojaCalificar> createState() => _HojaCalificarState();
}

class _HojaCalificarState extends State<HojaCalificar> {
  final _servicio = ServicioResenas();
  final _subida = ServicioSubidaImagenes();
  final _comentarioCtrl = TextEditingController();

  int _calificacion = 0;
  final List<String> _fotos = [];
  bool _guardando = false;
  bool _subiendoFoto = false;

  bool get _editando => widget.existente != null;

  @override
  void initState() {
    super.initState();

    final previa = widget.existente;
    if (previa == null) return;

    _calificacion = previa.calificacion;
    _comentarioCtrl.text = previa.comentario;
    _fotos.addAll(previa.fotos);
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  String get _textoCalificacion {
    switch (_calificacion) {
      case 1:
        return 'Muy mala';
      case 2:
        return 'Mala';
      case 3:
        return 'Regular';
      case 4:
        return 'Buena';
      case 5:
        return 'Excelente';
      default:
        return 'Toca las estrellas para calificar';
    }
  }

  Future<void> _agregarFoto() async {
    final mensajero = ScaffoldMessenger.of(context);

    if (!_subida.estaConfigurado) {
      mensajero.showSnackBar(
        construirMensaje(
          'La subida de fotos no está disponible',
          tipo: TipoAviso.info,
        ),
      );
      return;
    }

    try {
      final archivo = await _subida.elegirImagen(desdeCamara: false);
      if (archivo == null) return;

      setState(() => _subiendoFoto = true);
      final imagen = await _subida.subir(archivo);
      if (mounted) setState(() => _fotos.add(imagen.url));
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo subir la foto', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _subiendoFoto = false);
  }

  Future<void> _publicar() async {
    if (_calificacion == 0) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      if (_editando) {
        await _servicio.editar(
          profesionalId: widget.profesionalId,
          citaId: widget.citaId,
          calificacion: _calificacion,
          comentario: _comentarioCtrl.text,
          fotos: _fotos,
        );
        navegador.pop(true);
        mensajero.showSnackBar(
          construirMensaje('Reseña actualizada', tipo: TipoAviso.exito),
        );
        return;
      }

      await _servicio.publicar(
        profesionalId: widget.profesionalId,
        profesionalNombre: widget.profesionalNombre,
        profesionalFoto: widget.profesionalFoto,
        citaId: widget.citaId,
        clienteId: widget.clienteId,
        clienteNombre: widget.clienteNombre,
        clienteFoto: widget.clienteFoto,
        servicio: widget.servicio,
        calificacion: _calificacion,
        comentario: _comentarioCtrl.text,
        fotos: _fotos,
      );
      navegador.pop(true);
      mensajero.showSnackBar(
        const SnackBar(
          content: Text('Gracias por tu reseña'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    } on ResenaDuplicada {
      mensajero.showSnackBar(
        construirMensaje('Ya calificaste esta cita', tipo: TipoAviso.aviso),
      );
      navegador.pop(false);
      return;
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo publicar la reseña',
          tipo: TipoAviso.error,
        ),
      );
    }

    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: margenHoja(context, base: 24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Text(
                    '¿Cómo estuvo tu cita?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.servicio} con ${widget.profesionalNombre}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SelectorEstrellas(
              valor: _calificacion,
              onCambio: (valor) => setState(() => _calificacion = valor),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _textoCalificacion,
                style: TextStyle(
                  fontSize: 13,
                  color: _calificacion == 0
                      ? TemaApp.grisTexto
                      : TemaApp.textoOscuro,
                  fontWeight: _calificacion == 0
                      ? FontWeight.normal
                      : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _comentarioCtrl,
              maxLines: 4,
              maxLength: maximoComentarioResena,
              textCapitalization: TextCapitalization.sentences,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validarComentarioResena,
              decoration: const InputDecoration(
                labelText: 'Tu comentario (opcional)',
                hintText: 'Cuéntale a otros clientes cómo te fue',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            AdjuntarFotos(
              fotos: _fotos,
              subiendo: _subiendoFoto,
              onAgregar: _agregarFoto,
              onQuitar: (indice) => setState(() => _fotos.removeAt(indice)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_calificacion == 0 || _guardando)
                    ? null
                    : _publicar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_editando ? 'Guardar cambios' : 'Publicar reseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
