import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/services/cache_perfiles.dart';
import '../../data/services/servicio_chat.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../widgets/avatar_persona.dart';
import '../widgets/estado_vacio.dart';
import 'chat_screen.dart';
import '../../utils/margenes.dart';

class BandejaChatsScreen extends StatefulWidget {
  final bool esProfesional;

  const BandejaChatsScreen({super.key, required this.esProfesional});

  static Future<void> abrir(
    BuildContext context, {
    required bool esProfesional,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BandejaChatsScreen(esProfesional: esProfesional),
      ),
    );
  }

  @override
  State<BandejaChatsScreen> createState() => _BandejaChatsScreenState();
}

class _BandejaChatsScreenState extends State<BandejaChatsScreen> {
  final _servicio = ServicioChat();
  final _perfiles = CachePerfiles();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late final Stream<List<ResumenChat>> _conversaciones = _servicio
      .observarConversaciones(uid: _uid, esProfesional: widget.esProfesional);

  Future<void> _abrir(ResumenChat resumen) async {
    final otroId = resumen.otroId(esProfesional: widget.esProfesional);
    final perfil = await _perfiles.resumen(otroId);

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          citaId: resumen.citaId,
          clienteId: resumen.clienteId,
          profesionalId: resumen.profesionalId,
          servicio: resumen.servicio,
          otroNombre: perfil.nombre.isEmpty
              ? (widget.esProfesional ? 'Cliente' : 'Manicurista')
              : perfil.nombre,
          otraFoto: perfil.foto,
          esProfesional: widget.esProfesional,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        title: const Text(
          'Mensajes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<ResumenChat>>(
        stream: _conversaciones,
        builder: (context, instantanea) {
          if (instantanea.hasError) {
            return const EstadoVacio(
              icono: Icons.cloud_off_outlined,
              titulo: 'No se pudieron cargar las conversaciones',
            );
          }

          if (!instantanea.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversaciones = instantanea.data!;
          if (conversaciones.isEmpty) {
            return EstadoVacio(
              icono: Icons.forum_outlined,
              titulo: 'Todavía no tienes conversaciones',
              detalle: widget.esProfesional
                  ? 'El chat se abre cuando aceptas una cita'
                  : 'Podrás escribirle cuando confirme tu cita',
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              0,
              8,
              0,
              margenInferior(context, base: 8),
            ),
            itemCount: conversaciones.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, indent: 76, color: TemaApp.grisBorde),
            itemBuilder: (context, indice) => _Fila(
              resumen: conversaciones[indice],
              perfiles: _perfiles,
              esProfesional: widget.esProfesional,
              onTocar: () => _abrir(conversaciones[indice]),
            ),
          );
        },
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final ResumenChat resumen;
  final CachePerfiles perfiles;
  final bool esProfesional;
  final VoidCallback onTocar;

  const _Fila({
    required this.resumen,
    required this.perfiles,
    required this.esProfesional,
    required this.onTocar,
  });

  @override
  Widget build(BuildContext context) {
    final otroId = resumen.otroId(esProfesional: esProfesional);
    final sinLeer = resumen.sinLeer;

    return FutureBuilder<({String nombre, String? foto})>(
      future: perfiles.resumen(otroId),
      builder: (context, instantanea) {
        final perfil = instantanea.data;
        final nombre = (perfil?.nombre.trim().isNotEmpty ?? false)
            ? perfil!.nombre
            : (esProfesional ? 'Cliente' : 'Manicurista');

        return ListTile(
          onTap: onTocar,
          tileColor: TemaApp.blanco,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: AvatarPersona(
            nombre: nombre,
            foto: perfil?.foto,
            radio: 24,
            inicialPorDefecto: esProfesional ? 'C' : 'M',
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: sinLeer > 0 ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
              if (resumen.ultimoEn != null)
                Text(
                  formatearFecha(resumen.ultimoEn!),
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaApp.grisTexto,
                  ),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resumen.servicio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: TemaApp.grisTexto,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        resumen.ultimoEsMio
                            ? 'Tú: ${resumen.ultimoMensaje}'
                            : resumen.ultimoMensaje,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: sinLeer > 0
                              ? TemaApp.textoOscuro
                              : TemaApp.grisSubtitulo,
                          fontWeight: sinLeer > 0
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (sinLeer > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: TemaApp.rosa,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sinLeer > 9 ? '9+' : '$sinLeer',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: TemaApp.blanco,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
