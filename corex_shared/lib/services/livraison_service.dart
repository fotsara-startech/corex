import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/livraison_model.dart';
import '../models/transaction_model.dart';
import 'firebase_service.dart';
import 'transaction_service.dart';

class LivraisonService extends GetxService {
  Future<void> createLivraison(LivraisonModel livraison) async {
    await FirebaseService.livraisons.doc(livraison.id).set(livraison.toFirestore());
  }

  Future<void> updateLivraison(String livraisonId, Map<String, dynamic> data) async {
    await FirebaseService.livraisons.doc(livraisonId).update(data);
  }

  Future<LivraisonModel?> getLivraisonById(String livraisonId) async {
    final doc = await FirebaseService.livraisons.doc(livraisonId).get();
    if (!doc.exists) return null;
    return LivraisonModel.fromFirestore(doc);
  }

  Future<List<LivraisonModel>> getLivraisonsByCoursier(String coursierId) async {
    try {
      print('📋 [LIVRAISON_SERVICE] Récupération livraisons pour coursier: $coursierId');

      // D'abord, récupérer TOUTES les livraisons pour debug
      final allSnapshot = await FirebaseService.livraisons.get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ [LIVRAISON_SERVICE] Timeout - Mode offline');
          throw Exception('Timeout: Pas de connexion réseau');
        },
      );

      print('📊 [LIVRAISON_SERVICE] Total livraisons dans Firebase: ${allSnapshot.docs.length}');

      // Afficher les coursierId de toutes les livraisons
      for (var doc in allSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('   - Livraison ${doc.id}: coursierId = ${data['coursierId']}');
      }

      // Maintenant filtrer par coursier
      final snapshot = await FirebaseService.livraisons.where('coursierId', isEqualTo: coursierId).get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ [LIVRAISON_SERVICE] Timeout - Mode offline');
          throw Exception('Timeout: Pas de connexion réseau');
        },
      );

      final livraisons = snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList();
      print('✅ [LIVRAISON_SERVICE] ${livraisons.length} livraisons trouvées pour coursier $coursierId');
      return livraisons;
    } catch (e) {
      print('❌ [LIVRAISON_SERVICE] Erreur: $e');
      // En mode offline, retourner une liste vide
      return [];
    }
  }

  Future<List<LivraisonModel>> getLivraisonsByAgence(String agenceId) async {
    final snapshot = await FirebaseService.livraisons.where('agenceId', isEqualTo: agenceId).get();
    return snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList();
  }

  Future<List<LivraisonModel>> getLivraisonsByStatut(String statut) async {
    final snapshot = await FirebaseService.livraisons.where('statut', isEqualTo: statut).get();
    return snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList();
  }

  Stream<List<LivraisonModel>> watchLivraisonsByCoursier(String coursierId) {
    return FirebaseService.livraisons.where('coursierId', isEqualTo: coursierId).snapshots().map((snapshot) => snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList());
  }

  /// Crée automatiquement une transaction lors de la collecte du paiement à la livraison
  Future<void> createTransactionForLivraison(LivraisonModel livraison, String colisNumero, String userId) async {
    if (!livraison.paiementALaLivraison || !livraison.paiementCollecte || livraison.montantACollecte == null) {
      return; // Pas de paiement à collecter ou pas encore collecté
    }

    try {
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        agenceId: livraison.agenceId,
        type: 'recette',
        montant: livraison.montantACollecte!,
        date: livraison.datePaiementCollecte ?? DateTime.now(),
        categorieRecette: 'livraison',
        description: 'Paiement livraison colis $colisNumero',
        reference: colisNumero,
        userId: userId,
      );

      // Utiliser le service directement pour ne pas afficher de snackbar
      if (Get.isRegistered<TransactionService>()) {
        final transactionService = Get.find<TransactionService>();
        await transactionService.createTransaction(transaction);
        print('💰 [LIVRAISON_SERVICE] Transaction créée pour la livraison du colis $colisNumero');
      }
    } catch (e) {
      print('⚠️ [LIVRAISON_SERVICE] Erreur création transaction: $e');
      // Ne pas bloquer la confirmation de livraison si la transaction échoue
    }
  }

  // Méthode pour récupérer toutes les livraisons (toutes agences) pour le PDG
  Future<List<LivraisonModel>> getAllLivraisons() async {
    final snapshot = await FirebaseService.livraisons.get();
    return snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList();
  }
}
