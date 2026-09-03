import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/estado_vacio.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../widgets/hoja_modal.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../widgets/mensaje.dart';
import '../../utils/margenes.dart';
import '../../utils/validaciones.dart';

class ProfessionalServicesScreen extends StatelessWidget {
  final bool embebida;

  const ProfessionalServicesScreen({super.key, this.embebida = false});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Builder(
        builder: (contexto) => FloatingActionButton.extended(
          onPressed: () => _showServiceDialog(contexto, null, null),
          backgroundColor: TemaApp.negro,
          foregroundColor: TemaApp.blanco,
          icon: const Icon(Icons.add),
          label: const Text('Agregar servicio'),
        ),
      ),
      backgroundColor: TemaApp.grisClaro,
      appBar: embebida
          ? null
          : AppBar(
              backgroundColor: TemaApp.blanco,
              elevation: 0,
              title: const Text(
                'Mis Servicios',
                style: TextStyle(
                  color: TemaApp.textoOscuro,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('services')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return EstadoVacio(
              icono: Icons.spa_outlined,
              titulo: 'Aún no tienes servicios',
              detalle: 'Sin servicios nadie puede reservarte una cita',
              accion: 'Crear servicio',
              onAccion: () => _showServiceDialog(context, null, null),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: _MiniaturaServicio(url: data['imageUrl']),
                  title: Text(
                    data['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((data['description'] as String?)?.trim().isNotEmpty ??
                          false) ...[
                        Text(
                          data['description'].toString().trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TemaApp.grisSubtitulo,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: TemaApp.grisTexto,
                          ),
                          Text(
                            '  ${formatearDuracionCorta((data['duration'] as num?)?.toInt() ?? 0)} aprox.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: TemaApp.grisSubtitulo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatearPrecio(data['price'] as num?),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: TemaApp.textoOscuro,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showServiceDialog(context, doc.id, data);
                          } else if (value == 'delete') {
                            _deleteService(context, doc.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteService(BuildContext context, String serviceId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: const Text(
          'Dejará de aparecer en tu perfil. Las citas ya agendadas con este '
          'servicio no se modifican.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: TemaApp.error),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('services')
        .doc(serviceId)
        .delete();
  }

  void _showServiceDialog(
    BuildContext context,
    String? serviceId,
    Map<String, dynamic>? existing,
  ) {
    abrirHoja(
      context,
      hijo: _ServiceFormSheet(
        uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        serviceId: serviceId,
        existing: existing,
      ),
    );
  }
}

class _ServiceFormSheet extends StatefulWidget {
  final String uid;
  final String? serviceId;
  final Map<String, dynamic>? existing;

  const _ServiceFormSheet({required this.uid, this.serviceId, this.existing});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  final _subida = ServicioSubidaImagenes();
  bool _isLoading = false;
  bool _subiendoImagen = false;
  String? _imagenUrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?['name'] ?? '');
    _descCtrl = TextEditingController(
      text: widget.existing?['description'] ?? '',
    );
    _priceCtrl = TextEditingController(
      text: const FormatoPrecio()
          .formatEditUpdate(
            TextEditingValue.empty,
            TextEditingValue(
              text:
                  (widget.existing?['price'] as num?)?.toInt().toString() ?? '',
            ),
          )
          .text,
    );
    _durationCtrl = TextEditingController(
      text: widget.existing?['duration']?.toString() ?? '',
    );
    _imagenUrl = widget.existing?['imageUrl'];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Widget _selectorImagen() {
    return GestureDetector(
      onTap: _subiendoImagen ? null : _elegirImagen,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: TemaApp.grisClaro,
          borderRadius: BorderRadius.circular(16),
          image: _imagenUrl == null
              ? null
              : DecorationImage(
                  image: NetworkImage(
                    ServicioSubidaImagenes.miniatura(_imagenUrl!, ancho: 300),
                  ),
                  fit: BoxFit.cover,
                ),
        ),
        child: _subiendoImagen
            ? const Center(child: CircularProgressIndicator())
            : _imagenUrl != null
            ? null
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: TemaApp.textoOscuro),
                  SizedBox(height: 6),
                  Text(
                    'Foto del servicio',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: TemaApp.textoOscuro),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _elegirImagen() async {
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

      setState(() => _subiendoImagen = true);
      final imagen = await _subida.subir(archivo);
      if (mounted) setState(() => _imagenUrl = imagen.url);
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo subir la imagen', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _subiendoImagen = false);
  }

  String? get _duracionEnPalabras {
    final minutos = int.tryParse(_durationCtrl.text.trim()) ?? 0;
    if (minutos < 60) return null;
    return formatearDuracion(minutos);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final mensajero = ScaffoldMessenger.of(context);

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': int.tryParse(soloDigitos(_priceCtrl.text)) ?? 0,
      'duration': int.tryParse(_durationCtrl.text.trim()) ?? 0,
      'imageUrl': _imagenUrl,
    };

    if (widget.serviceId == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('services');

    try {
      if (widget.serviceId != null) {
        await ref.doc(widget.serviceId).update(data);
      } else {
        await ref.add(data);
      }
      if (mounted) Navigator.pop(context);
      return;
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo guardar el servicio',
          tipo: TipoAviso.error,
        ),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: margenHoja(context, base: 0),
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.serviceId != null ? 'Editar Servicio' : 'Nuevo Servicio',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(child: _selectorImagen()),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del servicio',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: const [FormatoPrecio()],
                    validator: validarPrecio,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _durationCtrl,
                    decoration: InputDecoration(
                      labelText: 'Duración estimada (min)',
                      helperText: _duracionEnPalabras,
                      helperStyle: const TextStyle(
                        fontSize: 11,
                        color: TemaApp.textoOscuro,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    validator: validarDuracion,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MiniaturaServicio extends StatelessWidget {
  final String? url;

  const _MiniaturaServicio({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: TemaApp.grisClaro,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.spa, color: TemaApp.textoOscuro),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        ServicioSubidaImagenes.miniatura(url!, ancho: 200),
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Container(width: 48, height: 48, color: TemaApp.grisBorde),
      ),
    );
  }
}
