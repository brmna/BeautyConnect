import 'package:shared_preferences/shared_preferences.dart';

const int maximoCorreosRecientes = 3;

String normalizarCorreo(String correo) => correo.trim().toLowerCase();

List<String> correosCon(
  List<String> guardados,
  String correo, {
  int maximo = maximoCorreosRecientes,
}) {
  final limpio = normalizarCorreo(correo);
  if (limpio.isEmpty) return List<String>.from(guardados);

  final lista = guardados.where((c) => normalizarCorreo(c) != limpio).toList();

  lista.insert(0, limpio);

  return lista.length <= maximo ? lista : lista.sublist(0, maximo);
}

List<String> correosSin(List<String> guardados, String correo) {
  final limpio = normalizarCorreo(correo);

  return guardados.where((c) => normalizarCorreo(c) != limpio).toList();
}

class ServicioCorreosRecientes {
  static const String _clave = 'correosRecientes';

  Future<List<String>> leer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_clave) ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> recordar(String correo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardados = prefs.getStringList(_clave) ?? const <String>[];

      await prefs.setStringList(_clave, correosCon(guardados, correo));
    } catch (_) {}
  }

  Future<List<String>> olvidar(String correo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardados = prefs.getStringList(_clave) ?? const <String>[];
      final quedan = correosSin(guardados, correo);

      await prefs.setStringList(_clave, quedan);
      return quedan;
    } catch (_) {
      return leer();
    }
  }
}
