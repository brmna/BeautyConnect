import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_connect/data/models/resena.dart';

Resena resena(int calificacion) => Resena(
  id: 'resena',
  profesionalId: 'p1',
  profesionalNombre: 'Ana',
  profesionalFoto: null,
  clienteId: 'c1',
  clienteNombre: 'Samuel',
  clienteFoto: null,
  servicio: 'Manicure',
  calificacion: calificacion,
  comentario: '',
  fotos: const [],
  respuesta: null,
  fecha: null,
  respondidaEn: null,
);

List<Resena> resenas(List<int> notas) => notas.map(resena).toList();

void main() {
  group('ResumenCalificaciones.desde', () {
    test('sin reseñas queda en cero pero conserva las cinco estrellas', () {
      final resumen = ResumenCalificaciones.desde(const []);

      expect(resumen.total, 0);
      expect(resumen.promedio, 0);
      expect(resumen.conteoPorEstrella.keys.toSet(), {1, 2, 3, 4, 5});
      expect(resumen.conteoPorEstrella.values.every((c) => c == 0), isTrue);
    });

    test('el promedio no se queda en un entero cuando no lo es', () {
      final resumen = ResumenCalificaciones.desde(resenas([5, 4]));

      expect(resumen.total, 2);
      expect(resumen.promedio, 4.5);
    });

    test('cuenta cada estrella y deja en cero las que nadie puso', () {
      final resumen = ResumenCalificaciones.desde(resenas([5, 5, 3]));

      expect(resumen.conteoPorEstrella[5], 2);
      expect(resumen.conteoPorEstrella[3], 1);
      expect(resumen.conteoPorEstrella[4], 0);
      expect(resumen.conteoPorEstrella[2], 0);
      expect(resumen.conteoPorEstrella[1], 0);
    });

    test('si todas tienen la misma nota el promedio es esa nota', () {
      final resumen = ResumenCalificaciones.desde(resenas([4, 4, 4]));

      expect(resumen.promedio, 4);
    });
  });

  group('ResumenCalificaciones.proporcion', () {
    test('sin reseñas devuelve cero y no divide por cero', () {
      final resumen = ResumenCalificaciones.desde(const []);

      for (var estrellas = 1; estrellas <= 5; estrellas++) {
        expect(resumen.proporcion(estrellas), 0);
      }
    });

    test('la mitad de las reseñas da 50', () {
      final resumen = ResumenCalificaciones.desde(resenas([5, 5, 3, 2]));

      expect(resumen.proporcion(5), 50);
    });

    test('con tres notas distintas cada barra da 33 y no suman 100', () {
      final resumen = ResumenCalificaciones.desde(resenas([5, 4, 3]));

      expect(resumen.proporcion(5), 33);
      expect(resumen.proporcion(4), 33);
      expect(resumen.proporcion(3), 33);

      final suma = [
        for (var estrellas = 1; estrellas <= 5; estrellas++)
          resumen.proporcion(estrellas),
      ].fold<int>(0, (total, valor) => total + valor);

      expect(suma, 99);
    });

    test('una estrella que nadie puso da cero', () {
      final resumen = ResumenCalificaciones.desde(resenas([5, 5]));

      expect(resumen.proporcion(1), 0);
    });

    test('una estrella fuera de rango da cero en vez de reventar', () {
      final resumen = ResumenCalificaciones.desde(resenas([5, 4]));

      expect(resumen.proporcion(0), 0);
      expect(resumen.proporcion(9), 0);
      expect(resumen.proporcion(-1), 0);
    });

    test('si todas coinciden esa estrella se lleva el 100', () {
      final resumen = ResumenCalificaciones.desde(resenas([2, 2, 2]));

      expect(resumen.proporcion(2), 100);
    });

    test('cada barra cabe entre 0 y 100', () {
      final resumen = ResumenCalificaciones.desde(resenas([5, 5, 4, 1]));

      for (var estrellas = 1; estrellas <= 5; estrellas++) {
        expect(resumen.proporcion(estrellas), inInclusiveRange(0, 100));
      }
    });
  });
}
