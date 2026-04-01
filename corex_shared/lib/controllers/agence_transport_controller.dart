import 'package:get/get.dart';
import '../models/agence_transport_model.dart';
import '../services/agence_transport_service.dart';

class AgenceTransportController extends GetxController {
  final AgenceTransportService _service = Get.find<AgenceTransportService>();

  final RxList<AgenceTransportModel> agencesList = <AgenceTransportModel>[].obs;
  final Rx<AgenceTransportModel?> selectedAgence = Rx<AgenceTransportModel?>(null);
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

  final RxList<AgenceTransportModel> _allAgences = <AgenceTransportModel>[].obs;

  Future<void> loadAgences() async {
    isLoading.value = true;
    try {
      print('📋 [AGENCE_TRANSPORT_CONTROLLER] Chargement des agences transport...');
      _allAgences.value = await _service.getAllAgencesTransport();
      _applyFilters();
      print('✅ [AGENCE_TRANSPORT_CONTROLLER] ${_allAgences.length} agences chargées');
    } catch (e) {
      print('❌ [AGENCE_TRANSPORT_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les agences de transport',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    var filtered = List<AgenceTransportModel>.from(_allAgences);

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
        return a.nom.toLowerCase().contains(query) || a.contact.toLowerCase().contains(query) || a.telephone.contains(query) || a.villesDesservies.any((v) => v.toLowerCase().contains(query));
      }).toList();
    }

    agencesList.value = filtered;
    print('🔍 [AGENCE_TRANSPORT_CONTROLLER] ${filtered.length} agences après filtres');
  }

  Future<bool> createAgence(AgenceTransportModel agence) async {
    try {
      print('➕ [AGENCE_TRANSPORT_CONTROLLER] Création: ${agence.nom}');
      await _service.createAgenceTransport(agence);
      Get.snackbar(
        'Succès',
        'Agence de transport créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadAgences();
      return true;
    } catch (e) {
      print('❌ [AGENCE_TRANSPORT_CONTROLLER] Erreur création: $e');
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
      print('📝 [AGENCE_TRANSPORT_CONTROLLER] Mise à jour: $agenceId');
      await _service.updateAgenceTransport(agenceId, data);
      Get.snackbar(
        'Succès',
        'Agence mise à jour',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadAgences();
      return true;
    } catch (e) {
      print('❌ [AGENCE_TRANSPORT_CONTROLLER] Erreur mise à jour: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'agence',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> toggleStatus(AgenceTransportModel agence) async {
    try {
      final newStatus = !agence.isActive;
      print('🔄 [AGENCE_TRANSPORT_CONTROLLER] Changement statut: ${agence.nom} -> $newStatus');
      await _service.toggleAgenceTransportStatus(agence.id, newStatus);
      Get.snackbar(
        'Succès',
        newStatus ? 'Agence activée' : 'Agence désactivée',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadAgences();
    } catch (e) {
      print('❌ [AGENCE_TRANSPORT_CONTROLLER] Erreur changement statut: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteAgence(AgenceTransportModel agence) async {
    try {
      print('🗑️ [AGENCE_TRANSPORT_CONTROLLER] Suppression: ${agence.nom}');
      await _service.deleteAgenceTransport(agence.id);
      Get.snackbar(
        'Succès',
        'Agence supprimée',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadAgences();
    } catch (e) {
      print('❌ [AGENCE_TRANSPORT_CONTROLLER] Erreur suppression: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer l\'agence',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void selectAgence(AgenceTransportModel agence) {
    selectedAgence.value = agence;
    print('🚌 [AGENCE_TRANSPORT_CONTROLLER] Agence sélectionnée: ${agence.nom}');
  }

  void clearSelection() {
    selectedAgence.value = null;
  }
}
