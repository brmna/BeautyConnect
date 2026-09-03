class AjustesProfesional {
  final bool aceptandoClientas;

  final bool autoAceptar;

  final int anticipacionMinutos;

  final bool haceDomicilios;

  final bool soloDomicilio;

  final double radioCoberturaKm;

  final num recargoDomicilio;

  const AjustesProfesional({
    this.aceptandoClientas = true,
    this.autoAceptar = false,
    this.anticipacionMinutos = anticipacionPorDefecto,
    this.haceDomicilios = false,
    this.soloDomicilio = false,
    this.radioCoberturaKm = radioPorDefecto,
    this.recargoDomicilio = 0,
  });

  static const String claveAceptando = 'aceptandoClientas';
  static const String claveAutoAceptar = 'autoAceptar';
  static const String claveAnticipacion = 'anticipacionMinutos';
  static const String claveDomicilios = 'haceDomicilios';
  static const String claveSoloDomicilio = 'soloDomicilio';
  static const String claveRadio = 'radioCoberturaKm';
  static const String claveRecargo = 'recargoDomicilio';

  static const int anticipacionPorDefecto = 120;
  static const double radioPorDefecto = 5;

  static const List<int> anticipacionesPosibles = [
    0,
    60,
    120,
    180,
    360,
    720,
    1440,
    2880,
  ];

  static const List<double> radiosPosibles = [2, 3, 5, 8, 10, 15, 20, 30];

  bool get atiendeEnSuLocal => !soloDomicilio;

  bool get llegaADomicilio => haceDomicilios || soloDomicilio;

  factory AjustesProfesional.desdeMapa(Map<String, dynamic>? perfil) {
    final ajustes = perfil?['ajustes'];
    if (ajustes is! Map) return const AjustesProfesional();

    return AjustesProfesional(
      aceptandoClientas: ajustes[claveAceptando] as bool? ?? true,
      autoAceptar: ajustes[claveAutoAceptar] as bool? ?? false,
      anticipacionMinutos:
          (ajustes[claveAnticipacion] as num?)?.toInt() ??
          anticipacionPorDefecto,
      haceDomicilios: ajustes[claveDomicilios] as bool? ?? false,
      soloDomicilio: ajustes[claveSoloDomicilio] as bool? ?? false,
      radioCoberturaKm:
          (ajustes[claveRadio] as num?)?.toDouble() ?? radioPorDefecto,
      recargoDomicilio: (ajustes[claveRecargo] as num?) ?? 0,
    );
  }
}

String etiquetaAnticipacion(int minutos) {
  if (minutos <= 0) return 'Sin anticipación';
  if (minutos < 60) return '$minutos minutos antes';

  if (minutos < 1440) {
    final horas = minutos ~/ 60;
    return horas == 1 ? '1 hora antes' : '$horas horas antes';
  }

  final dias = minutos ~/ 1440;
  return dias == 1 ? '1 día antes' : '$dias días antes';
}

String etiquetaRadio(double kilometros) {
  final entero = kilometros.round();
  return entero == 1
      ? 'Hasta 1 km a la redonda'
      : 'Hasta $entero km a la redonda';
}
