import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import '../../utils/novedades.dart';
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
      hijo: _HojaNovedades(novedades: novedades),
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

  const _HojaNovedades({required this.novedades});

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
  final VoidCallback onTocar;

  const _Fila({required this.novedad, required this.onTocar});

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
      TipoNovedad.confirmada => (
        icono: Icons.check_circle_outline,
        color: TemaApp.exito,
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
                  Text(
                    novedad.titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    novedad.detalle,
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
