import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/professional_model.dart';

class ProfessionalService {
  final _ref = FirebaseFirestore.instance.collection('users');

  Stream<List<Professional>> getProfessionals() {
    return _ref.where('role', isEqualTo: 'professional').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .where((doc) => doc.data()['activo'] != false)
          .map((doc) => Professional.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<Professional>> searchProfessionals(String query) async {
    final snapshot = await _ref.where('role', isEqualTo: 'professional').get();

    final all = snapshot.docs
        .where((doc) => doc.data()['activo'] != false)
        .map((doc) => Professional.fromMap(doc.id, doc.data()))
        .toList();

    return all.where((prof) {
      final nameMatch = prof.name.toLowerCase().contains(query.toLowerCase());

      final locationMatch = prof.location.toLowerCase().contains(
        query.toLowerCase(),
      );

      return nameMatch || locationMatch;
    }).toList();
  }
}
