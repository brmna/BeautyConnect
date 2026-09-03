List<String> franjasDeLaCita(Map<String, dynamic>? cita) {
  if (cita == null) return const [];

  final guardadas = cita['slots'];
  if (guardadas is List && guardadas.isNotEmpty) {
    return List<String>.from(guardadas);
  }

  final unica = cita['slot'];
  return unica is String ? [unica] : const [];
}
