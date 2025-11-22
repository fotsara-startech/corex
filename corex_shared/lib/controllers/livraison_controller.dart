import 'package:get/get.dart';
import '../models/livraison_model.dart';
import '../services/livraison_service.dart';
import 'auth_controller.dart';

class LivraisonController extends GetxController {
  final LivraisonService _livraisonService = Get.find<LivraisonService>();

  final RxList<LivraisonModel> livraisonsList = <LivraisonModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadLivraisons();
  }

  Future<void> loadLivraisons() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) return;

      if (user.role == 'coursier') {
        livraisonsList.value = await _livraisonService.getLivraisonsByCoursier(user.id);
      } else if (user.agenceId != null) {
        livraisonsList.value = await _livraisonService.getLivraisonsByAgence(user.agenceId!);
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les livraisons');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createLivraison(LivraisonModel livraison) async {
    try {
      await _livraisonService.createLivraison(livraison);
      Get.snackbar('Succès', 'Livraison créée et attribuée');
      await loadLivraisons();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer la livraison');
    }
  }

  Future<void> updateLivraison(String livraisonId, Map<String, dynamic> data) async {
    try {
      await _livraisonService.updateLivraison(livraisonId, data);
      Get.snackbar('Succès', 'Livraison mise à jour');
      await loadLivraisons();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour la livraison');
    }
  }
}
