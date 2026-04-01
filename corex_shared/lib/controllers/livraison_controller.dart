import 'package:get/get.dart';
import '../models/livraison_model.dart';
import '../models/colis_model.dart';
import '../models/user_model.dart';
import '../services/livraison_service.dart';
import '../services/colis_service.dart';
import 'auth_controller.dart';

class LivraisonController extends GetxController {
  final LivraisonService _livraisonService = Get.find<LivraisonService>();
  final ColisService _colisService = Get.find<ColisService>();

  final RxList<LivraisonModel> livraisonsList = <LivraisonModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filterStatut = 'tous'.obs;
  final RxString filterCoursier = 'tous'.obs;
  final RxString selectedStatutFilter = 'tous'.obs;

  @override
  void onInit() {
    super.onInit();
    loadLivraisons();
  }

  Future<void> loadLivraisons() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        print('⚠️ [LIVRAISON_CONTROLLER] Utilisateur non connecté');
        return;
      }

      print('📋 [LIVRAISON_CONTROLLER] Chargement livraisons pour ${user.role} (ID: ${user.id})');

      if (user.role == 'coursier') {
        livraisonsList.value = await _livraisonService.getLivraisonsByCoursier(user.id);
        print('✅ [LIVRAISON_CONTROLLER] ${livraisonsList.length} livraisons chargées pour coursier ${user.id}');
      } else if (user.agenceId != null) {
        livraisonsList.value = await _livraisonService.getLivraisonsByAgence(user.agenceId!);
        print('✅ [LIVRAISON_CONTROLLER] ${livraisonsList.length} livraisons chargées pour agence ${user.agenceId}');
      }
    } catch (e) {
      print('❌ [LIVRAISON_CONTROLLER] Erreur: $e');
      Get.snackbar('Erreur', 'Impossible de charger les livraisons: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Crée une livraison et met à jour le statut du colis
  Future<void> attribuerLivraison({
    required ColisModel colis,
    required UserModel coursier,
    required String typeLivraison, // expedition, recuperation, livraison_finale
    bool paiementALaLivraison = false,
    double? montantACollecte,
  }) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) {
        throw Exception('Utilisateur non connecté ou sans agence');
      }

      // Validation: coursier actif
      if (!coursier.isActive) {
        throw Exception('Le coursier sélectionné n\'est pas actif');
      }

      // Validation: zone compatible (si applicable)
      if (colis.zoneId == null || colis.zoneId!.isEmpty) {
        throw Exception('Le colis n\'a pas de zone définie');
      }

      // Créer la livraison
      final livraison = LivraisonModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        colisId: colis.id,
        coursierId: coursier.id,
        agenceId: user.agenceId!,
        zone: colis.zoneId!,
        dateCreation: DateTime.now(),
        statut: 'enAttente',
        typeLivraison: typeLivraison,
        paiementALaLivraison: paiementALaLivraison,
        montantACollecte: montantACollecte,
      );

      await _livraisonService.createLivraison(livraison);

      // Déterminer le message selon le type de livraison
      String messageType = '';
      switch (typeLivraison) {
        case 'expedition':
          messageType = 'Expédition vers agence de transport';
          break;
        case 'recuperation':
          messageType = 'Récupération depuis agence de transport';
          break;
        case 'livraison_finale':
          messageType = 'Livraison finale au destinataire';
          break;
        default:
          messageType = 'Livraison';
      }

      // Mettre à jour le statut du colis en "enCoursLivraison"
      await _colisService.updateStatut(
        colis.id,
        'enCoursLivraison',
        user.id,
        '$messageType attribuée à ${coursier.nomComplet}${paiementALaLivraison ? " (Paiement à la livraison)" : ""}',
      );

      // Ajouter le coursier au colis
      await _colisService.updateColis(colis.id, {
        'coursierId': coursier.id,
      });

      Get.snackbar(
        'Succès',
        '$messageType attribuée à ${coursier.nomComplet}${paiementALaLivraison ? "\nPaiement à collecter: ${montantACollecte?.toStringAsFixed(0)} FCFA" : ""}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      await loadLivraisons();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'attribuer la livraison: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> createLivraison(LivraisonModel livraison) async {
    try {
      await _livraisonService.createLivraison(livraison);
      Get.snackbar('Succès', 'Livraison créée et attribuée');
      await loadLivraisons();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer la livraison');
    }
  }

  Future<void> updateLivraison(String livraisonId, Map<String, dynamic> data) async {
    try {
      await _livraisonService.updateLivraison(livraisonId, data);
      Get.snackbar('Succès', 'Livraison mise à jour');
      await loadLivraisons();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour la livraison');
    }
  }

  List<LivraisonModel> get filteredLivraisons {
    var filtered = livraisonsList.toList();

    if (filterStatut.value != 'tous') {
      filtered = filtered.where((l) => l.statut == filterStatut.value).toList();
    }

    if (filterCoursier.value != 'tous') {
      filtered = filtered.where((l) => l.coursierId == filterCoursier.value).toList();
    }

    if (selectedStatutFilter.value != 'tous') {
      filtered = filtered.where((l) => l.statut == selectedStatutFilter.value).toList();
    }

    return filtered;
  }

  /// Démarre la tournée de livraison
  Future<void> demarrerTournee(String livraisonId) async {
    try {
      isLoading.value = true;

      await _livraisonService.updateLivraison(livraisonId, {
        'statut': 'enCours',
        'heureDepart': DateTime.now(),
      });

      Get.snackbar(
        'Succès',
        'Tournée démarrée',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadLivraisons();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer la tournée: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Confirme la livraison réussie
  Future<void> confirmerLivraison({
    required String livraisonId,
    required String colisId,
    String? preuveUrl,
    bool paiementCollecte = false,
    double? montantCollecte,
  }) async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Préparer les données de mise à jour
      final updateData = {
        'statut': 'livree',
        'heureRetour': DateTime.now(),
        'preuveUrl': preuveUrl,
      };

      // Ajouter les informations de paiement si collecté
      if (paiementCollecte && montantCollecte != null) {
        updateData['paiementCollecte'] = true;
        updateData['montantACollecte'] = montantCollecte;
        updateData['datePaiementCollecte'] = DateTime.now();
      }

      // Mettre à jour la livraison
      await _livraisonService.updateLivraison(livraisonId, updateData);

      // Mettre à jour le statut du colis en "livre"
      await _colisService.updateStatut(
        colisId,
        'livre',
        user.id,
        'Colis livré avec succès',
      );

      // Créer une transaction pour la commission COREX
      final livraison = await _livraisonService.getLivraisonById(livraisonId);
      if (livraison != null) {
        final colis = await _colisService.getColisById(colisId);
        if (colis != null) {
          // Créer la transaction de commission COREX automatiquement
          await _livraisonService.createCommissionCorexTransaction(
            livraison,
            colis,
            user.id,
          );
          print('💰 [LIVRAISON_CONTROLLER] Transaction de commission COREX créée pour la livraison du colis ${colis.numeroSuivi}');
        }
      }

      // Créer une transaction si paiement collecté
      if (paiementCollecte && montantCollecte != null) {
        final livraison = await _livraisonService.getLivraisonById(livraisonId);
        if (livraison != null) {
          final colis = await _colisService.getColisById(colisId);
          if (colis != null) {
            await _livraisonService.createTransactionForLivraison(
              livraison,
              colis.numeroSuivi,
              user.id,
            );
            print('💰 [LIVRAISON_CONTROLLER] Transaction créée pour paiement à la livraison');
          }
        }
      }

      Get.snackbar(
        'Succès',
        paiementCollecte ? 'Livraison confirmée et paiement collecté (${montantCollecte?.toStringAsFixed(0)} FCFA)' : 'Livraison confirmée',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadLivraisons();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de confirmer la livraison: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Déclare un échec de livraison
  Future<void> declarerEchec({
    required String livraisonId,
    required String colisId,
    required String motifEchec,
    String? commentaire,
    String? photoUrl,
  }) async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Mettre à jour la livraison
      await _livraisonService.updateLivraison(livraisonId, {
        'statut': 'echec',
        'heureRetour': DateTime.now(),
        'motifEchec': motifEchec,
        'commentaire': commentaire,
        'photoUrl': photoUrl,
      });

      // Mettre à jour le statut du colis en "echecLivraison"
      await _colisService.updateStatut(
        colisId,
        'echecLivraison',
        user.id,
        'Échec de livraison: $motifEchec${commentaire != null ? " - $commentaire" : ""}',
      );

      Get.snackbar(
        'Succès',
        'Échec de livraison enregistré',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadLivraisons();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer l\'échec: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Termine la tournée (retour)
  Future<void> terminerTournee(String livraisonId) async {
    try {
      isLoading.value = true;

      await _livraisonService.updateLivraison(livraisonId, {
        'heureRetour': DateTime.now(),
      });

      Get.snackbar(
        'Succès',
        'Tournée terminée',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadLivraisons();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de terminer la tournée: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
