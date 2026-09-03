import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/servicio_clientes.dart';
import 'hoja_modal.dart';
import '../../data/services/servicio_resenas_clientes.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/genero.dart';
import 'avatar_persona.dart';
import 'estrellas.dart';
import 'mensaje.dart';

class HojaPerfilCliente extends StatelessWidget {
  final String clienteId;
  final String profesionalId;

  final ResumenCliente? resumenPrecargado;

  const HojaPerfilCliente({
    super.key,
    required this.clienteId,
    required this.profesionalId,
    this.resumenPrecargado,
  });

  static Future<void> abrir(
    BuildContext context, {
    required String clienteId,
    required String profesionalId,
    ResumenCliente? resumen,
  }) {
    return abrirHoja(
      context,
      hijo: HojaPerfilCliente(
        clienteId: clienteId,
        profesionalId: profesionalId,
        resumenPrecargado: resumen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.94,
      builder: (context, controlador) =>
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(clienteId)
                .get(),
            builder: (context, instantanea) {
              if (!instantanea.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final datos = instantanea.data?.data() ?? {};

              return ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                controller: controlador,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  _encabezado(datos),
                  const SizedBox(height: 18),
                  _contacto(context, datos),
                  const SizedBox(height: 20),
                  _HistorialContigo(
                    clienteId: clienteId,
                    profesionalId: profesionalId,
                    precargado: resumenPrecargado,
                  ),
                  const SizedBox(height: 20),
                  _Calificaciones(clienteId: clienteId),
                ],
              );
            },
          ),
    );
  }

  Widget _encabezado(Map<String, dynamic> datos) {
    final nombre = (datos['name'] as String?)?.trim() ?? '';
    final foto = (datos['photoUrl'] as String?)?.trim() ?? '';
    final calificacion = (datos['ratingCliente'] as num?)?.toDouble() ?? 0;
    final total = (datos['reviewsCountCliente'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        AvatarCliente(nombre: nombre, foto: foto, radio: 30),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre.isEmpty ? 'Cliente' : nombre,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                conArticuloIndefinido(generoDePerfil(datos), 'cliente'),
                style: const TextStyle(
                  fontSize: 12,
                  color: TemaApp.grisSubtitulo,
                ),
              ),
              const SizedBox(height: 4),
              if (total > 0)
                Row(
                  children: [
                    Estrellas(calificacion: calificacion, tamano: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${formatearCalificacion(calificacion)}  '
                      '(${contarResenas(total)})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TemaApp.grisSubtitulo,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Sin calificar todavía',
                  style: TextStyle(fontSize: 12, color: TemaApp.grisTexto),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contacto(BuildContext context, Map<String, dynamic> datos) {
    final telefono = (datos['phone'] as String?)?.trim() ?? '';
    final sobreMi = (datos['about'] as String?)?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sobreMi.isNotEmpty) ...[
          Text(
            sobreMi,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: TemaApp.grisSubtitulo,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (telefono.isEmpty)
          const Text(
            'No registró un teléfono de contacto',
            style: TextStyle(fontSize: 12.5, color: TemaApp.grisTexto),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrir(context, 'tel', telefono),
                  icon: const Icon(Icons.call_outlined, size: 17),
                  label: const Text('Llamar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirWhatsapp(context, telefono),
                  icon: const Icon(Icons.chat_outlined, size: 17),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: telefono));
                ScaffoldMessenger.of(context).showSnackBar(
                  construirMensaje('Teléfono copiado', tipo: TipoAviso.exito),
                );
              },
              icon: const Icon(Icons.copy, size: 15),
              label: Text(telefono, style: const TextStyle(fontSize: 12.5)),
            ),
          ),
        ],
      ],
    );
  }

  String _soloDigitos(String telefono) =>
      telefono.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> _abrir(
    BuildContext context,
    String esquema,
    String telefono,
  ) async {
    final mensajero = ScaffoldMessenger.of(context);
    final abierto = await launchUrl(
      Uri(scheme: esquema, path: _soloDigitos(telefono)),
    );

    if (!abierto) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo abrir el marcador', tipo: TipoAviso.error),
      );
    }
  }

  Future<void> _abrirWhatsapp(BuildContext context, String telefono) async {
    final mensajero = ScaffoldMessenger.of(context);
    var numero = _soloDigitos(telefono).replaceAll('+', '');
    if (numero.length == 10) numero = '57$numero';

    final abierto = await launchUrl(
      Uri.parse('https://wa.me/$numero'),
      mode: LaunchMode.externalApplication,
    );

    if (!abierto) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo abrir WhatsApp', tipo: TipoAviso.error),
      );
    }
  }
}

class _HistorialContigo extends StatelessWidget {
  final String clienteId;
  final String profesionalId;
  final ResumenCliente? precargado;

  const _HistorialContigo({
    required this.clienteId,
    required this.profesionalId,
    this.precargado,
  });

  @override
  Widget build(BuildContext context) {
    final ya = precargado;
    if (ya != null) return _contenido(ya);

    return FutureBuilder<ResumenCliente?>(
      future: ServicioClientes().resumenDeCliente(
        profesionalId: profesionalId,
        clienteId: clienteId,
      ),
      builder: (context, instantanea) {
        if (instantanea.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final resumen = instantanea.data;
        if (resumen == null) return const SizedBox.shrink();
        return _contenido(resumen);
      },
    );
  }

  Widget _contenido(ResumenCliente resumen) {
    final historial = [...resumen.visitas]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Su historial contigo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Metrica(valor: '${resumen.atendidas}', etiqueta: 'Atendidas'),
            _Metrica(
              valor: formatearPrecio(resumen.totalGastado),
              etiqueta: 'Total',
            ),
            _Metrica(valor: '${resumen.canceladas}', etiqueta: 'Canceladas'),
          ],
        ),
        const SizedBox(height: 14),
        ...historial.take(6).map((visita) => _FilaVisita(visita: visita)),
        if (historial.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'y ${historial.length - 6} más',
              style: const TextStyle(fontSize: 12, color: TemaApp.grisTexto),
            ),
          ),
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _Metrica({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: TemaApp.grisClaro,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              etiqueta,
              style: const TextStyle(fontSize: 10.5, color: TemaApp.grisTexto),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaVisita extends StatelessWidget {
  final VisitaCliente visita;

  const _FilaVisita({required this.visita});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String etiqueta;

    switch (visita.estado) {
      case 'completed':
        color = TemaApp.exito;
        etiqueta = 'Completada';
      case 'confirmed':
        color = TemaApp.info;
        etiqueta = 'Confirmada';
      case 'cancelled':
        color = TemaApp.error;
        etiqueta = 'Cancelada';
      default:
        color = TemaApp.aviso;
        etiqueta = 'Pendiente';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visita.servicio,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${formatearFechaHora(visita.fecha)} · $etiqueta',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatearPrecio(visita.precio),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Calificaciones extends StatefulWidget {
  final String clienteId;

  const _Calificaciones({required this.clienteId});

  @override
  State<_Calificaciones> createState() => _CalificacionesState();
}

class _CalificacionesState extends State<_Calificaciones> {
  static const _visiblesAlPrincipio = 3;
  bool _todas = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ResenaCliente>>(
      stream: ServicioResenasClientes().observarDeCliente(widget.clienteId),
      builder: (context, instantanea) {
        final resenas = instantanea.data ?? [];

        if (resenas.isEmpty) {
          return const Text(
            'Todavía nadie lo ha calificado',
            style: TextStyle(fontSize: 12.5, color: TemaApp.grisTexto),
          );
        }

        final mostradas = _todas
            ? resenas
            : resenas.take(_visiblesAlPrincipio).toList();
        final ocultas = resenas.length - mostradas.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lo que dicen otras manicuristas',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...mostradas.map((resena) => _Comentario(resena: resena)),
            if (ocultas > 0)
              TextButton(
                onPressed: () => setState(() => _todas = true),
                child: Text(
                  ocultas == 1
                      ? 'Ver 1 comentario más'
                      : 'Ver $ocultas comentarios más',
                ),
              )
            else if (_todas && resenas.length > _visiblesAlPrincipio)
              TextButton(
                onPressed: () => setState(() => _todas = false),
                child: const Text('Ver menos'),
              ),
          ],
        );
      },
    );
  }
}

class _Comentario extends StatelessWidget {
  final ResenaCliente resena;

  const _Comentario({required this.resena});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              Estrellas(
                calificacion: resena.calificacion.toDouble(),
                tamano: 13,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resena.profesionalNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: TemaApp.grisSubtitulo,
                  ),
                ),
              ),
              if (resena.fecha != null)
                Text(
                  formatearFecha(resena.fecha!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaApp.grisTexto,
                  ),
                ),
            ],
          ),
          if (resena.comentario.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              resena.comentario,
              style: const TextStyle(
                fontSize: 12.5,
                color: TemaApp.grisSubtitulo,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
