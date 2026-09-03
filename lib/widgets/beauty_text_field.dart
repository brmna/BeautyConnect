import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class BeautyTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const BeautyTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
  });

  @override
  State<BeautyTextField> createState() => _BeautyTextFieldState();
}

class _BeautyTextFieldState extends State<BeautyTextField> {
  final _foco = FocusNode();
  bool _obscure = true;
  bool _enfocado = false;
  bool _conError = false;

  @override
  void initState() {
    super.initState();
    _foco.addListener(() => setState(() => _enfocado = _foco.hasFocus));
  }

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  Color get _acento {
    if (_conError) return TemaApp.error;
    return _enfocado ? TemaApp.rosa : TemaApp.grisTexto;
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final fontSize = r.isMobile ? 14.0 : 15.0;
    final labelSize = r.isMobile ? 13.0 : 14.0;
    final iconSize = r.isMobile ? 19.0 : 21.0;
    final verticalPad = r.isMobile ? 16.0 : 18.0;

    const suave = Duration(milliseconds: 180);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: suave,
          style: TextStyle(
            fontFamily: 'Gelasio',
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
            color: _conError
                ? TemaApp.error
                : (_enfocado ? TemaApp.rosa : TemaApp.textoOscuro),
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 7),
        AnimatedContainer(
          duration: suave,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _enfocado && !_conError
                ? [
                    BoxShadow(
                      color: TemaApp.rosa.withValues(alpha: 0.16),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : const [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _foco,
            obscureText: widget.isPassword && _obscure,
            keyboardType: widget.keyboardType,
            cursorColor: TemaApp.rosa,
            style: TextStyle(fontSize: fontSize, color: TemaApp.textoOscuro),
            validator: (valor) {
              final error = widget.validator?.call(valor);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _conError != (error != null)) {
                  setState(() => _conError = error != null);
                }
              });
              return error;
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                color: TemaApp.grisTexto,
                fontSize: fontSize,
              ),
              prefixIcon: AnimatedSwitcher(
                duration: suave,
                child: Icon(
                  widget.prefixIcon,
                  key: ValueKey(_acento.toARGB32()),
                  color: _acento,
                  size: iconSize,
                ),
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      splashRadius: 20,
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _acento,
                        size: iconSize,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              filled: true,
              fillColor: _enfocado ? TemaApp.blanco : TemaApp.grisClaro,
              contentPadding: EdgeInsets.symmetric(
                vertical: verticalPad,
                horizontal: 14,
              ),
              border: _borde(TemaApp.grisClaro),
              enabledBorder: _borde(TemaApp.grisClaro),
              focusedBorder: _borde(TemaApp.rosa, grosor: 1.6),
              errorBorder: _borde(TemaApp.error),
              focusedErrorBorder: _borde(TemaApp.error, grosor: 1.6),
              errorStyle: const TextStyle(fontSize: 11.5),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _borde(Color color, {double grosor = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: grosor),
      );
}
