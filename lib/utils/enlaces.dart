const String esquemaApp = 'beautyconnect';

String enlaceDePerfil(String profesionalId) =>
    '$esquemaApp://perfil/$profesionalId';

String? perfilDesdeEnlace(String? texto) {
  if (texto == null) return null;

  final enlace = Uri.tryParse(texto.trim());
  if (enlace == null || enlace.scheme != esquemaApp) return null;
  if (enlace.host != 'perfil') return null;

  final id = enlace.pathSegments.isEmpty ? '' : enlace.pathSegments.first;
  return id.isEmpty ? null : id;
}
