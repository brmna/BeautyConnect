import 'package:flutter/material.dart';

class TemaApp {
  static const Color negro = Color(0xFF1A1A1A);
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisClaro = Color(0xFFF5F5F5);
  static const Color grisBorde = Color(0xFFE0E0E0);
  static const Color grisTexto = Color(0xFF9E9E9E);
  static const Color textoOscuro = Color(0xFF212121);
  static const Color grisSubtitulo = Color(0xFF757575);
  static const Color fondo = Color(0xFFF2F2F2);
  static const Color rosa = Color(0xFFE91E63);
  static const Color rosaSuave = Color(0xFFFCE4EC);

  static const Color info = Color(0xFF1565C0);
  static const Color infoSuave = Color(0xFFE3F0FC);
  static const Color aviso = Color(0xFFB26A00);
  static const Color avisoSuave = Color(0xFFFFF4E0);
  static const Color exito = Color(0xFF2E7D32);
  static const Color exitoSuave = Color(0xFFE6F4EA);
  static const Color error = Color(0xFFC62828);
  static const Color errorSuave = Color(0xFFFDECEA);

  static const Color avisoClaro = Color(0xFFFFB300);
  static const Color infoClaro = Color(0xFF42A5F5);

  static OutlineInputBorder _borde(Color color, {double grosor = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: grosor),
      );

  static ThemeData get temaClaro {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Gelasio',
      scaffoldBackgroundColor: fondo,
      colorScheme: ColorScheme.fromSeed(
        seedColor: negro,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: blanco,
        foregroundColor: textoOscuro,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: blanco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: grisClaro,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        hintStyle: const TextStyle(color: grisTexto),
        floatingLabelStyle: const TextStyle(color: rosa),
        border: _borde(grisClaro),
        enabledBorder: _borde(grisClaro),
        focusedBorder: _borde(rosa, grosor: 1.6),
        errorBorder: _borde(error),
        focusedErrorBorder: _borde(error, grosor: 1.6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: negro,
        contentTextStyle: const TextStyle(color: blanco, fontSize: 13.5),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: blanco,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Gelasio',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textoOscuro,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Gelasio',
          fontSize: 14,
          height: 1.45,
          color: grisSubtitulo,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: blanco,
        indicatorColor: rosaSuave,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        elevation: 8,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            size: 22,
            color: estados.contains(WidgetState.selected) ? negro : grisTexto,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => TextStyle(
            fontSize: 11,
            fontWeight: estados.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: estados.contains(WidgetState.selected) ? negro : grisTexto,
          ),
        ),
      ),
    );
  }
}
