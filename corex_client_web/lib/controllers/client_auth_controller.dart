import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:corex_shared/corex_shared.dart';

class ClientAuthController extends GetxController {
  late final AuthService _authService;
  final GetStorage _storage = GetStorage();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  // Clés pour le stockage local
  static const String _userKey = 'client_user';
  static const String _isAuthenticatedKey = 'client_authenticated';

  @override
  void onInit() {
    super.onInit();

    // Initialiser AuthService de manière sécurisée
    try {
      _authService = Get.find<AuthService>();
    } catch (e) {
      print('⚠️ [CLIENT AUTH] AuthService non trouvé, création: $e');
      _authService = Get.put(AuthService());
    }

    _checkStoredSession();
  }

  /// Vérifie s'il y a une session stockée
  Future<void> _checkStoredSession() async {
    try {
      final firebaseUser = _authService.currentFirebaseUser;

      if (firebaseUser != null) {
        print('✅ [CLIENT AUTH] Utilisateur Firebase trouvé: ${firebaseUser.email}');

        final userData = _storage.read(_userKey);
        final wasAuthenticated = _storage.read(_isAuthenticatedKey) ?? false;

        if (userData != null && wasAuthenticated) {
          print('📱 [CLIENT AUTH] Données utilisateur trouvées dans le cache');
          try {
            final user = UserModel.fromJson(Map<String, dynamic>.from(userData));

            // Vérifier que c'est bien un client
            if (user.role == 'client') {
              currentUser.value = user;
              isAuthenticated.value = true;
              print('🎉 [CLIENT AUTH] Session client restaurée pour ${user.nomComplet}');
              return;
            }
          } catch (e) {
            print('❌ [CLIENT AUTH] Erreur restauration: $e');
            await _clearStoredAuth();
          }
        }
      }

      print('ℹ️ [CLIENT AUTH] Aucune session client valide');
    } catch (e) {
      print('❌ [CLIENT AUTH] Erreur vérification session: $e');
    }
  }

  /// Inscription d'un nouveau client
  Future<bool> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
  }) async {
    isLoading.value = true;
    try {
      print('📝 [CLIENT AUTH] Inscription client: $email');

      // Créer le compte Firebase et Firestore avec rôle 'client'
      final user = await _authService.createUser(
        email: email,
        password: password,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        role: 'client', // Rôle spécifique client
      );

      currentUser.value = user;
      isAuthenticated.value = true;

      // Sauvegarder la session
      await _saveAuthState(user);

      print('✅ [CLIENT AUTH] Inscription réussie pour ${user.nomComplet}');

      Get.snackbar(
        'Inscription réussie',
        'Bienvenue ${user.prenom} ! Votre compte a été créé avec succès.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
      );

      // Rediriger vers le dashboard
      Get.offAllNamed('/dashboard');

      return true;
    } catch (e) {
      print('❌ [CLIENT AUTH] Erreur inscription: $e');
      Get.snackbar(
        'Erreur d\'inscription',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Connexion client
  Future<bool> signIn(String email, String password) async {
    isLoading.value = true;
    try {
      print('🔐 [CLIENT AUTH] Connexion client: $email');

      final user = await _authService.signIn(email, password);

      // Vérifier que c'est bien un client
      if (user.role != 'client') {
        await _authService.signOut();
        throw Exception('Accès non autorisé. Cette interface est réservée aux clients.');
      }

      currentUser.value = user;
      isAuthenticated.value = true;

      // Sauvegarder la session
      await _saveAuthState(user);

      print('✅ [CLIENT AUTH] Connexion réussie pour ${user.nomComplet}');

      Get.snackbar(
        'Connexion réussie',
        'Bienvenue ${user.prenom} !',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
      );

      // Rediriger vers le dashboard
      Get.offAllNamed('/dashboard');

      return true;
    } catch (e) {
      print('❌ [CLIENT AUTH] Erreur connexion: $e');
      Get.snackbar(
        'Erreur de connexion',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    print('🚪 [CLIENT AUTH] Déconnexion client...');

    try {
      await _authService.signOut();
      await _clearStoredAuth();

      Get.offAllNamed('/login');

      Get.snackbar(
        'Déconnexion',
        'Vous avez été déconnecté avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2E7D32),
        colorText: Colors.white,
      );

      print('✅ [CLIENT AUTH] Déconnexion réussie');
    } catch (e) {
      print('❌ [CLIENT AUTH] Erreur déconnexion: $e');
      await _clearStoredAuth();
      Get.offAllNamed('/login');
    }
  }

  /// Sauvegarde l'état d'authentification
  Future<void> _saveAuthState(UserModel user) async {
    try {
      await _storage.write(_userKey, user.toJson());
      await _storage.write(_isAuthenticatedKey, true);
      print('💾 [CLIENT AUTH] État sauvegardé');
    } catch (e) {
      print('❌ [CLIENT AUTH] Erreur sauvegarde: $e');
    }
  }

  /// Efface l'état d'authentification
  Future<void> _clearStoredAuth() async {
    try {
      await _storage.remove(_userKey);
      await _storage.remove(_isAuthenticatedKey);
      currentUser.value = null;
      isAuthenticated.value = false;
      print('🧹 [CLIENT AUTH] Cache nettoyé');
    } catch (e) {
      print('❌ [CLIENT AUTH] Erreur nettoyage: $e');
    }
  }

  /// Vérifier si l'utilisateur est connecté
  void checkAuthState() {
    if (isAuthenticated.value && currentUser.value != null) {
      Get.offAllNamed('/dashboard');
    } else {
      Get.offAllNamed('/login');
    }
  }
}
