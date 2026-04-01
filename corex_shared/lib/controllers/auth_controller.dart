import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final GetStorage _storage = GetStorage();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  // Clés pour le stockage local
  static const String _userKey = 'current_user';
  static const String _isAuthenticatedKey = 'is_authenticated';

  @override
  void onInit() {
    super.onInit();
    // Vérifier la session dès que le controller est prêt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStoredSession();
    });
  }

  /// Vérifie silencieusement s'il y a une session stockée sans navigation
  Future<void> _checkStoredSession() async {
    try {
      print('🔍 [AUTH] Vérification silencieuse de session...');

      // 1. Vérifier si Firebase Auth a un utilisateur connecté
      final firebaseUser = _authService.currentFirebaseUser;

      if (firebaseUser != null) {
        print('✅ [AUTH] Utilisateur Firebase trouvé: ${firebaseUser.email}');

        // 2. Essayer de récupérer les données utilisateur depuis le stockage local
        final userData = _storage.read(_userKey);
        final wasAuthenticated = _storage.read(_isAuthenticatedKey) ?? false;

        if (userData != null && wasAuthenticated) {
          print('📱 [AUTH] Données utilisateur trouvées dans le cache local');
          try {
            final user = UserModel.fromJson(Map<String, dynamic>.from(userData));

            // 3. Restaurer l'état d'authentification SANS navigation
            currentUser.value = user;
            isAuthenticated.value = true;

            print('🎉 [AUTH] Session restaurée pour ${user.nomComplet} (sans navigation automatique)');

            // 4. Vérifier que l'utilisateur est toujours actif en arrière-plan
            _verifyUserInBackground(user);
            return;
          } catch (e) {
            print('❌ [AUTH] Erreur lors de la restauration des données: $e');
            await _clearStoredAuth();
          }
        }

        // 5. Si pas de données locales, essayer de récupérer depuis Firestore
        try {
          print('🔄 [AUTH] Récupération des données depuis Firestore...');
          if (Get.isRegistered<UserService>()) {
            final userService = Get.find<UserService>();
            final user = await userService.getUserById(firebaseUser.uid);

            if (user != null && user.isActive) {
              currentUser.value = user;
              isAuthenticated.value = true;

              // Sauvegarder dans le cache local
              await _saveAuthState(user);

              print('✅ [AUTH] Utilisateur récupéré depuis Firestore: ${user.nomComplet} (sans navigation automatique)');
              return;
            } else {
              print('⚠️ [AUTH] Utilisateur non trouvé ou inactif dans Firestore');
            }
          } else {
            print('⚠️ [AUTH] UserService non disponible');
          }
        } catch (e) {
          print('⚠️ [AUTH] Erreur récupération Firestore: $e');
          // Ne pas afficher de SnackBar ici car c'est une vérification silencieuse
        }
      } else {
        print('ℹ️ [AUTH] Aucun utilisateur Firebase connecté');
      }

      print('ℹ️ [AUTH] Aucune session valide trouvée - utilisateur doit se connecter');
    } catch (e) {
      print('❌ [AUTH] Erreur lors de la vérification silencieuse: $e');
      // Ne pas afficher de SnackBar ici pour éviter les erreurs de contexte
      // Nettoyer silencieusement en cas d'erreur
      try {
        await _clearStoredAuth();
      } catch (clearError) {
        print('❌ [AUTH] Erreur lors du nettoyage: $clearError');
      }
    }
  }

  /// Méthode publique pour vérifier l'état d'authentification avec navigation
  /// À appeler depuis LoginScreen après que l'interface soit prête
  Future<void> checkAuthState() async {
    await _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    print('🔍 [AUTH] Vérification de l\'état d\'authentification...');

    try {
      // 1. Vérifier si Firebase Auth a un utilisateur connecté
      final firebaseUser = _authService.currentFirebaseUser;

      if (firebaseUser != null) {
        print('✅ [AUTH] Utilisateur Firebase trouvé: ${firebaseUser.email}');

        // 2. Essayer de récupérer les données utilisateur depuis le stockage local
        final userData = _storage.read(_userKey);
        final wasAuthenticated = _storage.read(_isAuthenticatedKey) ?? false;

        if (userData != null && wasAuthenticated) {
          print('📱 [AUTH] Données utilisateur trouvées dans le cache local');
          try {
            final user = UserModel.fromJson(Map<String, dynamic>.from(userData));

            // 3. Vérifier que l'utilisateur est toujours actif en arrière-plan
            _verifyUserInBackground(user);

            // 4. Restaurer l'état d'authentification
            currentUser.value = user;
            isAuthenticated.value = true;

            print('🎉 [AUTH] Session restaurée pour ${user.nomComplet}');

            // 5. Rediriger vers l'écran d'accueil
            Get.offAllNamed('/home');
            return;
          } catch (e) {
            print('❌ [AUTH] Erreur lors de la restauration des données: $e');
            await _clearStoredAuth();
          }
        }

        // 6. Si pas de données locales, essayer de récupérer depuis Firestore
        try {
          print('🔄 [AUTH] Récupération des données depuis Firestore...');
          if (Get.isRegistered<UserService>()) {
            final userService = Get.find<UserService>();
            final user = await userService.getUserById(firebaseUser.uid);

            if (user != null && user.isActive) {
              currentUser.value = user;
              isAuthenticated.value = true;

              // Sauvegarder dans le cache local
              await _saveAuthState(user);

              print('✅ [AUTH] Utilisateur récupéré depuis Firestore: ${user.nomComplet}');
              Get.offAllNamed('/home');
              return;
            }
          }
        } catch (e) {
          print('⚠️ [AUTH] Erreur récupération Firestore: $e');
        }
      }

      // 7. Aucune session valide trouvée
      print('❌ [AUTH] Aucune session valide, redirection vers login');
      await _clearStoredAuth();
      Get.offAllNamed('/login');
    } catch (e) {
      print('❌ [AUTH] Erreur lors de la vérification: $e');
      await _clearStoredAuth();
      Get.offAllNamed('/login');
    }
  }

  /// Vérifie en arrière-plan que l'utilisateur est toujours actif
  Future<void> _verifyUserInBackground(UserModel user) async {
    try {
      if (Get.isRegistered<UserService>()) {
        final userService = Get.find<UserService>();
        final freshUser = await userService.getUserById(user.id);

        if (freshUser == null || !freshUser.isActive) {
          print('⚠️ [AUTH] Utilisateur désactivé, déconnexion...');
          await signOut();
          Get.offAllNamed('/login');
          Get.snackbar(
            'Session expirée',
            'Votre compte a été désactivé. Veuillez contacter l\'administrateur.',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else if (freshUser != user) {
          // Mettre à jour les données si elles ont changé
          currentUser.value = freshUser;
          await _saveAuthState(freshUser);
        }
      }
    } catch (e) {
      print('⚠️ [AUTH] Erreur vérification arrière-plan: $e');
      // Ne pas déconnecter en cas d'erreur réseau
    }
  }

  /// Sauvegarde l'état d'authentification dans le stockage local
  Future<void> _saveAuthState(UserModel user) async {
    try {
      await _storage.write(_userKey, user.toJson());
      await _storage.write(_isAuthenticatedKey, true);
      print('💾 [AUTH] État d\'authentification sauvegardé');
    } catch (e) {
      print('❌ [AUTH] Erreur sauvegarde: $e');
    }
  }

  /// Efface l'état d'authentification du stockage local
  Future<void> _clearStoredAuth() async {
    try {
      await _storage.remove(_userKey);
      await _storage.remove(_isAuthenticatedKey);
      currentUser.value = null;
      isAuthenticated.value = false;
      print('🧹 [AUTH] Cache d\'authentification nettoyé');
    } catch (e) {
      print('❌ [AUTH] Erreur nettoyage cache: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    isLoading.value = true;
    try {
      final user = await _authService.signIn(email, password);
      currentUser.value = user;
      isAuthenticated.value = true;

      // Sauvegarder l'état d'authentification
      await _saveAuthState(user);

      // Redirection automatique selon le rôle
      _redirectAfterLogin(user);

      return true;
    } catch (e) {
      print('❌ [AUTH] Erreur de connexion: $e');

      // Vérifier si GetX est prêt avant d'afficher le SnackBar
      try {
        if (Get.context != null) {
          Get.snackbar(
            'Erreur de connexion',
            e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        } else {
          print('⚠️ [AUTH] Contexte GetX non disponible pour afficher l\'erreur');
        }
      } catch (snackError) {
        print('⚠️ [AUTH] Erreur affichage SnackBar: $snackError');
      }

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Redirige l'utilisateur vers la page appropriée selon son rôle
  void _redirectAfterLogin(UserModel user) {
    print('🔄 [AUTH] Redirection pour utilisateur: ${user.nom} (${user.email})');
    print('🔄 [AUTH] Rôle détecté: ${user.role}');

    if (user.role == 'client') {
      // Les clients vont vers une interface web simplifiée
      print('🎯 [AUTH] Redirection client vers interface web');
      // Pour l'instant, rediriger vers home qui affichera le contenu client
      Get.offAllNamed('/home');
    } else {
      // Tous les autres utilisateurs (employés) vont vers l'interface desktop complète
      print('🎯 [AUTH] Redirection employé vers interface desktop complète');
      Get.offAllNamed('/home');
    }
  }

  Future<void> signOut() async {
    print('🚪 [AUTH] Déconnexion en cours...');

    try {
      // 1. Déconnexion Firebase
      await _authService.signOut();

      // 2. Nettoyer le cache local
      await _clearStoredAuth();

      // 3. Rediriger vers l'écran de connexion
      Get.offAllNamed('/login');

      print('✅ [AUTH] Déconnexion réussie');

      // Vérifier si GetX est prêt avant d'afficher le SnackBar
      try {
        if (Get.context != null) {
          Get.snackbar(
            'Déconnexion',
            'Vous avez été déconnecté avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      } catch (snackError) {
        print('⚠️ [AUTH] Erreur affichage SnackBar déconnexion: $snackError');
      }
    } catch (e) {
      print('❌ [AUTH] Erreur lors de la déconnexion: $e');
      // Forcer le nettoyage même en cas d'erreur
      try {
        await _clearStoredAuth();
        Get.offAllNamed('/login');
      } catch (cleanupError) {
        print('❌ [AUTH] Erreur lors du nettoyage forcé: $cleanupError');
      }
    }
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
