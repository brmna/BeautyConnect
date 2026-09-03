enum Genero { femenino, masculino, sinDecir }

const _claves = {
  Genero.femenino: 'femenino',
  Genero.masculino: 'masculino',
  Genero.sinDecir: 'sinDecir',
};

String claveGenero(Genero genero) => _claves[genero]!;

Genero generoDesde(Object? valor) {
  for (final entrada in _claves.entries) {
    if (entrada.value == valor) return entrada.key;
  }
  return Genero.sinDecir;
}

Genero generoDePerfil(Map<String, dynamic>? datos) =>
    generoDesde(datos?['genero']);

String etiquetaGenero(Genero genero) => switch (genero) {
  Genero.femenino => 'Mujer',
  Genero.masculino => 'Hombre',
  Genero.sinDecir => 'Prefiero no decirlo',
};

String conArticuloIndefinido(Genero genero, String sustantivo) =>
    switch (genero) {
      Genero.femenino => 'Una $sustantivo',
      Genero.masculino => 'Un $sustantivo',
      Genero.sinDecir => sustantivo[0].toUpperCase() + sustantivo.substring(1),
    };

String saludoBienvenida(Genero genero, {String? nombre}) {
  final sufijo = nombre == null || nombre.isEmpty ? '' : ', $nombre';

  return switch (genero) {
    Genero.femenino => 'Bienvenida$sufijo',
    Genero.masculino => 'Bienvenido$sufijo',
    Genero.sinDecir => 'Te damos la bienvenida$sufijo',
  };
}

String concordar(Genero genero, String raiz) => switch (genero) {
  Genero.femenino => '${raiz}a',
  _ => '${raiz}o',
};
