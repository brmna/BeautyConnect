import 'package:beauty_connect/theme/app_theme.dart';
import 'package:beauty_connect/widgets/beauty_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BeautyButton muestra la etiqueta y responde al toque', (
    WidgetTester tester,
  ) async {
    var pulsado = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.temaClaro,
        home: Scaffold(
          body: BeautyButton(
            label: 'Iniciar Sesion',
            onPressed: () => pulsado = true,
          ),
        ),
      ),
    );

    expect(find.text('Iniciar Sesion'), findsOneWidget);

    await tester.tap(find.byType(BeautyButton));
    await tester.pump();

    expect(pulsado, isTrue);
  });

  testWidgets('BeautyButton oculta la etiqueta mientras carga', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaApp.temaClaro,
        home: Scaffold(
          body: BeautyButton(
            label: 'Iniciar Sesion',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.text('Iniciar Sesion'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
