import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';
import '../../data/services/servicio_chat.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/margenes.dart';
import '../widgets/mensaje.dart';
import '../../data/services/servicio_notificaciones.dart';

class ChatScreen extends StatefulWidget {
  final String citaId;
  final String clienteId;
  final String profesionalId;
  final String servicio;
  final String otroNombre;
  final String? otraFoto;
  final bool esProfesional;

  const ChatScreen({
    super.key,
    required this.citaId,
    required this.clienteId,
    required this.profesionalId,
    required this.servicio,
    required this.otroNombre,
    required this.esProfesional,
    this.otraFoto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _servicio = ServicioChat();
  final _texto = TextEditingController();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _enviando = false;

  Stream<List<Mensaje>>? _mensajes;
  bool _falloLaPreparacion = false;
  String? _ultimoMensajeIdVisto;

  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _cita =
      FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.citaId)
          .snapshots();

  @override
  void initState() {
    super.initState();
    ServicioNotificaciones.instancia.chatAbierto = widget.citaId;
    _prepararChat();
  }

  Future<void> _prepararChat() async {
    if (mounted) {
      setState(() {
        _mensajes = null;
        _falloLaPreparacion = false;
      });
    }

    try {
      await _servicio.asegurarChat(
        citaId: widget.citaId,
        clienteId: widget.clienteId,
        profesionalId: widget.profesionalId,
        servicio: widget.servicio,
      );

      if (!mounted) return;
      setState(() => _mensajes = _servicio.observarMensajes(widget.citaId));
    } catch (_) {
      if (mounted) setState(() => _falloLaPreparacion = true);
    }
  }

  @override
  void dispose() {
    if (ServicioNotificaciones.instancia.chatAbierto == widget.citaId) {
      ServicioNotificaciones.instancia.chatAbierto = null;
    }
    _texto.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    final mensajero = ScaffoldMessenger.of(context);
    _texto.clear();

    try {
      await _servicio.enviar(
        citaId: widget.citaId,
        autorId: _uid,
        clienteId: widget.clienteId,
        profesionalId: widget.profesionalId,
        servicio: widget.servicio,
        texto: texto,
        esProfesional: widget.esProfesional,
      );
    } catch (_) {
      _texto.text = texto;
      mensajero.showSnackBar(
        construirMensaje('No se pudo enviar el mensaje', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final foto = widget.otraFoto?.trim() ?? '';

    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: TemaApp.grisClaro,
              backgroundImage: foto.isEmpty
                  ? null
                  : NetworkImage(
                      ServicioSubidaImagenes.miniatura(foto, ancho: 100),
                    ),
              child: foto.isEmpty
                  ? Text(
                      widget.otroNombre.isEmpty
                          ? '?'
                          : widget.otroNombre[0].toUpperCase(),
                      style: const TextStyle(
                        color: TemaApp.textoOscuro,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otroNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.servicio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _conversacion()),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _cita,
            builder: (context, instantanea) {
              final estado = instantanea.data?.data()?['status'];
              final cerrada = estado == 'completed' || estado == 'cancelled';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cerrada) _NotaCitaCerrada(estado: estado),
                  _redactor(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _conversacion() {
    if (_falloLaPreparacion) return _error();

    final mensajes = _mensajes;
    if (mensajes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Mensaje>>(
      stream: mensajes,
      builder: (context, instantanea) {
        if (instantanea.hasError) return _error();

        if (!instantanea.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lista = instantanea.data!;
        if (lista.isEmpty) return _vacio();

        if (lista.first.id != _ultimoMensajeIdVisto) {
          _ultimoMensajeIdVisto = lista.first.id;
          _servicio.marcarLeido(
            citaId: widget.citaId,
            clienteId: widget.clienteId,
            profesionalId: widget.profesionalId,
            esProfesional: widget.esProfesional,
          );
        }

        return ListView.builder(
          reverse: true,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          itemCount: lista.length,
          itemBuilder: (context, indice) => _Burbuja(
            mensaje: lista[indice],
            propio: lista[indice].autorId == _uid,
          ),
        );
      },
    );
  }

  Widget _error() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: TemaApp.grisTexto,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo abrir la conversación',
              style: TextStyle(color: TemaApp.grisTexto, fontSize: 15),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _prepararChat,
              icon: const Icon(Icons.refresh, size: 17),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vacio() {
    return EstadoVacio(
      compacto: true,
      icono: Icons.chat_bubble_outline,
      titulo: 'Todavía no hay mensajes',
      detalle: widget.esProfesional
          ? 'Escríbele a ${widget.otroNombre} sobre esta cita'
          : 'Pregúntale lo que necesites sobre tu cita',
    );
  }

  Widget _redactor() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, margenInferior(context, base: 8)),
      decoration: const BoxDecoration(
        color: TemaApp.blanco,
        border: Border(top: BorderSide(color: TemaApp.grisBorde)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _texto,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _enviar(),
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 23,
            backgroundColor: TemaApp.negro,
            child: IconButton(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TemaApp.blanco,
                      ),
                    )
                  : const Icon(Icons.send, size: 19, color: TemaApp.blanco),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final Mensaje mensaje;
  final bool propio;

  const _Burbuja({required this.mensaje, required this.propio});

  @override
  Widget build(BuildContext context) {
    if (mensaje.esAviso) return _Aviso(mensaje: mensaje);

    return Align(
      alignment: propio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: propio ? TemaApp.negro : TemaApp.blanco,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(propio ? 16 : 4),
            bottomRight: Radius.circular(propio ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mensaje.texto,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: propio ? TemaApp.blanco : TemaApp.textoOscuro,
              ),
            ),
            if (mensaje.fecha != null) ...[
              const SizedBox(height: 3),
              Text(
                formatearHoraDeFecha(mensaje.fecha!),
                style: TextStyle(
                  fontSize: 10,
                  color: propio ? Colors.white70 : TemaApp.grisTexto,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final Mensaje mensaje;

  const _Aviso({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TemaApp.avisoSuave,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit_calendar_outlined,
                        size: 15,
                        color: TemaApp.aviso,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          mensaje.texto,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: TemaApp.aviso,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (mensaje.fecha != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      formatearHoraDeFecha(mensaje.fecha!),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: TemaApp.grisTexto,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotaCitaCerrada extends StatelessWidget {
  final String? estado;

  const _NotaCitaCerrada({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      color: TemaApp.grisClaro,
      child: Row(
        children: [
          const Icon(Icons.history, size: 15, color: TemaApp.grisTexto),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              estado == 'cancelled'
                  ? 'Esta cita se canceló, pero pueden seguir escribiéndose.'
                  : 'Esta cita ya terminó, pero pueden seguir escribiéndose.',
              style: const TextStyle(
                fontSize: 11.5,
                color: TemaApp.grisSubtitulo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
