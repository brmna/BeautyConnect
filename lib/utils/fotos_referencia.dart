const int maximoFotosReferencia = 1;

const String claveFotosReferencia = 'fotosReferencia';

List<String> limpiarFotosReferencia(Iterable<Object?> crudas) {
  final limpias = <String>[];

  for (final cruda in crudas) {
    if (cruda is! String) continue;

    final url = cruda.trim();
    if (!url.startsWith('https://')) continue;
    if (limpias.contains(url)) continue;

    limpias.add(url);
    if (limpias.length == maximoFotosReferencia) break;
  }

  return limpias;
}

List<String> fotosReferenciaDeCita(Map<String, dynamic>? cita) {
  final crudo = cita?[claveFotosReferencia];
  if (crudo is! List) return const [];

  return limpiarFotosReferencia(crudo);
}
