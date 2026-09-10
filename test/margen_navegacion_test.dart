import 'package:beauty_connect/presentation/widgets/confirmacion.dart';
import 'package:beauty_connect/presentation/widgets/hoja_modal.dart';
import 'package:beauty_connect/utils/margenes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _altoBotones = 48;

void main() {
  void simularBotonesDelSistema(WidgetTester tester) {
    final fisicos = _altoBotones * tester.view.devicePixelRatio;
    tester.view.padding = FakeViewPadding(bottom: fisicos);
    tester.view.viewPadding = FakeViewPadding(bottom: fisicos);
    addTearDown(tester.view.reset);
  }

  Future<void> abrir(
    WidgetTester tester,
    VoidCallback Function(BuildContext) accion,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: const SizedBox(height: 60),
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: accion(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('margenHoja suma la franja de los botones del teléfono', (
    tester,
  ) async {
    simularBotonesDelSistema(tester);
    late double margen;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            margen = margenHoja(context, base: 12);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(margen, 12 + _altoBotones);
  });

  testWidgets('abrirHoja no se come la franja inferior del sistema', (
    tester,
  ) async {
    simularBotonesDelSistema(tester);
    late double abajo;

    await abrir(
      tester,
      (context) =>
          () => abrirHoja<void>(
            context,
            hijo: Builder(
              builder: (hoja) {
                abajo = MediaQuery.paddingOf(hoja).bottom;
                return const SizedBox(height: 40);
              },
            ),
          ),
    );

    expect(abajo, _altoBotones);
  });

  testWidgets('los botones de una hoja quedan sobre la barra del sistema', (
    tester,
  ) async {
    simularBotonesDelSistema(tester);

    await abrir(
      tester,
      (context) =>
          () => pedirMotivoCancelacion(
            context,
            titulo: '¿Seguro?',
            mensaje: 'Avisaremos a la manicurista',
            sugeridos: MotivoCancelacion.sugeridosCliente,
          ),
    );

    final alto = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final boton = tester.getRect(find.text('Cancelar la cita'));

    expect(boton.bottom, lessThanOrEqualTo(alto - _altoBotones));
  });

  testWidgets('una hoja abierta desde una pestaña respeta la barra', (
    tester,
  ) async {
    simularBotonesDelSistema(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: const SizedBox(height: 60),
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => abrirHoja<void>(
                  context,
                  hijo: Padding(
                    padding: EdgeInsets.only(
                      bottom: margenHoja(context, base: 12),
                    ),
                    child: const Text('última opción'),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final alto = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final opcion = tester.getRect(find.text('última opción'));

    expect(opcion.bottom, lessThanOrEqualTo(alto - _altoBotones));
  });

  testWidgets('con el teclado abierto la hoja no suma dos veces la franja', (
    tester,
  ) async {
    simularBotonesDelSistema(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    late double margen;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            margen = margenHoja(context, base: 20);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(margen, 20 + 900 / tester.view.devicePixelRatio);
  });
}
