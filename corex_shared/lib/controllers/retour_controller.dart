import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/colis_model.dart';
import 'auth_controller.dart';

class RetourController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ColisModel> retours = <ColisModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<ColisModel?> selectedColis = Rx<ColisModel?>(null);
  final Rx<ColisModel?> selectedRetour = Rx<ColisModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadRetours();
  }

  // Charger tous les retours
  Future<void> loadRetours() async {
    try {
      isLoading.value = true;

      print('📦 [RETOUR_CONTROLLER] Chargement des retours...');

      Query query = _firestore.collection('colis').where('isRetour', isEqualTo: true);

      // Filtrer par agence si l'utilisateur n'est pas PDG
      if (_authController.currentUser.value?.role != 'pdg') {
        query = query.where('agenceCorexId', isEqualTo: _authController.currentUser.value?.agenceId);
      }

      final snapshot = await query.get();
      retours.value = snapshot.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();

      print('✅ [RETOUR_CONTROLLER] ${retours.length} retours chargés');
    } catch (e, stackTrace) {
      print('❌ [RETOUR_CONTROLLER] Erreur chargement: $e');
      print('📍 [RETOUR_CONTROLLER] Stack trace: $stackTrace');
      Get.snackbar('Erreur', 'Impossible de charger les retours: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Rechercher un colis par numéro de suivi
  Future<ColisModel?> rechercherColisParNumero(String numeroSuivi) async {
    try {
      isLoading.value = true;

      final snapshot = await _firestore.collection('colis').where('numeroSuivi', isEqualTo: numeroSuivi).where('isRetour', isEqualTo: false).limit(1).get();

      if (snapshot.docs.isEmpty) {
        Get.snackbar('Erreur', 'Aucun colis trouvé avec ce numéro de suivi');
        return null;
      }

      selectedColis.value = ColisModel.fromFirestore(snapshot.docs.first);
      return selectedColis.value;
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la recherche: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Générer un numéro de suivi pour le retour
  Future<String> _genererNumeroSuiviRetour() async {
    try {
      print('🔢 [RETOUR_CONTROLLER] Accès au compteur...');
      final counterDoc = _firestore.collection('counters').doc('retour');

      // Récupérer le compteur actuel
      print('📄 [RETOUR_CONTROLLER] Lecture du compteur...');
      final snapshot = await counterDoc.get();
      print('📊 [RETOUR_CONTROLLER] Snapshot récupéré, existe: ${snapshot.exists}');

      int currentCount = 1;
      if (snapshot.exists) {
        final data = snapshot.data();
        print('📊 [RETOUR_CONTROLLER] Données: $data');
        currentCount = (data?['count'] ?? 0) + 1;
      }
      print('🔢 [RETOUR_CONTROLLER] Compteur: $currentCount');

      // Mettre à jour le compteur
      print('💾 [RETOUR_CONTROLLER] Mise à jour du compteur...');
      await counterDoc.set({'count': currentCount}, SetOptions(merge: true));
      print('✅ [RETOUR_CONTROLLER] Compteur mis à jour');

      // Générer le numéro de suivi
      final year = DateTime.now().year;
      final numeroSuivi = 'RET-$year-${currentCount.toString().padLeft(6, '0')}';
      print('✅ [RETOUR_CONTROLLER] Numéro généré: $numeroSuivi');

      return numeroSuivi;
    } catch (e, stackTrace) {
      print('❌ [RETOUR_CONTROLLER] Erreur génération numéro: $e');
      print('📍 [RETOUR_CONTROLLER] Stack trace: $stackTrace');
      throw Exception('Erreur lors de la génération du numéro de suivi: $e');
    }
  }

  // Créer un retour à partir d'un colis initial
  Future<bool> creerRetour(ColisModel colisInitial, {String? commentaire}) async {
    try {
      isLoading.value = true;

      print('🔄 [RETOUR_CONTROLLER] Début création retour pour colis: ${colisInitial.numeroSuivi}');

      // Vérifier que l'utilisateur est connecté
      if (_authController.currentUser.value == null) {
        print('❌ [RETOUR_CONTROLLER] Utilisateur non connecté');
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return false;
      }

      // Vérifier que le colis n'est pas déjà un retour
      if (colisInitial.isRetour) {
        print('❌ [RETOUR_CONTROLLER] Impossible de créer un retour d\'un retour');
        Get.snackbar('Erreur', 'Impossible de créer un retour à partir d\'un retour');
        return false;
      }

      // Vérifier qu'un retour n'existe pas déjà pour ce colis
      if (colisInitial.retourId != null) {
        print('❌ [RETOUR_CONTROLLER] Un retour existe déjà pour ce colis');
        Get.snackbar('Erreur', 'Un retour existe déjà pour ce colis (${colisInitial.retourId})');
        return false;
      }

      final currentUserId = _authController.currentUser.value!.id;
      print('👤 [RETOUR_CONTROLLER] Utilisateur: $currentUserId');

      // Générer le numéro de suivi du retour
      print('🔢 [RETOUR_CONTROLLER] Génération du numéro de suivi...');
      final numeroSuiviRetour = await _genererNumeroSuiviRetour();
      print('✅ [RETOUR_CONTROLLER] Numéro généré: $numeroSuiviRetour');

      // Créer le retour (inverser expéditeur et destinataire)
      // IMPORTANT: Ne pas copier zoneId car elle correspond à l'ancienne destination
      // Le gestionnaire devra définir la zone appropriée pour la nouvelle destination
      final retourData = {
        'numeroSuivi': numeroSuiviRetour,
        'expediteurNom': colisInitial.destinataireNom,
        'expediteurTelephone': colisInitial.destinataireTelephone,
        'expediteurAdresse': colisInitial.destinataireAdresse,
        'destinataireNom': colisInitial.expediteurNom,
        'destinataireTelephone': colisInitial.expediteurTelephone,
        'destinataireAdresse': colisInitial.expediteurAdresse,
        'destinataireVille': colisInitial.destinataireVille,
        'destinataireQuartier': colisInitial.destinataireQuartier,
        'contenu': colisInitial.contenu,
        'poids': colisInitial.poids,
        'dimensions': colisInitial.dimensions,
        'montantTarif': colisInitial.montantTarif,
        'isPaye': false,
        'datePaiement': null,
        'modeLivraison': 'domicile', // Par défaut, retour à domicile
        'zoneId': null, // Zone à définir par le gestionnaire selon la nouvelle destination
        'agenceTransportId': null, // Pas d'agence transport pour les retours
        'agenceTransportNom': null,
        'tarifAgenceTransport': null,
        'statut': 'collecte',
        'agenceCorexId': colisInitial.agenceCorexId,
        'commercialId': currentUserId,
        'coursierId': null,
        'dateCollecte': Timestamp.now(),
        'dateEnregistrement': null,
        'dateLivraison': null,
        'historique': [
          {
            'statut': 'collecte',
            'date': Timestamp.now(),
            'userId': currentUserId,
            'commentaire': commentaire ?? 'Retour créé',
          }
        ],
        'commentaire': commentaire,
        'isRetour': true,
        'colisInitialId': colisInitial.id,
        'retourId': null,
      };

      // Enregistrer le retour
      print('💾 [RETOUR_CONTROLLER] Enregistrement du retour dans Firestore...');
      final retourDoc = await _firestore.collection('colis').add(retourData);
      print('✅ [RETOUR_CONTROLLER] Retour enregistré avec ID: ${retourDoc.id}');

      // Mettre à jour le colis initial avec l'ID du retour
      print('🔗 [RETOUR_CONTROLLER] Mise à jour du colis initial...');
      await _firestore.collection('colis').doc(colisInitial.id).update({
        'retourId': retourDoc.id,
      });
      print('✅ [RETOUR_CONTROLLER] Colis initial mis à jour');

      Get.snackbar('Succès', 'Retour créé avec succès: $numeroSuiviRetour');

      print('🔄 [RETOUR_CONTROLLER] Rechargement de la liste des retours...');
      await loadRetours();

      return true;
    } catch (e, stackTrace) {
      print('❌ [RETOUR_CONTROLLER] Erreur création retour: $e');
      print('📍 [RETOUR_CONTROLLER] Stack trace: $stackTrace');
      Get.snackbar('Erreur', 'Erreur lors de la création du retour: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Attribuer un retour à un coursier
  Future<bool> attribuerRetour(String retourId, String coursierId, {String? zoneId}) async {
    try {
      isLoading.value = true;

      final updateData = {
        'coursierId': coursierId,
        'statut': 'enCoursLivraison',
        'historique': FieldValue.arrayUnion([
          {
            'statut': 'enCoursLivraison',
            'date': Timestamp.now(),
            'userId': _authController.currentUser.value!.id,
            'commentaire': 'Retour attribué au coursier',
          }
        ]),
      };

      // Ajouter la zone si elle est fournie
      if (zoneId != null) {
        updateData['zoneId'] = zoneId;
      }

      await _firestore.collection('colis').doc(retourId).update(updateData);

      Get.snackbar('Succès', 'Retour attribué avec succès');
      await loadRetours();

      return true;
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'attribution: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Marquer un retour comme livré
  Future<bool> marquerRetourLivre(String retourId, String colisInitialId) async {
    try {
      isLoading.value = true;

      // Mettre à jour le statut du retour
      await _firestore.collection('colis').doc(retourId).update({
        'statut': 'livre',
        'dateLivraison': Timestamp.now(),
        'historique': FieldValue.arrayUnion([
          {
            'statut': 'livre',
            'date': Timestamp.now(),
            'userId': _authController.currentUser.value!.id,
            'commentaire': 'Retour livré',
          }
        ]),
      });

      // Mettre à jour le statut du colis initial en "retourne"
      await _firestore.collection('colis').doc(colisInitialId).update({
        'statut': 'retourne',
        'historique': FieldValue.arrayUnion([
          {
            'statut': 'retourne',
            'date': Timestamp.now(),
            'userId': _authController.currentUser.value!.id,
            'commentaire': 'Colis retourné à l\'expéditeur',
          }
        ]),
      });

      Get.snackbar('Succès', 'Retour marqué comme livré');
      await loadRetours();

      return true;
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la mise à jour: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Filtrer les retours par statut
  List<ColisModel> getRetoursByStatut(String statut) {
    return retours.where((retour) => retour.statut == statut).toList();
  }

  // Obtenir le colis initial d'un retour
  Future<ColisModel?> getColisInitial(String colisInitialId) async {
    try {
      final doc = await _firestore.collection('colis').doc(colisInitialId).get();
      if (doc.exists) {
        return ColisModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la récupération du colis initial: $e');
      return null;
    }
  }

  // Obtenir le retour d'un colis
  Future<ColisModel?> getRetourByColis(String colisId) async {
    try {
      final snapshot = await _firestore.collection('colis').where('colisInitialId', isEqualTo: colisId).where('isRetour', isEqualTo: true).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        return ColisModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la récupération du retour: $e');
      return null;
    }
  }
}
