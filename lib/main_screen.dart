import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'presentation/screens/client_appointments_screen.dart';
import 'presentation/screens/client_favorites_screen.dart';
import 'presentation/screens/client_home.dart';
import 'presentation/screens/client_profile_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/widgets/historial_pestanas.dart';
import 'theme/app_theme.dart';
import 'utils/estado_cita.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with HistorialPestanas<MainScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  late final List<Widget> _pantallas = [
    ClientHome(onIrAPestana: _irA),
    const SearchScreen(),
    ClientFavoritesScreen(onIrAPestana: _irA),
    ClientAppointmentsScreen(onIrAPestana: _irA),
    ClientProfileScreen(onIrAPestana: _irA),
  ];

  void _irA(int indice) => abrirPestana(indice);

  @override
  Widget build(BuildContext context) {
    return conGestoVolver(
      hijo: Scaffold(
        body: IndexedStack(index: pestanaActual, children: _pantallas),
        bottomNavigationBar: NavigationBar(
          selectedIndex: pestanaActual,
          onDestinationSelected: _irA,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            const NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search),
              label: 'Buscar',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: _IconoCitas(
                uid: _uid,
                icono: Icons.calendar_month_outlined,
              ),
              selectedIcon: _IconoCitas(uid: _uid, icono: Icons.calendar_month),
              label: 'Citas',
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

class _IconoCitas extends StatelessWidget {
  final String uid;
  final IconData icono;

  const _IconoCitas({required this.uid, required this.icono});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('clientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, instantanea) {
        final citas = instantanea.data?.docs ?? [];

        final activas = citas.where((cita) {
          final estado = clasificarCita(cita.data());
          return estado.esperaRespuesta || estado.estaPorVenir;
        }).length;

        final sinLeer = citas.any((cita) => cita.data()['avisoVisto'] == false);

        return Badge.count(
          count: activas,
          isLabelVisible: activas > 0,
          backgroundColor: sinLeer ? TemaApp.avisoClaro : TemaApp.infoClaro,
          child: Icon(icono),
        );
      },
    );
  }
}
