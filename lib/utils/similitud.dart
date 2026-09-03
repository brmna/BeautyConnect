import '../data/models/diseno.dart';

int puntajeDeParecido(Diseno diseno, List<String> etiquetas) {
  if (etiquetas.isEmpty) return 0;

  final suyas = diseno.etiquetas
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toSet();

  var puntaje = 0;
  for (var indice = 0; indice < etiquetas.length; indice++) {
    if (suyas.contains(etiquetas[indice].trim().toLowerCase())) {
      puntaje += etiquetas.length - indice;
    }
  }

  return puntaje;
}

List<Diseno> ordenarPorParecido(List<Diseno> disenos, List<String> etiquetas) {
  if (etiquetas.isEmpty) return disenos;

  final conPuntaje = <(Diseno, int)>[];
  for (final diseno in disenos) {
    final puntaje = puntajeDeParecido(diseno, etiquetas);
    if (puntaje > 0) conPuntaje.add((diseno, puntaje));
  }

  conPuntaje.sort((a, b) {
    final porPuntaje = b.$2.compareTo(a.$2);
    if (porPuntaje != 0) return porPuntaje;
    return b.$1.favoritos.compareTo(a.$1.favoritos);
  });

  return conPuntaje.map((par) => par.$1).toList();
}
