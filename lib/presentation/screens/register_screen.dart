import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../auth_provider.dart';
import '../widgets/boton_google.dart';
import '../widgets/nota_legal.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes_auth.dart';
import '../../utils/responsive.dart';
import '../../widgets/beauty_logo.dart';
import '../../widgets/beauty_text_field.dart';
import '../../widgets/beauty_button.dart';
import '../../widgets/selector_tipo_usuario.dart';
import '../widgets/mensaje.dart';
import '../../utils/validaciones.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isProfessional = false;
  bool _isLoading = false;
  bool _entrandoConGoogle = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);

    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _isProfessional ? 'professional' : 'client',
          );
      navegador.pop();
      return;
    } on FirebaseAuthException catch (e) {
      mensajero.showSnackBar(SnackBar(content: Text(mensajeErrorAuth(e.code))));
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje('No se pudo crear la cuenta', tipo: TipoAviso.error),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _entrarConGoogle() async {
    setState(() => _entrandoConGoogle = true);
    final mensajero = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(authRepositoryProvider)
          .entrarConGoogle(rol: _isProfessional ? 'professional' : 'client');
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
                const BeautyLogo(subtitle: 'Únete a nuestra comunidad'),
                SizedBox(height: r.isMobile ? 28 : 36),
                _buildCard(r),
              ],
            ),
          ),
        ),
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
              'Crear Cuenta',
              style: TextStyle(
                fontSize: r.formTitleSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: r.fieldGap),

            SelectorTipoUsuario(
              esProfesional: _isProfessional,
              onCambio: (val) => setState(() => _isProfessional = val),
            ),

            SizedBox(height: r.fieldGap),

            BeautyTextField(
              label: 'Nombre',
              hint: 'Tu nombre',
              prefixIcon: Icons.person_outline,
              controller: _nameController,
              validator: validarNombre,
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

            SizedBox(height: r.fieldGap),

            BeautyTextField(
              label: 'Contraseña',
              hint: '••••••••',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              controller: _passwordController,
              validator: validarContrasena,
            ),

            SizedBox(height: r.isMobile ? 24 : 28),

            BeautyButton(
              label: 'Crear Cuenta',
              onPressed: _handleRegister,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 12),

            const NotaLegal(),

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
              etiqueta: 'Registrarme con Google',
              cargando: _entrandoConGoogle,
              onPressed: _entrarConGoogle,
            ),

            SizedBox(height: r.fieldGap),

            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text(
                "¿Ya tienes cuenta? Inicia sesión",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
