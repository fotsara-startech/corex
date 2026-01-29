import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/livraison_model.dart';
import '../models/transaction_model.dart';
import '../models/colis_model.dart';
import 'firebase_service.dart';
import 'transaction_service.dart';
import 'notification_service.dart';
import 'colis_service.dart';

class LivraisonService extends GetxService {
  Future<void> createLivraison(LivraisonModel livraison) async {
    await FirebaseService.livraisons.doc(livraison.id).set(livraison.toFirestore());
  }

  /// Crée une livraison et envoie les notifications d'attribution
  Future<void> createLivraisonWithNotification({
    required LivraisonModel livraison,
    required String colisId,
    required String coursierId,
  }) async {
    // Créer la livraison
    await createLivraison(livraison);

    // Envoyer les notifications
    try {
      if (Get.isRegistered<NotificationService>() && Get.isRegistered<ColisService>()) {
        final notificationService = Get.find<NotificationService>();
        final colisService = Get.find<ColisService>();

        // Récupérer les détails du colis
        final colis = await colisService.getColisById(colisId);
        if (colis != null) {
          await notificationService.notifyLivraisonAttribution(
            livraison: livraison,
            colis: colis,
            coursierId: coursierId,
          );

          print('✅ [LIVRAISON_SERVICE] Notification d\'attribution envoyée pour la livraison ${livraison.id}');
        }
      }
    } catch (e) {
      print('⚠️ [LIVRAISON_SERVICE] Erreur lors de l\'envoi des notifications: $e');
      // Ne pas bloquer la création de la livraison si les notifications échouent
    }
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

  /// Crée automatiquement une transaction de commission COREX lors de la validation de la livraison
  Future<void> createCommissionCorexTransaction(LivraisonModel livraison, ColisModel colis, String userId) async {
    try {
      // Commission COREX = 10% du montant du tarif
      final tauxCommission = 0.10;
      final montantCommission = colis.montantTarif * tauxCommission;

      final transaction = TransactionModel(
        id: const Uuid().v4(),
        agenceId: livraison.agenceId,
        type: 'recette',
        montant: montantCommission,
        date: DateTime.now(),
        categorieRecette: 'commission_livraison',
        description: 'Commission COREX - Livraison colis ${colis.numeroSuivi}',
        reference: colis.numeroSuivi,
        userId: userId,
      );

      // Utiliser le service directement pour ne pas afficher de snackbar
      if (Get.isRegistered<TransactionService>()) {
        final transactionService = Get.find<TransactionService>();
        await transactionService.createTransaction(transaction);
        print('💰 [LIVRAISON_SERVICE] Commission COREX créée pour la livraison du colis ${colis.numeroSuivi}: $montantCommission FCFA');
      }
    } catch (e) {
      print('⚠️ [LIVRAISON_SERVICE] Erreur création commission COREX: $e');
      // Ne pas bloquer la confirmation de livraison si la transaction échoue
    }
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

  /// Récupère les livraisons par période pour le dashboard PDG
  Future<List<LivraisonModel>> getLivraisonsByPeriod(DateTime debut, DateTime fin) async {
    try {
      final snapshot = await FirebaseService.livraisons
          .where('dateCreation', isGreaterThanOrEqualTo: Timestamp.fromDate(debut))
          .where('dateCreation', isLessThanOrEqualTo: Timestamp.fromDate(fin))
          .orderBy('dateCreation', descending: true)
          .get();
      return snapshot.docs.map((doc) => LivraisonModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('⚠️ [LIVRAISON_SERVICE] Erreur récupération livraisons par période: $e');
      return [];
    }
  }
}
