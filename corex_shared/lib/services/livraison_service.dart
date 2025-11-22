import 'package:get/get.dart';
import '../models/livraison_model.dart';
import 'firebase_service.dart';

class LivraisonService extends GetxService {
  Future<void> createLivraison(LivraisonModel livraison) async {
    await FirebaseService.livraisons.doc(livraison.id).set(livraison.toFirestore());
  }

  Future<void> updateLivraison(String livraisonId, Map<String, dynamic> data) async {
    await FirebaseService.livraisons.doc(livraisonId).update(data);
  }

  Future<LivraisonModel?> getLivraisonById(String livraisonId) async {
    final doc = await FirebaseService.livraisons.doc(livraisonId).get();
    if (!doc.exists) return null;
    return LivraisonModel.fromFirestore(doc);
  }

  Future<List<LivraisonModel>> getLivraisonsByCoursier(String coursierId) async {
    final snapshot = await FirebaseService.livraisons.where('coursierId', isEqualTo: coursierId).get();
    return snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList();
  }

  Future<List<LivraisonModel>> getLivraisonsByAgence(String agenceId) async {
    final snapshot = await FirebaseService.livraisons.where('agenceId', isEqualTo: agenceId).get();
    return snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList();
  }

  Future<List<LivraisonModel>> getLivraisonsByStatut(String statut) async {
    final snapshot = await FirebaseService.livraisons.where('statut', isEqualTo: statut).get();
    return snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList();
  }

  Stream<List<LivraisonModel>> watchLivraisonsByCoursier(String coursierId) {
    return FirebaseService.livraisons.where('coursierId', isEqualTo: coursierId).snapshots().map((snapshot) => snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList());
  }
}
