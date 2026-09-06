import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import 'hoja_modal.dart';

Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String siga = 'Continuar',
  String vuelva = 'Volver',
  bool destructiva = false,
}) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje, style: const TextStyle(height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo, false),
          child: Text(vuelva),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogo, true),
          style: FilledButton.styleFrom(
            backgroundColor: destructiva ? TemaApp.error : TemaApp.negro,
            foregroundColor: TemaApp.blanco,
          ),
          child: Text(siga),
        ),
      ],
    ),
  );

  return respuesta ?? false;
}

class MotivoCancelacion {
  final String texto;

  const MotivoCancelacion(this.texto);

  static const List<String> sugeridosProfesional = [
    'Me surgió un imprevisto',
    'Ya no tengo ese horario libre',
    'No alcanzo a llegar hasta allá',
    'Problemas de salud',
  ];

  static const List<String> sugeridosCliente = [
    'Me surgió un imprevisto',
    'Ya no puedo a esa hora',
    'Encontré otra opción',
    'Cambié de opinión',
  ];
}

Future<MotivoCancelacion?> pedirMotivoCancelacion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required List<String> sugeridos,
}) {
  return abrirHoja<MotivoCancelacion>(
    context,
    hijo: _HojaMotivo(titulo: titulo, mensaje: mensaje, sugeridos: sugeridos),
  );
}

class _HojaMotivo extends StatefulWidget {
  final String titulo;
  final String mensaje;
  final List<String> sugeridos;

  const _HojaMotivo({
    required this.titulo,
    required this.mensaje,
    required this.sugeridos,
  });

  @override
  State<_HojaMotivo> createState() => _HojaMotivoState();
}

class _HojaMotivoState extends State<_HojaMotivo> {
  final _otro = TextEditingController();

  String? _elegido;

  @override
  void dispose() {
    _otro.dispose();
    super.dispose();
  }

  String get _motivo => _elegido == null ? _otro.text.trim() : _elegido!.trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: margenHoja(context, base: 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.mensaje,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: TemaApp.grisSubtitulo,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Por qué la cancelas?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.sugeridos.map((sugerido) {
              final activo = _elegido == sugerido;

              return ChoiceChip(
                selected: activo,
                showCheckmark: false,
                label: Text(sugerido),
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: activo ? TemaApp.blanco : TemaApp.textoOscuro,
                ),
                selectedColor: TemaApp.negro,
                backgroundColor: TemaApp.blanco,
                side: const BorderSide(color: TemaApp.grisBorde),
                onSelected: (marcado) => setState(() {
                  _elegido = marcado ? sugerido : null;
                  if (marcado) _otro.clear();
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _otro,
            maxLength: 140,
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() => _elegido = null),
            decoration: const InputDecoration(
              hintText: 'O escribe otro motivo',
              hintStyle: TextStyle(fontSize: 13),
              counterText: '',
              isDense: true,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _motivo.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                            MotivoCancelacion(_motivo),
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: TemaApp.error,
                      foregroundColor: TemaApp.blanco,
                    ),
                    child: const Text('Cancelar la cita'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
