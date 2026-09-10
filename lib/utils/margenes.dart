import 'package:flutter/material.dart';

double margenInferior(BuildContext context, {double base = 16}) =>
    base + MediaQuery.paddingOf(context).bottom;

double margenHoja(BuildContext context, {double base = 20}) {
  final vista = View.of(context);
  final escala = vista.devicePixelRatio;
  final teclado = vista.viewInsets.bottom / escala;
  final sistema = vista.viewPadding.bottom / escala;

  return base + (teclado > sistema ? teclado : sistema);
}
