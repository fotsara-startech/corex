import 'package:get/get.dart';
import '../models/agence_transport_model.dart';
import 'firebase_service.dart';

class AgenceTransportService extends GetxService {
  Future<List<AgenceTransportModel>> getAllAgencesTransport() async {
    print('📥 [AGENCE_TRANSPORT_SERVICE] Récupération de toutes les agences transport...');
    final snapshot = await FirebaseService.agencesTransport.get();
    final agences = snapshot.docs.map((doc) => AgenceTransportModel.fromFirestore(doc)).toList();
    print('✅ [AGENCE_TRANSPORT_SERVICE] ${agences.length} agences transport récupérées');
    return agences;
  }

  Future<List<AgenceTransportModel>> getActiveAgencesTransport() async {
    print('📥 [AGENCE_TRANSPORT_SERVICE] Récupération agences transport actives...');
    final snapshot = await FirebaseService.agencesTransport.where('isActive', isEqualTo: true).get();
    return snapshot.docs.map((doc) => AgenceTransportModel.fromFirestore(doc)).toList();
  }

  Future<AgenceTransportModel?> getAgenceTransportById(String agenceId) async {
    print('📥 [AGENCE_TRANSPORT_SERVICE] Récupération agence transport: $agenceId');
    final doc = await FirebaseService.agencesTransport.doc(agenceId).get();
    if (!doc.exists) {
      print('❌ [AGENCE_TRANSPORT_SERVICE] Agence transport non trouvée');
      return null;
    }
    return AgenceTransportModel.fromFirestore(doc);
  }

  Future<void> createAgenceTransport(AgenceTransportModel agence) async {
    print('➕ [AGENCE_TRANSPORT_SERVICE] Création agence transport: ${agence.nom}');
    await FirebaseService.agencesTransport.doc(agence.id).set(agence.toFirestore());
    print('✅ [AGENCE_TRANSPORT_SERVICE] Agence transport créée');
  }

  Future<void> updateAgenceTransport(String agenceId, Map<String, dynamic> data) async {
    print('📝 [AGENCE_TRANSPORT_SERVICE] Mise à jour agence transport: $agenceId');
    await FirebaseService.agencesTransport.doc(agenceId).update(data);
    print('✅ [AGENCE_TRANSPORT_SERVICE] Agence transport mise à jour');
  }

  Future<void> toggleAgenceTransportStatus(String agenceId, bool isActive) async {
    print('🔄 [AGENCE_TRANSPORT_SERVICE] Changement statut: $agenceId -> $isActive');
    await FirebaseService.agencesTransport.doc(agenceId).update({
      'isActive': isActive,
    });
    print('✅ [AGENCE_TRANSPORT_SERVICE] Statut modifié');
  }

  Future<void> deleteAgenceTransport(String agenceId) async {
    print('🗑️ [AGENCE_TRANSPORT_SERVICE] Suppression agence transport: $agenceId');
    await FirebaseService.agencesTransport.doc(agenceId).delete();
    print('✅ [AGENCE_TRANSPORT_SERVICE] Agence transport supprimée');
  }

  Stream<List<AgenceTransportModel>> watchAllAgencesTransport() {
    return FirebaseService.agencesTransport.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => AgenceTransportModel.fromFirestore(doc)).toList(),
        );
  }
}
