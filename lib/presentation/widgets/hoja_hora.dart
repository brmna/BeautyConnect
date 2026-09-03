import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/margenes.dart';
import 'cabecera_pantalla.dart';
import 'hoja_modal.dart';

const int _pasoMinutos = 5;
const double _altoFila = 46;
const double _altoRueda = 184;

Future<TimeOfDay?> elegirHora(
  BuildContext context, {
  required TimeOfDay inicial,
  String? ayuda,
}) {
  return abrirHoja<TimeOfDay>(
    context,
    hijo: _HojaHora(inicial: inicial, ayuda: ayuda),
  );
}

class _HojaHora extends StatefulWidget {
  final TimeOfDay inicial;
  final String? ayuda;

  const _HojaHora({required this.inicial, this.ayuda});

  @override
  State<_HojaHora> createState() => _HojaHoraState();
}

class _HojaHoraState extends State<_HojaHora> {
  late int _hora12 = _aDoce(widget.inicial.hour);
  late int _minuto = _alPaso(widget.inicial.minute);
  late bool _tarde = widget.inicial.hour >= 12;

  late final FixedExtentScrollController _ruedaHoras =
      FixedExtentScrollController(initialItem: _hora12 - 1);
  late final FixedExtentScrollController _ruedaMinutos =
      FixedExtentScrollController(initialItem: _minuto ~/ _pasoMinutos);

  static int _aDoce(int hora24) {
    final resto = hora24 % 12;
    return resto == 0 ? 12 : resto;
  }

  static int _alPaso(int minuto) => (minuto ~/ _pasoMinutos) * _pasoMinutos;

  TimeOfDay get _elegida {
    final base = _hora12 % 12;
    return TimeOfDay(hour: _tarde ? base + 12 : base, minute: _minuto);
  }

  String get _dosDigitos => _minuto.toString().padLeft(2, '0');

  @override
  void dispose() {
    _ruedaHoras.dispose();
    _ruedaMinutos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: margenHoja(context, base: 20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.ayuda ?? 'Elige la hora',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '$_hora12:$_dosDigitos ${_tarde ? 'p.m.' : 'a.m.'}',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: _altoRueda,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const _Resaltado(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Rueda(
                      control: _ruedaHoras,
                      cuantos: 12,
                      etiqueta: (indice) => '${indice + 1}',
                      onCambio: (indice) =>
                          setState(() => _hora12 = indice + 1),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _Rueda(
                      control: _ruedaMinutos,
                      cuantos: 60 ~/ _pasoMinutos,
                      etiqueta: (indice) =>
                          (indice * _pasoMinutos).toString().padLeft(2, '0'),
                      onCambio: (indice) =>
                          setState(() => _minuto = indice * _pasoMinutos),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PestanasPildora(
            etiquetas: const ['a.m.', 'p.m.'],
            seleccionada: _tarde ? 1 : 0,
            onCambio: (indice) => setState(() => _tarde = indice == 1),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _elegida),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaApp.negro,
                foregroundColor: TemaApp.blanco,
              ),
              child: const Text('Listo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Resaltado extends StatelessWidget {
  const _Resaltado();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _altoFila,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: TemaApp.grisClaro,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _Rueda extends StatelessWidget {
  final FixedExtentScrollController control;
  final int cuantos;
  final String Function(int) etiqueta;
  final ValueChanged<int> onCambio;

  const _Rueda({
    required this.control,
    required this.cuantos,
    required this.etiqueta,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: ListWheelScrollView.useDelegate(
        controller: control,
        itemExtent: _altoFila,
        perspective: 0.004,
        diameterRatio: 1.6,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: (indice) => onCambio(indice % cuantos),
        childDelegate: ListWheelChildLoopingListDelegate(
          children: List.generate(
            cuantos,
            (indice) => Center(
              child: Text(
                etiqueta(indice),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
