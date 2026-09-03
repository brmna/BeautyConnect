import 'package:flutter/material.dart';

import '../../data/models/resena.dart';
import 'hoja_modal.dart';
import '../../data/services/servicio_resenas.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import '../../utils/validaciones.dart';
import 'estrellas.dart';
import 'mensaje.dart';

class HojaResponderResena extends StatefulWidget {
  final String profesionalId;
  final Resena resena;

  const HojaResponderResena({
    super.key,
    required this.profesionalId,
    required this.resena,
  });

  static Future<void> abrir(
    BuildContext context, {
    required String profesionalId,
    required Resena resena,
  }) {
    return abrirHoja(
      context,
      hijo: HojaResponderResena(profesionalId: profesionalId, resena: resena),
    );
  }

  @override
  State<HojaResponderResena> createState() => _HojaResponderResenaState();
}

class _HojaResponderResenaState extends State<HojaResponderResena> {
  final _servicio = ServicioResenas();
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _texto = TextEditingController(
    text: widget.resena.respuesta ?? '',
  );

  bool _guardando = false;

  bool get _yaHabiaRespuesta => widget.resena.tieneRespuesta;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _guardar({bool borrar = false}) async {
    if (!borrar && !_formulario.currentState!.validate()) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      await _servicio.responder(
        profesionalId: widget.profesionalId,
        resenaId: widget.resena.id,
        respuesta: borrar ? '' : _texto.text,
      );

      navegador.pop();
      mensajero.showSnackBar(
        construirMensaje(
          borrar ? 'Respuesta eliminada' : 'Respuesta publicada',
          tipo: TipoAviso.exito,
        ),
      );
      return;
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo guardar la respuesta',
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
      child: Form(
        key: _formulario,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _yaHabiaRespuesta ? 'Editar tu respuesta' : 'Responder reseña',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lo que escribas lo verá cualquiera que visite tu perfil.',
                style: TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
              ),
              const SizedBox(height: 16),
              _resenaOriginal(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _texto,
                maxLines: 4,
                maxLength: maximoRespuestaResena,
                textCapitalization: TextCapitalization.sentences,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validarRespuestaResena,
                decoration: const InputDecoration(
                  labelText: 'Tu respuesta',
                  hintText: 'Agradece, aclara o explica lo que pasó',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaApp.negro,
                    foregroundColor: TemaApp.blanco,
                  ),
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _yaHabiaRespuesta
                              ? 'Guardar cambios'
                              : 'Publicar respuesta',
                        ),
                ),
              ),
              if (_yaHabiaRespuesta)
                Center(
                  child: TextButton.icon(
                    onPressed: _guardando ? null : () => _guardar(borrar: true),
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 17,
                      color: TemaApp.error,
                    ),
                    label: const Text(
                      'Quitar mi respuesta',
                      style: TextStyle(color: TemaApp.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resenaOriginal() {
    final resena = widget.resena;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaApp.grisClaro,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  resena.clienteNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Estrellas(
                calificacion: resena.calificacion.toDouble(),
                tamano: 13,
              ),
            ],
          ),
          if (resena.comentario.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              resena.comentario,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: TemaApp.grisSubtitulo,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
