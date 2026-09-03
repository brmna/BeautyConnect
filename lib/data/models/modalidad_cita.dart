import '../../utils/formato.dart';

enum ModalidadCita { local, domicilio }

const String _claveModalidad = 'modalidad';
const String _valorDomicilio = 'domicilio';

extension DatosModalidad on ModalidadCita {
  String get clave =>
      this == ModalidadCita.domicilio ? _valorDomicilio : 'local';

  bool get esDomicilio => this == ModalidadCita.domicilio;

  String get etiqueta =>
      this == ModalidadCita.domicilio ? 'A domicilio' : 'En su local';

  String get etiquetaParaCliente =>
      this == ModalidadCita.domicilio ? 'A domicilio' : 'Voy a su local';
}

ModalidadCita modalidadDeCita(Map<String, dynamic>? cita) =>
    cita?[_claveModalidad] == _valorDomicilio
    ? ModalidadCita.domicilio
    : ModalidadCita.local;

num recargoDeCita(Map<String, dynamic>? cita) =>
    (cita?['recargoDomicilio'] as num?) ?? 0;

num precioServicioDeCita(Map<String, dynamic>? cita) =>
    (cita?['servicePrice'] as num?) ?? 0;

num precioTotalDeCita(Map<String, dynamic>? cita) =>
    precioServicioDeCita(cita) + recargoDeCita(cita);

String precioTotalFormateado(Map<String, dynamic>? cita) =>
    formatearPrecio(precioTotalDeCita(cita));
