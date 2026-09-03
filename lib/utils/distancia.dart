import 'dart:math';

const double _radioTierraKm = 6371.0;

double distanciaKm({
  required double latitudA,
  required double longitudA,
  required double latitudB,
  required double longitudB,
}) {
  final dLat = _aRadianes(latitudB - latitudA);
  final dLon = _aRadianes(longitudB - longitudA);

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_aRadianes(latitudA)) *
          cos(_aRadianes(latitudB)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  return _radioTierraKm * 2 * atan2(sqrt(a), sqrt(1 - a));
}

String formatearDistancia(double kilometros) {
  if (kilometros < 1) return '${(kilometros * 1000).round()} m';
  if (kilometros < 10) {
    return '${kilometros.toStringAsFixed(1).replaceAll('.', ',')} km';
  }
  return '${kilometros.round()} km';
}

double _aRadianes(double grados) => grados * pi / 180;
