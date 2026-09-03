import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BarraOcultable extends StatelessWidget {
  final bool visible;
  final Widget child;

  const BarraOcultable({super.key, required this.visible, required this.child});

  @override
  Widget build(BuildContext context) {
    const duracion = Duration(milliseconds: 220);

    return ClipRect(
      child: AnimatedAlign(
        duration: duracion,
        curve: Curves.easeOut,
        alignment: Alignment.bottomCenter,
        heightFactor: visible ? 1 : 0,
        child: AnimatedOpacity(
          duration: duracion,
          opacity: visible ? 1 : 0,
          child: child,
        ),
      ),
    );
  }
}

mixin CabeceraSegunScroll<T extends StatefulWidget> on State<T> {
  bool _cabeceraVisible = true;

  bool get cabeceraVisible => _cabeceraVisible;

  bool get anclarCabecera => false;

  void mostrarCabecera() {
    if (!_cabeceraVisible) setState(() => _cabeceraVisible = true);
  }

  bool alDesplazar(ScrollNotification aviso) {
    if (aviso.metrics.axis != Axis.vertical) return false;

    if (aviso.metrics.pixels <= 0 || anclarCabecera) {
      mostrarCabecera();
      return false;
    }

    if (aviso is! UserScrollNotification) return false;

    if (aviso.direction == ScrollDirection.reverse && _cabeceraVisible) {
      setState(() => _cabeceraVisible = false);
    } else if (aviso.direction == ScrollDirection.forward) {
      mostrarCabecera();
    }

    return false;
  }
}
