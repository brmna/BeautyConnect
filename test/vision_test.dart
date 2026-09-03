import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_connect/data/models/diseno.dart';
import 'package:beauty_connect/data/services/servicio_vision.dart';
import 'package:beauty_connect/utils/similitud.dart';

String respuestaGemini(String textoDelModelo) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': textoDelModelo},
        ],
      },
    },
  ],
});

Diseno diseno(String id, List<String> etiquetas, {int favoritos = 0}) => Diseno(
  id: id,
  profesionalId: 'p1',
  profesionalNombre: 'Ana',
  imagenUrl: 'https://ejemplo/$id.jpg',
  titulo: null,
  etiquetas: etiquetas,
  favoritos: favoritos,
);

void main() {
  group('ServicioVision.interpretar', () {
    test('lee las etiquetas de una respuesta normal', () {
      final lectura = ServicioVision.interpretar(
        respuestaGemini(
          jsonEncode({
            'sonUnas': true,
            'etiquetas': ['Francesa', 'Nude'],
          }),
        ),
      );

      expect(lectura.sonUnas, isTrue);
      expect(lectura.etiquetas, ['Francesa', 'Nude']);
    });

    test('descarta etiquetas que no están en el catálogo', () {
      final lectura = ServicioVision.interpretar(
        respuestaGemini(
          jsonEncode({
            'sonUnas': true,
            'etiquetas': ['Francesa', 'Veraniego', 'Elegante', 'Gel'],
          }),
        ),
      );

      expect(lectura.etiquetas, ['Francesa', 'Gel']);
      for (final etiqueta in lectura.etiquetas) {
        expect(CatalogoEtiquetas.sugeridas, contains(etiqueta));
      }
    });

    test('quita repetidas y respeta el tope', () {
      final lectura = ServicioVision.interpretar(
        respuestaGemini(
          jsonEncode({
            'sonUnas': true,
            'etiquetas': [
              'Gel',
              'Gel',
              'Nude',
              'Ombre',
              'Cristales',
              'Pedicura',
            ],
          }),
        ),
      );

      expect(lectura.etiquetas.length, ServicioVision.maximoEtiquetas);
      expect(lectura.etiquetas.toSet().length, lectura.etiquetas.length);
    });

    test('una foto que no son uñas no trae etiquetas', () {
      final lectura = ServicioVision.interpretar(
        respuestaGemini(jsonEncode({'sonUnas': false, 'etiquetas': []})),
      );

      expect(lectura.sonUnas, isFalse);
      expect(lectura.etiquetas, isEmpty);
    });

    test('avisa cuando la respuesta viene rota', () {
      expect(
        () => ServicioVision.interpretar('esto no es json'),
        throwsA(isA<ErrorDeVision>()),
      );

      expect(
        () => ServicioVision.interpretar(jsonEncode({'candidates': []})),
        throwsA(isA<ErrorDeVision>()),
      );

      expect(
        () => ServicioVision.interpretar(respuestaGemini('{roto')),
        throwsA(isA<ErrorDeVision>()),
      );
    });
  });

  group('ordenarPorParecido', () {
    test('deja fuera los que no comparten ninguna etiqueta', () {
      final resultado = ordenarPorParecido(
        [
          diseno('a', ['Francesa']),
          diseno('b', ['Pedicura']),
        ],
        ['Francesa'],
      );

      expect(resultado.map((d) => d.id), ['a']);
    });

    test('la primera etiqueta pesa más que las siguientes', () {
      final resultado = ordenarPorParecido(
        [
          diseno('soloSegunda', ['Nude']),
          diseno('soloPrimera', ['Francesa']),
        ],
        ['Francesa', 'Nude'],
      );

      expect(resultado.map((d) => d.id), ['soloPrimera', 'soloSegunda']);
    });

    test('el que coincide en más etiquetas va primero', () {
      final resultado = ordenarPorParecido(
        [
          diseno('una', ['Francesa']),
          diseno('dos', ['Francesa', 'Nude']),
        ],
        ['Francesa', 'Nude'],
      );

      expect(resultado.first.id, 'dos');
    });

    test('a igual parecido gana el más guardado', () {
      final resultado = ordenarPorParecido(
        [
          diseno('poco', ['Gel'], favoritos: 2),
          diseno('mucho', ['Gel'], favoritos: 40),
        ],
        ['Gel'],
      );

      expect(resultado.map((d) => d.id), ['mucho', 'poco']);
    });

    test('ignora mayúsculas y espacios al comparar', () {
      final resultado = ordenarPorParecido(
        [
          diseno('a', ['  gel  ']),
        ],
        ['Gel'],
      );

      expect(resultado, hasLength(1));
    });

    test('sin etiquetas devuelve la lista tal cual', () {
      final todos = [
        diseno('a', ['Gel']),
        diseno('b', ['Nude']),
      ];

      expect(ordenarPorParecido(todos, const []), same(todos));
    });
  });
}
