import 'package:flutter/material.dart';

import '../../data/services/servicio_resenas_clientes.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import '../../utils/validaciones.dart';
import 'estrellas.dart';
import 'mensaje.dart';

class HojaCalificarCliente extends StatefulWidget {
  final String citaId;
  final String clienteId;
  final String clienteNombre;
  final String profesionalId;
  final String profesionalNombre;
  final String servicio;

  const HojaCalificarCliente({
    super.key,
    required this.citaId,
    required this.clienteId,
    required this.clienteNombre,
    required this.profesionalId,
    required this.profesionalNombre,
    required this.servicio,
  });

  @override
  State<HojaCalificarCliente> createState() => _HojaCalificarClienteState();
}

class _HojaCalificarClienteState extends State<HojaCalificarCliente> {
  final _servicio = ServicioResenasClientes();
  final _comentarioCtrl = TextEditingController();

  int _calificacion = 0;
  bool _guardando = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  String get _textoCalificacion => switch (_calificacion) {
    1 => 'Muy difícil de atender',
    2 => 'Con inconvenientes',
    3 => 'Normal',
    4 => 'Buen cliente',
    5 => 'Excelente cliente',
    _ => 'Toca las estrellas para calificar',
  };

  Future<void> _publicar() async {
    if (_calificacion == 0) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      await _servicio.publicar(
        clienteId: widget.clienteId,
        profesionalId: widget.profesionalId,
        profesionalNombre: widget.profesionalNombre,
        citaId: widget.citaId,
        servicio: widget.servicio,
        calificacion: _calificacion,
        comentario: _comentarioCtrl.text,
      );

      navegador.pop(true);
      mensajero.showSnackBar(
        construirMensaje('Calificación guardada', tipo: TipoAviso.exito),
      );
      return;
    } on ResenaClienteDuplicada {
      mensajero.showSnackBar(
        construirMensaje('Ya calificaste esta cita', tipo: TipoAviso.aviso),
      );
      navegador.pop(false);
      return;
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo guardar la calificación',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Califica a ${widget.clienteNombre}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.servicio}. Tu comentario solo lo ven otras manicuristas; '
            'el cliente únicamente verá su promedio.',
            style: const TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
          ),
          const SizedBox(height: 20),
          Center(
            child: SelectorEstrellas(
              valor: _calificacion,
              onCambio: (valor) => setState(() => _calificacion = valor),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _textoCalificacion,
              style: const TextStyle(
                fontSize: 13,
                color: TemaApp.grisSubtitulo,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _comentarioCtrl,
            maxLines: 3,
            maxLength: maximoComentarioResena,
            textCapitalization: TextCapitalization.sentences,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validarComentarioResena,
            decoration: const InputDecoration(
              labelText: 'Comentario (opcional)',
              hintText: '¿Llegó a tiempo? ¿Cómo fue el trato?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_calificacion == 0 || _guardando) ? null : _publicar,
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.negro,
                foregroundColor: TemaApp.blanco,
              ),
              child: _guardando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar calificación'),
            ),
          ),
        ],
      ),
    );
  }
}
