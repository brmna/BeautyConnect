import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../theme/app_theme.dart';
import '../../utils/enlaces.dart';
import '../../utils/margenes.dart';
import '../widgets/marca_app.dart';

class QrPerfilScreen extends StatelessWidget {
  final String profesionalId;

  const QrPerfilScreen({super.key, required this.profesionalId});

  @override
  Widget build(BuildContext context) {
    final enlace = enlaceDePerfil(profesionalId);

    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        title: const Text(
          'Mi código',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          margenInferior(context, base: 20),
        ),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TemaApp.blanco,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: TemaApp.grisBorde),
                    ),
                    child: QrImageView(
                      data: enlace,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: TemaApp.blanco,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: TemaApp.negro,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: TemaApp.negro,
                      ),
                      embeddedImage: null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _NombreDelPerfil(profesionalId: profesionalId),
                  const SizedBox(height: 4),
                  const Text(
                    'Escanéalo desde BeautyConnect',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _ComoUsarlo(),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => SharePlus.instance.share(
                ShareParams(
                  text: 'Agenda tu cita conmigo en BeautyConnect: $enlace',
                  subject: 'Mi perfil en BeautyConnect',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.negro,
                foregroundColor: TemaApp.blanco,
              ),
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Compartir mi enlace'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComoUsarlo extends StatelessWidget {
  const _ComoUsarlo();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const MarcaBeautyConnect(tamano: 22, color: TemaApp.rosa),
                const SizedBox(width: 6),
                const Text(
                  'Cómo usarlo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const _Paso(
              numero: '1',
              texto: 'Muéstralo o pégalo en tu sitio de trabajo.',
            ),
            const _Paso(
              numero: '2',
              texto:
                  'Tu cliente entra a BeautyConnect, toca el botón de escanear '
                  'en Buscar y apunta la cámara.',
            ),
            const _Paso(
              numero: '3',
              texto: 'Se abre tu perfil y puede reservar de una vez.',
            ),
            const SizedBox(height: 10),
            const Text(
              'Quien no tenga la app instalada verá solo el enlace: por ahora '
              'el código funciona entre usuarias de BeautyConnect.',
              style: TextStyle(fontSize: 11.5, color: TemaApp.grisTexto),
            ),
          ],
        ),
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  final String numero;
  final String texto;

  const _Paso({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: TemaApp.grisClaro,
              shape: BoxShape.circle,
            ),
            child: Text(
              numero,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: TemaApp.textoOscuro,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: TemaApp.grisSubtitulo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NombreDelPerfil extends StatelessWidget {
  final String profesionalId;

  const _NombreDelPerfil({required this.profesionalId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(profesionalId)
          .get(),
      builder: (context, instantanea) {
        final nombre = instantanea.data?.data()?['name'] as String? ?? '';

        return Text(
          nombre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
