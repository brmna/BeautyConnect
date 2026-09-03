import 'package:flutter/material.dart';

class CampoCorreoFijo extends StatefulWidget {
  final String correo;

  const CampoCorreoFijo({super.key, required this.correo});

  @override
  State<CampoCorreoFijo> createState() => _CampoCorreoFijoState();
}

class _CampoCorreoFijoState extends State<CampoCorreoFijo> {
  late final TextEditingController _controlador = TextEditingController(
    text: widget.correo,
  );

  @override
  void didUpdateWidget(CampoCorreoFijo anterior) {
    super.didUpdateWidget(anterior);
    if (widget.correo != anterior.correo) _controlador.text = widget.correo;
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: false,
      controller: _controlador,
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        prefixIcon: Icon(Icons.mail_outline, size: 20),
        helperText: 'El correo no se puede cambiar',
      ),
    );
  }
}
