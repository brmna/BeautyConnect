import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../data/services/servicio_correos_recientes.dart';
import '../auth_provider.dart';
import '../widgets/boton_google.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes_auth.dart';
import '../../utils/responsive.dart';
import '../../widgets/beauty_logo.dart';
import '../../widgets/beauty_text_field.dart';
import '../../widgets/beauty_button.dart';
import 'recuperar_contrasena_screen.dart';
import 'register_screen.dart';
import '../widgets/mensaje.dart';
import '../../utils/validaciones.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _entrandoConGoogle = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _focoContrasena = FocusNode();

  final _correos = ServicioCorreosRecientes();
  List<String> _recientes = const [];

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_alEscribirCorreo);
    _cargarRecientes();
  }

  @override
  void dispose() {
    _emailController.removeListener(_alEscribirCorreo);
    _emailController.dispose();
    _passwordController.dispose();
    _focoContrasena.dispose();
    super.dispose();
  }

  bool _campoVacio = true;

  void _alEscribirCorreo() {
    final vacio = _emailController.text.trim().isEmpty;
    if (vacio != _campoVacio) setState(() => _campoVacio = vacio);
  }

  Future<void> _cargarRecientes() async {
    final guardados = await _correos.leer();
    if (mounted) setState(() => _recientes = guardados);
  }

  void _usarCorreo(String correo) {
    _emailController.text = correo;
    _focoContrasena.requestFocus();
  }

  Future<void> _olvidarCorreo(String correo) async {
    final quedan = await _correos.olvidar(correo);
    if (mounted) setState(() => _recientes = quedan);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(authRepositoryProvider)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    } on FirebaseAuthException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeErrorAuth(e.code))));
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo iniciar sesión', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _entrarConGoogle() async {
    setState(() => _entrandoConGoogle = true);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await ref.read(authRepositoryProvider).entrarConGoogle(rol: 'client');
    } on GoogleNoConfigurado {
      mensajero.showSnackBar(
        construirMensaje(
          'El ingreso con Google aún no está habilitado',
          tipo: TipoAviso.info,
        ),
      );
    } on FirebaseAuthException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeErrorAuth(e.code))));
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo entrar con Google', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _entrandoConGoogle = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: r.screenPadding,
              vertical: r.verticalPadding,
            ),
            child: Column(
              children: [
                const BeautyLogo(
                  subtitle: 'Tu plataforma de belleza profesional',
                ),
                SizedBox(height: r.isMobile ? 28 : 36),
                _buildCard(r),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuentasRecientes() {
    if (_recientes.isEmpty || !_campoVacio) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entraste antes con',
            style: TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
          ),
          const SizedBox(height: 4),
          for (final correo in _recientes)
            _FilaCorreo(
              correo: correo,
              onUsar: () => _usarCorreo(correo),
              onOlvidar: () => _olvidarCorreo(correo),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(Responsive r) {
    return Container(
      width: r.cardWidth,
      padding: EdgeInsets.all(r.cardPadding),
      decoration: BoxDecoration(
        color: TemaApp.blanco,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: r.formTitleSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: r.fieldGap),

            BeautyTextField(
              label: 'Correo electrónico',
              hint: 'tu@email.com',
              prefixIcon: Icons.mail_outline,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: validarCorreo,
            ),

            _cuentasRecientes(),

            SizedBox(height: r.fieldGap),

            BeautyTextField(
              label: 'Contraseña',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _passwordController,
              focusNode: _focoContrasena,
              validator: validarContrasena,
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecuperarContrasenaScreen(
                      correoInicial: _emailController.text.trim(),
                    ),
                  ),
                ),
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),

            SizedBox(height: r.isMobile ? 8 : 12),

            BeautyButton(
              label: 'Iniciar Sesión',
              onPressed: _handleLogin,
              isLoading: _isLoading,
            ),

            SizedBox(height: r.fieldGap),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o',
                    style: TextStyle(
                      color: TemaApp.grisTexto,
                      fontSize: r.isMobile ? 13 : 14,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            SizedBox(height: r.fieldGap),

            BotonGoogle(
              etiqueta: 'Continuar con Google',
              cargando: _entrandoConGoogle,
              onPressed: _entrarConGoogle,
            ),

            SizedBox(height: r.fieldGap),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text(
                "¿No tienes cuenta? Regístrate",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaCorreo extends StatelessWidget {
  final String correo;
  final VoidCallback onUsar;
  final VoidCallback onOlvidar;

  const _FilaCorreo({
    required this.correo,
    required this.onUsar,
    required this.onOlvidar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUsar,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            const Icon(
              Icons.account_circle_outlined,
              size: 18,
              color: TemaApp.grisTexto,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                correo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: TemaApp.textoOscuro,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Olvidar este correo',
              onPressed: onOlvidar,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.close, size: 15, color: TemaApp.grisTexto),
            ),
          ],
        ),
      ),
    );
  }
}
