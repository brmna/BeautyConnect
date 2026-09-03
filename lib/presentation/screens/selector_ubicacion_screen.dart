import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/ubicacion.dart';
import '../../utils/distancia.dart';
import '../../utils/validaciones.dart';
import '../../theme/app_theme.dart';
import '../widgets/mensaje.dart';

class SelectorUbicacionScreen extends StatefulWidget {
  final Ubicacion inicial;

  final Ubicacion? centroCobertura;
  final double? radioCoberturaKm;

  const SelectorUbicacionScreen({
    super.key,
    required this.inicial,
    this.centroCobertura,
    this.radioCoberturaKm,
  });

  @override
  State<SelectorUbicacionScreen> createState() =>
      _SelectorUbicacionScreenState();
}

class _SelectorUbicacionScreenState extends State<SelectorUbicacionScreen> {
  final _mapa = MapController();
  final _direccionCtrl = TextEditingController();
  final _barrioCtrl = TextEditingController();

  LatLng? _punto;
  bool _buscandoGps = false;
  bool _traduciendoPunto = false;
  bool _buscandoDireccion = false;

  String _direccionDelPunto = '';

  @override
  void initState() {
    super.initState();
    _direccionCtrl.text = widget.inicial.direccion;
    _barrioCtrl.text = widget.inicial.barrio;
    _direccionDelPunto = widget.inicial.direccion;
    if (widget.inicial.tienePunto) {
      _punto = LatLng(widget.inicial.latitud!, widget.inicial.longitud!);
    }
  }

  @override
  void dispose() {
    _direccionCtrl.dispose();
    _barrioCtrl.dispose();
    _mapa.dispose();
    super.dispose();
  }

  LatLng get _centro =>
      _punto ?? const LatLng(Villavicencio.latitud, Villavicencio.longitud);

  bool get _puedeGuardar => _punto != null;

  Future<void> _marcarPunto(LatLng punto, {bool moverMapa = false}) async {
    setState(() {
      _punto = punto;
      _traduciendoPunto = true;
    });
    if (moverMapa) _mapa.move(punto, 17);

    try {
      final lugares = await placemarkFromCoordinates(
        punto.latitude,
        punto.longitude,
      );

      if (lugares.isEmpty || !mounted) return;
      final lugar = lugares.first;

      final calle = [lugar.street, lugar.name]
          .where((p) => p != null && p.trim().isNotEmpty)
          .map((p) => p!.trim())
          .toSet()
          .join(', ');

      setState(() {
        if (calle.isNotEmpty) {
          _direccionCtrl.text = calle;
          _direccionDelPunto = calle;
        }
        final sector = lugar.subLocality?.trim() ?? '';
        if (sector.isNotEmpty && _barrioCtrl.text.trim().isEmpty) {
          _barrioCtrl.text = sector;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _traduciendoPunto = false);
    }
  }

  Future<void> _ubicarDireccion() async {
    final direccion = _direccionCtrl.text.trim();
    if (direccion.isEmpty) return;

    setState(() => _buscandoDireccion = true);
    final mensajero = ScaffoldMessenger.of(context);

    final barrio = _barrioCtrl.text.trim();
    final consulta = [
      direccion,
      if (barrio.isNotEmpty) barrio,
      'Villavicencio',
      'Meta',
      'Colombia',
    ].join(', ');

    try {
      final lugares = await locationFromAddress(consulta);

      if (lugares.isEmpty) {
        mensajero.showSnackBar(
          construirMensaje(
            'No encontramos esa dirección. Tócala en el mapa',
            tipo: TipoAviso.aviso,
          ),
        );
      } else if (mounted) {
        final lugar = lugares.first;
        final punto = LatLng(lugar.latitude, lugar.longitude);

        setState(() {
          _punto = punto;
          _direccionDelPunto = direccion;
        });
        _mapa.move(punto, 17);
      }
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No encontramos esa dirección. Tócala en el mapa',
          tipo: TipoAviso.aviso,
        ),
      );
    }

    if (mounted) setState(() => _buscandoDireccion = false);
  }

  bool get _puntoDesactualizado {
    final direccion = _direccionCtrl.text.trim();
    if (_punto == null || direccion.isEmpty) return false;
    return direccion.toLowerCase() != _direccionDelPunto.trim().toLowerCase();
  }

  Future<void> _usarMiUbicacion() async {
    setState(() => _buscandoGps = true);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }

      if (permiso == LocationPermission.denied ||
          permiso == LocationPermission.deniedForever) {
        mensajero.showSnackBar(
          construirMensaje(
            'Sin permiso de ubicación. Tócala en el mapa',
            tipo: TipoAviso.info,
          ),
        );
      } else {
        final posicion = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await _marcarPunto(
          LatLng(posicion.latitude, posicion.longitude),
          moverMapa: true,
        );
      }
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo obtener tu ubicación. Tócala en el mapa',
          tipo: TipoAviso.error,
        ),
      );
    }

    if (mounted) setState(() => _buscandoGps = false);
  }

  void _guardar() {
    Navigator.pop(
      context,
      Ubicacion(
        direccion: _direccionCtrl.text.trim(),
        barrio: _barrioCtrl.text.trim(),
        latitud: _punto?.latitude,
        longitud: _punto?.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        title: Text(
          widget.radioCoberturaKm == null
              ? 'Dónde atiendes'
              : 'Dónde quieres el servicio',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _vistaMapa()),
          _formulario(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _puedeGuardar ? _guardar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.negro,
                foregroundColor: TemaApp.blanco,
              ),
              child: const Text('Guardar ubicación'),
            ),
          ),
        ),
      ),
    );
  }

  CircleLayer? _capaCobertura() {
    final centro = widget.centroCobertura;
    final radio = widget.radioCoberturaKm;
    if (centro == null || radio == null || !centro.tienePunto) return null;

    final dentro = !_fueraDeCobertura;

    return CircleLayer(
      circles: [
        CircleMarker(
          point: LatLng(centro.latitud!, centro.longitud!),
          radius: radio * 1000,
          useRadiusInMeter: true,
          color: (dentro ? TemaApp.exito : TemaApp.error).withValues(
            alpha: 0.10,
          ),
          borderColor: (dentro ? TemaApp.exito : TemaApp.error).withValues(
            alpha: 0.55,
          ),
          borderStrokeWidth: 1.5,
        ),
      ],
    );
  }

  bool get _fueraDeCobertura {
    final centro = widget.centroCobertura;
    final radio = widget.radioCoberturaKm;
    final punto = _punto;

    if (centro == null || radio == null || punto == null) return false;
    if (!centro.tienePunto) return false;

    return distanciaKm(
          latitudA: punto.latitude,
          longitudA: punto.longitude,
          latitudB: centro.latitud!,
          longitudB: centro.longitud!,
        ) >
        radio;
  }

  Widget _avisoCobertura() {
    final radio = widget.radioCoberturaKm;
    if (radio == null || _punto == null) return const SizedBox.shrink();

    final fuera = _fueraDeCobertura;

    return Positioned(
      left: 16,
      right: 16,
      top: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: TemaApp.blanco,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              fuera ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: fuera ? TemaApp.error : TemaApp.exito,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fuera
                    ? 'Fuera de su zona de atención'
                    : 'Dentro de su zona de atención',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: fuera ? TemaApp.error : TemaApp.exito,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vistaMapa() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapa,
          options: MapOptions(
            initialCenter: _centro,
            initialZoom: _punto == null ? 12 : 17,
            onTap: (_, punto) => _marcarPunto(punto),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.beautyconnect.app',
            ),
            ?_capaCobertura(),
            if (_punto != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _punto!,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: TemaApp.grisSubtitulo,
                      size: 44,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (_punto != null) _avisoCobertura(),
        if (_punto == null)
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TemaApp.blanco,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_outlined, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Toca el mapa donde atiendes',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'gps',
            onPressed: _buscandoGps ? null : _usarMiUbicacion,
            backgroundColor: TemaApp.blanco,
            foregroundColor: TemaApp.textoOscuro,
            icon: _buscandoGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: const Text('Mi ubicación'),
          ),
        ),
      ],
    );
  }

  Widget _formulario() {
    return Container(
      decoration: const BoxDecoration(
        color: TemaApp.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _direccionCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            maxLength: maximoDireccion,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _ubicarDireccion(),
            decoration: InputDecoration(
              counterText: '',
              labelText: 'Dirección',
              hintText: 'Calle 40 # 25-30',
              prefixIcon: const Icon(Icons.home_outlined),
              suffixIcon: (_traduciendoPunto || _buscandoDireccion)
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Ubicar en el mapa',
                      icon: const Icon(Icons.travel_explore_outlined),
                      onPressed: _direccionCtrl.text.trim().isEmpty
                          ? null
                          : _ubicarDireccion,
                    ),
              isDense: true,
            ),
          ),
          if (_puntoDesactualizado)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: TemaApp.aviso,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'El punto del mapa es de otra dirección',
                      style: TextStyle(fontSize: 11.5, color: TemaApp.aviso),
                    ),
                  ),
                  TextButton(
                    onPressed: _ubicarDireccion,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                    ),
                    child: const Text('Ubicar'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _barrioCtrl,
            textCapitalization: TextCapitalization.words,
            maxLength: maximoBarrio,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              counterText: '',
              labelText: 'Barrio o sector (opcional)',
              hintText: 'Con esto te encuentran por zona',
              prefixIcon: Icon(Icons.map_outlined),
              isDense: true,
            ),
          ),
          _sugerenciasBarrio(),
        ],
      ),
    );
  }

  Widget _sugerenciasBarrio() {
    final sugerencias = Villavicencio.sugerencias(_barrioCtrl.text);
    final exacta =
        sugerencias.length == 1 &&
        sugerencias.first.toLowerCase() ==
            _barrioCtrl.text.trim().toLowerCase();

    if (sugerencias.isEmpty || exacta) return const SizedBox(height: 4);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        children: sugerencias
            .map(
              (barrio) => ActionChip(
                label: Text(barrio, style: const TextStyle(fontSize: 12)),
                onPressed: () => setState(() {
                  _barrioCtrl.text = barrio;
                }),
              ),
            )
            .toList(),
      ),
    );
  }
}
