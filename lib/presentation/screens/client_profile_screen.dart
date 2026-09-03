import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/services/servicio_subida_imagenes.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../../utils/sesion.dart';
import '../widgets/estrellas.dart';
import 'configuracion_screen.dart';
import 'editar_perfil_cliente_screen.dart';
import 'mis_resenas_screen.dart';

class ClientProfileScreen extends StatelessWidget {
  final ValueChanged<int>? onIrAPestana;

  const ClientProfileScreen({super.key, this.onIrAPestana});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

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
                const _Encabezado(),
                const SizedBox(height: 16),
                _TarjetaIdentidad(
                  datos: datos,
                  uid: _uid,
                  onIrAPestana: onIrAPestana,
                ),
                const SizedBox(height: 16),
                _Opcion(
                  icono: Icons.person_outline,
                  titulo: 'Editar Perfil',
                  detalle: 'Actualiza tu información personal',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditarPerfilClienteScreen(),
                    ),
                  ),
                ),
                _Opcion(
                  icono: Icons.star_border,
                  titulo: 'Mis Reseñas',
                  detalle: 'Reseñas que has dejado',
                  onTap: () => _verResenas(context),
                ),
                _Opcion(
                  icono: Icons.settings_outlined,
                  titulo: 'Configuración',
                  detalle: 'Ajustes de la aplicación',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ConfiguracionScreen(esProfesional: false),
                    ),
                  ),
                ),
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
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Versión 1.0.0',
                    style: TextStyle(fontSize: 11, color: TemaApp.grisTexto),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static void _verResenas(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MisResenasScreen()),
  );
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mi Perfil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Gestiona tu cuenta y preferencias',
            style: TextStyle(fontSize: 13, color: TemaApp.grisSubtitulo),
          ),
        ],
      ),
    );
  }
}

class _TarjetaIdentidad extends StatelessWidget {
  final Map<String, dynamic> datos;
  final String uid;
  final ValueChanged<int>? onIrAPestana;

  const _TarjetaIdentidad({
    required this.datos,
    required this.uid,
    this.onIrAPestana,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = datos['name'] ?? '';
    final foto = datos['photoUrl'] as String?;
    final creado = (datos['createdAt'] as Timestamp?)?.toDate();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: TemaApp.grisClaro,
                  backgroundImage: (foto != null && foto.isNotEmpty)
                      ? NetworkImage(
                          ServicioSubidaImagenes.miniatura(foto, ancho: 160),
                        )
                      : null,
                  child: (foto == null || foto.isEmpty)
                      ? Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            fontSize: 24,
                            color: TemaApp.textoOscuro,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        datos['email'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: TemaApp.grisSubtitulo,
                        ),
                      ),
                      if (creado != null)
                        Text(
                          'Miembro desde ${DateFormat.yMMMM().format(creado)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: TemaApp.grisTexto,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            _MiPromedioComoCliente(datos: datos),
            const Divider(height: 28),
            _Estadisticas(
              uid: uid,
              datos: datos,
              onIrAPestana: onIrAPestana,
              onVerResenas: () => ClientProfileScreen._verResenas(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiPromedioComoCliente extends StatelessWidget {
  final Map<String, dynamic> datos;

  const _MiPromedioComoCliente({required this.datos});

  @override
  Widget build(BuildContext context) {
    final total = (datos['reviewsCountCliente'] as num?)?.toInt() ?? 0;
    if (total == 0) return const SizedBox.shrink();

    final promedio = (datos['ratingCliente'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TemaApp.grisClaro,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              formatearCalificacion(promedio),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Estrellas(calificacion: promedio, tamano: 13),
                      const SizedBox(width: 6),
                      Text(
                        '(${contarResenas(total)})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: TemaApp.grisTexto,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tu promedio como cliente. Lo califican las manicuristas '
                    'que te han atendido.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: TemaApp.grisSubtitulo,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Estadisticas extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> datos;
  final ValueChanged<int>? onIrAPestana;
  final VoidCallback onVerResenas;

  const _Estadisticas({
    required this.uid,
    required this.datos,
    required this.onVerResenas,
    this.onIrAPestana,
  });

  @override
  Widget build(BuildContext context) {
    final favoritos = (datos['favorites'] as List?)?.length ?? 0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, citasSnap) {
        final citas = citasSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collectionGroup('resenas')
              .where('clienteId', isEqualTo: uid)
              .snapshots(),
          builder: (context, resenasSnap) {
            final resenas = resenasSnap.data?.docs.length ?? 0;

            return Row(
              children: [
                _Metrica(
                  valor: '$citas',
                  etiqueta: 'Citas',
                  onTap: onIrAPestana == null ? null : () => onIrAPestana!(3),
                ),
                _Metrica(
                  valor: '$resenas',
                  etiqueta: 'Reseñas',
                  onTap: onVerResenas,
                ),
                _Metrica(
                  valor: '$favoritos',
                  etiqueta: 'Favoritos',
                  onTap: onIrAPestana == null ? null : () => onIrAPestana!(2),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Metrica extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final VoidCallback? onTap;

  const _Metrica({required this.valor, required this.etiqueta, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 20,
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

class _Opcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  const _Opcion({
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: TemaApp.grisClaro,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icono, size: 20),
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
