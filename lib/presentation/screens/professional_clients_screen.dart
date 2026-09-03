import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/estado_vacio.dart';
import '../../data/services/servicio_clientes.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato.dart';
import '../widgets/avatar_persona.dart';
import '../widgets/hoja_perfil_cliente.dart';
import '../../utils/margenes.dart';

class PantallaClientes extends StatefulWidget {
  const PantallaClientes({super.key});

  @override
  State<PantallaClientes> createState() => _PantallaClientesState();
}

class _PantallaClientesState extends State<PantallaClientes> {
  static const int _letrasMinimas = 2;
  static const Duration _reposo = Duration(milliseconds: 350);

  final _servicio = ServicioClientes();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Timer? _retraso;
  String _busqueda = '';

  @override
  void dispose() {
    _retraso?.cancel();
    super.dispose();
  }

  void _buscar(String valor) {
    _retraso?.cancel();
    final limpio = valor.trim();

    if (limpio.length < _letrasMinimas) {
      if (_busqueda.isNotEmpty) setState(() => _busqueda = '');
      return;
    }

    _retraso = Timer(_reposo, () {
      if (mounted) setState(() => _busqueda = limpio);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        title: const Text(
          'Mis Clientes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _servicio.observarCitas(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'No se pudo cargar el registro',
                style: TextStyle(color: TemaApp.grisTexto),
              ),
            );
          }

          return FutureBuilder<List<ResumenCliente>>(
            future: _servicio.agrupar(snapshot.data?.docs ?? []),
            builder: (context, resumen) {
              if (!resumen.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final todas = resumen.data!
                  .where((cliente) => cliente.atendidas > 0)
                  .toList();
              if (todas.isEmpty) return _vacio();

              final filtradas = _busqueda.isEmpty
                  ? todas
                  : todas
                        .where(
                          (c) => c.nombre.toLowerCase().contains(
                            _busqueda.toLowerCase(),
                          ),
                        )
                        .toList();

              return Column(
                children: [
                  _buscador(),
                  _resumenGeneral(todas),
                  Expanded(
                    child: filtradas.isEmpty
                        ? const Center(
                            child: Text(
                              'Ningún cliente coincide',
                              style: TextStyle(color: TemaApp.grisTexto),
                            ),
                          )
                        : ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              16,
                              8,
                              16,
                              margenInferior(context),
                            ),
                            itemCount: filtradas.length,
                            itemBuilder: (context, indice) => _TarjetaCliente(
                              cliente: filtradas[indice],
                              onTap: () => _abrirDetalle(filtradas[indice]),
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre (min. 2 letras)',
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: TemaApp.blanco,
        ),
        onChanged: _buscar,
      ),
    );
  }

  Widget _resumenGeneral(List<ResumenCliente> clientes) {
    final atendidas = clientes.fold<int>(0, (s, c) => s + c.atendidas);
    final recurrentes = clientes.where((c) => c.atendidas > 1).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _Metrica(valor: '${clientes.length}', etiqueta: 'Clientes'),
          _Metrica(valor: '$atendidas', etiqueta: 'Servicios'),
          _Metrica(valor: '$recurrentes', etiqueta: 'Recurrentes'),
        ],
      ),
    );
  }

  Widget _vacio() {
    return const EstadoVacio(
      icono: Icons.people_outline,
      titulo: 'Aún no has atendido a nadie',
      detalle: 'Cada cita que marques como completada suma su cliente aquí',
    );
  }

  void _abrirDetalle(ResumenCliente cliente) {
    HojaPerfilCliente.abrir(
      context,
      clienteId: cliente.id,
      profesionalId: _uid,
      resumen: cliente,
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: TemaApp.blanco,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              etiqueta,
              style: const TextStyle(fontSize: 11, color: TemaApp.grisTexto),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaCliente extends StatelessWidget {
  final ResumenCliente cliente;
  final VoidCallback onTap;

  const _TarjetaCliente({required this.cliente, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ultima = cliente.ultimaVisita;
    final proxima = cliente.proximaCita;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: AvatarCliente(
          nombre: cliente.nombre,
          foto: cliente.foto,
          radio: 24,
        ),
        title: Text(
          cliente.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${cliente.atendidas} servicios  -  '
              '${formatearPrecio(cliente.totalGastado)}',
              style: const TextStyle(
                fontSize: 12,
                color: TemaApp.grisSubtitulo,
              ),
            ),
            if (proxima != null)
              Text(
                'Próxima: ${formatearFechaHora(proxima)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: TemaApp.grisSubtitulo,
                ),
              )
            else if (ultima != null)
              Text(
                'Última: ${formatearFecha(ultima)}',
                style: const TextStyle(fontSize: 12, color: TemaApp.grisTexto),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: TemaApp.grisTexto),
      ),
    );
  }
}
