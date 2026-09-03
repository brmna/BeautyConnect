import 'package:cloud_firestore/cloud_firestore.dart';

class Diseno {
  final String id;
  final String profesionalId;
  final String profesionalNombre;
  final String imagenUrl;
  final String? titulo;
  final List<String> etiquetas;
  final int favoritos;

  const Diseno({
    required this.id,
    required this.profesionalId,
    required this.profesionalNombre,
    required this.imagenUrl,
    required this.titulo,
    required this.etiquetas,
    required this.favoritos,
  });

  String get etiquetaPrincipal => etiquetas.isEmpty ? '' : etiquetas.first;

  factory Diseno.desdeDocumento(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final datos = documento.data();
    final guardado = (datos['profesionalId'] as String?)?.trim() ?? '';

    return Diseno(
      id: documento.id,
      profesionalId: guardado.isNotEmpty
          ? guardado
          : (documento.reference.parent.parent?.id ?? ''),
      profesionalNombre: datos['profesionalNombre'] ?? '',
      imagenUrl: datos['imageUrl'] ?? '',
      titulo: (datos['titulo'] as String?)?.trim().isEmpty ?? true
          ? null
          : datos['titulo'],
      etiquetas: List<String>.from(datos['etiquetas'] ?? []),
      favoritos: (datos['favoritos'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> aFavorito() => {
    'profesionalId': profesionalId,
    'profesionalNombre': profesionalNombre,
    'imageUrl': imagenUrl,
    'titulo': titulo,
    'etiquetas': etiquetas,
    'guardadoEn': FieldValue.serverTimestamp(),
  };
}

class CatalogoEtiquetas {
  static const List<String> sugeridas = [
    'Francesa',
    'Nude',
    'Gel',
    'Acrilicas',
    'Nail Art',
    'Minimalista',
    'Ombre',
    'Esmaltado Permanente',
    'Diseños 3D',
    'Cristales',
    'Encapsulado',
    'Pedicura',
  ];
}
