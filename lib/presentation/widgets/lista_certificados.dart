import 'package:flutter/material.dart';

import 'estado_vacio.dart';
import '../../data/services/servicio_certificados.dart';
import 'hoja_modal.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import 'mensaje.dart';
import 'visor_fotos.dart';
import '../../utils/margenes.dart';
import '../../utils/validaciones.dart';

class ListaCertificados extends StatelessWidget {
  final String profesionalId;
  final bool editable;

  const ListaCertificados({
    super.key,
    required this.profesionalId,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    final servicio = ServicioCertificados();

    return StreamBuilder<List<Certificado>>(
      stream: servicio.observar(profesionalId),
      builder: (context, instantanea) {
        if (instantanea.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final certificados = instantanea.data ?? [];

        if (certificados.isEmpty) {
          return EstadoVacio(
            compacto: true,
            icono: Icons.workspace_premium_outlined,
            titulo: editable
                ? 'Agrega tus cursos y certificaciones'
                : 'Aún no ha registrado certificaciones',
            detalle: editable
                ? 'Un perfil con formación genera más confianza'
                : null,
            accion: editable ? 'Agregar certificado' : null,
            onAccion: editable
                ? () => abrirFormulario(context, profesionalId)
                : null,
          );
        }

        return Column(
          children: [
            ...certificados.map(
              (certificado) => _Fila(
                certificado: certificado,
                editable: editable,
                onEditar: () => abrirFormulario(
                  context,
                  profesionalId,
                  certificado: certificado,
                ),
                onEliminar: () => _confirmarEliminar(
                  context,
                  servicio,
                  profesionalId,
                  certificado,
                ),
              ),
            ),
            if (editable) ...[
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => abrirFormulario(context, profesionalId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar certificado'),
              ),
            ],
          ],
        );
      },
    );
  }

  static void abrirFormulario(
    BuildContext context,
    String uid, {
    Certificado? certificado,
  }) {
    abrirHoja(
      context,
      hijo: _Formulario(uid: uid, certificado: certificado),
    );
  }
}

Future<void> _confirmarEliminar(
  BuildContext context,
  ServicioCertificados servicio,
  String profesionalId,
  Certificado certificado,
) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogo) => AlertDialog(
      title: const Text('Eliminar certificado'),
      content: Text(
        '¿Quieres eliminar "${certificado.titulo}"? No se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogo, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogo, true),
          child: const Text('Eliminar', style: TextStyle(color: TemaApp.error)),
        ),
      ],
    ),
  );

  if (confirmado != true || !context.mounted) return;

  final mensajero = ScaffoldMessenger.of(context);
  try {
    await servicio.eliminar(uid: profesionalId, id: certificado.id);
  } catch (_) {
    mensajero.showSnackBar(
      construirMensaje(
        'No se pudo eliminar el certificado',
        tipo: TipoAviso.error,
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final Certificado certificado;
  final bool editable;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _Fila({
    required this.certificado,
    required this.editable,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TemaApp.grisClaro,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (certificado.tieneImagen)
            GestureDetector(
              onTap: () => _verImagen(context, certificado),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ServicioSubidaImagenes.miniatura(
                    certificado.imagenUrl!,
                    ancho: 140,
                  ),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.workspace_premium_outlined,
                    color: TemaApp.textoOscuro,
                    size: 22,
                  ),
                ),
              ),
            )
          else
            const Icon(
              Icons.workspace_premium_outlined,
              color: TemaApp.textoOscuro,
              size: 22,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificado.titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (certificado.institucion.isNotEmpty)
                  Text(
                    certificado.institucion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TemaApp.grisSubtitulo,
                    ),
                  ),
                if (certificado.anio.isNotEmpty)
                  Text(
                    certificado.anio,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaApp.grisTexto,
                    ),
                  ),
              ],
            ),
          ),
          if (editable)
            PopupMenuButton<String>(
              onSelected: (valor) =>
                  valor == 'editar' ? onEditar() : onEliminar(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  final String uid;
  final Certificado? certificado;

  const _Formulario({required this.uid, this.certificado});

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  final _servicio = ServicioCertificados();
  final _subida = ServicioSubidaImagenes();
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _institucionCtrl;
  late final TextEditingController _anioCtrl;

  String? _imagenUrl;
  bool _guardando = false;
  bool _subiendo = false;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.certificado?.titulo ?? '');
    _institucionCtrl = TextEditingController(
      text: widget.certificado?.institucion ?? '',
    );
    _anioCtrl = TextEditingController(text: widget.certificado?.anio ?? '');
    _imagenUrl = widget.certificado?.imagenUrl;
  }

  Future<void> _cambiarImagen() async {
    final mensajero = ScaffoldMessenger.of(context);

    if (!_subida.estaConfigurado) {
      mensajero.showSnackBar(
        construirMensaje(
          'La subida de imágenes no está configurada',
          tipo: TipoAviso.aviso,
        ),
      );
      return;
    }

    try {
      final archivo = await _subida.elegirImagen(desdeCamara: false);
      if (archivo == null) return;

      setState(() => _subiendo = true);
      final imagen = await _subida.subir(archivo);
      if (mounted) setState(() => _imagenUrl = imagen.url);
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo subir la imagen', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _subiendo = false);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _institucionCtrl.dispose();
    _anioCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      if (widget.certificado == null) {
        await _servicio.agregar(
          uid: widget.uid,
          titulo: _tituloCtrl.text,
          institucion: _institucionCtrl.text,
          anio: _anioCtrl.text,
          imagenUrl: _imagenUrl,
        );
      } else {
        await _servicio.actualizar(
          uid: widget.uid,
          id: widget.certificado!.id,
          titulo: _tituloCtrl.text,
          institucion: _institucionCtrl.text,
          anio: _anioCtrl.text,
          imagenUrl: _imagenUrl,
        );
      }
      navegador.pop();
      return;
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo guardar el certificado',
          tipo: TipoAviso.error,
        ),
      );
    }

    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: margenHoja(context, base: 24),
      ),
      child: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.certificado == null
                  ? 'Nuevo certificado'
                  : 'Editar certificado',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tus clientes podrán verlo en tu perfil',
              style: TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validarTituloCertificado,
              decoration: const InputDecoration(
                labelText: 'Título o curso',
                hintText: 'Técnico en Manicura Profesional',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _institucionCtrl,
              textCapitalization: TextCapitalization.words,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (valor) =>
                  validarTextoOpcional(valor, maximo: maximoTituloCertificado),
              decoration: const InputDecoration(
                labelText: 'Institución',
                hintText: 'Instituto de Belleza Integral',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _anioCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: validarAnio,
              decoration: const InputDecoration(
                labelText: 'Año',
                hintText: '2022',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            _SelectorImagen(
              url: _imagenUrl,
              subiendo: _subiendo,
              onElegir: _cambiarImagen,
              onQuitar: () => setState(() => _imagenUrl = null),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                ),
                child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _verImagen(BuildContext context, Certificado certificado) {
  VisorFotos.abrir(context, fotos: [certificado.imagenUrl!]);
}

class _SelectorImagen extends StatelessWidget {
  final String? url;
  final bool subiendo;
  final VoidCallback onElegir;
  final VoidCallback onQuitar;

  const _SelectorImagen({
    required this.url,
    required this.subiendo,
    required this.onElegir,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final tiene = url != null && url!.isNotEmpty;

    return Row(
      children: [
        GestureDetector(
          onTap: subiendo ? null : onElegir,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: TemaApp.grisClaro,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TemaApp.grisBorde),
            ),
            clipBehavior: Clip.antiAlias,
            child: subiendo
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : tiene
                ? Image.network(
                    ServicioSubidaImagenes.miniatura(url!, ancho: 200),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  )
                : const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: TemaApp.grisTexto,
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Foto del certificado',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              const Text(
                'Opcional. Una foto del diploma da más confianza.',
                style: TextStyle(fontSize: 11.5, color: TemaApp.grisSubtitulo),
              ),
              if (tiene && !subiendo)
                TextButton(
                  onPressed: onQuitar,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    foregroundColor: TemaApp.error,
                  ),
                  child: const Text('Quitar foto'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
