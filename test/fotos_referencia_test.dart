import 'package:beauty_connect/presentation/widgets/fotos_referencia.dart';
import 'package:beauty_connect/utils/fotos_referencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _foto = 'https://res.cloudinary.com/demo/image/upload/uñas.jpg';
const _otra = 'https://res.cloudinary.com/demo/image/upload/otras.jpg';

void main() {
  group('limpiarFotosReferencia', () {
    test('deja pasar una url https', () {
      expect(limpiarFotosReferencia(const [_foto]), [_foto]);
    });

    test('descarta lo que no sea texto', () {
      expect(limpiarFotosReferencia(const [42, null, _foto]), [_foto]);
    });

    test('descarta urls que no sean https', () {
      expect(
        limpiarFotosReferencia(const [
          'http://inseguro.com/a.jpg',
          'javascript:alert(1)',
          '  ',
        ]),
        isEmpty,
      );
    });

    test('no repite la misma foto', () {
      expect(limpiarFotosReferencia(const [_foto, _foto]), [_foto]);
    });

    test('nunca devuelve más del máximo', () {
      final muchas = [...List.filled(10, _foto), ...List.filled(10, _otra)];

      expect(
        limpiarFotosReferencia(muchas).length,
        lessThanOrEqualTo(maximoFotosReferencia),
      );
    });
  });

  group('fotosReferenciaDeCita', () {
    test('una cita sin el campo no trae fotos', () {
      expect(fotosReferenciaDeCita(const {}), isEmpty);
      expect(fotosReferenciaDeCita(null), isEmpty);
    });

    test('un campo con basura no rompe nada', () {
      expect(
        fotosReferenciaDeCita(const {claveFotosReferencia: 'no'}),
        isEmpty,
      );
      expect(fotosReferenciaDeCita(const {claveFotosReferencia: 7}), isEmpty);
    });

    test('lee y limpia la lista guardada', () {
      expect(
        fotosReferenciaDeCita(const {
          claveFotosReferencia: [_foto, 'http://malo.com/x.jpg'],
        }),
        [_foto],
      );
    });
  });

  group('SubirReferencia', () {
    Future<void> pintar(
      WidgetTester tester, {
      required List<String> fotos,
      bool subiendo = false,
      VoidCallback? onAgregar,
      VoidCallback? onQuitar,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SubirReferencia(
                fotos: fotos,
                subiendo: subiendo,
                onAgregar: onAgregar ?? () {},
                onQuitar: onQuitar ?? () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('vacía invita a subir y responde al toque', (tester) async {
      var tocada = false;
      await pintar(tester, fotos: const [], onAgregar: () => tocada = true);

      expect(find.text('Sube tu foto de referencia'), findsOneWidget);

      await tester.tap(find.byType(SubirReferencia));
      expect(tocada, isTrue);
    });

    testWidgets('mientras sube no deja tocar de nuevo', (tester) async {
      var tocada = false;
      await pintar(
        tester,
        fotos: const [],
        subiendo: true,
        onAgregar: () => tocada = true,
      );

      expect(find.text('Subiendo tu foto...'), findsOneWidget);

      await tester.tap(find.byType(SubirReferencia));
      expect(tocada, isFalse);
    });

    testWidgets('con foto confirma y ofrece quitarla', (tester) async {
      var quitada = false;
      await pintar(
        tester,
        fotos: const [_foto],
        onQuitar: () => quitada = true,
      );

      expect(find.text('Listo, ya tiene tu referencia'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(quitada, isTrue);
    });

    testWidgets('con foto ya no dispara otra subida al tocar', (tester) async {
      var tocada = false;
      await pintar(
        tester,
        fotos: const [_foto],
        onAgregar: () => tocada = true,
      );

      await tester.tap(find.text('Listo, ya tiene tu referencia'));
      expect(tocada, isFalse);
    });
  });

  group('BloqueReferencia', () {
    Future<void> pintar(WidgetTester tester, Map<String, dynamic> cita) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BloqueReferencia(cita: cita)),
        ),
      );
    }

    testWidgets('sin fotos no ocupa espacio', (tester) async {
      await pintar(tester, const {});

      expect(find.byType(Image), findsNothing);
      expect(tester.getSize(find.byType(BloqueReferencia)), Size.zero);
    });

    testWidgets('con foto muestra el bloque y su título', (tester) async {
      await pintar(tester, const {
        claveFotosReferencia: [_foto],
      });

      expect(find.text('Diseño de referencia'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('una foto inválida no pinta el bloque', (tester) async {
      await pintar(tester, const {
        claveFotosReferencia: ['http://malo.com/x.jpg'],
      });

      expect(find.byType(Image), findsNothing);
    });
  });
}
