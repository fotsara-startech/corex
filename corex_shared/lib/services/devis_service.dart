import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/devis_model.dart';

class DevisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> generateNumeroDevis() async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month.toString().padLeft(2, '0');
      final counterDoc = _firestore.collection('counters').doc('devis');

      return await _firestore.runTransaction<String>((transaction) async {
        final snapshot = await transaction.get(counterDoc);
        int counter = 1;
        if (snapshot.exists) {
          counter = (snapshot.data()?['count'] ?? 0) + 1;
        }
        transaction.set(counterDoc, {'count': counter}, SetOptions(merge: true));
        return 'DEV-$year-$month-${counter.toString().padLeft(6, '0')}';
      });
    } catch (e) {
      print('⚠️ [DEVIS_SERVICE] Erreur génération numéro, fallback UUID: $e');
      return 'DEV-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    }
  }

  Future<String> createDevis(DevisModel devis) async {
    try {
      final docRef = await _firestore.collection('devis').add(devis.toFirestore());
      print('✅ [DEVIS_SERVICE] Devis créé: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ [DEVIS_SERVICE] Erreur création devis: $e');
      rethrow;
    }
  }

  Future<void> updateDevis(String id, Map<String, dynamic> data) async {
    try {
      data['dateModification'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('devis').doc(id).update(data);
      print('✅ [DEVIS_SERVICE] Devis mis à jour: $id');
    } catch (e) {
      print('❌ [DEVIS_SERVICE] Erreur mise à jour devis: $e');
      rethrow;
    }
  }

  Future<void> deleteDevis(String id) async {
    try {
      await _firestore.collection('devis').doc(id).delete();
      print('✅ [DEVIS_SERVICE] Devis supprimé: $id');
    } catch (e) {
      print('❌ [DEVIS_SERVICE] Erreur suppression devis: $e');
      rethrow;
    }
  }

  Stream<List<DevisModel>> getDevisByAgence(String agenceId) {
    return _firestore
        .collection('devis')
        .where('agenceId', isEqualTo: agenceId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => DevisModel.fromFirestore(doc)).toList());
  }

  Future<DevisModel?> getDevisById(String id) async {
    try {
      final doc = await _firestore.collection('devis').doc(id).get();
      if (!doc.exists) return null;
      return DevisModel.fromFirestore(doc);
    } catch (e) {
      print('❌ [DEVIS_SERVICE] Erreur récupération devis: $e');
      return null;
    }
  }
}
