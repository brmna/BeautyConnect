import 'package:flutter/material.dart';
import '../presentation/widgets/marca_app.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class BeautyLogo extends StatelessWidget {
  final String subtitle;

  const BeautyLogo({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Column(
      children: [
        Container(
          width: r.logoSize,
          height: r.logoSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r.logoSize * 0.28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2B2B2B), Color(0xFF0F0F0F)],
            ),
          ),
          child: MarcaBeautyConnect(tamano: r.logoSize),
        ),
        const SizedBox(height: 10),
        Text(
          'BeautyConnect',
          style: TextStyle(
            fontSize: r.appNameSize,
            fontWeight: FontWeight.w400,
            fontStyle: FontStyle.italic,
            color: TemaApp.textoOscuro,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: r.isMobile ? 13 : 15,
            color: TemaApp.grisSubtitulo,
          ),
        ),
      ],
    );
  }
}
