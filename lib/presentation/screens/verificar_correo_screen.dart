import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/auth_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import '../../utils/sesion.dart';
import '../widgets/marca_app.dart';
import '../widgets/mensaje.dart';

class VerificarCorreoScreen extends StatefulWidget {
  const VerificarCorreoScreen({super.key});

  @override
  State<VerificarCorreoScreen> createState() => _VerificarCorreoScreenState();
}

class _VerificarCorreoScreenState extends State<VerificarCorreoScreen>
    with WidgetsBindingObserver {
  final _auth = AuthRepository();

  Timer? _revisionPeriodica;
  Timer? _cuentaRegresiva;
  int _segundosParaReenviar = 0;
  bool _revisando = false;

  String get _correo => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _revisionPeriodica = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _revisar(silencioso: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _revisar(silencioso: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _revisionPeriodica?.cancel();
    _cuentaRegresiva?.cancel();
    super.dispose();
  }

  Future<void> _revisar({bool silencioso = false}) async {
    if (_revisando) return;
    setState(() => _revisando = true);

    bool verificado;
    try {
      verificado = await _auth.revisarVerificacion();
    } catch (_) {
      verificado = false;
    }

    if (!mounted) return;
    setState(() => _revisando = false);

    if (verificado) {
      _revisionPeriodica?.cancel();
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      return;
    }

    if (!silencioso) {
      mostrarMensaje(
        context,
        'Todavía no aparece confirmado. Revisa tu correo',
        tipo: TipoAviso.aviso,
      );
    }
  }

  Future<void> _reenviar() async {
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await _auth.enviarVerificacion();
      mensajero.showSnackBar(
        construirMensaje('Correo reenviado', tipo: TipoAviso.exito),
      );
      _iniciarEspera();
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo reenviar. Espera un momento e intenta de nuevo',
          tipo: TipoAviso.error,
        ),
      );
    }
  }

  void _iniciarEspera() {
    setState(() => _segundosParaReenviar = 60);

    _cuentaRegresiva?.cancel();
    _cuentaRegresiva = Timer.periodic(const Duration(seconds: 1), (reloj) {
      if (!mounted) return reloj.cancel();

      setState(() => _segundosParaReenviar--);
      if (_segundosParaReenviar <= 0) reloj.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final puedeReenviar = _segundosParaReenviar == 0;

    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            28,
            24,
            28,
            margenInferior(context, base: 24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2B2B2B), Color(0xFF0F0F0F)],
                  ),
                ),
                child: const MarcaBeautyConnect(tamano: 92),
              ),
              const SizedBox(height: 26),
              const Text(
                'Confirma tu correo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: TemaApp.grisSubtitulo,
                  ),
                  children: [
                    const TextSpan(text: 'Te enviamos un enlace a '),
                    TextSpan(
                      text: _correo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: TemaApp.textoOscuro,
                      ),
                    ),
                    const TextSpan(
                      text:
                          '. Ábrelo para activar tu cuenta. Si no lo ves, '
                          'revisa la carpeta de correo no deseado.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _revisando ? null : () => _revisar(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaApp.negro,
                    foregroundColor: TemaApp.blanco,
                  ),
                  icon: _revisando
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TemaApp.blanco,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: const Text('Ya lo confirmé'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: puedeReenviar ? _reenviar : null,
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: Text(
                    puedeReenviar
                        ? 'Reenviar el correo'
                        : 'Reenviar en $_segundosParaReenviar s',
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => cerrarSesion(context),
                child: const Text(
                  'Usar otra cuenta',
                  style: TextStyle(color: TemaApp.grisTexto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
