import 'package:beauty_connect/presentation/widgets/tarjeta_servicio.dart';
import 'package:beauty_connect/utils/formato.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _largo = {
  'name': 'Manicure semipermanente con decoración francesa y pedrería',
  'description':
      'Incluye limado, retiro de cutícula, esmaltado semipermanente de '
      'larga duración y diseño personalizado a mano alzada',
  'duration': 150,
  'price': 125000,
};

void main() {
  Future<void> pintar(WidgetTester tester, Widget hijo) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ListView(children: [hijo])),
      ),
    );
  }

  testWidgets('la tarjeta con textos largos no se desborda', (tester) async {
    await pintar(
      tester,
      TarjetaServicio(
        servicio: _largo,
        accion: FilledButton(onPressed: () {}, child: const Text('Reservar')),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('la tarjeta recorta el nombre a dos líneas', (tester) async {
    await pintar(tester, const TarjetaServicio(servicio: _largo));

    final nombre = tester.widget<Text>(find.text(_largo['name'] as String));

    expect(nombre.maxLines, 2);
    expect(nombre.overflow, TextOverflow.ellipsis);
  });

  testWidgets('la tarjeta muestra precio y duración', (tester) async {
    await pintar(tester, const TarjetaServicio(servicio: _largo));

    expect(find.text(formatearPrecio(125000)), findsOneWidget);
    expect(find.text('2 h 30 min aprox.'), findsOneWidget);
  });

  testWidgets('sin descripción la tarjeta no deja un hueco', (tester) async {
    await pintar(
      tester,
      TarjetaServicio(
        servicio: const {'name': 'Uñas', 'duration': 100, 'price': 40000},
        accion: BotonReservar(onReservar: () {}),
      ),
    );

    final sinTexto = tester.getSize(find.byType(TarjetaServicio)).height;

    await pintar(
      tester,
      TarjetaServicio(
        servicio: _largo,
        accion: BotonReservar(onReservar: () {}),
      ),
    );

    final conTexto = tester.getSize(find.byType(TarjetaServicio)).height;

    expect(sinTexto, lessThan(conTexto));
    expect(sinTexto, lessThan(150));
  });

  testWidgets('la fila compacta con nombre largo no se desborda', (
    tester,
  ) async {
    await pintar(
      tester,
      FilaServicio(
        servicio: _largo,
        accion: TextButton(onPressed: () {}, child: const Text('Reservar')),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('un servicio sin nombre no deja la tarjeta vacía', (
    tester,
  ) async {
    await pintar(tester, const TarjetaServicio(servicio: {'price': 20000}));

    expect(find.text('Servicio'), findsOneWidget);
  });
}
