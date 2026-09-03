import 'package:flutter/material.dart';

mixin HistorialPestanas<T extends StatefulWidget> on State<T> {
  final List<int> _historial = [0];

  int get pestanaActual => _historial.last;

  bool get puedeSalir => _historial.length <= 1;

  void abrirPestana(int indice) {
    if (indice == _historial.last) return;

    setState(() {
      _historial.remove(indice);
      _historial.add(indice);
    });
  }

  void volverAPestanaAnterior() {
    if (puedeSalir) return;
    setState(_historial.removeLast);
  }

  Widget conGestoVolver({required Widget hijo}) {
    return PopScope(
      canPop: puedeSalir,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) volverAPestanaAnterior();
      },
      child: hijo,
    );
  }
}
