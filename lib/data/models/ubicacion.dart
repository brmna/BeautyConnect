class Ubicacion {
  final String direccion;
  final String barrio;
  final double? latitud;
  final double? longitud;

  const Ubicacion({
    this.direccion = '',
    this.barrio = '',
    this.latitud,
    this.longitud,
  });

  bool get tienePunto => latitud != null && longitud != null;

  static const double ladoZona = 0.005;

  static double aZona(double grado) =>
      (grado / ladoZona).roundToDouble() * ladoZona;

  double? get latitudZona => latitud == null ? null : aZona(latitud!);

  double? get longitudZona => longitud == null ? null : aZona(longitud!);

  bool get estaDefinida =>
      tienePunto || direccion.trim().isNotEmpty || barrio.trim().isNotEmpty;

  String get resumen {
    if (direccion.trim().isNotEmpty) return direccion.trim();
    return barrio.trim();
  }

  factory Ubicacion.desdeMapa(Map<String, dynamic>? datos) {
    if (datos == null) return const Ubicacion();

    return Ubicacion(
      direccion: datos['direccion'] ?? '',
      barrio: datos['location'] ?? '',
      latitud: (datos['latitud'] as num?)?.toDouble(),
      longitud: (datos['longitud'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> aMapa() => {
    'direccion': direccion.trim(),
    'location': barrio.trim(),
    'latitud': latitud,
    'longitud': longitud,
    'latitudZona': latitudZona,
    'longitudZona': longitudZona,
  };

  Ubicacion copiarCon({
    String? direccion,
    String? barrio,
    double? latitud,
    double? longitud,
    bool limpiarPunto = false,
  }) {
    return Ubicacion(
      direccion: direccion ?? this.direccion,
      barrio: barrio ?? this.barrio,
      latitud: limpiarPunto ? null : (latitud ?? this.latitud),
      longitud: limpiarPunto ? null : (longitud ?? this.longitud),
    );
  }
}

class Villavicencio {
  static const double latitud = 4.1420;
  static const double longitud = -73.6266;

  static const List<String> barrios = [
    'Barzal Alto',
    'Barzal Bajo',
    'Brisas del Guatiquia',
    'Camoa',
    'Catumare',
    'Centro',
    'Ciudad Porfia',
    'Cooperativo',
    'Danubio',
    'Doce de Octubre',
    'El Buque',
    'El Emporio',
    'El Estero',
    'El Trapiche',
    'Esperanza',
    'Galan',
    'Hacaritama',
    'Industrial',
    'Kirpas',
    'La Alborada',
    'La Ceiba',
    'La Grama',
    'La Rosita',
    'La Vainilla',
    'Las Colinas',
    'Los Centauros',
    'Macunaima',
    'Montecarlo',
    'Morichal',
    'Nueva Andalucia',
    'Playa Rica',
    'Popular',
    'Porvenir',
    'Rondinela',
    'Rosablanca',
    'San Antonio',
    'San Isidro',
    'Santa Helena',
    'Siete de Agosto',
    'Villa Bolivar',
    'Villa Codem',
    'Villa Julia',
    'Villa Suarez',
  ];

  static List<String> sugerencias(String texto) {
    final consulta = texto.trim().toLowerCase();
    if (consulta.isEmpty) return const [];
    return barrios
        .where((barrio) => barrio.toLowerCase().contains(consulta))
        .take(6)
        .toList();
  }
}
