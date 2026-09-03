import 'package:flutter/services.dart';

const int precioMinimo = 1000;
const int precioMaximo = 999999;
const int duracionMinima = 5;
const int duracionMaxima = 480;

String? validarNombre(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'Ingresa tu nombre';
  if (texto.length < 3) return 'El nombre es muy corto';
  if (texto.length > 60) return 'El nombre es muy largo';
  return null;
}

String? validarCorreo(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'Ingresa tu correo';

  final patron = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
  if (!patron.hasMatch(texto)) return 'Correo inválido';
  return null;
}

String? validarContrasena(String? valor) {
  final texto = valor ?? '';
  if (texto.isEmpty) return 'Ingresa una contraseña';
  if (texto.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

String? validarTelefono(String? valor, {bool obligatorio = false}) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return obligatorio ? 'Ingresa tu teléfono' : null;

  final digitos = texto.replaceAll(RegExp(r'[^0-9]'), '');
  final sinIndicativo = digitos.startsWith('57') && digitos.length == 12
      ? digitos.substring(2)
      : digitos;

  if (sinIndicativo.length != 10) return 'Debe tener 10 dígitos';
  if (!sinIndicativo.startsWith('3')) return 'Un celular empieza por 3';
  return null;
}

String? validarPrecio(String? valor) {
  final numero = int.tryParse(soloDigitos(valor ?? ''));
  if (numero == null) return 'Ingresa el precio';
  if (numero < precioMinimo) return 'Mínimo ${_conPuntos(precioMinimo)}';
  if (numero > precioMaximo) return 'Máximo ${_conPuntos(precioMaximo)}';
  return null;
}

String? validarDuracion(String? valor) {
  final numero = int.tryParse((valor ?? '').trim());
  if (numero == null) return 'Ingresa la duración';
  if (numero < duracionMinima) return 'Mínimo $duracionMinima minutos';
  if (numero > duracionMaxima) return 'Máximo $duracionMaxima minutos';
  return null;
}

String? validarAnio(String? valor, {bool obligatorio = false}) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return obligatorio ? 'Ingresa el año' : null;

  final numero = int.tryParse(texto);
  final actual = DateTime.now().year;
  if (numero == null) return 'Año inválido';
  if (numero < 1950 || numero > actual) return 'Entre 1950 y $actual';
  return null;
}

String? validarAniosExperiencia(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return null;

  final numero = int.tryParse(texto);
  if (numero == null) return 'Solo números';
  if (numero < 0 || numero > 60) return 'Entre 0 y 60 años';
  return null;
}

String soloDigitos(String texto) => texto.replaceAll(RegExp(r'[^0-9]'), '');

String _conPuntos(int numero) {
  final texto = numero.toString();
  final partes = <String>[];

  for (var i = texto.length; i > 0; i -= 3) {
    partes.insert(0, texto.substring(i - 3 < 0 ? 0 : i - 3, i));
  }

  return '\$${partes.join('.')}';
}

class FormatoPrecio extends TextInputFormatter {
  const FormatoPrecio();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final digitos = soloDigitos(nuevo.text);
    if (digitos.isEmpty) return nuevo.copyWith(text: '');

    final recortado = digitos.length > 6 ? digitos.substring(0, 6) : digitos;
    final conPuntos = _conPuntos(int.parse(recortado)).substring(1);

    return TextEditingValue(
      text: conPuntos,
      selection: TextSelection.collapsed(offset: conPuntos.length),
    );
  }
}

const int maximoComentarioResena = 500;
const int maximoRespuestaResena = 400;
const int maximoSobreMi = 400;
const int maximoTituloDiseno = 60;
const int maximoEtiquetasDiseno = 8;
const int maximoTituloCertificado = 80;
const int maximoDireccion = 120;
const int maximoBarrio = 60;
const int maximoEspecialidades = 10;

String? validarTextoOpcional(String? valor, {required int maximo}) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return null;
  if (texto.length > maximo) return 'Máximo $maximo caracteres';
  return null;
}

String? validarTextoObligatorio(
  String? valor, {
  required String queFalta,
  int minimo = 3,
  int maximo = 120,
}) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'Ingresa $queFalta';
  if (texto.length < minimo) return 'Es muy corto';
  if (texto.length > maximo) return 'Máximo $maximo caracteres';
  return null;
}

String? validarComentarioResena(String? valor) =>
    validarTextoOpcional(valor, maximo: maximoComentarioResena);

String? validarRespuestaResena(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return 'Escribe tu respuesta';
  if (texto.length > maximoRespuestaResena) {
    return 'Máximo $maximoRespuestaResena caracteres';
  }
  return null;
}

String? validarSobreMi(String? valor) =>
    validarTextoOpcional(valor, maximo: maximoSobreMi);

String? validarBarrio(String? valor) =>
    validarTextoOpcional(valor, maximo: maximoBarrio);

String? validarDireccion(String? valor) =>
    validarTextoOpcional(valor, maximo: maximoDireccion);

String? validarTituloDiseno(String? valor) =>
    validarTextoOpcional(valor, maximo: maximoTituloDiseno);

String? validarTituloCertificado(String? valor) => validarTextoObligatorio(
  valor,
  queFalta: 'el nombre del certificado',
  maximo: maximoTituloCertificado,
);

String? validarListaSeparada(
  String? valor, {
  required int maximoElementos,
  int maximoLargo = 30,
}) {
  final elementos = separarPorComas(valor ?? '');
  if (elementos.isEmpty) return null;

  if (elementos.length > maximoElementos) {
    return 'Máximo $maximoElementos, separadas por comas';
  }
  if (elementos.any((e) => e.length > maximoLargo)) {
    return 'Cada una máximo $maximoLargo caracteres';
  }
  return null;
}

String? validarEspecialidades(String? valor) =>
    validarListaSeparada(valor, maximoElementos: maximoEspecialidades);

String? validarEtiquetasDiseno(String? valor) => validarListaSeparada(
  valor,
  maximoElementos: maximoEtiquetasDiseno,
  maximoLargo: 20,
);

String? validarUsuarioRed(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.isEmpty) return null;
  if (texto.length > 200) return 'Es demasiado largo';
  if (texto.contains(' ')) return 'No puede llevar espacios';
  return null;
}

List<String> separarPorComas(String texto) =>
    texto.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

class FormatoTelefono extends TextInputFormatter {
  const FormatoTelefono();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue nuevo,
  ) {
    final permitido = nuevo.text.replaceAll(RegExp(r'[^0-9+ ]'), '');
    final digitos = soloDigitos(permitido);

    if (digitos.length > 12) return anterior;
    if (permitido == nuevo.text) return nuevo;

    return TextEditingValue(
      text: permitido,
      selection: TextSelection.collapsed(offset: permitido.length),
    );
  }
}
