class RangoHorario {
  final String inicio;
  final String fin;

  const RangoHorario({required this.inicio, required this.fin});

  factory RangoHorario.desdeMapa(Map<String, dynamic> datos) => RangoHorario(
    inicio: datos['inicio'] ?? '09:00',
    fin: datos['fin'] ?? '18:00',
  );

  Map<String, dynamic> aMapa() => {'inicio': inicio, 'fin': fin};
}

class HorarioBase {
  final Map<int, RangoHorario> dias;
  final int intervaloMinutos;

  const HorarioBase({required this.dias, required this.intervaloMinutos});

  bool get estaConfigurado => dias.isNotEmpty;

  static const List<String> nombresDias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  factory HorarioBase.vacio() =>
      const HorarioBase(dias: {}, intervaloMinutos: 30);

  factory HorarioBase.porDefecto() => HorarioBase(
    intervaloMinutos: 30,
    dias: {
      for (var dia = 1; dia <= 5; dia++)
        dia: const RangoHorario(inicio: '09:00', fin: '18:00'),
      6: const RangoHorario(inicio: '09:00', fin: '14:00'),
    },
  );

  factory HorarioBase.desdeMapa(Map<String, dynamic>? datos) {
    if (datos == null) return HorarioBase.vacio();

    final crudos = Map<String, dynamic>.from(datos['dias'] ?? {});
    final dias = <int, RangoHorario>{};

    crudos.forEach((clave, valor) {
      final dia = int.tryParse(clave);
      if (dia == null || valor == null) return;
      dias[dia] = RangoHorario.desdeMapa(Map<String, dynamic>.from(valor));
    });

    final intervalo =
        (datos['intervaloMinutos'] as num?)?.toInt() ??
        (datos['duracionMinutos'] as num?)?.toInt() ??
        30;

    return HorarioBase(dias: dias, intervaloMinutos: intervalo);
  }

  Map<String, dynamic> aMapa() => {
    'intervaloMinutos': intervaloMinutos,
    'dias': dias.map((dia, rango) => MapEntry('$dia', rango.aMapa())),
  };

  HorarioBase copiarCon({
    Map<int, RangoHorario>? dias,
    int? intervaloMinutos,
  }) => HorarioBase(
    dias: dias ?? this.dias,
    intervaloMinutos: intervaloMinutos ?? this.intervaloMinutos,
  );
}

enum EstadoFranja { libre, reservada, bloqueada }

class FranjaHoraria {
  final String hora;
  final EstadoFranja estado;
  final String? citaId;

  final bool esExtra;

  const FranjaHoraria({
    required this.hora,
    required this.estado,
    this.citaId,
    this.esExtra = false,
  });

  bool get estaLibre => estado == EstadoFranja.libre;
}

class TramoOcupado {
  final String inicio;
  final String fin;
  final String citaId;

  const TramoOcupado({
    required this.inicio,
    required this.fin,
    required this.citaId,
  });

  factory TramoOcupado.desdeMapa(Map<String, dynamic> datos) => TramoOcupado(
    inicio: datos['inicio'] ?? '',
    fin: datos['fin'] ?? '',
    citaId: datos['citaId'] ?? '',
  );

  Map<String, dynamic> aMapa() => {
    'inicio': inicio,
    'fin': fin,
    'citaId': citaId,
  };
}

class DisponibilidadDia {
  final List<String> bloqueadas;
  final List<String> extras;
  final Map<String, String> reservadas;
  final List<TramoOcupado> ocupadas;

  const DisponibilidadDia({
    required this.bloqueadas,
    required this.extras,
    required this.reservadas,
    this.ocupadas = const [],
  });

  factory DisponibilidadDia.vacia() =>
      const DisponibilidadDia(bloqueadas: [], extras: [], reservadas: {});

  factory DisponibilidadDia.desdeMapa(Map<String, dynamic>? datos) {
    if (datos == null) return DisponibilidadDia.vacia();

    final tramos = (datos['ocupadas'] as List? ?? [])
        .whereType<Map>()
        .map((t) => TramoOcupado.desdeMapa(Map<String, dynamic>.from(t)))
        .where((t) => t.inicio.isNotEmpty && t.fin.isNotEmpty)
        .toList();

    return DisponibilidadDia(
      bloqueadas: List<String>.from(datos['bloqueadas'] ?? []),
      extras: List<String>.from(datos['extras'] ?? []),
      reservadas: Map<String, String>.from(datos['reservadas'] ?? {}),
      ocupadas: tramos,
    );
  }
}
