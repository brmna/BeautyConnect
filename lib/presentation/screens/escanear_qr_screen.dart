import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import '../../utils/enlaces.dart';
import '../widgets/mensaje.dart';
import 'professional_detail_screen.dart';

class EscanearQrScreen extends StatefulWidget {
  const EscanearQrScreen({super.key});

  @override
  State<EscanearQrScreen> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends State<EscanearQrScreen> {
  final _control = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _yaAbrio = false;

  @override
  void dispose() {
    _control.dispose();
    super.dispose();
  }

  void _alDetectar(BarcodeCapture captura) {
    if (_yaAbrio) return;

    for (final codigo in captura.barcodes) {
      final id = perfilDesdeEnlace(codigo.rawValue);
      if (id == null) continue;

      _yaAbrio = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalDetailScreen(professionalId: id),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.negro,
      appBar: AppBar(
        backgroundColor: TemaApp.negro,
        foregroundColor: TemaApp.blanco,
        title: const Text(
          'Escanear código',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Linterna',
            onPressed: () => _control.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _control,
            onDetect: _alDetectar,
            errorBuilder: (context, error) => _sinCamara(),
          ),
          const _Mira(),
          Positioned(
            left: 24,
            right: 24,
            bottom: margenInferior(context, base: 40),
            child: Text(
              'Apunta al código de tu manicurista',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TemaApp.blanco.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sinCamara() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 52,
              color: TemaApp.grisTexto,
            ),
            const SizedBox(height: 14),
            const Text(
              'No pudimos usar la cámara',
              textAlign: TextAlign.center,
              style: TextStyle(color: TemaApp.blanco, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Revisa que le hayas dado permiso a BeautyConnect',
              textAlign: TextAlign.center,
              style: TextStyle(color: TemaApp.grisTexto, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                mostrarMensaje(
                  context,
                  'También puedes buscarla por su nombre',
                  tipo: TipoAviso.info,
                );
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: TemaApp.blanco,
                side: const BorderSide(color: TemaApp.grisTexto),
              ),
              child: const Text('Volver a buscar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Mira extends StatelessWidget {
  const _Mira();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: TemaApp.blanco, width: 2.5),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
