import 'package:flutter/material.dart';

mixin RecargaManual<T extends StatefulWidget> on State<T> {
  void crearConsultas();

  Future<void> recargar() async {
    setState(crearConsultas);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  Widget conRecarga({required Widget hijo}) =>
      RefreshIndicator(onRefresh: recargar, child: hijo);
}
