import 'package:get/get.dart';
import '../models/colis_model.dart';
import '../services/colis_service.dart';
import 'auth_controller.dart';

class ColisController extends GetxController {
  final ColisService _colisService = Get.find<ColisService>();

  final RxList<ColisModel> colisList = <ColisModel>[].obs;
  final Rx<ColisModel?> selectedColis = Rx<ColisModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterStatut = 'tous'.obs;

  @override
  void onInit() {
    super.onInit();
    loadColis();

    // Écouter les changements
    ever(searchQuery, (_) => loadColis());
    ever(filterStatut, (_) => loadColis());
  }

  Future<void> loadColis() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) return;

      List<ColisModel> allColis;

      // Filtrer selon le rôle
      if (user.role == 'commercial') {
        allColis = await _colisService.getColisByCommercial(user.id);
      } else if (user.role == 'agent' || user.role == 'gestionnaire') {
        allColis = await _colisService.getColisByAgence(user.agenceId!);
      } else {
        allColis = await _colisService.getAllColis();
      }

      // Appliquer les filtres
      colisList.value = _applyFilters(allColis);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les colis');
    } finally {
      isLoading.value = false;
    }
  }

  List<ColisModel> _applyFilters(List<ColisModel> colis) {
    var filtered = colis;

    // Filtre par statut
    if (filterStatut.value != 'tous') {
      filtered = filtered.where((c) => c.statut == filterStatut.value).toList();
    }

    // Filtre par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered
          .where((c) =>
              c.numeroSuivi.toLowerCase().contains(query) ||
              c.expediteurNom.toLowerCase().contains(query) ||
              c.destinataireNom.toLowerCase().contains(query) ||
              c.expediteurTelephone.contains(query) ||
              c.destinataireTelephone.contains(query))
          .toList();
    }

    return filtered;
  }

  Future<void> createColis(ColisModel colis) async {
    try {
      print('📦 [COLIS_CONTROLLER] Création du colis: ${colis.numeroSuivi}');
      await _colisService.createColis(colis);
      print('✅ [COLIS_CONTROLLER] Colis créé avec succès');
      Get.snackbar('Succès', 'Colis créé avec succès');
      await loadColis();
    } catch (e) {
      print('❌ [COLIS_CONTROLLER] Erreur création: $e');
      Get.snackbar('Erreur', 'Impossible de créer le colis: $e');
      rethrow;
    }
  }

  Future<void> updateStatut(String colisId, String newStatut, String? commentaire) async {
    try {
      final authController = Get.find<AuthController>();
      await _colisService.updateStatut(
        colisId,
        newStatut,
        authController.currentUser.value!.id,
        commentaire,
      );
      Get.snackbar('Succès', 'Statut mis à jour');
      await loadColis();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour le statut');
    }
  }

  void selectColis(ColisModel colis) {
    selectedColis.value = colis;
  }

  Future<ColisModel?> getColisById(String colisId) async {
    try {
      return await _colisService.getColisById(colisId);
    } catch (e) {
      print('❌ [COLIS_CONTROLLER] Erreur récupération colis: $e');
      return null;
    }
  }
}
