import 'package:get/get.dart';
import '../models/zone_model.dart';
import '../services/zone_service.dart';
import 'auth_controller.dart';

class ZoneController extends GetxController {
  final ZoneService _zoneService = Get.find<ZoneService>();

  final RxList<ZoneModel> zonesList = <ZoneModel>[].obs;
  final Rx<ZoneModel?> selectedZone = Rx<ZoneModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterAgence = 'tous'.obs;

  @override
  void onInit() {
    super.onInit();
    loadZones();

    // Écouter les changements de filtres
    ever(searchQuery, (_) => _applyFilters());
    ever(filterAgence, (_) => _applyFilters());
  }

  final RxList<ZoneModel> _allZones = <ZoneModel>[].obs;

  Future<void> loadZones() async {
    isLoading.value = true;
    try {
      print('📋 [ZONE_CONTROLLER] Chargement des zones...');
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) return;

      // Si gestionnaire, charger uniquement les zones de son agence
      if (user.role == 'gestionnaire' && user.agenceId != null) {
        _allZones.value = await _zoneService.getZonesByAgence(user.agenceId!);
      } else {
        _allZones.value = await _zoneService.getAllZones();
      }

      _applyFilters();
      print('✅ [ZONE_CONTROLLER] ${_allZones.length} zones chargées');
    } catch (e) {
      print('❌ [ZONE_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les zones',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    var filtered = List<ZoneModel>.from(_allZones);

    // Filtre par agence
    if (filterAgence.value != 'tous') {
      filtered = filtered.where((z) => z.agenceId == filterAgence.value).toList();
    }

    // Filtre par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((z) {
        return z.nom.toLowerCase().contains(query) || z.ville.toLowerCase().contains(query) || z.quartiers.any((q) => q.toLowerCase().contains(query));
      }).toList();
    }

    zonesList.value = filtered;
    print('🔍 [ZONE_CONTROLLER] ${filtered.length} zones après filtres');
  }

  Future<bool> createZone(ZoneModel zone) async {
    try {
      print('➕ [ZONE_CONTROLLER] Création zone: ${zone.nom}');
      await _zoneService.createZone(zone);
      Get.snackbar(
        'Succès',
        'Zone créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadZones();
      return true;
    } catch (e) {
      print('❌ [ZONE_CONTROLLER] Erreur création: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer la zone: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> updateZone(String zoneId, Map<String, dynamic> data) async {
    try {
      print('📝 [ZONE_CONTROLLER] Mise à jour zone: $zoneId');
      await _zoneService.updateZone(zoneId, data);
      Get.snackbar(
        'Succès',
        'Zone mise à jour',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadZones();
      return true;
    } catch (e) {
      print('❌ [ZONE_CONTROLLER] Erreur mise à jour: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour la zone',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> deleteZone(ZoneModel zone) async {
    try {
      print('🗑️ [ZONE_CONTROLLER] Suppression zone: ${zone.nom}');
      await _zoneService.deleteZone(zone.id);
      Get.snackbar(
        'Succès',
        'Zone supprimée',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadZones();
    } catch (e) {
      print('❌ [ZONE_CONTROLLER] Erreur suppression: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la zone',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void selectZone(ZoneModel zone) {
    selectedZone.value = zone;
    print('📍 [ZONE_CONTROLLER] Zone sélectionnée: ${zone.nom}');
  }

  void clearSelection() {
    selectedZone.value = null;
  }
}
