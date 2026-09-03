import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/ubicacion.dart';
import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/sesion.dart';
import '../widgets/cabecera_pantalla.dart';
import '../widgets/lista_certificados.dart';
import '../widgets/redes_sociales.dart';
import '../widgets/visor_fotos.dart';
import 'configuracion_screen.dart';
import 'editar_perfil_profesional_screen.dart';
import 'mis_resenas_screen.dart';
import 'professional_clients_screen.dart';
import 'professional_detail_screen.dart';
import 'professional_home.dart';
import 'qr_perfil_screen.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  final ValueChanged<DestinoProfesional>? onIr;

  const ProfessionalProfileScreen({super.key, this.onIr});

  @override
  State<ProfessionalProfileScreen> createState() =>
      _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _seccion = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_uid)
              .snapshots(),
          builder: (context, instantanea) {
            if (!instantanea.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final datos = instantanea.data!.data() ?? {};

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _identidad(datos),
                const SizedBox(height: 16),
                _botones(),
                const SizedBox(height: 16),
                _estadisticas(datos),
                const SizedBox(height: 16),
                _acercaDe(datos),
                _especialidades(datos),
                const SizedBox(height: 4),
                _atajos(),
                const SizedBox(height: 16),
                _seccionesPortafolio(),
                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () => cerrarSesion(context),
                    icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                    label: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _identidad(Map<String, dynamic> datos) {
    final nombre = datos['name'] ?? '';
    final foto = datos['photoUrl'] as String?;
    final resenas = (datos['reviewsCount'] as num?)?.toInt() ?? 0;
    final calificacion = (datos['rating'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: TemaApp.grisClaro,
          backgroundImage: (foto != null && foto.isNotEmpty)
              ? NetworkImage(ServicioSubidaImagenes.miniatura(foto, ancho: 260))
              : null,
          child: (foto == null || foto.isEmpty)
              ? Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    fontSize: 34,
                    color: TemaApp.textoOscuro,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          nombre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: resenas == 0 ? null : _verResenas,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: resenas == 0
                ? const Text(
                    'Todavía sin reseñas',
                    style: TextStyle(fontSize: 12.5, color: TemaApp.grisTexto),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 17),
                      const SizedBox(width: 4),
                      Text(
                        formatearCalificacion(calificacion),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        contarResenas(resenas),
                        style: const TextStyle(
                          color: TemaApp.textoOscuro,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: TemaApp.textoOscuro,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  void _verResenas() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MisResenasScreen(profesionalId: _uid)),
  );

  Widget _botones() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EditarPerfilProfesionalScreen(),
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Editar Perfil'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConfiguracionScreen(esProfesional: true),
              ),
            ),
            icon: const Icon(Icons.settings_outlined, size: 17),
            label: const Text('Configuración'),
          ),
        ),
      ],
    );
  }

  Widget _estadisticas(Map<String, dynamic> datos) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(_uid)
                .collection('services')
                .snapshots(),
            builder: (context, servicios) => _TarjetaStat(
              icono: Icons.spa_outlined,
              valor: '${servicios.data?.docs.length ?? 0}',
              etiqueta: 'Servicios',
              onTap: widget.onIr == null
                  ? null
                  : () => widget.onIr!(DestinoProfesional.servicios),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TarjetaStat(
            icono: Icons.star_border,
            valor: '${(datos['reviewsCount'] as num?)?.toInt() ?? 0}',
            etiqueta: 'Reseñas',
            onTap: _verResenas,
          ),
        ),
      ],
    );
  }

  Widget _acercaDe(Map<String, dynamic> datos) {
    final sobreMi = datos['about'] as String?;
    final telefono = datos['phone'] as String?;
    final ubicacion = Ubicacion.desdeMapa(datos);
    final experiencia = (datos['aniosExperiencia'] as num?)?.toInt();

    final filas = <Widget>[];

    if (sobreMi != null && sobreMi.isNotEmpty) {
      filas.add(_Fila(icono: Icons.person_outline, texto: sobreMi));
    }
    if (ubicacion.estaDefinida) {
      filas.add(
        _Fila(icono: Icons.location_on_outlined, texto: ubicacion.resumen),
      );
    }
    if (telefono != null && telefono.isNotEmpty) {
      filas.add(_Fila(icono: Icons.phone_outlined, texto: telefono));
    }
    if (experiencia != null && experiencia > 0) {
      filas.add(
        _Fila(
          icono: Icons.workspace_premium_outlined,
          texto: experiencia == 1
              ? '1 año de experiencia'
              : '$experiencia años de experiencia',
        ),
      );
    }

    final redes = leerRedes(datos);
    if (redes.isNotEmpty) {
      filas.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: BotonesRedes(redes: redes),
        ),
      );
    }

    if (filas.isEmpty) {
      filas.add(
        const _Fila(
          icono: Icons.info_outline,
          texto: 'Completa tu perfil para que tus clientes te conozcan',
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acerca de',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...filas,
          ],
        ),
      ),
    );
  }

  Widget _especialidades(Map<String, dynamic> datos) {
    final especialidades = List<String>.from(datos['specialties'] ?? []);
    if (especialidades.isEmpty) return const SizedBox(height: 12);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Especialidades',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: especialidades
                    .map(
                      (e) => Chip(
                        label: Text(e),
                        backgroundColor: TemaApp.grisClaro,
                        labelStyle: const TextStyle(
                          color: TemaApp.textoOscuro,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _atajos() {
    return Column(
      children: [
        const SizedBox(height: 12),
        _Atajo(
          icono: Icons.visibility_outlined,
          titulo: 'Ver mi perfil público',
          detalle: 'Así te ven tus clientes antes de reservar',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfessionalDetailScreen(professionalId: _uid),
            ),
          ),
        ),
        _Atajo(
          icono: Icons.star_border,
          titulo: 'Reseñas recibidas',
          detalle: 'Lo que opinan tus clientes',
          onTap: _verResenas,
        ),
        _Atajo(
          icono: Icons.qr_code_2,
          titulo: 'Mi código QR',
          detalle: 'Para que te encuentren escaneando',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QrPerfilScreen(profesionalId: _uid),
            ),
          ),
        ),
        _Atajo(
          icono: Icons.people_outline,
          titulo: 'Mis Clientes',
          detalle: 'Historial de servicios y contacto',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PantallaClientes()),
          ),
        ),
      ],
    );
  }

  Widget _seccionesPortafolio() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PestanasPildora(
              etiquetas: const ['Portafolio', 'Certificados'],
              seleccionada: _seccion,
              onCambio: (indice) => setState(() => _seccion = indice),
            ),
            const SizedBox(height: 16),
            if (_seccion == 0)
              _VistaPortafolio(uid: _uid)
            else
              ListaCertificados(profesionalId: _uid, editable: true),
          ],
        ),
      ),
    );
  }
}

class _VistaPortafolio extends StatelessWidget {
  final String uid;

  const _VistaPortafolio({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('portfolio')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, instantanea) {
        if (!instantanea.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final fotos = instantanea.data!.docs;

        if (fotos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 44,
                  color: TemaApp.grisTexto,
                ),
                SizedBox(height: 10),
                Text(
                  'Agrega fotos desde la pestana Portafolio',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: TemaApp.grisTexto, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final urls = fotos
            .map((foto) => (foto.data()['imageUrl'] as String?) ?? '')
            .where((url) => url.isNotEmpty)
            .toList();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: urls.length,
          itemBuilder: (context, indice) => GestureDetector(
            onTap: () =>
                VisorFotos.abrir(context, fotos: urls, inicial: indice),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                ServicioSubidaImagenes.miniatura(urls[indice], ancho: 300),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: TemaApp.grisBorde),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TarjetaStat extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final VoidCallback? onTap;

  const _TarjetaStat({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icono, color: TemaApp.textoOscuro, size: 20),
              const SizedBox(height: 6),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    etiqueta,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TemaApp.grisTexto,
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      size: 13,
                      color: TemaApp.grisTexto,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _Fila({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: TemaApp.grisTexto),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: TemaApp.grisSubtitulo,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Atajo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  const _Atajo({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: TemaApp.grisClaro,
          child: Icon(icono, color: TemaApp.textoOscuro, size: 20),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          detalle,
          style: const TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
        ),
        trailing: const Icon(Icons.chevron_right, color: TemaApp.grisTexto),
      ),
    );
  }
}
