import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/cabecera_pantalla.dart';
import 'professional_portfolio_screen.dart';
import 'professional_schedule_screen.dart';
import 'professional_services_screen.dart';

class MiTrabajoScreen extends StatefulWidget {
  final int pestanaInicial;

  const MiTrabajoScreen({super.key, this.pestanaInicial = 0});

  @override
  State<MiTrabajoScreen> createState() => _MiTrabajoScreenState();
}

class _MiTrabajoScreenState extends State<MiTrabajoScreen> {
  late int _pestana = widget.pestanaInicial;

  static const _subtitulos = [
    'Lo que ofreces y a qué precio',
    'Las fotos que ven tus clientes',
    'Los días y horas en que atiendes',
  ];

  @override
  void didUpdateWidget(MiTrabajoScreen anterior) {
    super.didUpdateWidget(anterior);
    if (widget.pestanaInicial != anterior.pestanaInicial) {
      setState(() => _pestana = widget.pestanaInicial);
    }
  }

  void irA(int pestana) => setState(() => _pestana = pestana);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: Column(
        children: [
          CabeceraPantalla(
            titulo: 'Mi trabajo',
            subtitulo: _subtitulos[_pestana],
            icono: Icons.work_outline,
            estilo: EstiloCabecera.destacada,
          ),
          PestanasPildora(
            etiquetas: const ['Servicios', 'Portafolio', 'Horarios'],
            seleccionada: _pestana,
            onCambio: irA,
          ),
          Expanded(
            child: IndexedStack(
              index: _pestana,
              children: const [
                ProfessionalServicesScreen(embebida: true),
                ProfessionalPortfolioScreen(embebida: true),
                PantallaAgendaProfesional(embebida: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
