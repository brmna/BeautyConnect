import 'package:flutter/material.dart';

import '../../utils/validaciones.dart';

class CampoTelefono extends StatelessWidget {
  final TextEditingController controlador;

  final bool obligatorio;

  final String etiqueta;
  final bool conIcono;

  const CampoTelefono({
    super.key,
    required this.controlador,
    this.obligatorio = false,
    this.etiqueta = 'Teléfono',
    this.conIcono = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      keyboardType: TextInputType.phone,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: const [FormatoTelefono()],
      validator: (valor) => validarTelefono(valor, obligatorio: obligatorio),
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: '300 000 0000',
        prefixIcon: conIcono
            ? const Icon(Icons.phone_outlined, size: 20)
            : null,
        prefixText: '+57 ',
        helperText: obligatorio
            ? null
            : 'Opcional, pero ayuda a que te ubiquen',
      ),
    );
  }
}
