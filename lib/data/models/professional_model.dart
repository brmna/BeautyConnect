import 'ajustes_profesional.dart';

class Professional {
  String get zona => direccion.trim().isNotEmpty ? direccion : location;

  final String id;
  final String name;
  final String? photoUrl;
  final String location;
  final String direccion;
  final String about;
  final List<String> specialties;
  final List<String> services;
  final double rating;
  final int reviewsCount;
  final double? latitude;
  final double? longitude;

  final bool aceptaCitas;

  final bool soloDomicilio;

  final bool vaADomicilio;

  bool get atiendeEnSuLocal => !soloDomicilio;

  bool get apareceEnElMapa =>
      !soloDomicilio && latitude != null && longitude != null;

  Professional({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.location,
    this.direccion = '',
    required this.about,
    required this.specialties,
    required this.services,
    required this.rating,
    required this.reviewsCount,
    this.latitude,
    this.longitude,
    this.aceptaCitas = true,
    this.soloDomicilio = false,
    this.vaADomicilio = false,
  });

  factory Professional.fromMap(String id, Map<String, dynamic> data) {
    return Professional(
      id: id,
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      location: data['location'] ?? '',
      direccion: data['direccion'] ?? '',
      about: data['about'] ?? '',
      specialties: List<String>.from(data['specialties'] ?? []),
      services: List<String>.from(data['services'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      latitude: (data['latitud'] as num?)?.toDouble(),
      longitude: (data['longitud'] as num?)?.toDouble(),
      aceptaCitas: AjustesProfesional.desdeMapa(data).aceptandoClientas,
      soloDomicilio: AjustesProfesional.desdeMapa(data).soloDomicilio,
      vaADomicilio: AjustesProfesional.desdeMapa(data).llegaADomicilio,
    );
  }
}
