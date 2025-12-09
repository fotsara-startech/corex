import 'package:get/get.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';
import 'auth_controller.dart';

class ClientController extends GetxController {
  final ClientService _clientService = Get.find<ClientService>();

  final RxList<ClientModel> clientsList = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  Future<void> loadClients() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) return;

      final clients = await _clientService.getClientsByAgence(user.agenceId!);
      clientsList.value = clients;
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur chargement clients: $e');
      Get.snackbar('Erreur', 'Impossible de charger les clients');
    } finally {
      isLoading.value = false;
    }
  }

  Future<ClientModel?> searchByPhone(String telephone) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) return null;

      return await _clientService.searchClientByPhone(telephone, user.agenceId!);
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur recherche: $e');
      return null;
    }
  }

  Future<bool> createClient(ClientModel client) async {
    try {
      await _clientService.createClient(client);
      await loadClients();
      Get.snackbar('Succès', 'Client enregistré');
      return true;
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur création: $e');
      Get.snackbar('Erreur', 'Impossible de créer le client');
      return false;
    }
  }

  Future<bool> updateClient(String clientId, Map<String, dynamic> data) async {
    try {
      await _clientService.updateClient(clientId, data);
      await loadClients();
      Get.snackbar('Succès', 'Client mis à jour');
      return true;
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur mise à jour: $e');
      Get.snackbar('Erreur', 'Impossible de mettre à jour le client');
      return false;
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await _clientService.deleteClient(clientId);
      await loadClients();
      Get.snackbar('Succès', 'Client supprimé');
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur suppression: $e');
      Get.snackbar('Erreur', 'Impossible de supprimer le client');
    }
  }
}
