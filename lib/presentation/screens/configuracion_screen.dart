import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/ajustes_profesional.dart';
import '../../theme/app_theme.dart';
import 'cambiar_contrasena_screen.dart';
import '../../utils/sesion.dart';
import '../../data/models/ubicacion.dart';
import '../widgets/hoja_cobertura.dart';
import '../widgets/hoja_modal.dart';
import '../widgets/mensaje.dart';
import '../../data/services/servicio_notificaciones.dart';
import '../../data/auth_repository.dart';
import 'cambiar_correo_screen.dart';
import 'texto_legal_screen.dart';
import '../../utils/formato.dart';
import '../../utils/margenes.dart';
import '../../utils/validaciones.dart';

class ConfiguracionScreen extends StatelessWidget {
  final bool esProfesional;

  const ConfiguracionScreen({super.key, required this.esProfesional});

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> get _perfil =>
      FirebaseFirestore.instance.collection('users').doc(_uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.grisClaro,
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _perfil.snapshots(),
        builder: (context, instantanea) {
          if (!instantanea.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final datos = instantanea.data!.data() ?? {};
          final ajustesPro = AjustesProfesional.desdeMapa(datos);
          final aceptando = ajustesPro.aceptandoClientas;
          final puedeCambiarCredenciales = AuthRepository().puedeCambiarCorreo;

          void cambiar(
            String clave,
            bool activo, {
            Map<String, dynamic>? extra,
          }) {
            _perfil.set({
              'ajustes': {clave: activo, ...?extra},
            }, SetOptions(merge: true));
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              margenInferior(context, base: 32),
            ),
            children: [
              if (esProfesional) ...[
                _Grupo(
                  titulo: 'DISPONIBILIDAD',
                  hijos: [
                    _Interruptor(
                      icono: Icons.event_available_outlined,
                      titulo: 'Aceptando nuevos clientes',
                      detalle: aceptando
                          ? 'Los clientes pueden enviarte solicitudes'
                          : 'Tu perfil se ve, pero no pueden reservarte',
                      valor: aceptando,
                      onCambio: (v) =>
                          cambiar(AjustesProfesional.claveAceptando, v),
                    ),
                    _Interruptor(
                      icono: Icons.bolt_outlined,
                      titulo: 'Auto-aceptar solicitudes',
                      detalle: aceptando
                          ? 'Las citas quedan confirmadas sin que respondas'
                          : 'Sin recibir clientes no hay nada que aceptar',
                      valor: aceptando && ajustesPro.autoAceptar,
                      onCambio: aceptando
                          ? (v) =>
                                cambiar(AjustesProfesional.claveAutoAceptar, v)
                          : null,
                    ),
                    _Opcion(
                      icono: Icons.schedule_outlined,
                      titulo: 'Anticipación mínima',
                      detalle: etiquetaAnticipacion(
                        ajustesPro.anticipacionMinutos,
                      ),
                      onTap: () => _elegirAnticipacion(
                        context,
                        ajustesPro.anticipacionMinutos,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Grupo(
                  titulo: 'SERVICIO A DOMICILIO',
                  hijos: [
                    _Interruptor(
                      icono: Icons.directions_car_outlined,
                      titulo: 'Hago domicilios',
                      detalle: ajustesPro.llegaADomicilio
                          ? 'Tus clientes pueden pedirte que vayas a su casa'
                          : 'Tus clientes solo pueden ir a tu local',
                      valor: ajustesPro.llegaADomicilio,
                      onCambio: (v) => cambiar(
                        AjustesProfesional.claveDomicilios,
                        v,
                        extra: v
                            ? null
                            : {AjustesProfesional.claveSoloDomicilio: false},
                      ),
                    ),
                    if (ajustesPro.llegaADomicilio) ...[
                      _Interruptor(
                        icono: Icons.home_work_outlined,
                        titulo: 'Solo trabajo a domicilio',
                        detalle: ajustesPro.soloDomicilio
                            ? 'No apareces en el mapa y nadie puede reservar '
                                  'para ir a tu local'
                            : 'Actívalo si no atiendes en un local fijo',
                        valor: ajustesPro.soloDomicilio,
                        onCambio: (v) => cambiar(
                          AjustesProfesional.claveSoloDomicilio,
                          v,
                          extra: v
                              ? {AjustesProfesional.claveDomicilios: true}
                              : null,
                        ),
                      ),
                      _Opcion(
                        icono: Icons.travel_explore_outlined,
                        titulo: 'Zona de cobertura',
                        detalle: etiquetaRadio(ajustesPro.radioCoberturaKm),
                        onTap: () => _elegirRadio(
                          context,
                          ajustesPro.radioCoberturaKm,
                          Ubicacion.desdeMapa(datos),
                        ),
                      ),
                      _Opcion(
                        icono: Icons.payments_outlined,
                        titulo: 'Recargo por domicilio',
                        detalle: ajustesPro.recargoDomicilio <= 0
                            ? 'Sin recargo'
                            : formatearPrecio(ajustesPro.recargoDomicilio),
                        onTap: () => _editarRecargo(
                          context,
                          ajustesPro.recargoDomicilio,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
              ],
              const _Grupo(
                titulo: 'NOTIFICACIONES',
                hijos: [_FilaNotificaciones()],
              ),
              if (puedeCambiarCredenciales) ...[
                const SizedBox(height: 16),
                _Grupo(
                  titulo: 'CUENTA',
                  hijos: [
                    _Opcion(
                      icono: Icons.alternate_email,
                      titulo: 'Cambiar correo',
                      detalle: 'Se confirma con un enlace al correo nuevo',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CambiarCorreoScreen(),
                        ),
                      ),
                    ),
                    _Opcion(
                      icono: Icons.lock_outline,
                      titulo: 'Cambiar contraseña',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CambiarContrasenaScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _Grupo(
                titulo: 'LEGAL',
                hijos: [
                  _Opcion(
                    titulo: 'Términos de servicio',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TextoLegalScreen(
                          tipo: TipoTextoLegal.terminos,
                        ),
                      ),
                    ),
                  ),
                  _Opcion(
                    titulo: 'Política de privacidad',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TextoLegalScreen(
                          tipo: TipoTextoLegal.privacidad,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Grupo(
                titulo: 'ZONA PELIGROSA',
                borde: true,
                hijos: [
                  _Opcion(
                    icono: Icons.person_off_outlined,
                    titulo: 'Desactivar mi cuenta',
                    detalle: esProfesional
                        ? 'Dejarás de aparecer en las búsquedas'
                        : 'Podrás volver cuando quieras',
                    onTap: () => _desactivarCuenta(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  esProfesional
                      ? 'BeautyConnect Pro v1.0.0'
                      : 'BeautyConnect v1.0.0',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TemaApp.grisTexto,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _elegirAnticipacion(BuildContext context, int actual) async {
    final elegida = await abrirHoja<int>(
      context,
      hijo: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 4),
              child: Text(
                'Anticipación mínima',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Cuánto tiempo antes tienen que pedirte una cita. Las horas '
                'que estén más cerca que eso no le aparecen disponibles a tus '
                'clientes.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: TemaApp.grisSubtitulo,
                ),
              ),
            ),
            Flexible(
              child: RadioGroup<int>(
                groupValue: actual,
                onChanged: (valor) => Navigator.pop(context, valor),
                child: ListView(
                  shrinkWrap: true,
                  children: AjustesProfesional.anticipacionesPosibles
                      .map(
                        (minutos) => RadioListTile<int>(
                          value: minutos,
                          title: Text(etiquetaAnticipacion(minutos)),
                          activeColor: TemaApp.negro,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (elegida == null || elegida == actual) return;

    await _perfil.set({
      'ajustes': {AjustesProfesional.claveAnticipacion: elegida},
    }, SetOptions(merge: true));
  }

  Future<void> _elegirRadio(
    BuildContext context,
    double actual,
    Ubicacion centro,
  ) async {
    final elegido = await abrirHoja<double>(
      context,
      hijo: HojaCobertura(actual: actual, centro: centro),
    );

    if (elegido == null || elegido == actual) return;

    await _perfil.set({
      'ajustes': {AjustesProfesional.claveRadio: elegido},
    }, SetOptions(merge: true));
  }

  Future<void> _editarRecargo(BuildContext context, num actual) async {
    final nuevo = await abrirHoja<num>(
      context,
      hijo: _HojaRecargo(actual: actual),
    );

    if (nuevo == null || nuevo == actual) return;

    await _perfil.set({
      'ajustes': {AjustesProfesional.claveRecargo: nuevo},
    }, SetOptions(merge: true));
  }

  Future<void> _desactivarCuenta(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Desactivar mi cuenta'),
        content: Text(
          esProfesional
              ? 'Dejarás de aparecer en las búsquedas y nadie podrá '
                    'reservarte citas nuevas. Tus datos se conservan y puedes '
                    'reactivarla al volver a entrar.'
              : 'Tu cuenta quedará inactiva. Tus datos se conservan y puedes '
                    'reactivarla al volver a entrar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text(
              'Desactivar',
              style: TextStyle(color: TemaApp.error),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || !context.mounted) return;

    final mensajero = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'activo': false,
          'desactivadaEn': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      navegador.popUntil((ruta) => ruta.isFirst);
      await salirDeLaSesion();
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo desactivar la cuenta',
          tipo: TipoAviso.error,
        ),
      );
    }
  }
}

class _Grupo extends StatelessWidget {
  final String titulo;
  final List<Widget> hijos;
  final bool borde;

  const _Grupo({required this.titulo, required this.hijos, this.borde = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: TemaApp.grisTexto,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: TemaApp.blanco,
            borderRadius: BorderRadius.circular(12),
            border: borde ? Border.all(color: TemaApp.grisBorde) : null,
          ),
          child: Column(children: hijos),
        ),
      ],
    );
  }
}

class _Interruptor extends StatelessWidget {
  final IconData? icono;
  final String titulo;
  final String? detalle;
  final bool valor;

  final ValueChanged<bool>? onCambio;

  const _Interruptor({
    this.icono,
    required this.titulo,
    this.detalle,
    required this.valor,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: valor,
      onChanged: onCambio,
      secondary: icono == null
          ? const Icon(Icons.schedule, size: 20)
          : Icon(icono, size: 20),
      title: Text(titulo, style: const TextStyle(fontSize: 14)),
      subtitle: detalle == null
          ? null
          : Text(
              detalle!,
              style: const TextStyle(
                fontSize: 11,
                color: TemaApp.grisSubtitulo,
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      dense: true,
    );
  }
}

class _FilaInformativa extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;

  const _FilaInformativa({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, size: 20, color: TemaApp.grisSubtitulo),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(titulo, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        detalle,
        style: const TextStyle(
          fontSize: 11.5,
          height: 1.4,
          color: TemaApp.grisSubtitulo,
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  final IconData? icono;
  final String titulo;
  final String? detalle;
  final VoidCallback? onTap;

  const _Opcion({this.icono, required this.titulo, this.detalle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: icono == null ? null : Icon(icono, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(titulo, style: const TextStyle(fontSize: 14)),
      subtitle: detalle == null
          ? null
          : Text(
              detalle!,
              style: const TextStyle(
                fontSize: 12,
                color: TemaApp.grisSubtitulo,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: TemaApp.grisTexto),
        ],
      ),
    );
  }
}

class _HojaRecargo extends StatefulWidget {
  final num actual;

  const _HojaRecargo({required this.actual});

  @override
  State<_HojaRecargo> createState() => _HojaRecargoState();
}

class _HojaRecargoState extends State<_HojaRecargo> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _controlador = TextEditingController(
    text: widget.actual <= 0 ? '' : _conPuntosSimple(widget.actual.toInt()),
  );

  static String _conPuntosSimple(int valor) {
    final texto = valor.toString();
    final partes = <String>[];
    for (var i = texto.length; i > 0; i -= 3) {
      partes.insert(0, texto.substring(i - 3 < 0 ? 0 : i - 3, i));
    }
    return partes.join('.');
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formulario.currentState!.validate()) return;

    final digitos = soloDigitos(_controlador.text);
    Navigator.pop(context, digitos.isEmpty ? 0 : int.parse(digitos));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 4,
        bottom: margenHoja(context, base: 24),
      ),
      child: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recargo por domicilio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Lo que cobras de más por ir hasta donde está el cliente. Se le '
              'muestra aparte del precio del servicio antes de que reserve. '
              'Déjalo vacío si no cobras nada extra.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: TemaApp.grisSubtitulo,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _controlador,
              keyboardType: TextInputType.number,
              inputFormatters: const [FormatoPrecio()],
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (valor) {
                final digitos = soloDigitos(valor ?? '');
                if (digitos.isEmpty) return null;
                return validarPrecio(valor);
              },
              decoration: const InputDecoration(
                labelText: 'Recargo',
                prefixText: '\$ ',
                hintText: 'Sin recargo',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TemaApp.negro,
                  foregroundColor: TemaApp.blanco,
                ),
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaNotificaciones extends StatefulWidget {
  const _FilaNotificaciones();

  @override
  State<_FilaNotificaciones> createState() => _FilaNotificacionesState();
}

class _FilaNotificacionesState extends State<_FilaNotificaciones> {
  final _avisos = ServicioNotificaciones.instancia;

  bool? _permitidas;
  bool _exactas = true;

  @override
  void initState() {
    super.initState();
    _revisar();
  }

  Future<void> _revisar() async {
    final permitidas = await _avisos.hayPermiso();
    final exactas = await _avisos.puedeProgramarExactas();

    if (!mounted) return;
    setState(() {
      _permitidas = permitidas;
      _exactas = exactas;
    });
  }

  @override
  Widget build(BuildContext context) {
    final permitidas = _permitidas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilaInformativa(
          icono: Icons.notifications_active_outlined,
          titulo: 'Recordatorios de citas',
          detalle: permitidas == false
              ? 'Están desactivadas para BeautyConnect. Actívalas en los '
                    'ajustes de notificaciones de tu teléfono.'
              : 'Te avisamos 24 horas y 2 horas antes de cada cita '
                    'confirmada. Para apagarlos, usa los ajustes de tu '
                    'teléfono.',
        ),
        if (permitidas == true && !_exactas)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TemaApp.avisoSuave,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_alarm, size: 16, color: TemaApp.aviso),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Los avisos pueden llegar tarde. Tu teléfono no '
                          'deja programar alarmas exactas para la app.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: TemaApp.aviso,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () async {
                      await _avisos.pedirAlarmasExactas();
                      await _revisar();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TemaApp.aviso,
                      side: const BorderSide(color: TemaApp.aviso),
                    ),
                    child: const Text('Permitir alarmas exactas'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
