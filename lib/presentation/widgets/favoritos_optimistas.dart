import 'package:flutter/material.dart';

mixin FavoritosOptimistas<T extends StatefulWidget> on State<T> {
  final Map<String, bool> _pendientes = {};

  void sincronizarFavoritos(Set<String> confirmados) {
    _pendientes.removeWhere(
      (id, deseado) => confirmados.contains(id) == deseado,
    );
  }

  bool esFavorito(String id, Set<String> confirmados) =>
      _pendientes[id] ?? confirmados.contains(id);

  Future<void> alternarFavorito({
    required String id,
    required bool guardar,
    required Future<void> Function() accion,
    required void Function(String mensaje) alFallar,
  }) async {
    setState(() => _pendientes[id] = guardar);

    try {
      await accion();
    } catch (_) {
      if (mounted) setState(() => _pendientes.remove(id));
      alFallar('No se pudo guardar el favorito');
    }
  }
}
