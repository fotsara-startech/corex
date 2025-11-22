import 'package:get/get.dart';
import '../models/zone_model.dart';
import 'firebase_service.dart';

class ZoneService extends GetxService {
  Future<List<ZoneModel>> getAllZones() async {
    print('📥 [ZONE_SERVICE] Récupération de toutes les zones...');
    final snapshot = await FirebaseService.zones.get();
    final zones = snapshot.docs.map((doc) => ZoneModel.fromFirestore(doc)).toList();
    print('✅ [ZONE_SERVICE] ${zones.length} zones récupérées');
    return zones;
  }

  Future<List<ZoneModel>> getZonesByAgence(String agenceId) async {
    print('📥 [ZONE_SERVICE] Récupération zones de l\'agence: $agenceId');
    final snapshot = await FirebaseService.zones.where('agenceId', isEqualTo: agenceId).get();
    return snapshot.docs.map((doc) => ZoneModel.fromFirestore(doc)).toList();
  }

  Future<ZoneModel?> getZoneById(String zoneId) async {
    print('📥 [ZONE_SERVICE] Récupération zone: $zoneId');
    final doc = await FirebaseService.zones.doc(zoneId).get();
    if (!doc.exists) {
      print('❌ [ZONE_SERVICE] Zone non trouvée');
      return null;
    }
    return ZoneModel.fromFirestore(doc);
  }

  Future<void> createZone(ZoneModel zone) async {
    print('➕ [ZONE_SERVICE] Création zone: ${zone.nom}');
    await FirebaseService.zones.doc(zone.id).set(zone.toFirestore());
    print('✅ [ZONE_SERVICE] Zone créée');
  }

  Future<void> updateZone(String zoneId, Map<String, dynamic> data) async {
    print('📝 [ZONE_SERVICE] Mise à jour zone: $zoneId');
    await FirebaseService.zones.doc(zoneId).update(data);
    print('✅ [ZONE_SERVICE] Zone mise à jour');
  }

  Future<void> deleteZone(String zoneId) async {
    print('🗑️ [ZONE_SERVICE] Suppression zone: $zoneId');
    await FirebaseService.zones.doc(zoneId).delete();
    print('✅ [ZONE_SERVICE] Zone supprimée');
  }

  Stream<List<ZoneModel>> watchZonesByAgence(String agenceId) {
    return FirebaseService.zones.where('agenceId', isEqualTo: agenceId).snapshots().map((snapshot) => snapshot.docs.map((doc) => ZoneModel.fromFirestore(doc)).toList());
  }
}
