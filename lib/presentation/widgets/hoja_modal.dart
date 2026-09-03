import 'package:flutter/material.dart';

const double _altoMaximo = 0.88;

Future<T?> abrirHoja<T>(BuildContext context, {required Widget hijo}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * _altoMaximo,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => hijo,
  );
}
