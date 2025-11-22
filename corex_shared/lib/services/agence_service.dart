import 'package:get/get.dart';
import '../models/agence_model.dart';
import 'firebase_service.dart';

class AgenceService extends GetxService {
  Future<List<AgenceModel>> getAllAgences() async {
    print('📥 [AGENCE_SERVICE] Récupération de toutes les agences...');
    final snapshot = await FirebaseService.agences.get();
    final agences = snapshot.docs.map((doc) => AgenceModel.fromFirestore(doc)).toList();
    print('✅ [AGENCE_SERVICE] ${agences.length} agences récupérées');
    return agences;
  }

  Future<AgenceModel?> getAgenceById(String agenceId) async {
    print('📥 [AGENCE_SERVICE] Récupération agence: $agenceId');
    final doc = await FirebaseService.agences.doc(agenceId).get();
    if (!doc.exists) {
      print('❌ [AGENCE_SERVICE] Agence non trouvée');
      return null;
    }
    return AgenceModel.fromFirestore(doc);
  }

  Future<void> createAgence(AgenceModel agence) async {
    print('➕ [AGENCE_SERVICE] Création agence: ${agence.nom}');
    await FirebaseService.agences.doc(agence.id).set(agence.toFirestore());
    print('✅ [AGENCE_SERVICE] Agence créée');
  }

  Future<void> updateAgence(String agenceId, Map<String, dynamic> data) async {
    print('📝 [AGENCE_SERVICE] Mise à jour agence: $agenceId');
    await FirebaseService.agences.doc(agenceId).update(data);
    print('✅ [AGENCE_SERVICE] Agence mise à jour');
  }

  Future<void> toggleAgenceStatus(String agenceId, bool isActive) async {
    print('🔄 [AGENCE_SERVICE] Changement statut agence: $agenceId -> $isActive');
    await FirebaseService.agences.doc(agenceId).update({
      'isActive': isActive,
    });
    print('✅ [AGENCE_SERVICE] Statut agence modifié');
  }

  Future<void> deleteAgence(String agenceId) async {
    print('🗑️ [AGENCE_SERVICE] Suppression agence: $agenceId');
    await FirebaseService.agences.doc(agenceId).delete();
    print('✅ [AGENCE_SERVICE] Agence supprimée');
  }

  Stream<List<AgenceModel>> watchAllAgences() {
    return FirebaseService.agences.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => AgenceModel.fromFirestore(doc)).toList(),
        );
  }

  Future<int> countUsersByAgence(String agenceId) async {
    print('🔢 [AGENCE_SERVICE] Comptage utilisateurs agence: $agenceId');
    final snapshot = await FirebaseService.users.where('agenceId', isEqualTo: agenceId).get();
    return snapshot.docs.length;
  }
}
