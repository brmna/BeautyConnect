import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/validaciones.dart';
import '../../theme/app_theme.dart';
import 'mensaje.dart';

enum RedSocial { instagram, facebook, tiktok, whatsapp }

extension DatosRed on RedSocial {
  String get clave => name;

  String get nombre => switch (this) {
    RedSocial.instagram => 'Instagram',
    RedSocial.facebook => 'Facebook',
    RedSocial.tiktok => 'TikTok',
    RedSocial.whatsapp => 'WhatsApp',
  };

  IconData get icono => switch (this) {
    RedSocial.instagram => Icons.camera_alt_outlined,
    RedSocial.facebook => Icons.thumb_up_alt_outlined,
    RedSocial.tiktok => Icons.music_note_outlined,
    RedSocial.whatsapp => Icons.chat_outlined,
  };

  Color get color => switch (this) {
    RedSocial.instagram => const Color(0xFFC13584),
    RedSocial.facebook => const Color(0xFF1877F2),
    RedSocial.tiktok => const Color(0xFF111111),
    RedSocial.whatsapp => const Color(0xFF25D366),
  };

  String get pista => switch (this) {
    RedSocial.instagram => 'tu_usuario',
    RedSocial.facebook => 'tu.perfil',
    RedSocial.tiktok => 'tu_usuario',
    RedSocial.whatsapp => '3000000000',
  };

  Uri enlace(String valor) {
    final limpio = valor.trim().replaceAll('@', '');

    if (this != RedSocial.whatsapp) {
      final yaEsEnlace = RegExp(
        r'^(https?://|www\.)',
        caseSensitive: false,
      ).hasMatch(limpio);

      if (yaEsEnlace) {
        return Uri.parse(
          limpio.toLowerCase().startsWith('www.') ? 'https://$limpio' : limpio,
        );
      }
    }

    final soloDigitos = limpio.replaceAll(RegExp(r'[^0-9]'), '');

    return switch (this) {
      RedSocial.instagram => Uri.parse('https://instagram.com/$limpio'),
      RedSocial.facebook => Uri.parse('https://facebook.com/$limpio'),
      RedSocial.tiktok => Uri.parse('https://tiktok.com/@$limpio'),
      RedSocial.whatsapp => Uri.parse('https://wa.me/57$soloDigitos'),
    };
  }
}

Map<String, String> leerRedes(Map<String, dynamic>? datos) {
  final crudas = datos?['redes'];
  if (crudas is! Map) return {};

  final resultado = <String, String>{};
  crudas.forEach((clave, valor) {
    if (valor is String && valor.trim().isNotEmpty) {
      resultado['$clave'] = valor.trim();
    }
  });
  return resultado;
}

class BotonesRedes extends StatelessWidget {
  final Map<String, String> redes;

  const BotonesRedes({super.key, required this.redes});

  @override
  Widget build(BuildContext context) {
    final disponibles = RedSocial.values
        .where((red) => redes.containsKey(red.clave))
        .toList();

    if (disponibles.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: disponibles.map((red) {
        final valor = redes[red.clave]!;

        return ActionChip(
          avatar: Icon(red.icono, size: 16, color: red.color),
          label: Text(red.nombre, style: const TextStyle(fontSize: 12)),
          backgroundColor: TemaApp.blanco,
          side: const BorderSide(color: TemaApp.grisBorde),
          onPressed: () => _abrir(context, red, valor),
        );
      }).toList(),
    );
  }

  Future<void> _abrir(BuildContext context, RedSocial red, String valor) async {
    final mensajero = ScaffoldMessenger.of(context);
    final abierto = await launchUrl(
      red.enlace(valor),
      mode: LaunchMode.externalApplication,
    );

    if (!abierto) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo abrir ${red.nombre}',
          tipo: TipoAviso.error,
        ),
      );
    }
  }
}

class CamposRedes extends StatelessWidget {
  final Map<String, TextEditingController> controladores;

  const CamposRedes({super.key, required this.controladores});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: RedSocial.values.map((red) {
        final esWhatsapp = red == RedSocial.whatsapp;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
            controller: controladores[red.clave],
            keyboardType: esWhatsapp ? TextInputType.phone : TextInputType.text,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: esWhatsapp ? const [FormatoTelefono()] : null,
            validator: esWhatsapp ? validarTelefono : validarUsuarioRed,
            decoration: InputDecoration(
              labelText: red.nombre,
              hintText: esWhatsapp
                  ? red.pista
                  : '${red.pista} o pega el enlace',
              prefixIcon: Icon(red.icono, size: 20, color: red.color),
              prefixText: esWhatsapp ? '+57 ' : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}
