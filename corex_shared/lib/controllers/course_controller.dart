import 'package:get/get.dart';
import '../models/course_model.dart';
import '../models/user_model.dart';
import '../services/course_service.dart';
import 'auth_controller.dart';

class CourseController extends GetxController {
  late final CourseService _courseService;

  final RxList<CourseModel> coursesList = <CourseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString filterStatut = 'tous'.obs;
  final RxString filterCoursier = 'tous'.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialiser le service de manière sécurisée
    if (!Get.isRegistered<CourseService>()) {
      print('⚠️ [COURSE_CONTROLLER] CourseService non trouvé, initialisation...');
      Get.put(CourseService(), permanent: true);
    }
    _courseService = Get.find<CourseService>();

    loadCourses();
  }

  Future<void> loadCourses() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        print('⚠️ [COURSE_CONTROLLER] Utilisateur non connecté');
        return;
      }

      print('📋 [COURSE_CONTROLLER] Chargement courses pour ${user.role} (ID: ${user.id})');

      if (user.role == 'coursier') {
        coursesList.value = await _courseService.getCoursesByCoursier(user.id);
        print('✅ [COURSE_CONTROLLER] ${coursesList.length} courses chargées pour coursier ${user.id}');
      } else if (user.agenceId != null) {
        coursesList.value = await _courseService.getCoursesByAgence(user.agenceId!);
        print('✅ [COURSE_CONTROLLER] ${coursesList.length} courses chargées pour agence ${user.agenceId}');
      }
    } catch (e) {
      print('❌ [COURSE_CONTROLLER] Erreur: $e');
      Get.snackbar('Erreur', 'Impossible de charger les courses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Crée une nouvelle course
  Future<void> createCourse({
    required String clientId,
    required String clientNom,
    required String clientTelephone,
    required String instructions,
    required String lieu,
    required String tache,
    required double montantEstime,
    double? commissionFixe, // Commission fixe en FCFA
    double? commissionPourcentage, // Garde pour compatibilité
  }) async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) {
        throw Exception('Utilisateur non connecté ou sans agence');
      }

      // Calculer la commission
      double finalCommissionMontant;
      double finalCommissionPourcentage;

      if (commissionFixe != null) {
        // Utiliser la commission fixe
        finalCommissionMontant = commissionFixe;
        // Calculer le pourcentage équivalent pour la compatibilité
        finalCommissionPourcentage = montantEstime > 0 ? (commissionFixe / montantEstime) * 100 : 0;
      } else {
        // Utiliser le pourcentage (mode legacy)
        final pourcentage = commissionPourcentage ?? 10.0;
        finalCommissionPourcentage = pourcentage;
        finalCommissionMontant = montantEstime * (pourcentage / 100);
      }

      final course = CourseModel(
        clientId: clientId,
        clientNom: clientNom,
        clientTelephone: clientTelephone,
        instructions: instructions,
        lieu: lieu,
        tache: tache,
        montantEstime: montantEstime,
        commissionPourcentage: finalCommissionPourcentage,
        commissionMontant: finalCommissionMontant,
        agenceId: user.agenceId!,
        createdBy: user.id,
      );

      await _courseService.createCourse(course);

      Get.snackbar(
        'Succès',
        'Course créée avec succès\nCommission COREX: ${course.commissionMontant.toStringAsFixed(0)} FCFA',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      await loadCourses();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer la course: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Attribue une course à un coursier
  Future<void> attribuerCourse({
    required String courseId,
    required UserModel coursier,
  }) async {
    try {
      isLoading.value = true;

      // Validation: coursier actif
      if (!coursier.isActive) {
        throw Exception('Le coursier sélectionné n\'est pas actif');
      }

      await _courseService.attribuerCourse(courseId, coursier.id, coursier.nomComplet);

      Get.snackbar(
        'Succès',
        'Course attribuée à ${coursier.nomComplet}',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadCourses();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'attribuer la course: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Démarre une course (coursier)
  Future<void> demarrerCourse(String courseId) async {
    try {
      isLoading.value = true;

      await _courseService.demarrerCourse(courseId);

      Get.snackbar(
        'Succès',
        'Course démarrée',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadCourses();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de démarrer la course: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Termine une course (coursier)
  Future<void> terminerCourse({
    required String courseId,
    required double montantReel,
    required List<String> justificatifs,
  }) async {
    try {
      isLoading.value = true;

      await _courseService.terminerCourse(courseId, montantReel, justificatifs);

      Get.snackbar(
        'Succès',
        'Course terminée\nMontant: ${montantReel.toStringAsFixed(0)} FCFA',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadCourses();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de terminer la course: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Enregistre le paiement d'une course
  Future<void> enregistrerPaiement(
    String courseId, {
    double? montantCommission,
  }) async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final course = await _courseService.getCourseById(courseId);
      if (course == null) {
        throw Exception('Course introuvable');
      }

      // Créer la transaction avec le montant de commission fourni
      await _courseService.createTransactionForCourse(
        course,
        user.id,
        montantCommission: montantCommission,
      );

      // Marquer la course comme payée
      await _courseService.updateCourse(courseId, {
        'paye': true,
        'datePaiement': DateTime.now(),
      });

      final montantCourse = course.montantReel ?? course.montantEstime;
      final commissionEnregistree = montantCommission ?? (montantCourse * 0.10);
      Get.snackbar(
        'Succès',
        'Paiement enregistré\nMontant course: ${montantCourse.toStringAsFixed(0)} FCFA\nCommission COREX: ${commissionEnregistree.toStringAsFixed(0)} FCFA',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadCourses();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer le paiement: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Annule une course
  Future<void> annulerCourse(String courseId, String commentaire) async {
    try {
      isLoading.value = true;

      await _courseService.annulerCourse(courseId, commentaire);

      Get.snackbar(
        'Succès',
        'Course annulée',
        snackPosition: SnackPosition.BOTTOM,
      );

      await loadCourses();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'annuler la course: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Filtre les courses
  List<CourseModel> get filteredCourses {
    var filtered = coursesList.toList();

    if (filterStatut.value != 'tous') {
      filtered = filtered.where((c) => c.statut == filterStatut.value).toList();
    }

    if (filterCoursier.value != 'tous') {
      filtered = filtered.where((c) => c.coursierId == filterCoursier.value).toList();
    }

    return filtered;
  }

  /// Statistiques
  int get totalCourses => coursesList.length;
  int get coursesEnAttente => coursesList.where((c) => c.statut == 'enAttente').length;
  int get coursesEnCours => coursesList.where((c) => c.statut == 'enCours').length;
  int get coursesTerminees => coursesList.where((c) => c.statut == 'terminee').length;
  int get coursesAnnulees => coursesList.where((c) => c.statut == 'annulee').length;

  double get totalCommissions {
    return coursesList.where((c) => c.statut == 'terminee').fold(0.0, (sum, c) => sum + c.commissionMontant);
  }
}
