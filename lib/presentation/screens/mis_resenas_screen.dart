import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';
import '../../data/models/resena.dart';
import '../../data/services/servicio_resenas.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../widgets/confirmacion.dart';
import '../widgets/hoja_calificar.dart';
import '../widgets/hoja_modal.dart';
import '../widgets/mensaje.dart';
import '../widgets/hoja_responder_resena.dart';
import '../widgets/resenas.dart';

class MisResenasScreen extends StatelessWidget {
  final String? profesionalId;

  const MisResenasScreen({super.key, this.profesionalId});

  bool get _esProfesional => profesionalId != null;

  @override
  Widget build(BuildContext context) {
    final servicio = ServicioResenas();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final puedeResponder = _esProfesional && profesionalId == uid;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: TemaApp.grisClaro,
        appBar: AppBar(
          title: Text(
            _esProfesional ? 'Reseñas recibidas' : 'Mis Reseñas',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        body: StreamBuilder<List<Resena>>(
          stream: _esProfesional
              ? servicio.observarDeProfesional(profesionalId!)
              : servicio.observarDeCliente(uid),
          builder: (context, instantanea) {
            if (instantanea.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (instantanea.hasError) {
              return const Center(
                child: Text(
                  'No se pudieron cargar las reseñas',
                  style: TextStyle(color: TemaApp.grisTexto),
                ),
              );
            }

            final resenas = instantanea.data ?? [];
            if (resenas.isEmpty) return _vacio();

            final resumen = ResumenCalificaciones.desde(resenas);
            final conFotos = resenas.where((r) => r.tieneFotos).toList();
            final conRespuesta = resenas
                .where((r) => r.tieneRespuesta)
                .toList();

            final perspectiva = _esProfesional
                ? PerspectivaResena.recibidas
                : PerspectivaResena.escritas;

            void responder(Resena resena) => HojaResponderResena.abrir(
              context,
              profesionalId: profesionalId!,
              resena: resena,
            );

            void editar(Resena resena) => abrirHoja(
              context,
              hijo: HojaCalificar(
                profesionalId: resena.profesionalId,
                profesionalNombre: resena.profesionalNombre,
                profesionalFoto: resena.profesionalFoto,
                citaId: resena.id,
                clienteId: resena.clienteId,
                clienteNombre: resena.clienteNombre,
                clienteFoto: resena.clienteFoto,
                servicio: resena.servicio,
                existente: resena,
              ),
            );

            Future<void> eliminar(Resena resena) async {
              final seguro = await confirmar(
                context,
                titulo: 'Eliminar tu reseña',
                mensaje:
                    'Se borra tu comentario y tu nota deja de contar en el '
                    'promedio de ${resena.profesionalNombre}.',
                siga: 'Eliminar',
                destructiva: true,
              );
              if (!seguro || !context.mounted) return;

              final mensajero = ScaffoldMessenger.of(context);

              try {
                await servicio.eliminar(
                  profesionalId: resena.profesionalId,
                  citaId: resena.id,
                );
                mensajero.showSnackBar(
                  construirMensaje('Reseña eliminada', tipo: TipoAviso.exito),
                );
              } catch (_) {
                mensajero.showSnackBar(
                  construirMensaje(
                    'No se pudo eliminar la reseña',
                    tipo: TipoAviso.error,
                  ),
                );
              }
            }

            final mias = !_esProfesional;

            return Column(
              children: [
                ResumenResenas(
                  resumen: resumen,
                  subtitulo: _esProfesional
                      ? '${contarResenas(resumen.total)} recibidas'
                      : '${contarResenas(resumen.total)} escritas',
                ),
                Container(
                  color: TemaApp.blanco,
                  child: TabBar(
                    tabs: [
                      const Tab(text: 'Todas'),
                      const Tab(text: 'Con fotos'),
                      Tab(text: _esProfesional ? 'Respondidas' : 'Respuestas'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListaResenas(
                        resenas: resenas,
                        perspectiva: perspectiva,
                        onResponder: puedeResponder ? responder : null,
                        onEditar: mias ? editar : null,
                        onEliminar: mias ? eliminar : null,
                      ),
                      ListaResenas(
                        resenas: conFotos,
                        perspectiva: perspectiva,
                        textoVacio: _esProfesional
                            ? 'Ninguna reseña trae fotos todavía'
                            : 'No has subido fotos en tus reseñas',
                        onResponder: puedeResponder ? responder : null,
                        onEditar: mias ? editar : null,
                        onEliminar: mias ? eliminar : null,
                      ),
                      ListaResenas(
                        resenas: conRespuesta,
                        perspectiva: perspectiva,
                        textoVacio: _esProfesional
                            ? 'Aún no has respondido ninguna reseña'
                            : 'Todavía no te han respondido',
                        onResponder: puedeResponder ? responder : null,
                        onEditar: mias ? editar : null,
                        onEliminar: mias ? eliminar : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _vacio() {
    return EstadoVacio(
      icono: Icons.star_border,
      titulo: _esProfesional
          ? 'Aún no tienes reseñas'
          : 'Aún no has dejado reseñas',
      detalle: _esProfesional
          ? 'Aparecerán cuando tus clientes califiquen sus citas'
          : 'Podrás calificar cuando termine una cita',
    );
  }
}
