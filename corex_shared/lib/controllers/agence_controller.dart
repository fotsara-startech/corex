import 'package:get/get.dart';
import '../models/agence_model.dart';
import '../services/agence_service.dart';

class AgenceController extends GetxController {
  final AgenceService _agenceService = Get.find<AgenceService>();

  final RxList<AgenceModel> agencesList = <AgenceModel>[].obs;
  final Rx<AgenceModel?> selectedAgence = Rx<AgenceModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterStatus = 'tous'.obs;

  @override
  void onInit() {
    super.onInit();
    loadAgences();

    // Écouter les changements de filtres
    ever(searchQuery, (_) => _applyFilters());
    ever(filterStatus, (_) => _applyFilters());
  }

  final RxList<AgenceModel> _allAgences = <AgenceModel>[].obs;

  Future<void> loadAgences() async {
    isLoading.value = true;
    try {
      print('📋 [AGENCE_CONTROLLER] Chargement des agences...');
      _allAgences.value = await _agenceService.getAllAgences();
      _applyFilters();
      print('✅ [AGENCE_CONTROLLER] ${_allAgences.length} agences chargées');
    } catch (e) {
      print('❌ [AGENCE_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les agences',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    var filtered = List<AgenceModel>.from(_allAgences);

    // Filtre par statut
    if (filterStatus.value == 'actif') {
      filtered = filtered.where((a) => a.isActive).toList();
    } else if (filterStatus.value == 'inactif') {
      filtered = filtered.where((a) => !a.isActive).toList();
    }

    // Filtre par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((a) {
        return a.nom.toLowerCase().contains(query) || a.ville.toLowerCase().contains(query) || a.telephone.contains(query) || a.email.toLowerCase().contains(query);
      }).toList();
    }

    agencesList.value = filtered;
    print('🔍 [AGENCE_CONTROLLER] ${filtered.length} agences après filtres');
  }

  Future<bool> createAgence(AgenceModel agence) async {
    try {
      print('➕ [AGENCE_CONTROLLER] Création agence: ${agence.nom}');
      await _agenceService.createAgence(agence);
      Get.snackbar(
        'Succès',
        'Agence créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadAgences();
      return true;
    } catch (e) {
      print('❌ [AGENCE_CONTROLLER] Erreur création: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'agence: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> updateAgence(String agenceId, Map<String, dynamic> data) async {
    try {
      print('📝 [AGENCE_CONTROLLER] Mise à jour agence: $agenceId');
      await _agenceService.updateAgence(agenceId, data);
      Get.snackbar(
        'Succès',
        'Agence mise à jour',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadAgences();
      return true;
    } catch (e) {
      print('❌ [AGENCE_CONTROLLER] Erreur mise à jour: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'agence',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> toggleAgenceStatus(AgenceModel agence) async {
    try {
      final newStatus = !agence.isActive;
      print('🔄 [AGENCE_CONTROLLER] Changement statut: ${agence.nom} -> $newStatus');
      await _agenceService.toggleAgenceStatus(agence.id, newStatus);
      Get.snackbar(
        'Succès',
        newStatus ? 'Agence activée' : 'Agence désactivée',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadAgences();
    } catch (e) {
      print('❌ [AGENCE_CONTROLLER] Erreur changement statut: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteAgence(AgenceModel agence) async {
    try {
      // Vérifier s'il y a des utilisateurs dans cette agence
      final userCount = await _agenceService.countUsersByAgence(agence.id);
      if (userCount > 0) {
        Get.snackbar(
          'Impossible',
          'Cette agence a $userCount utilisateur(s). Veuillez les réassigner avant de supprimer l\'agence.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      print('🗑️ [AGENCE_CONTROLLER] Suppression agence: ${agence.nom}');
      await _agenceService.deleteAgence(agence.id);
      Get.snackbar(
        'Succès',
        'Agence supprimée',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadAgences();
    } catch (e) {
      print('❌ [AGENCE_CONTROLLER] Erreur suppression: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer l\'agence',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void selectAgence(AgenceModel agence) {
    selectedAgence.value = agence;
    print('🏢 [AGENCE_CONTROLLER] Agence sélectionnée: ${agence.nom}');
  }

  void clearSelection() {
    selectedAgence.value = null;
  }
}
