import 'package:get/get.dart';
import '../models/colis_model.dart';
import '../services/colis_service.dart';
import 'auth_controller.dart';

class SuiviController extends GetxController {
  final ColisService _colisService = Get.find<ColisService>();
  final AuthController _authController = Get.find<AuthController>();

  // Observables
  final RxList<ColisModel> colisList = <ColisModel>[].obs;
  final RxList<ColisModel> filteredColisList = <ColisModel>[].obs;
  final Rx<ColisModel?> selectedColis = Rx<ColisModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedStatutFilter = 'tous'.obs;
  final RxString selectedAgenceFilter = 'tous'.obs;
  final RxString selectedCommercialFilter = 'tous'.obs;
  final RxString selectedCoursierFilter = 'tous'.obs;
  final Rx<DateTime?> dateDebutFilter = Rx<DateTime?>(null);
  final Rx<DateTime?> dateFinFilter = Rx<DateTime?>(null);
  final RxBool afficherRetours = false.obs; // Nouveau filtre pour les retours

  // Statuts disponibles
  final List<String> statutsDisponibles = [
    'tous',
    'collecte',
    'enregistre',
    'enTransit',
    'arriveDestination',
    'enCoursLivraison',
    'livre',
    'retire',
    'echec',
    'retour',
  ];

  @override
  void onInit() {
    super.onInit();
    loadColis();

    // Écouter les changements de recherche et filtres
    ever(searchQuery, (_) => applyFilters());
    ever(selectedStatutFilter, (_) => applyFilters());
    ever(selectedAgenceFilter, (_) => applyFilters());
    ever(selectedCommercialFilter, (_) => applyFilters());
    ever(selectedCoursierFilter, (_) => applyFilters());
    ever(dateDebutFilter, (_) => applyFilters());
    ever(dateFinFilter, (_) => applyFilters());
    ever(afficherRetours, (_) => applyFilters());
  }

  /// Charge tous les colis selon le rôle de l'utilisateur
  Future<void> loadColis() async {
    try {
      isLoading.value = true;
      final user = _authController.currentUser.value;

      if (user == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return;
      }

      List<ColisModel> colis = [];

      // Charger selon le rôle
      switch (user.role) {
        case 'pdg':
          colis = await _colisService.getAllColis();
          break;
        case 'admin':
        case 'gestionnaire':
        case 'agent':
          if (user.agenceId != null) {
            colis = await _colisService.getColisByAgence(user.agenceId!);
          }
          break;
        case 'commercial':
          colis = await _colisService.getColisByCommercial(user.id);
          break;
        case 'coursier':
          colis = await _colisService.getAllColis();
          colis = colis.where((c) => c.coursierId == user.id).toList();
          break;
        case 'caisse':
          if (user.agenceId != null) {
            colis = await _colisService.getColisByAgence(user.agenceId!);
          }
          break;
      }

      colisList.value = colis;
      applyFilters();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les colis: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Recherche un colis par numéro de suivi
  Future<void> searchByNumeroSuivi(String numeroSuivi) async {
    try {
      isLoading.value = true;
      final colis = await _colisService.searchColisByNumero(numeroSuivi);

      if (colis != null) {
        selectedColis.value = colis;
        Get.snackbar('Succès', 'Colis trouvé: ${colis.numeroSuivi}');
      } else {
        Get.snackbar('Non trouvé', 'Aucun colis avec ce numéro de suivi');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la recherche: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Applique les filtres sur la liste des colis
  void applyFilters() {
    List<ColisModel> filtered = List.from(colisList);

    // Filtre par recherche (numéro, nom expéditeur, nom destinataire, téléphone)
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((colis) {
        return colis.numeroSuivi.toLowerCase().contains(query) ||
            colis.expediteurNom.toLowerCase().contains(query) ||
            colis.destinataireNom.toLowerCase().contains(query) ||
            colis.expediteurTelephone.contains(query) ||
            colis.destinataireTelephone.contains(query);
      }).toList();
    }

    // Filtre par statut
    if (selectedStatutFilter.value != 'tous') {
      filtered = filtered.where((colis) => colis.statut == selectedStatutFilter.value).toList();
    }

    // Filtre par agence
    if (selectedAgenceFilter.value != 'tous') {
      filtered = filtered.where((colis) => colis.agenceCorexId == selectedAgenceFilter.value).toList();
    }

    // Filtre par commercial
    if (selectedCommercialFilter.value != 'tous') {
      filtered = filtered.where((colis) => colis.commercialId == selectedCommercialFilter.value).toList();
    }

    // Filtre par coursier
    if (selectedCoursierFilter.value != 'tous') {
      filtered = filtered.where((colis) => colis.coursierId == selectedCoursierFilter.value).toList();
    }

    // Filtre par date
    if (dateDebutFilter.value != null) {
      filtered = filtered.where((colis) => colis.dateCollecte.isAfter(dateDebutFilter.value!) || colis.dateCollecte.isAtSameMomentAs(dateDebutFilter.value!)).toList();
    }

    if (dateFinFilter.value != null) {
      filtered = filtered.where((colis) => colis.dateCollecte.isBefore(dateFinFilter.value!) || colis.dateCollecte.isAtSameMomentAs(dateFinFilter.value!)).toList();
    }

    // Filtre pour afficher/masquer les retours
    if (!afficherRetours.value) {
      filtered = filtered.where((colis) => !colis.isRetour).toList();
    }

    filteredColisList.value = filtered;
  }

  /// Sélectionne un colis pour afficher les détails
  void selectColis(ColisModel colis) {
    selectedColis.value = colis;
  }

  /// Met à jour le statut d'un colis
  Future<void> updateStatut(String colisId, String newStatut, String? commentaire) async {
    try {
      isLoading.value = true;
      final user = _authController.currentUser.value;

      if (user == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return;
      }

      // Valider le workflow des statuts
      final colis = colisList.firstWhereOrNull((c) => c.id == colisId);
      if (colis == null) {
        Get.snackbar('Erreur', 'Colis non trouvé');
        return;
      }

      if (!_isValidStatutTransition(colis.statut, newStatut)) {
        Get.snackbar('Erreur', 'Transition de statut invalide');
        return;
      }

      await _colisService.updateStatut(colisId, newStatut, user.id, commentaire);

      Get.snackbar('Succès', 'Statut mis à jour avec succès');
      await loadColis();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour le statut: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Valide la transition de statut
  bool _isValidStatutTransition(String currentStatut, String newStatut) {
    // Définir les transitions valides
    final Map<String, List<String>> validTransitions = {
      'collecte': ['enregistre', 'annule'],
      'enregistre': ['enTransit', 'annule'],
      'enTransit': ['arriveDestination', 'retour'],
      'arriveDestination': ['enCoursLivraison', 'retire', 'retour'],
      'enCoursLivraison': ['livre', 'echec', 'retour'],
      'echec': ['enCoursLivraison', 'retour'],
      'livre': [],
      'retire': [],
      'retour': ['enTransit'],
      'annule': [],
    };

    return validTransitions[currentStatut]?.contains(newStatut) ?? false;
  }

  /// Réinitialise les filtres
  void resetFilters() {
    searchQuery.value = '';
    selectedStatutFilter.value = 'tous';
    selectedAgenceFilter.value = 'tous';
    selectedCommercialFilter.value = 'tous';
    selectedCoursierFilter.value = 'tous';
    dateDebutFilter.value = null;
    dateFinFilter.value = null;
  }

  /// Obtient le libellé d'un statut
  String getStatutLabel(String statut) {
    final Map<String, String> labels = {
      'collecte': 'Collecté',
      'enregistre': 'Enregistré',
      'enTransit': 'En Transit',
      'arriveDestination': 'Arrivé à Destination',
      'enCoursLivraison': 'En Cours de Livraison',
      'livre': 'Livré',
      'retire': 'Retiré',
      'echec': 'Échec de Livraison',
      'retour': 'En Retour',
      'annule': 'Annulé',
    };
    return labels[statut] ?? statut;
  }

  /// Obtient la couleur d'un statut
  String getStatutColor(String statut) {
    final Map<String, String> colors = {
      'collecte': '#FFA500',
      'enregistre': '#4CAF50',
      'enTransit': '#2196F3',
      'arriveDestination': '#9C27B0',
      'enCoursLivraison': '#FF9800',
      'livre': '#4CAF50',
      'retire': '#4CAF50',
      'echec': '#F44336',
      'retour': '#FF5722',
      'annule': '#9E9E9E',
    };
    return colors[statut] ?? '#000000';
  }
}
