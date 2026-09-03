import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/models/ajustes_profesional.dart';
import '../../data/models/horario.dart';
import '../../data/models/ubicacion.dart';
import '../../theme/app_theme.dart';
import 'selector_ubicacion_screen.dart';
import '../widgets/campo_telefono.dart';
import '../widgets/mensaje.dart';
import '../../utils/formato.dart';
import '../widgets/hoja_hora.dart';
import '../../utils/validaciones.dart';

class BienvenidaProfesionalScreen extends StatefulWidget {
  final String uid;
  final String nombre;

  const BienvenidaProfesionalScreen({
    super.key,
    required this.uid,
    required this.nombre,
  });

  @override
  State<BienvenidaProfesionalScreen> createState() =>
      _BienvenidaProfesionalScreenState();
}

class _BienvenidaProfesionalScreenState
    extends State<BienvenidaProfesionalScreen> {
  final _paginas = PageController();
  final _formularioDatos = GlobalKey<FormState>();

  final _telefonoCtrl = TextEditingController();
  final _especialidadesCtrl = TextEditingController();
  final _sobreMiCtrl = TextEditingController();

  int _paso = 0;
  bool _guardando = false;

  Ubicacion _ubicacion = const Ubicacion(barrio: '');
  bool _soloDomicilio = false;
  final Set<int> _diasActivos = {1, 2, 3, 4, 5};
  TimeOfDay _apertura = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _cierre = const TimeOfDay(hour: 18, minute: 0);
  int _intervalo = 30;

  @override
  void dispose() {
    _paginas.dispose();
    _telefonoCtrl.dispose();
    _especialidadesCtrl.dispose();
    _sobreMiCtrl.dispose();
    super.dispose();
  }

  bool get _puedeAvanzar {
    if (_paso == 0) return _soloDomicilio || _ubicacion.estaDefinida;
    if (_paso == 2) return _diasActivos.isNotEmpty;
    return true;
  }

  void _avanzar() {
    if (_paso == 1 && !(_formularioDatos.currentState?.validate() ?? true)) {
      return;
    }

    if (_paso < 2) {
      _paginas.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    _terminar();
  }

  Future<void> _terminar() async {
    setState(() => _guardando = true);
    final mensajero = ScaffoldMessenger.of(context);

    final especialidades = _especialidadesCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final horario = HorarioBase(
      intervaloMinutos: _intervalo,
      dias: {
        for (final dia in _diasActivos)
          dia: RangoHorario(inicio: _texto(_apertura), fin: _texto(_cierre)),
      },
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        ..._ubicacion.aMapa(),
        if (_soloDomicilio)
          'ajustes': {
            AjustesProfesional.claveDomicilios: true,
            AjustesProfesional.claveSoloDomicilio: true,
          },
        'phone': _telefonoCtrl.text.trim(),
        'about': _sobreMiCtrl.text.trim(),
        'specialties': especialidades,
        'horarioBase': horario.aMapa(),
        'onboardingCompleto': true,
      }, SetOptions(merge: true));
    } catch (_) {
      mensajero.showSnackBar(
        construirMensaje(
          'No se pudo guardar. Intenta de nuevo',
          tipo: TipoAviso.error,
        ),
      );
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _texto(TimeOfDay hora) => horaGuardable(hora);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blanco,
      body: SafeArea(
        child: Column(
          children: [
            _cabecera(),
            Expanded(
              child: PageView(
                controller: _paginas,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (indice) => setState(() => _paso = indice),
                children: [_pasoUbicacion(), _pasoDatos(), _pasoHorario()],
              ),
            ),
            _pie(),
          ],
        ),
      ),
    );
  }

  Widget _cabecera() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (indice) {
              final activo = indice <= _paso;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: activo ? TemaApp.negro : TemaApp.grisBorde,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Paso ${_paso + 1} de 3',
            style: const TextStyle(fontSize: 12, color: TemaApp.grisTexto),
          ),
        ],
      ),
    );
  }

  Widget _pie() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_paso > 0)
            TextButton(
              onPressed: _guardando
                  ? null
                  : () => _paginas.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
              child: const Text('Atrás'),
            ),
          const Spacer(),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (!_puedeAvanzar || _guardando) ? null : _avanzar,
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.negro,
                foregroundColor: TemaApp.blanco,
                padding: const EdgeInsets.symmetric(horizontal: 36),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_paso == 2 ? 'Empezar' : 'Continuar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenedor({
    required String titulo,
    required String descripcion,
    required List<Widget> hijos,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 14,
              color: TemaApp.grisSubtitulo,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          ...hijos,
        ],
      ),
    );
  }

  Widget _pasoUbicacion() {
    return _contenedor(
      titulo: 'Hola, ${widget.nombre.split(' ').first}',
      descripcion: _soloDomicilio
          ? 'Como vas a donde están tus clientes, no necesitas marcar una '
                'dirección. Puedes agregarla después si quieres.'
          : 'Vamos a configurar tu perfil en un minuto. Empecemos por donde '
                'atiendes, para que tus clientes te encuentren.',
      hijos: [
        InkWell(
          onTap: () async {
            final elegida = await Navigator.push<Ubicacion>(
              context,
              MaterialPageRoute(
                builder: (_) => SelectorUbicacionScreen(inicial: _ubicacion),
              ),
            );
            if (elegida == null) return;
            setState(() => _ubicacion = elegida);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: TemaApp.grisClaro,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _ubicacion.estaDefinida
                    ? TemaApp.negro
                    : TemaApp.grisBorde,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ubicacion.estaDefinida
                            ? _ubicacion.resumen
                            : 'Marca donde atiendes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _ubicacion.estaDefinida
                              ? TemaApp.textoOscuro
                              : TemaApp.grisTexto,
                        ),
                      ),
                      if (_ubicacion.barrio.isNotEmpty &&
                          _ubicacion.direccion.isNotEmpty)
                        Text(
                          _ubicacion.barrio,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TemaApp.grisSubtitulo,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          value: _soloDomicilio,
          onChanged: (activo) => setState(() => _soloDomicilio = activo),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: TemaApp.negro,
          title: const Text(
            'Solo trabajo a domicilio',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Voy a donde está el cliente y no atiendo en un local fijo',
            style: TextStyle(fontSize: 12, color: TemaApp.grisSubtitulo),
          ),
        ),
      ],
    );
  }

  Widget _pasoDatos() {
    return _contenedor(
      titulo: 'Cuéntanos de ti',
      descripcion:
          'Esto es lo que verán tus clientes en tu perfil. Puedes dejarlo en blanco '
          'y completarlo después.',
      hijos: [
        Form(
          key: _formularioDatos,
          child: Column(
            children: [
              CampoTelefono(controlador: _telefonoCtrl, conIcono: false),
              const SizedBox(height: 16),
              TextFormField(
                controller: _especialidadesCtrl,
                textCapitalization: TextCapitalization.words,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validarEspecialidades,
                decoration: const InputDecoration(
                  labelText: 'Especialidades',
                  hintText: 'Francesas, Acrilicas, Gel',
                  helperText: 'Separalas con comas',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sobreMiCtrl,
                maxLines: 3,
                maxLength: maximoSobreMi,
                textCapitalization: TextCapitalization.sentences,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: validarSobreMi,
                decoration: const InputDecoration(
                  labelText: 'Sobre mi',
                  hintText: 'Cuéntale a tus clientes sobre tu experiencia',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pasoHorario() {
    const nombres = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return _contenedor(
      titulo: 'Tu horario',
      descripcion:
          'Con esto la app genera tu agenda sola. Después puedes ajustar días '
          'sueltos desde Mi Agenda.',
      hijos: [
        const Text(
          'Días que trabajas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (indice) {
            final dia = indice + 1;
            final activo = _diasActivos.contains(dia);

            return GestureDetector(
              onTap: () => setState(() {
                activo ? _diasActivos.remove(dia) : _diasActivos.add(dia);
              }),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: activo ? TemaApp.negro : TemaApp.grisClaro,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  nombres[indice],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: activo ? TemaApp.blanco : TemaApp.grisTexto,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(child: _selectorHora('Abro', _apertura, true)),
            const SizedBox(width: 12),
            Expanded(child: _selectorHora('Cierro', _cierre, false)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Text('Cada cuánto puede empezar una cita')),
            DropdownButton<int>(
              value: _intervalo,
              items: const [15, 20, 30, 45, 60]
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(formatearDuracionCorta(m)),
                    ),
                  )
                  .toList(),
              onChanged: (valor) {
                if (valor == null) return;
                setState(() => _intervalo = valor);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _selectorHora(String etiqueta, TimeOfDay valor, bool esApertura) {
    return InkWell(
      onTap: () async {
        final elegida = await elegirHora(
          context,
          inicial: valor,
          ayuda: esApertura ? 'Hora de apertura' : 'Hora de cierre',
        );
        if (elegida == null) return;
        setState(() {
          if (esApertura) {
            _apertura = elegida;
          } else {
            _cierre = elegida;
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(labelText: etiqueta),
        child: Text(
          formatearHoraDeReloj(valor),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
