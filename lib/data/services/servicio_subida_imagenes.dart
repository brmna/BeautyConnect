import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ImagenSubida {
  final String url;
  final String? identificador;

  const ImagenSubida({required this.url, this.identificador});
}

class SubidaNoConfigurada implements Exception {
  const SubidaNoConfigurada();
}

class ErrorDeSubida implements Exception {
  final String mensaje;
  const ErrorDeSubida([this.mensaje = 'No se pudo subir la imagen']);
}

class ServicioSubidaImagenes {
  static const String _nube = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String _preajuste = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  final ImagePicker _selector = ImagePicker();

  bool get estaConfigurado => _nube.isNotEmpty && _preajuste.isNotEmpty;

  Future<XFile?> elegirImagen({required bool desdeCamara}) {
    return _selector.pickImage(
      source: desdeCamara ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
  }

  Future<ImagenSubida> subir(XFile archivo) async {
    if (!estaConfigurado) throw const SubidaNoConfigurada();

    final peticion =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://api.cloudinary.com/v1_1/$_nube/image/upload'),
          )
          ..fields['upload_preset'] = _preajuste
          ..files.add(await http.MultipartFile.fromPath('file', archivo.path));

    final respuesta = await http.Response.fromStream(await peticion.send());

    if (respuesta.statusCode != 200) {
      throw const ErrorDeSubida();
    }

    final datos = json.decode(respuesta.body) as Map<String, dynamic>;
    final url = datos['secure_url'] as String?;

    if (url == null) throw const ErrorDeSubida();

    return ImagenSubida(url: url, identificador: datos['public_id'] as String?);
  }

  static String miniatura(String url, {int ancho = 400, bool cuadrada = true}) {
    const marca = '/image/upload/';
    final corte = url.indexOf(marca);
    if (corte == -1) return url;

    final ajustes = cuadrada
        ? 'w_$ancho,h_$ancho,c_fill,g_auto,q_auto,f_auto'
        : 'w_$ancho,c_limit,q_auto,f_auto';

    final inicio = corte + marca.length;
    return '${url.substring(0, inicio)}$ajustes/${url.substring(inicio)}';
  }
}
