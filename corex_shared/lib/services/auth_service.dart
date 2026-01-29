import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel> signIn(String email, String password) async {
    try {
      print('🔐 [AUTH] Tentative de connexion pour: $email');

      // Vérifier que Firebase Auth est disponible
      if (_auth.app.options.projectId.isEmpty) {
        throw Exception('Firebase Auth non initialisé correctement');
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ [AUTH] Authentification Firebase réussie pour UID: ${credential.user!.uid}');

      // Récupérer les données utilisateur depuis Firestore
      print('📥 [FIRESTORE] Récupération des données utilisateur...');
      final userDoc = await FirebaseService.users.doc(credential.user!.uid).get();

      print('📊 [FIRESTORE] Document existe: ${userDoc.exists}');

      if (!userDoc.exists) {
        print('❌ [FIRESTORE] Utilisateur non trouvé dans Firestore');
        await _auth.signOut();
        throw Exception('Utilisateur non trouvé dans la base de données');
      }

      print('✅ [FIRESTORE] Données utilisateur récupérées');
      final user = UserModel.fromFirestore(userDoc);

      print('👤 [USER] Nom: ${user.nomComplet}, Rôle: ${user.role}, Actif: ${user.isActive}');

      if (!user.isActive) {
        print('❌ [USER] Compte désactivé');
        await _auth.signOut();
        throw Exception('Compte désactivé. Contactez l\'administrateur');
      }

      // Mettre à jour lastLogin
      print('📝 [FIRESTORE] Mise à jour lastLogin...');
      await FirebaseService.users.doc(user.id).update({
        'lastLogin': Timestamp.now(),
      });

      print('🎉 [AUTH] Connexion réussie pour ${user.nomComplet}');
      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ [AUTH ERROR] Code: ${e.code}, Message: ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      print('❌ [ERROR] Erreur de connexion: $e');
      print('📍 [STACK] $stackTrace');
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel> createUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    String? agenceId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        role: role,
        agenceId: agenceId,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await FirebaseService.users.doc(user.id).set(user.toFirestore());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur de création: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'invalid-email':
        return 'Email invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
