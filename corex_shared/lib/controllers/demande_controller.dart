import 'package:get/get.dart';
import '../models/demande_course_model.dart';
import '../models/demande_colis_model.dart';
import '../services/demande_service.dart';
import 'auth_controller.dart';

class DemandeController extends GetxController {
  final DemandeService _demandeService = DemandeService();

  // Listes observables
  final RxList<DemandeCoursModel> demandesCoursesEnAttente = <DemandeCoursModel>[].obs;
  final RxList<DemandeColisModel> demandesColisEnAttente = <DemandeColisModel>[].obs;

  // États de chargement
  final RxBool isLoadingCourses = false.obs;
  final RxBool isLoadingColis = false.obs;
  final RxBool isProcessing = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDemandesEnAttente();
  }

  /// Crée une nouvelle demande de course par un client
  Future<String> creerDemandeCourse(DemandeCoursModel demande) async {
    try {
      print('📝 [DEMANDE_CONTROLLER] Création demande course pour ${demande.clientNom}');

      final demandeId = await _demandeService.creerDemandeCourse(demande);

      print('✅ [DEMANDE_CONTROLLER] Demande course créée avec ID: $demandeId');

      return demandeId;
    } catch (e) {
      print('❌ [DEMANDE_CONTROLLER] Erreur création demande course: $e');
      rethrow;
    }
  }

  /// Crée une nouvelle demande de colis par un client
  Future<String> creerDemandeColis(DemandeColisModel demande) async {
    try {
      print('📝 [DEMANDE_CONTROLLER] Création demande colis pour ${demande.clientNom}');

      final demandeId = await _demandeService.creerDemandeColis(demande);

      print('✅ [DEMANDE_CONTROLLER] Demande colis créée avec ID: $demandeId');

      return demandeId;
    } catch (e) {
      print('❌ [DEMANDE_CONTROLLER] Erreur création demande colis: $e');
      rethrow;
    }
  }

  /// Charge toutes les demandes en attente de validation
  Future<void> loadDemandesEnAttente() async {
    await Future.wait([
      loadDemandesCoursesEnAttente(),
      loadDemandesColisEnAttente(),
    ]);
  }

  /// Charge les demandes de courses en attente
  Future<void> loadDemandesCoursesEnAttente() async {
    try {
      isLoadingCourses.value = true;
      print('📋 [DEMANDE_CONTROLLER] Chargement demandes courses...');

      final demandes = await _demandeService.getDemandesCoursesEnAttente();
      demandesCoursesEnAttente.value = demandes;

      print('✅ [DEMANDE_CONTROLLER] ${demandes.length} demandes courses chargées');
    } catch (e) {
      print('❌ [DEMANDE_CONTROLLER] Erreur chargement demandes courses: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les demandes de courses: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingCourses.value = false;
    }
  }

  /// Charge les demandes de colis en attente
  Future<void> loadDemandesColisEnAttente() async {
    try {
      isLoadingColis.value = true;
      print('📋 [DEMANDE_CONTROLLER] Chargement demandes colis...');

      final demandes = await _demandeService.getDemandesColisEnAttente();
      demandesColisEnAttente.value = demandes;

      print('✅ [DEMANDE_CONTROLLER] ${demandes.length} demandes colis chargées');
    } catch (e) {
      print('❌ [DEMANDE_CONTROLLER] Erreur chargement demandes colis: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les demandes de colis: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingColis.value = false;
    }
  }

  /// Valide une demande de course
  Future<void> validerDemandeCourse({
    required String demandeId,
    required double tarifValide,
    String? commentaire,
  }) async {
    try {
      isProcessing.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) {
        throw Exception('Utilisateur non connecté ou sans agence');
      }

      print('✅ [DEMANDE_CONTROLLER] Validation demande course: $demandeId');

      await _demandeService.validerDemandeCourse(
        demandeId: demandeId,
        tarifValide: tarifValide,
        validateurId: user.id,
        validateurNom: user.nomComplet,
        agenceId: user.agenceId!,
        commentaire: commentaire,
      );

      Get.snackbar(
        'Succès',
        'Demande de course validée avec succès\nTarif: ${tarifValide.toStringAsFixed(0)} FCFA',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Recharger les demandes
      await loadDemandesCoursesEnAttente();
    } catch (e) {
      print('❌ [DEMANDE_CONTROLLER] Erreur validation demande course: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de valider la demande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Rejette une demande de course
  Future<void> rejeterDemandeCourse({
    required String demandeId,
    required String motifRejet,
  }) async {
    try {
      isProcessing.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      print('❌ [DEMANDE_CONTROLLER] Rejet demande course: $demandeId');

      await _demandeService.rejeterDemandeCourse(
        demandeId: demandeId,
        validateurId: user.id,
        validateurNom: user.nomComplet,
        motifRejet: motifRejet,
      );

      Get.snackbar(
        'Demande rejetée',
        'La demande a été rejetée et le client a été notifié',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Recharger les demandes
      await loadDemandesCoursesEnAttente();
    } catch (e) {
      print('❌ [DEMANDE_CONTROLLER] Erreur rejet demande course: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter la demande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Valide une demande de colis
  Future<void> validerDemandeColis({
    required String demandeId,
    required double tarifValide,
    String? commentaire,
  }) async {
    try {
      isProcessing.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) {
        throw Exception('Utilisateur non connecté ou sans agence');
      }

      print('✅ [DEMANDE_CONTROLLER] Validation demande colis: $demandeId');

      await _demandeService.validerDemandeColis(
        demandeId: demandeId,
        tarifValide: tarifValide,
        validateurId: user.id,
        validateurNom: user.nomComplet,
        agenceId: user.agenceId!,
        commentaire: commentaire,
      );

      Get.snackbar(
        'Succès',
        'Demande de colis validée avec succès\nTarif: ${tarifValide.toStringAsFixed(0)} FCFA',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      // Recharger les demandes
      await loadDemandesColisEnAttente();
    } catch (e) {
      print('❌ [DEMANDE_CONTROLLER] Erreur validation demande colis: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de valider la demande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Rejette une demande de colis
  Future<void> rejeterDemandeColis({
    required String demandeId,
    required String motifRejet,
  }) async {
    try {
      isProcessing.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      print('❌ [DEMANDE_CONTROLLER] Rejet demande colis: $demandeId');

      await _demandeService.rejeterDemandeColis(
        demandeId: demandeId,
        validateurId: user.id,
        validateurNom: user.nomComplet,
        motifRejet: motifRejet,
      );

      Get.snackbar(
        'Demande rejetée',
        'La demande a été rejetée et le client a été notifié',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Recharger les demandes
      await loadDemandesColisEnAttente();
    } catch (e) {
      print('❌ [DEMANDE_CONTROLLER] Erreur rejet demande colis: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter la demande: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Statistiques des demandes
  int get totalDemandesEnAttente => demandesCoursesEnAttente.length + demandesColisEnAttente.length;

  int get totalDemandesCourses => demandesCoursesEnAttente.length;
  int get totalDemandesColis => demandesColisEnAttente.length;

  /// Filtre les demandes par date
  List<DemandeCoursModel> getDemandesCoursesParDate(DateTime date) {
    return demandesCoursesEnAttente.where((demande) {
      return demande.dateCreation.day == date.day && demande.dateCreation.month == date.month && demande.dateCreation.year == date.year;
    }).toList();
  }

  List<DemandeColisModel> getDemandesColisParDate(DateTime date) {
    return demandesColisEnAttente.where((demande) {
      return demande.dateCreation.day == date.day && demande.dateCreation.month == date.month && demande.dateCreation.year == date.year;
    }).toList();
  }

  /// Recherche dans les demandes
  List<DemandeCoursModel> rechercherDemandeCourse(String query) {
    if (query.isEmpty) return demandesCoursesEnAttente;

    final queryLower = query.toLowerCase();
    return demandesCoursesEnAttente.where((demande) {
      return demande.clientNom.toLowerCase().contains(queryLower) ||
          demande.lieu.toLowerCase().contains(queryLower) ||
          demande.tache.toLowerCase().contains(queryLower) ||
          demande.clientTelephone.contains(query);
    }).toList();
  }

  List<DemandeColisModel> rechercherDemandeColis(String query) {
    if (query.isEmpty) return demandesColisEnAttente;

    final queryLower = query.toLowerCase();
    return demandesColisEnAttente.where((demande) {
      return demande.clientNom.toLowerCase().contains(queryLower) ||
          demande.expediteurNom.toLowerCase().contains(queryLower) ||
          demande.destinataireNom.toLowerCase().contains(queryLower) ||
          demande.description.toLowerCase().contains(queryLower) ||
          demande.clientTelephone.contains(query);
    }).toList();
  }
}
