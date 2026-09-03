import 'package:flutter/material.dart';

double margenInferior(BuildContext context, {double base = 16}) =>
    base + MediaQuery.paddingOf(context).bottom;

double margenHoja(BuildContext context, {double base = 20}) {
  final medidas = MediaQuery.of(context);
  return base + medidas.viewInsets.bottom + medidas.padding.bottom;
}
