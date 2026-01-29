import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Vérifier si un utilisateur est déjà connecté
    if (_authService.currentFirebaseUser != null) {
      // Charger les données utilisateur
      // Cette logique sera implémentée plus tard
    }
  }

  Future<bool> signIn(String email, String password) async {
    isLoading.value = true;
    try {
      final user = await _authService.signIn(email, password);
      currentUser.value = user;
      isAuthenticated.value = true;

      // Redirection automatique selon le rôle
      _redirectAfterLogin(user);

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur de connexion',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Redirige l'utilisateur vers la page appropriée selon son rôle
  void _redirectAfterLogin(UserModel user) {
    print('🔄 [AUTH] Redirection pour utilisateur: ${user.nom} (${user.email})');
    print('🔄 [AUTH] Rôle détecté: ${user.role}');

    // Tous les utilisateurs vont vers /home
    // Le HomeScreen affichera le contenu approprié selon le rôle
    print('🎯 [AUTH] Redirection vers home screen (contenu conditionnel)');
    Get.offAllNamed('/home');
  }

  Future<void> signOut() async {
    await _authService.signOut();
    currentUser.value = null;
    isAuthenticated.value = false;
  }

  bool hasRole(List<String> roles) {
    return currentUser.value != null && roles.contains(currentUser.value!.role);
  }

  bool get isAdmin => currentUser.value?.role == 'admin';
  bool get isPdg => currentUser.value?.role == 'pdg';
  bool get isGestionnaire => currentUser.value?.role == 'gestionnaire';
  bool get isCommercial => currentUser.value?.role == 'commercial';
  bool get isCoursier => currentUser.value?.role == 'coursier';
  bool get isAgent => currentUser.value?.role == 'agent';
}
