import 'package:beauty_connect/presentation/widgets/etiqueta_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Size> medir(WidgetTester tester, {required bool activo}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: EtiquetaChip(texto: 'En local', activo: activo),
          ),
        ),
      ),
    );

    return tester.getSize(find.byType(EtiquetaChip));
  }

  testWidgets('EtiquetaChip mide igual seleccionada que sin seleccionar', (
    tester,
  ) async {
    final apagada = await medir(tester, activo: false);
    final encendida = await medir(tester, activo: true);

    expect(encendida, apagada);
  });

  testWidgets('EtiquetaChip resalta el texto cuando está activa', (
    tester,
  ) async {
    await medir(tester, activo: true);

    final visible = tester.widgetList<Text>(find.text('En local')).last;

    expect(visible.style?.fontWeight, FontWeight.w600);
  });
}
