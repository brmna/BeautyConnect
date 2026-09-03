import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/ajustes_profesional.dart';
import '../../data/models/ubicacion.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import 'rejilla_opciones.dart';

class HojaCobertura extends StatefulWidget {
  final double actual;
  final Ubicacion centro;

  const HojaCobertura({super.key, required this.actual, required this.centro});

  @override
  State<HojaCobertura> createState() => _HojaCoberturaState();
}

class _HojaCoberturaState extends State<HojaCobertura> {
  final _mapa = MapController();
  late double _elegido = widget.actual;

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  double _zoomPara(double kilometros) {
    if (kilometros <= 2) return 13.2;
    if (kilometros <= 3) return 12.7;
    if (kilometros <= 5) return 12.0;
    if (kilometros <= 8) return 11.4;
    if (kilometros <= 10) return 11.1;
    if (kilometros <= 15) return 10.5;
    if (kilometros <= 20) return 10.1;
    return 9.5;
  }

  void _cambiar(double kilometros) {
    setState(() => _elegido = kilometros);

    if (widget.centro.tienePunto) {
      _mapa.move(
        LatLng(widget.centro.latitud!, widget.centro.longitud!),
        _zoomPara(kilometros),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tienePunto = widget.centro.tienePunto;
    final centro = tienePunto
        ? LatLng(widget.centro.latitud!, widget.centro.longitud!)
        : const LatLng(Villavicencio.latitud, Villavicencio.longitud);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: margenHoja(context, base: 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zona de cobertura',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            tienePunto
                ? 'Hasta dónde estás dispuesta a ir. Fuera de este círculo '
                      'nadie puede pedirte domicilio.'
                : 'Marca primero dónde atiendes en tu perfil para ver el '
                      'círculo en el mapa.',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: TemaApp.grisSubtitulo,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                mapController: _mapa,
                options: MapOptions(
                  initialCenter: centro,
                  initialZoom: _zoomPara(_elegido),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.beautyconnect.app',
                  ),
                  if (tienePunto) ...[
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: centro,
                          radius: _elegido * 1000,
                          useRadiusInMeter: true,
                          color: TemaApp.negro.withValues(alpha: 0.10),
                          borderColor: TemaApp.negro.withValues(alpha: 0.55),
                          borderStrokeWidth: 1.5,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: centro,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: TemaApp.negro,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: TemaApp.blanco,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              etiquetaRadio(_elegido),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          RejillaOpciones(
            anchoMinimo: 70,
            hijos: AjustesProfesional.radiosPosibles
                .map(
                  (km) => CeldaOpcion(
                    etiqueta: '${km.round()} km',
                    activa: km == _elegido,
                    onTocar: () => _cambiar(km),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _elegido),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.negro,
                foregroundColor: TemaApp.blanco,
              ),
              child: const Text('Guardar zona'),
            ),
          ),
        ],
      ),
    );
  }
}
