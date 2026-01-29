import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/colis_model.dart';
import '../models/transaction_model.dart';
import '../repositories/local_colis_repository.dart';
import 'firebase_service.dart';
import 'transaction_service.dart';
import 'notification_service.dart';

class ColisService extends GetxService {
  LocalColisRepository? _localRepo;

  @override
  void onInit() {
    super.onInit();
    // Récupérer le repository local s'il est disponible
    if (Get.isRegistered<LocalColisRepository>()) {
      _localRepo = Get.find<LocalColisRepository>();
    }
  }

  Future<String> generateNumeroSuivi() async {
    try {
      final year = DateTime.now().year;
      final counterDoc = FirebaseService.counters.doc('colis_$year');

      // Lire le compteur actuel
      final snapshot = await counterDoc.get();

      int counter = 0;
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>?;
        counter = data?['count'] ?? 0;
      }

      // Incrémenter
      counter++;

      // Mettre à jour (sans transaction pour éviter les problèmes sur Windows)
      await counterDoc.set({'count': counter});

      final numeroSuivi = 'COL-$year-${counter.toString().padLeft(6, '0')}';
      print('📦 [COLIS_SERVICE] Numéro généré: $numeroSuivi');
      return numeroSuivi;
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Mode offline détecté, génération numéro temporaire: $e');
      // En mode offline, générer un numéro temporaire avec timestamp
      // Il sera remplacé par un numéro définitif lors de la synchronisation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'COL-${DateTime.now().year}-TEMP$timestamp';
    }
  }

  /// Génère un numéro de suivi temporaire pour le mode offline
  String generateNumeroSuiviTemporaire() {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final numeroSuivi = 'COL-$year-TEMP$timestamp';
    print('📦 [COLIS_SERVICE] Numéro temporaire généré (offline): $numeroSuivi');
    return numeroSuivi;
  }

  /// Crée un colis avec approche hybride (local + cloud)
  Future<void> createColis(ColisModel colis) async {
    print('📦 [COLIS_SERVICE] Enregistrement du colis ${colis.numeroSuivi} (ID: ${colis.id})');

    // 1. TOUJOURS sauvegarder localement en premier (garantie)
    if (_localRepo != null) {
      await _localRepo!.saveColis(colis);
      print('✅ [COLIS_SERVICE] Colis sauvegardé localement');
    }

    // 2. Tenter de sauvegarder dans Firebase avec timeout de 5 secondes
    try {
      final data = colis.toFirestore();
      await FirebaseService.colis.doc(colis.id).set(data).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout: Pas de connexion réseau');
        },
      );
      print('✅ [COLIS_SERVICE] Colis enregistré dans Firestore');
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Échec Firestore (mode offline): $e');

      // Marquer pour synchronisation ultérieure
      if (_localRepo != null) {
        await _localRepo!.markPendingSync(colis.id);
        print('🔄 [COLIS_SERVICE] Colis marqué pour synchronisation');
      }

      // Ne pas lancer d'erreur car le colis est sauvegardé localement
    }
  }

  Future<void> updateColis(String colisId, Map<String, dynamic> data) async {
    await FirebaseService.colis.doc(colisId).update(data);
  }

  Future<ColisModel?> getColisById(String colisId) async {
    final doc = await FirebaseService.colis.doc(colisId).get();
    if (!doc.exists) return null;
    return ColisModel.fromFirestore(doc);
  }

  /// Récupère tous les colis (local + cloud fusionnés)
  Future<List<ColisModel>> getAllColis() async {
    try {
      final snapshot = await FirebaseService.colis.get();
      final cloudColis = snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();

      // Fusionner avec les colis locaux non synchronisés
      if (_localRepo != null) {
        final localColis = _localRepo!.getAllColis();
        final mergedColis = _mergeColis(cloudColis, localColis);
        return mergedColis;
      }

      return cloudColis;
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Erreur cloud, utilisation cache local: $e');
      // En cas d'erreur, retourner uniquement les colis locaux
      return _localRepo?.getAllColis() ?? [];
    }
  }

  Future<List<ColisModel>> getColisByAgence(String agenceId) async {
    try {
      final snapshot = await FirebaseService.colis.where('agenceCorexId', isEqualTo: agenceId).get();
      final cloudColis = snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();

      if (_localRepo != null) {
        final localColis = _localRepo!.getColisByAgence(agenceId);
        return _mergeColis(cloudColis, localColis);
      }

      return cloudColis;
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Erreur cloud, utilisation cache local: $e');
      return _localRepo?.getColisByAgence(agenceId) ?? [];
    }
  }

  Future<List<ColisModel>> getColisByCommercial(String commercialId) async {
    try {
      final snapshot = await FirebaseService.colis.where('commercialId', isEqualTo: commercialId).get();
      final cloudColis = snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();

      if (_localRepo != null) {
        final localColis = _localRepo!.getColisByCommercial(commercialId);
        return _mergeColis(cloudColis, localColis);
      }

      return cloudColis;
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Erreur cloud, utilisation cache local: $e');
      return _localRepo?.getColisByCommercial(commercialId) ?? [];
    }
  }

  Future<List<ColisModel>> getColisByStatut(String statut) async {
    try {
      final snapshot = await FirebaseService.colis.where('statut', isEqualTo: statut).get();
      final cloudColis = snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();

      if (_localRepo != null) {
        final localColis = _localRepo!.getColisByStatut(statut);
        return _mergeColis(cloudColis, localColis);
      }

      return cloudColis;
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Erreur cloud, utilisation cache local: $e');
      return _localRepo?.getColisByStatut(statut) ?? [];
    }
  }

  /// Fusionne les colis cloud et locaux, en privilégiant les locaux non synchronisés
  List<ColisModel> _mergeColis(List<ColisModel> cloudColis, List<ColisModel> localColis) {
    final Map<String, ColisModel> merged = {};

    // Ajouter tous les colis cloud
    for (final colis in cloudColis) {
      merged[colis.id] = colis;
    }

    // Ajouter/remplacer avec les colis locaux en attente de sync
    for (final colis in localColis) {
      if (_localRepo?.isPendingSync(colis.id) ?? false) {
        merged[colis.id] = colis; // Privilégier la version locale
      }
    }

    return merged.values.toList();
  }

  Future<ColisModel?> searchColisByNumero(String numeroSuivi) async {
    final snapshot = await FirebaseService.colis.where('numeroSuivi', isEqualTo: numeroSuivi).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return ColisModel.fromFirestore(snapshot.docs.first);
  }

  Future<void> updateStatut(
    String colisId,
    String newStatut,
    String userId,
    String? commentaire,
  ) async {
    final colisDoc = await FirebaseService.colis.doc(colisId).get();
    if (!colisDoc.exists) {
      throw Exception('Colis non trouvé');
    }

    final colis = ColisModel.fromFirestore(colisDoc);
    final oldStatut = colis.statut;

    // Ajouter à l'historique
    final historique = List<HistoriqueStatut>.from(colis.historique);
    historique.add(HistoriqueStatut(
      statut: newStatut,
      date: DateTime.now(),
      userId: userId,
      commentaire: commentaire,
    ));

    // Préparer les données à mettre à jour
    final updateData = {
      'statut': newStatut,
      'historique': historique.map((h) => h.toMap()).toList(),
    };

    // Ajouter les dates selon le statut
    if (newStatut == 'enregistre') {
      updateData['dateEnregistrement'] = Timestamp.now();
    } else if (newStatut == 'livre' || newStatut == 'retire') {
      updateData['dateLivraison'] = Timestamp.now();
    }

    await FirebaseService.colis.doc(colisId).update(updateData);

    // Envoyer les notifications automatiques
    try {
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = Get.find<NotificationService>();
        final updatedColis = colis.copyWith(statut: newStatut, historique: historique);

        // Notification de changement de statut
        await notificationService.notifyColisStatusChange(
          colis: updatedColis,
          newStatus: newStatut,
          changedBy: userId,
        );

        // Notification spéciale d'arrivée à destination
        if (newStatut == 'arriveDestination') {
          await notificationService.notifyColisArrival(colis: updatedColis);
        }

        print('✅ [COLIS_SERVICE] Notifications envoyées pour changement de statut: $oldStatut → $newStatut');
      }
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Erreur lors de l\'envoi des notifications: $e');
      // Ne pas bloquer la mise à jour du statut si les notifications échouent
    }
  }

  Stream<List<ColisModel>> watchColisByAgence(String agenceId) {
    return FirebaseService.colis.where('agenceCorexId', isEqualTo: agenceId).snapshots().map((snapshot) => snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList());
  }

  Stream<List<ColisModel>> watchColisByCommercial(String commercialId) {
    return FirebaseService.colis.where('commercialId', isEqualTo: commercialId).snapshots().map((snapshot) => snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList());
  }

  /// Crée automatiquement une transaction lors du paiement d'un colis
  Future<void> createTransactionForColis(ColisModel colis, String userId) async {
    if (!colis.isPaye || colis.datePaiement == null) {
      return; // Pas de paiement, pas de transaction
    }

    try {
      final transaction = TransactionModel(
        id: const Uuid().v4(),
        agenceId: colis.agenceCorexId,
        type: 'recette',
        montant: colis.montantTarif,
        date: colis.datePaiement!,
        categorieRecette: 'expedition',
        description: 'Paiement colis ${colis.numeroSuivi}',
        reference: colis.numeroSuivi,
        userId: userId,
      );

      // Utiliser le service directement pour ne pas afficher de snackbar
      if (Get.isRegistered<TransactionService>()) {
        final transactionService = Get.find<TransactionService>();
        await transactionService.createTransaction(transaction);
        print('💰 [COLIS_SERVICE] Transaction créée pour le colis ${colis.numeroSuivi}');
      }
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Erreur création transaction: $e');
      // Ne pas bloquer la création du colis si la transaction échoue
    }
  }

  /// Récupère les colis par période pour le dashboard PDG
  Future<List<ColisModel>> getColisByPeriod(DateTime debut, DateTime fin) async {
    try {
      final snapshot = await FirebaseService.colis
          .where('dateCollecte', isGreaterThanOrEqualTo: Timestamp.fromDate(debut))
          .where('dateCollecte', isLessThanOrEqualTo: Timestamp.fromDate(fin))
          .orderBy('dateCollecte', descending: true)
          .get();
      return snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Erreur récupération colis par période: $e');
      return [];
    }
  }

  /// Récupère les colis non payés pour le calcul des créances
  Future<List<ColisModel>> getColisNonPayes() async {
    try {
      final snapshot = await FirebaseService.colis.where('isPaye', isEqualTo: false).orderBy('dateCollecte', descending: true).get();
      return snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('⚠️ [COLIS_SERVICE] Erreur récupération colis non payés: $e');
      return [];
    }
  }
}
