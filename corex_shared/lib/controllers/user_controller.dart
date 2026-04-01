import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

class UserController extends GetxController {
  late final UserService _userService;
  late final AuthService _authService;

  final RxList<UserModel> usersList = <UserModel>[].obs;
  final Rx<UserModel?> selectedUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterRole = 'tous'.obs;
  final RxString filterStatus = 'tous'.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialiser les services de manière sécurisée
    if (!Get.isRegistered<UserService>()) {
      print('⚠️ [USER_CONTROLLER] UserService non trouvé, initialisation...');
      Get.put(UserService(), permanent: true);
    }
    _userService = Get.find<UserService>();

    if (!Get.isRegistered<AuthService>()) {
      print('⚠️ [USER_CONTROLLER] AuthService non trouvé, initialisation...');
      Get.put(AuthService(), permanent: true);
    }
    _authService = Get.find<AuthService>();

    loadUsers();

    // Écouter les changements de filtres
    ever(searchQuery, (_) => _applyFilters());
    ever(filterRole, (_) => _applyFilters());
    ever(filterStatus, (_) => _applyFilters());
  }

  final RxList<UserModel> _allUsers = <UserModel>[].obs;

  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      print('📋 [USER_CONTROLLER] Chargement des utilisateurs...');
      _allUsers.value = await _userService.getAllUsers();
      _applyFilters();
      print('✅ [USER_CONTROLLER] ${_allUsers.length} utilisateurs chargés');
    } catch (e) {
      print('❌ [USER_CONTROLLER] Erreur: $e');
      Get.snackbar('Erreur', 'Impossible de charger les utilisateurs');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    var filtered = List<UserModel>.from(_allUsers);

    // Filtre par rôle
    if (filterRole.value != 'tous') {
      filtered = filtered.where((u) => u.role == filterRole.value).toList();
    }

    // Filtre par statut
    if (filterStatus.value == 'actif') {
      filtered = filtered.where((u) => u.isActive).toList();
    } else if (filterStatus.value == 'inactif') {
      filtered = filtered.where((u) => !u.isActive).toList();
    }

    // Filtre par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((u) {
        return u.nomComplet.toLowerCase().contains(query) || u.email.toLowerCase().contains(query) || u.telephone.contains(query);
      }).toList();
    }

    usersList.value = filtered;
    print('🔍 [USER_CONTROLLER] ${filtered.length} utilisateurs après filtres');
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    String? agenceId,
  }) async {
    try {
      print('➕ [USER_CONTROLLER] Création utilisateur: $email');
      await _authService.createUser(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        role: role,
        agenceId: agenceId,
      );
      Get.snackbar(
        'Succès',
        'Utilisateur créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadUsers();
      return true;
    } catch (e) {
      print('❌ [USER_CONTROLLER] Erreur création: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'utilisateur: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      print('📝 [USER_CONTROLLER] Mise à jour utilisateur: $userId');
      await _userService.updateUser(userId, data);
      Get.snackbar(
        'Succès',
        'Utilisateur mis à jour',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadUsers();
      return true;
    } catch (e) {
      print('❌ [USER_CONTROLLER] Erreur mise à jour: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'utilisateur',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<void> toggleUserStatus(UserModel user) async {
    try {
      final newStatus = !user.isActive;
      print('🔄 [USER_CONTROLLER] Changement statut: ${user.email} -> $newStatus');
      await _userService.toggleUserStatus(user.id, newStatus);
      Get.snackbar(
        'Succès',
        newStatus ? 'Utilisateur activé' : 'Utilisateur désactivé',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadUsers();
    } catch (e) {
      print('❌ [USER_CONTROLLER] Erreur changement statut: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de modifier le statut',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> deleteUser(UserModel user) async {
    try {
      print('🗑️ [USER_CONTROLLER] Suppression utilisateur: ${user.email}');
      await _userService.deleteUser(user.id);
      Get.snackbar(
        'Succès',
        'Utilisateur supprimé',
        snackPosition: SnackPosition.BOTTOM,
      );
      await loadUsers();
    } catch (e) {
      print('❌ [USER_CONTROLLER] Erreur suppression: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer l\'utilisateur',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void selectUser(UserModel user) {
    selectedUser.value = user;
    print('👤 [USER_CONTROLLER] Utilisateur sélectionné: ${user.nomComplet}');
  }

  void clearSelection() {
    selectedUser.value = null;
  }
}
