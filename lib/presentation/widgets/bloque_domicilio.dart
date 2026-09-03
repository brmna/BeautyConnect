import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/ubicacion.dart';
import '../../data/services/servicio_ubicacion_cita.dart';
import '../../theme/app_theme.dart';
import 'mensaje.dart';

class BloqueDomicilio extends StatefulWidget {
  final String citaId;
  final Map<String, dynamic> cita;
  final bool confirmada;
  final bool finalizada;

  const BloqueDomicilio({
    super.key,
    required this.citaId,
    required this.cita,
    required this.confirmada,
    this.finalizada = false,
  });

  @override
  State<BloqueDomicilio> createState() => _BloqueDomicilioState();
}

class _BloqueDomicilioState extends State<BloqueDomicilio> {
  final _servicio = ServicioUbicacionCita();

  Ubicacion? _exacta;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.confirmada) _cargarExacta();
  }

  @override
  void didUpdateWidget(BloqueDomicilio anterior) {
    super.didUpdateWidget(anterior);
    if (widget.confirmada && !anterior.confirmada) _cargarExacta();
  }

  Future<void> _cargarExacta() async {
    if (_cargando || _exacta != null) return;
    setState(() => _cargando = true);

    final ubicacion = await _servicio.exacta(widget.citaId);

    if (!mounted) return;
    setState(() {
      _exacta = ubicacion;
      _cargando = false;
    });
  }

  String get _sector {
    final barrio = (widget.cita['barrioCliente'] as String?)?.trim() ?? '';
    return barrio.isEmpty ? 'Villavicencio' : barrio;
  }

  Future<void> _abrirRuta() async {
    final exacta = _exacta;
    final mensajero = ScaffoldMessenger.of(context);

    final destino = exacta != null && exacta.tienePunto
        ? rutaEnGoogleMaps(latitud: exacta.latitud!, longitud: exacta.longitud!)
        : buscarEnGoogleMaps(exacta?.direccion ?? _sector);

    final abierto = await launchUrl(
      destino,
      mode: LaunchMode.externalApplication,
    );

    if (!abierto) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo abrir Google Maps', tipo: TipoAviso.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exacta = _exacta;
    final tieneExacta = widget.confirmada && (exacta?.estaDefinida ?? false);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TemaApp.grisClaro,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_car_outlined,
                  size: 16,
                  color: TemaApp.grisSubtitulo,
                ),
                const SizedBox(width: 8),
                const Text(
                  'A domicilio',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tieneExacta ? exacta!.resumen : 'Zona de $_sector',
              style: const TextStyle(fontSize: 13, color: TemaApp.textoOscuro),
            ),
            if (!widget.confirmada) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.lock_outline, size: 13, color: TemaApp.grisTexto),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Verás la dirección exacta cuando confirmes la cita',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: TemaApp.grisTexto,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (widget.confirmada && !widget.finalizada) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cargando ? null : _abrirRuta,
                  icon: _cargando
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.navigation_outlined, size: 17),
                  label: const Text('Cómo llegar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
