import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/diseno.dart';

class VisionNoConfigurada implements Exception {
  const VisionNoConfigurada();
}

class ErrorDeVision implements Exception {
  final String mensaje;

  const ErrorDeVision(this.mensaje);
}

class LecturaDeFoto {
  final bool sonUnas;
  final List<String> etiquetas;

  const LecturaDeFoto({required this.sonUnas, required this.etiquetas});
}

class ServicioVision {
  static const String _llave = String.fromEnvironment('GEMINI_API_KEY');
  static const String _modelo = String.fromEnvironment(
    'GEMINI_MODELO',
    defaultValue: 'gemini-3.6-flash',
  );

  static const int maximoEtiquetas = 4;
  static const Duration _espera = Duration(seconds: 30);

  final http.Client _cliente;

  ServicioVision({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  bool get estaConfigurado => _llave.isNotEmpty;

  Uri get _url => Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/'
    '$_modelo:generateContent?key=$_llave',
  );

  Future<LecturaDeFoto> leerUnas(XFile archivo) async {
    if (!estaConfigurado) throw const VisionNoConfigurada();

    final bytes = await archivo.readAsBytes();
    if (bytes.isEmpty) throw const ErrorDeVision('La foto llegó vacía');

    final http.Response respuesta;
    try {
      respuesta = await _cliente
          .post(
            _url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(_peticion(bytes, archivo)),
          )
          .timeout(_espera);
    } catch (_) {
      throw const ErrorDeVision('No pudimos conectarnos. Revisa tu internet');
    }

    if (respuesta.statusCode != 200) {
      throw ErrorDeVision(_explicar(respuesta.statusCode));
    }

    return interpretar(respuesta.body);
  }

  Map<String, dynamic> _peticion(List<int> bytes, XFile archivo) => {
    'contents': [
      {
        'parts': [
          {'text': _instruccion},
          {
            'inline_data': {
              'mime_type': _tipoDe(archivo),
              'data': base64Encode(bytes),
            },
          },
        ],
      },
    ],
    'generationConfig': {
      'temperature': 0,
      'responseMimeType': 'application/json',
      'responseSchema': {
        'type': 'OBJECT',
        'properties': {
          'sonUnas': {'type': 'BOOLEAN'},
          'etiquetas': {
            'type': 'ARRAY',
            'items': {'type': 'STRING', 'enum': CatalogoEtiquetas.sugeridas},
          },
        },
        'required': ['sonUnas', 'etiquetas'],
      },
    },
  };

  static String _tipoDe(XFile archivo) {
    final nombre = archivo.name.toLowerCase();
    if (nombre.endsWith('.png')) return 'image/png';
    if (nombre.endsWith('.webp')) return 'image/webp';
    if (nombre.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }

  static const String _instruccion =
      'Eres quien clasifica fotos de uñas para una app de manicuristas.\n'
      'Mira la foto y responde dos cosas.\n\n'
      'sonUnas: true solo si se ven uñas de manos o pies. Si es cualquier '
      'otra cosa, false.\n\n'
      'etiquetas: como máximo $maximoEtiquetas etiquetas del catálogo, de la '
      'que mejor describe el diseño a la que menos. Elige solo las que se '
      'vean con claridad; prefiere pocas y seguras antes que muchas dudosas. '
      'Si sonUnas es false, devuelve la lista vacía.';

  static LecturaDeFoto interpretar(String cuerpo) {
    final Map<String, dynamic> sobre;
    try {
      sobre = jsonDecode(cuerpo) as Map<String, dynamic>;
    } catch (_) {
      throw const ErrorDeVision('No entendimos la respuesta del análisis');
    }

    final candidatos = sobre['candidates'];
    if (candidatos is! List || candidatos.isEmpty) {
      throw const ErrorDeVision('El análisis no devolvió nada');
    }

    final primero = candidatos.first;
    final contenido = primero is Map ? primero['content'] : null;
    final partes = contenido is Map ? contenido['parts'] : null;

    String? texto;
    if (partes is List && partes.isNotEmpty) {
      final parte = partes.first;
      if (parte is Map) texto = parte['text'] as String?;
    }

    if (texto == null || texto.trim().isEmpty) {
      throw const ErrorDeVision('El análisis no devolvió nada');
    }

    final Map<String, dynamic> lectura;
    try {
      lectura = jsonDecode(texto) as Map<String, dynamic>;
    } catch (_) {
      throw const ErrorDeVision('No entendimos la respuesta del análisis');
    }

    final crudas = lectura['etiquetas'];
    final etiquetas = crudas is List
        ? crudas
              .whereType<String>()
              .where(CatalogoEtiquetas.sugeridas.contains)
              .toSet()
              .take(maximoEtiquetas)
              .toList()
        : <String>[];

    return LecturaDeFoto(
      sonUnas: lectura['sonUnas'] == true,
      etiquetas: etiquetas,
    );
  }

  static String _explicar(int codigo) {
    if (codigo == 400 || codigo == 401 || codigo == 403) {
      return 'La llave del análisis no es válida';
    }
    if (codigo == 404) {
      return 'El modelo "$_modelo" ya no está disponible';
    }
    if (codigo == 429) return 'Demasiadas búsquedas seguidas. Espera un poco';
    if (codigo == 503) {
      return 'El análisis está saturado. Prueba en un momento';
    }
    if (codigo >= 500) return 'El análisis no está disponible ahora';

    return 'No se pudo analizar la foto';
  }
}
