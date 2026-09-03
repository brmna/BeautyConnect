import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../screens/texto_legal_screen.dart';

class NotaLegal extends StatefulWidget {
  const NotaLegal({super.key});

  @override
  State<NotaLegal> createState() => _NotaLegalState();
}

class _NotaLegalState extends State<NotaLegal> {
  final _terminos = TapGestureRecognizer();
  final _privacidad = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _terminos.onTap = () => _abrir(TipoTextoLegal.terminos);
    _privacidad.onTap = () => _abrir(TipoTextoLegal.privacidad);
  }

  @override
  void dispose() {
    _terminos.dispose();
    _privacidad.dispose();
    super.dispose();
  }

  void _abrir(TipoTextoLegal tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TextoLegalScreen(tipo: tipo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 11.5,
      height: 1.4,
      color: TemaApp.grisTexto,
    );
    final enlace = base.copyWith(
      color: TemaApp.info,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: TemaApp.info,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Al crear tu cuenta aceptas los '),
          TextSpan(
            text: 'Términos de servicio',
            style: enlace,
            recognizer: _terminos,
          ),
          const TextSpan(text: ' y la '),
          TextSpan(
            text: 'Política de privacidad',
            style: enlace,
            recognizer: _privacidad,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
