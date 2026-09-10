import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/services/cache_perfiles.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import '../../utils/novedades.dart';
import '../../utils/texto_aviso.dart';
import 'estado_vacio.dart';
import 'hoja_modal.dart';

class BotonNovedades extends StatefulWidget {
  final String uid;
  final bool esProfesional;
  final VoidCallback? onVerCitas;

  const BotonNovedades({
    super.key,
    required this.uid,
    required this.esProfesional,
    this.onVerCitas,
  });

  @override
  State<BotonNovedades> createState() => _BotonNovedadesState();
}

class _BotonNovedadesState extends State<BotonNovedades> {
  final _perfiles = CachePerfiles();

  DateTime? _vistoAqui;

  DocumentReference<Map<String, dynamic>> get _perfil =>
      FirebaseFirestore.instance.collection('users').doc(widget.uid);

  Stream<QuerySnapshot<Map<String, dynamic>>> get _citas => FirebaseFirestore
      .instance
      .collection('bookings')
      .where(
        widget.esProfesional ? 'professionalId' : 'clientId',
        isEqualTo: widget.uid,
      )
      .snapshots();

  DateTime? _ultimaVista(DateTime? delServidor) {
    final local = _vistoAqui;
    if (local == null) return delServidor;
    if (delServidor == null) return local;

    return delServidor.isAfter(local) ? delServidor : local;
  }

  Future<void> _abrir(List<Novedad> novedades) async {
    setState(() => _vistoAqui = DateTime.now());

    _perfil.set({
      'novedadesVistasEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final verCitas = await abrirHoja<bool>(
      context,
      hijo: _HojaNovedades(
        novedades: novedades,
        perfiles: _perfiles,
        esProfesional: widget.esProfesional,
      ),
    );

    if (verCitas == true) widget.onVerCitas?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _citas,
      builder: (context, citas) {
        final novedades = novedadesDeCitas(
          citas.data?.docs ?? const [],
          esProfesional: widget.esProfesional,
        );

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _perfil.snapshots(),
          builder: (context, perfil) {
            final delServidor =
                (perfil.data?.data()?['novedadesVistasEn'] as Timestamp?)
                    ?.toDate();

            final sinVer = contarSinVer(novedades, _ultimaVista(delServidor));

            return IconButton(
              tooltip: 'Novedades',
              onPressed: () => _abrir(novedades),
              icon: Badge.count(
                count: sinVer,
                isLabelVisible: sinVer > 0,
                backgroundColor: TemaApp.rosa,
                child: Icon(
                  sinVer > 0
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _HojaNovedades extends StatelessWidget {
  final List<Novedad> novedades;
  final CachePerfiles perfiles;
  final bool esProfesional;

  const _HojaNovedades({
    required this.novedades,
    required this.perfiles,
    required this.esProfesional,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, margenHoja(context, base: 16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_none, size: 20),
              SizedBox(width: 8),
              Text(
                'Novedades',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Lo que pasó con tus citas',
            style: TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
          ),
          const SizedBox(height: 12),
          if (novedades.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: EstadoVacio(
                icono: Icons.notifications_off_outlined,
                titulo: 'Sin novedades',
                detalle: 'Aquí verás los movimientos de tus citas',
                compacto: true,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: novedades.length,
                separatorBuilder: (_, _) => const Divider(height: 18),
                itemBuilder: (_, indice) => _Fila(
                  novedad: novedades[indice],
                  perfiles: perfiles,
                  esProfesional: esProfesional,
                  onTocar: () => Navigator.pop(context, true),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final Novedad novedad;
  final CachePerfiles perfiles;
  final bool esProfesional;
  final VoidCallback onTocar;

  const _Fila({
    required this.novedad,
    required this.perfiles,
    required this.esProfesional,
    required this.onTocar,
  });

  ({IconData icono, Color color}) get _aspecto {
    return switch (novedad.tipo) {
      TipoNovedad.solicitudNueva => (
        icono: Icons.mark_email_unread_outlined,
        color: TemaApp.aviso,
      ),
      TipoNovedad.citaNueva => (
        icono: Icons.event_available_outlined,
        color: TemaApp.exito,
      ),
      TipoNovedad.cambioPedido => (
        icono: Icons.edit_calendar_outlined,
        color: TemaApp.aviso,
      ),
      TipoNovedad.cambioRechazado => (
        icono: Icons.event_repeat_outlined,
        color: TemaApp.grisTexto,
      ),
      TipoNovedad.confirmada => (
        icono: Icons.check_circle_outline,
        color: TemaApp.exito,
      ),
      TipoNovedad.completada => (
        icono: Icons.star_border,
        color: TemaApp.aviso,
      ),
      TipoNovedad.movida => (
        icono: Icons.edit_calendar_outlined,
        color: TemaApp.info,
      ),
      TipoNovedad.cancelada => (
        icono: Icons.event_busy_outlined,
        color: TemaApp.error,
      ),
      TipoNovedad.vencida => (
        icono: Icons.running_with_errors_outlined,
        color: TemaApp.grisTexto,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final aspecto = _aspecto;

    return InkWell(
      onTap: onTocar,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: aspecto.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(aspecto.icono, size: 17, color: aspecto.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Titulo(
                    novedad: novedad,
                    perfiles: perfiles,
                    esProfesional: esProfesional,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    avisoDeNovedad(
                      novedad,
                      esProfesional: esProfesional,
                    ).cuerpo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              hace(novedad.momento),
              style: const TextStyle(fontSize: 11, color: TemaApp.grisTexto),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  final Novedad novedad;
  final CachePerfiles perfiles;
  final bool esProfesional;

  const _Titulo({
    required this.novedad,
    required this.perfiles,
    required this.esProfesional,
  });

  static const _estilo = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    if (novedad.plantilla == null || novedad.personaId.isEmpty) {
      return Text(novedad.titulo, style: _estilo);
    }

    return FutureBuilder<({String nombre, String? foto})>(
      future: perfiles.resumen(novedad.personaId),
      builder: (context, instantanea) {
        final nombre = instantanea.data?.nombre;

        return Text(novedad.tituloCon(nombre), style: _estilo);
      },
    );
  }
}
