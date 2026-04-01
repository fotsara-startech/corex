import 'package:get/get.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

class UserService extends GetxService {
  Future<List<UserModel>> getAllUsers() async {
    print('📥 [USER_SERVICE] Récupération de tous les utilisateurs...');
    final snapshot = await FirebaseService.users.get();
    final users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    print('✅ [USER_SERVICE] ${users.length} utilisateurs récupérés');
    return users;
  }

  Future<UserModel?> getUserById(String userId) async {
    print('📥 [USER_SERVICE] Récupération utilisateur: $userId');
    final doc = await FirebaseService.users.doc(userId).get();
    if (!doc.exists) {
      print('❌ [USER_SERVICE] Utilisateur non trouvé');
      return null;
    }
    return UserModel.fromFirestore(doc);
  }

  Future<List<UserModel>> getUsersByAgence(String agenceId) async {
    print('📥 [USER_SERVICE] Récupération utilisateurs de l\'agence: $agenceId');
    final snapshot = await FirebaseService.users.where('agenceId', isEqualTo: agenceId).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    print('📥 [USER_SERVICE] Récupération utilisateurs avec rôle: $role');
    final snapshot = await FirebaseService.users.where('role', isEqualTo: role).get();
    return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    print('📝 [USER_SERVICE] Mise à jour utilisateur: $userId');
    await FirebaseService.users.doc(userId).update(data);
    print('✅ [USER_SERVICE] Utilisateur mis à jour');
  }

  Future<void> toggleUserStatus(String userId, bool isActive) async {
    print('🔄 [USER_SERVICE] Changement statut utilisateur: $userId -> $isActive');
    await FirebaseService.users.doc(userId).update({
      'isActive': isActive,
    });
    print('✅ [USER_SERVICE] Statut utilisateur modifié');
  }

  Future<void> deleteUser(String userId) async {
    print('🗑️ [USER_SERVICE] Suppression utilisateur: $userId');
    await FirebaseService.users.doc(userId).delete();
    print('✅ [USER_SERVICE] Utilisateur supprimé');
  }

  Stream<List<UserModel>> watchAllUsers() {
    return FirebaseService.users.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<UserModel>> watchUsersByAgence(String agenceId) {
    return FirebaseService.users.where('agenceId', isEqualTo: agenceId).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList(),
        );
  }
}
