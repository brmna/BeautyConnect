import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'estado_vacio.dart';
import '../../data/models/professional_model.dart';
import '../../data/models/ubicacion.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';

const double _radioZona = 400;

class MapaZonas extends StatefulWidget {
  final List<Professional> profesionales;
  final ValueChanged<Professional> onTocar;

  const MapaZonas({
    super.key,
    required this.profesionales,
    required this.onTocar,
  });

  @override
  State<MapaZonas> createState() => _MapaZonasState();
}

class _MapaZonasState extends State<MapaZonas> {
  final _mapa = MapController();

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  List<Professional> get _conZona =>
      widget.profesionales.where((p) => p.apareceEnElMapa).toList();

  LatLng _zonaDe(Professional profesional) => LatLng(
    Ubicacion.aZona(profesional.latitude!),
    Ubicacion.aZona(profesional.longitude!),
  );

  @override
  Widget build(BuildContext context) {
    final conZona = _conZona;

    if (conZona.isEmpty) {
      return const EstadoVacio(
        icono: Icons.map_outlined,
        titulo: 'Nadie ha marcado su zona todavía',
        detalle:
            'Cuando las manicuristas marquen dónde atienden, '
            'aparecerán en el mapa',
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapa,
          options: MapOptions(
            initialCenter: _zonaDe(conZona.first),
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.beautyconnect.app',
            ),
            CircleLayer(
              circles: conZona
                  .map(
                    (profesional) => CircleMarker(
                      point: _zonaDe(profesional),
                      radius: _radioZona,
                      useRadiusInMeter: true,
                      color: TemaApp.negro.withValues(alpha: 0.14),
                      borderColor: TemaApp.negro.withValues(alpha: 0.5),
                      borderStrokeWidth: 1.5,
                    ),
                  )
                  .toList(),
            ),
            MarkerLayer(
              markers: conZona
                  .map(
                    (profesional) => Marker(
                      point: _zonaDe(profesional),
                      width: 46,
                      height: 46,
                      child: _Punto(
                        profesional: profesional,
                        onTocar: () => widget.onTocar(profesional),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: margenInferior(context, base: 12),
          child: const _Nota(),
        ),
      ],
    );
  }
}

class MapaZonaProfesional extends StatefulWidget {
  final String nombre;
  final Ubicacion ubicacion;

  const MapaZonaProfesional({
    super.key,
    required this.nombre,
    required this.ubicacion,
  });

  static Future<void> abrir(
    BuildContext context, {
    required String nombre,
    required Ubicacion ubicacion,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapaZonaProfesional(nombre: nombre, ubicacion: ubicacion),
      ),
    );
  }

  @override
  State<MapaZonaProfesional> createState() => _MapaZonaProfesionalState();
}

class _MapaZonaProfesionalState extends State<MapaZonaProfesional> {
  final _mapa = MapController();

  @override
  void dispose() {
    _mapa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zona = LatLng(
      widget.ubicacion.latitudZona!,
      widget.ubicacion.longitudZona!,
    );

    final sector = widget.ubicacion.barrio.trim().isNotEmpty
        ? widget.ubicacion.barrio.trim()
        : 'Villavicencio';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dónde atiende',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Zona de $sector',
              style: const TextStyle(
                fontSize: 12,
                color: TemaApp.grisSubtitulo,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: zona,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beautyconnect.app',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: zona,
                    radius: _radioZona,
                    useRadiusInMeter: true,
                    color: TemaApp.negro.withValues(alpha: 0.14),
                    borderColor: TemaApp.negro.withValues(alpha: 0.5),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: zona,
                    width: 46,
                    height: 46,
                    child: _Inicial(nombre: widget.nombre),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: margenInferior(context, base: 12),
            child: Column(
              children: [
                const _Nota(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _mapa.move(zona, 14.5),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TemaApp.negro,
                      foregroundColor: TemaApp.blanco,
                    ),
                    icon: const Icon(Icons.my_location, size: 17),
                    label: const Text('Centrar en la zona'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Inicial extends StatelessWidget {
  final String nombre;

  const _Inicial({required this.nombre});

  @override
  Widget build(BuildContext context) {
    final limpio = nombre.trim();

    return Container(
      decoration: BoxDecoration(
        color: TemaApp.negro,
        shape: BoxShape.circle,
        border: Border.all(color: TemaApp.blanco, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: TemaApp.negro.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        limpio.isEmpty ? 'M' : limpio[0].toUpperCase(),
        style: const TextStyle(
          color: TemaApp.blanco,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  final Professional profesional;
  final VoidCallback onTocar;

  const _Punto({required this.profesional, required this.onTocar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTocar,
      child: _Inicial(nombre: profesional.name),
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TemaApp.blanco.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.privacy_tip_outlined, size: 16, color: TemaApp.grisTexto),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Se muestra la zona, no la dirección exacta. La recibes cuando '
              'confirme tu cita.',
              style: TextStyle(fontSize: 11.5, color: TemaApp.grisSubtitulo),
            ),
          ),
        ],
      ),
    );
  }
}
