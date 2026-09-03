import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class CalendarioMes extends StatefulWidget {
  final DateTime seleccionada;
  final ValueChanged<DateTime> onSeleccionar;

  const CalendarioMes({
    super.key,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  @override
  State<CalendarioMes> createState() => _CalendarioMesState();
}

class _CalendarioMesState extends State<CalendarioMes> {
  late DateTime _mes;

  @override
  void initState() {
    super.initState();
    _mes = DateTime(widget.seleccionada.year, widget.seleccionada.month);
  }

  @override
  void didUpdateWidget(CalendarioMes anterior) {
    super.didUpdateWidget(anterior);
    if (!DateUtils.isSameMonth(anterior.seleccionada, widget.seleccionada)) {
      _mes = DateTime(widget.seleccionada.year, widget.seleccionada.month);
    }
  }

  void _cambiarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final hoy = DateUtils.dateOnly(DateTime.now());
    final diasDelMes = DateUtils.getDaysInMonth(_mes.year, _mes.month);
    final primerDia = DateTime(_mes.year, _mes.month, 1);
    final desplazamiento = primerDia.weekday - 1;
    final celdas = desplazamiento + diasDelMes;
    final filas = (celdas / 7).ceil();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _cambiarMes(-1),
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Text(
                    DateFormat.yMMMM().format(_mes),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _cambiarMes(1),
                  icon: const Icon(Icons.chevron_right),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: const ['lu', 'ma', 'mi', 'ju', 'vi', 'sa', 'do']
                  .map(
                    (dia) => Expanded(
                      child: Center(
                        child: Text(
                          dia,
                          style: const TextStyle(
                            fontSize: 11,
                            color: TemaApp.grisTexto,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 6),
            for (var fila = 0; fila < filas; fila++)
              Row(
                children: List.generate(7, (columna) {
                  final numero = fila * 7 + columna - desplazamiento + 1;

                  if (numero < 1 || numero > diasDelMes) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final fecha = DateTime(_mes.year, _mes.month, numero);
                  final activa = DateUtils.isSameDay(
                    fecha,
                    widget.seleccionada,
                  );
                  final pasada = fecha.isBefore(hoy);
                  final esHoy = DateUtils.isSameDay(fecha, hoy);

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: pasada ? null : () => widget.onSeleccionar(fecha),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: activa ? TemaApp.negro : null,
                          shape: BoxShape.circle,
                          border: esHoy && !activa
                              ? Border.all(color: TemaApp.negro)
                              : null,
                        ),
                        child: Text(
                          '$numero',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: activa
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: activa
                                ? TemaApp.blanco
                                : pasada
                                ? TemaApp.grisBorde
                                : TemaApp.textoOscuro,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
