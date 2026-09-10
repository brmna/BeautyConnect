import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/ubicacion.dart';
import '../../data/services/cache_perfiles.dart';
import '../../data/services/servicio_ubicacion_cita.dart';
import '../../theme/app_theme.dart';
import '../../utils/distancia.dart';
import 'mapa_zonas.dart';
import 'mensaje.dart';

Future<void> abrirRuta(
  BuildContext context, {
  required Ubicacion? destino,
  required String respaldo,
}) async {
  final mensajero = ScaffoldMessenger.of(context);

  final enlace = destino != null && destino.tienePunto
      ? rutaEnGoogleMaps(latitud: destino.latitud!, longitud: destino.longitud!)
      : buscarEnGoogleMaps(
          destino?.resumen.isNotEmpty == true ? destino!.resumen : respaldo,
        );

  final abierto = await launchUrl(enlace, mode: LaunchMode.externalApplication);

  if (!abierto) {
    mensajero.showSnackBar(
      construirMensaje('No se pudo abrir Google Maps', tipo: TipoAviso.error),
    );
  }
}

class _Caja extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final List<Widget> hijos;

  const _Caja({required this.icono, required this.titulo, required this.hijos});

  @override
  Widget build(BuildContext context) {
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
                Icon(icono, size: 16, color: TemaApp.grisSubtitulo),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...hijos,
          ],
        ),
      ),
    );
  }
}

class _EnlaceZona extends StatelessWidget {
  final String sector;
  final VoidCallback? onVer;

  const _EnlaceZona({required this.sector, this.onVer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onVer,
      child: Row(
        children: [
          Flexible(
            child: Text(
              'Zona de $sector',
              style: TextStyle(
                fontSize: 13,
                color: TemaApp.textoOscuro,
                decoration: onVer == null ? null : TextDecoration.underline,
              ),
            ),
          ),
          if (onVer != null) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.map_outlined,
              size: 15,
              color: TemaApp.grisSubtitulo,
            ),
          ],
        ],
      ),
    );
  }
}

class _NotaBloqueada extends StatelessWidget {
  final String texto;

  const _NotaBloqueada(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 13, color: TemaApp.grisTexto),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 11.5, color: TemaApp.grisTexto),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonRuta extends StatelessWidget {
  final bool cargando;
  final VoidCallback onIr;

  const _BotonRuta({required this.cargando, required this.onIr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: cargando ? null : onIr,
          icon: cargando
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.navigation_outlined, size: 17),
          label: const Text('Cómo llegar'),
        ),
      ),
    );
  }
}

class BloqueDomicilio extends StatefulWidget {
  final String citaId;
  final Map<String, dynamic> cita;
  final bool confirmada;
  final bool finalizada;
  final Ubicacion? desde;

  const BloqueDomicilio({
    super.key,
    required this.citaId,
    required this.cita,
    required this.confirmada,
    this.finalizada = false,
    this.desde,
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

  double? get _distancia {
    final origen = widget.desde;
    if (origen == null || !origen.tienePunto) return null;

    final exacta = _exacta;
    final latitud =
        exacta?.latitud ??
        (widget.cita['latitudZonaCliente'] as num?)?.toDouble();
    final longitud =
        exacta?.longitud ??
        (widget.cita['longitudZonaCliente'] as num?)?.toDouble();
    if (latitud == null || longitud == null) return null;

    return distanciaKm(
      latitudA: origen.latitud!,
      longitudA: origen.longitud!,
      latitudB: latitud,
      longitudB: longitud,
    );
  }

  Ubicacion? get _zonaCliente {
    final latitud = (widget.cita['latitudZonaCliente'] as num?)?.toDouble();
    final longitud = (widget.cita['longitudZonaCliente'] as num?)?.toDouble();
    if (latitud == null || longitud == null) return null;

    return Ubicacion(
      barrio: (widget.cita['barrioCliente'] as String?)?.trim() ?? '',
      latitud: latitud,
      longitud: longitud,
    );
  }

  void _verZona() {
    final zona = _zonaCliente;
    if (zona == null) return;

    MapaDeZona.abrir(
      context,
      nombre: 'C',
      ubicacion: zona,
      titulo: 'Dónde tendrías que ir',
      nota: MapaDeZona.notaProfesional,
    );
  }

  String get _sector {
    final barrio = (widget.cita['barrioCliente'] as String?)?.trim() ?? '';
    return barrio.isEmpty ? 'Villavicencio' : barrio;
  }

  @override
  Widget build(BuildContext context) {
    final exacta = _exacta;
    final tieneExacta = widget.confirmada && (exacta?.estaDefinida ?? false);
    final distancia = _distancia;

    return _Caja(
      icono: Icons.directions_car_outlined,
      titulo: 'A domicilio',
      hijos: [
        if (tieneExacta)
          Text(
            exacta!.resumen,
            style: const TextStyle(fontSize: 13, color: TemaApp.textoOscuro),
          )
        else
          _EnlaceZona(
            sector: _sector,
            onVer: _zonaCliente == null ? null : _verZona,
          ),
        if (distancia != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.near_me_outlined,
                  size: 13,
                  color: TemaApp.grisTexto,
                ),
                const SizedBox(width: 5),
                Text(
                  'A ${formatearDistancia(distancia)} de donde atiendes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
              ],
            ),
          ),
        if (!widget.confirmada)
          const _NotaBloqueada(
            'Verás la dirección exacta cuando confirmes la cita',
          ),
        if (widget.confirmada && !widget.finalizada)
          _BotonRuta(
            cargando: _cargando,
            onIr: () => abrirRuta(context, destino: _exacta, respaldo: _sector),
          ),
      ],
    );
  }
}

class BloqueLocal extends StatelessWidget {
  final String? profesionalId;
  final Map<String, dynamic> cita;
  final CachePerfiles perfiles;
  final bool confirmada;
  final bool finalizada;

  const BloqueLocal({
    super.key,
    required this.profesionalId,
    required this.cita,
    required this.perfiles,
    required this.confirmada,
    this.finalizada = false,
  });

  String _sector(Ubicacion? lugar) {
    final barrio = lugar?.barrio.trim() ?? '';
    return barrio.isEmpty ? 'Villavicencio' : barrio;
  }

  String _direccion(Ubicacion? lugar) {
    final guardada = (cita['direccionProfesional'] as String?)?.trim() ?? '';
    return guardada.isEmpty ? (lugar?.resumen ?? '') : guardada;
  }

  void _verZona(BuildContext context, Ubicacion lugar) {
    MapaDeZona.abrir(
      context,
      nombre: 'M',
      ubicacion: lugar,
      titulo: 'Dónde atiende',
      nota: MapaDeZona.notaCliente,
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = profesionalId;
    if (id == null || id.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>>(
      future: perfiles.datos(id),
      builder: (context, instantanea) {
        final lugar = instantanea.hasData
            ? Ubicacion.desdeMapa(instantanea.data)
            : null;

        final direccion = _direccion(lugar);
        final sector = _sector(lugar);
        final tieneZona = lugar?.tienePunto ?? false;

        return _Caja(
          icono: Icons.storefront_outlined,
          titulo: 'En su local',
          hijos: [
            if (confirmada && direccion.isNotEmpty)
              Text(
                direccion,
                style: const TextStyle(
                  fontSize: 13,
                  color: TemaApp.textoOscuro,
                ),
              )
            else
              _EnlaceZona(
                sector: sector,
                onVer: tieneZona ? () => _verZona(context, lugar!) : null,
              ),
            if (!confirmada)
              const _NotaBloqueada(
                'Verás la dirección exacta cuando confirme la cita',
              ),
            if (confirmada && !finalizada)
              _BotonRuta(
                cargando: !instantanea.hasData,
                onIr: () => abrirRuta(
                  context,
                  destino: lugar,
                  respaldo: direccion.isEmpty ? sector : direccion,
                ),
              ),
          ],
        );
      },
    );
  }
}
