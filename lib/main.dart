import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';
import 'presentation/auth_wrapper.dart';
import 'theme/app_theme.dart';
import 'presentation/escucha_enlaces.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  Intl.defaultLocale = 'es_CO';
  await initializeDateFormatting('es_CO');

  runApp(const ProviderScope(child: AplicacionBeautyConnect()));
}

class AplicacionBeautyConnect extends StatelessWidget {
  const AplicacionBeautyConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeautyConnect',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.temaClaro,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: navegadorGlobal,
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const EscuchaEnlaces(child: AuthWrapper()),
    );
  }
}

final navegadorGlobal = GlobalKey<NavigatorState>();
