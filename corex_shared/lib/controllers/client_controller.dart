import 'package:get/get.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';
import '../utils/safe_snackbar.dart';
import 'auth_controller.dart';

class ClientController extends GetxController {
  late final ClientService _clientService;

  final RxList<ClientModel> clientsList = <ClientModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialiser le service de manière sécurisée
    if (!Get.isRegistered<ClientService>()) {
      print('⚠️ [CLIENT_CONTROLLER] ClientService non trouvé, initialisation...');
      Get.put(ClientService(), permanent: true);
    }
    _clientService = Get.find<ClientService>();

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
      safeSnackbar('Erreur', 'Impossible de charger les clients');
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

  Future<ClientModel?> searchByEmail(String email) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) return null;

      return await _clientService.searchClientByEmail(email, user.agenceId!);
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur recherche par email: $e');
      return null;
    }
  }

  Future<List<ClientModel>> searchMultiCriteria(String query) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) return [];

      return await _clientService.searchClientsMultiCriteria(query, user.agenceId!);
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur recherche multi-critères: $e');
      return [];
    }
  }

  Future<bool> createClient(ClientModel client) async {
    try {
      await _clientService.createClient(client);
      await loadClients();
      safeSnackbar('Succès', 'Client enregistré');
      return true;
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur création: $e');
      safeSnackbar('Erreur', 'Impossible de créer le client');
      return false;
    }
  }

  Future<bool> updateClient(String clientId, Map<String, dynamic> data) async {
    try {
      await _clientService.updateClient(clientId, data);
      await loadClients();
      safeSnackbar('Succès', 'Client mis à jour');
      return true;
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur mise à jour: $e');
      safeSnackbar('Erreur', 'Impossible de mettre à jour le client');
      return false;
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await _clientService.deleteClient(clientId);
      await loadClients();
      safeSnackbar('Succès', 'Client supprimé');
    } catch (e) {
      print('❌ [CLIENT_CONTROLLER] Erreur suppression: $e');
      safeSnackbar('Erreur', 'Impossible de supprimer le client');
    }
  }
}
