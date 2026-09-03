import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'dashboard_profesional_screen.dart';
import 'mi_trabajo_screen.dart';
import 'professional_agenda_screen.dart';
import 'professional_profile_screen.dart';
import '../widgets/historial_pestanas.dart';

enum DestinoProfesional {
  inicio,
  citas,
  servicios,
  portafolio,
  horarios,
  perfil,
}

class ProfessionalHome extends StatefulWidget {
  const ProfessionalHome({super.key});

  @override
  State<ProfessionalHome> createState() => _ProfessionalHomeState();
}

class _ProfessionalHomeState extends State<ProfessionalHome>
    with HistorialPestanas<ProfessionalHome> {
  int _pestanaTrabajo = 0;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _ir(DestinoProfesional destino) {
    switch (destino) {
      case DestinoProfesional.inicio:
        abrirPestana(0);
      case DestinoProfesional.citas:
        abrirPestana(1);
      case DestinoProfesional.servicios:
        setState(() => _pestanaTrabajo = 0);
        abrirPestana(2);
      case DestinoProfesional.portafolio:
        setState(() => _pestanaTrabajo = 1);
        abrirPestana(2);
      case DestinoProfesional.horarios:
        setState(() => _pestanaTrabajo = 2);
        abrirPestana(2);
      case DestinoProfesional.perfil:
        abrirPestana(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return conGestoVolver(
      hijo: Scaffold(
        body: IndexedStack(
          index: pestanaActual,
          children: [
            DashboardProfesionalScreen(onIr: _ir),
            const ProfessionalAgendaScreen(),
            MiTrabajoScreen(pestanaInicial: _pestanaTrabajo),
            ProfessionalProfileScreen(onIr: _ir),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: pestanaActual,
          onDestinationSelected: abrirPestana,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: _IconoSolicitudes(
                uid: _uid,
                icono: Icons.calendar_month_outlined,
              ),
              selectedIcon: _IconoSolicitudes(
                uid: _uid,
                icono: Icons.calendar_month,
              ),
              label: 'Citas',
            ),
            const NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Mi trabajo',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

class _IconoSolicitudes extends StatelessWidget {
  final String uid;
  final IconData icono;

  const _IconoSolicitudes({required this.uid, required this.icono});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('professionalId', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, instantanea) {
        final pendientes = instantanea.data?.docs.length ?? 0;

        return Badge.count(
          count: pendientes,
          isLabelVisible: pendientes > 0,
          backgroundColor: TemaApp.avisoClaro,
          child: Icon(icono),
        );
      },
    );
  }
}
