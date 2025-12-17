import 'package:get/get.dart';
import '../services/notification_service.dart';
import '../services/alert_service.dart';
import '../controllers/auth_controller.dart';

class NotificationController extends GetxController {
  final NotificationService _notificationService = Get.find<NotificationService>();
  final AlertService _alertService = Get.find<AlertService>();
  final AuthController _authController = Get.find<AuthController>();

  // Alertes actives pour l'utilisateur connecté
  final RxList<AlertModel> _activeAlerts = <AlertModel>[].obs;
  List<AlertModel> get activeAlerts => _activeAlerts;

  // Nombre d'alertes non lues
  final RxInt _unreadAlertsCount = 0.obs;
  int get unreadAlertsCount => _unreadAlertsCount.value;

  // Préférences de notification de l'utilisateur
  final Rx<NotificationPreferences> _preferences = NotificationPreferences().obs;
  NotificationPreferences get preferences => _preferences.value;

  // État de chargement
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _loadUserAlerts();
    _loadNotificationPreferences();

    // Actualiser les alertes toutes les 5 minutes
    ever(_authController.currentUser, (_) => _loadUserAlerts());
    Stream.periodic(const Duration(minutes: 5)).listen((_) => _loadUserAlerts());
  }

  /// Charge les alertes actives pour l'utilisateur connecté
  Future<void> _loadUserAlerts() async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return;

    try {
      final alerts = _alertService.getActiveAlertsForUser(
        currentUser.id,
        currentUser.role,
        currentUser.agenceId,
      );

      _activeAlerts.value = alerts;
      _unreadAlertsCount.value = alerts.where((alert) => !alert.isRead).length;

      print('📱 [NOTIFICATION_CONTROLLER] ${alerts.length} alertes chargées, ${_unreadAlertsCount.value} non lues');
    } catch (e) {
      print('❌ [NOTIFICATION_CONTROLLER] Erreur lors du chargement des alertes: $e');
    }
  }

  /// Charge les préférences de notification de l'utilisateur
  Future<void> _loadNotificationPreferences() async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null || currentUser.email.isEmpty) return;

    try {
      // TODO: Charger depuis Firebase quand implémenté
      // Pour l'instant, utiliser les valeurs par défaut
      _preferences.value = NotificationPreferences();
    } catch (e) {
      print('❌ [NOTIFICATION_CONTROLLER] Erreur lors du chargement des préférences: $e');
    }
  }

  /// Marque une alerte comme lue
  Future<void> markAlertAsRead(String alertId) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return;

    try {
      await _alertService.markAlertAsRead(alertId, currentUser.id);
      await _loadUserAlerts(); // Recharger les alertes

      Get.snackbar(
        'Alerte marquée',
        'L\'alerte a été marquée comme lue',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ [NOTIFICATION_CONTROLLER] Erreur lors du marquage de l\'alerte: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de marquer l\'alerte comme lue',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Résout une alerte
  Future<void> resolveAlert(String alertId, String resolution) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return;

    if (resolution.trim().isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez saisir une description de la résolution',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      _isLoading.value = true;

      await _alertService.resolveAlert(alertId, currentUser.id, resolution);
      await _loadUserAlerts(); // Recharger les alertes

      Get.snackbar(
        'Alerte résolue',
        'L\'alerte a été marquée comme résolue',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ [NOTIFICATION_CONTROLLER] Erreur lors de la résolution de l\'alerte: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de résoudre l\'alerte',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Met à jour les préférences de notification
  Future<void> updateNotificationPreferences(NotificationPreferences newPreferences) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null || currentUser.email.isEmpty) return;

    try {
      _isLoading.value = true;

      await _notificationService.updateNotificationPreferences(
        userEmail: currentUser.email,
        preferences: newPreferences,
      );

      _preferences.value = newPreferences;

      Get.snackbar(
        'Préférences mises à jour',
        'Vos préférences de notification ont été sauvegardées',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ [NOTIFICATION_CONTROLLER] Erreur lors de la mise à jour des préférences: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de sauvegarder les préférences',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Crée une alerte manuelle (pour les admins)
  Future<void> createManualAlert({
    required String title,
    required String message,
    required AlertSeverity severity,
    String? agenceId,
  }) async {
    final currentUser = _authController.currentUser.value;
    if (currentUser == null) return;

    // Vérifier les permissions
    if (!['admin', 'pdg'].contains(currentUser.role)) {
      Get.snackbar(
        'Accès refusé',
        'Vous n\'avez pas les permissions pour créer des alertes',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (title.trim().isEmpty || message.trim().isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez remplir tous les champs obligatoires',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      _isLoading.value = true;

      await _alertService.createAlert(
        type: AlertType.erreurSysteme, // Type par défaut pour les alertes manuelles
        title: title,
        message: message,
        severity: severity,
        agenceId: agenceId,
        userId: currentUser.id,
      );

      await _loadUserAlerts(); // Recharger les alertes

      Get.snackbar(
        'Alerte créée',
        'L\'alerte a été créée et les notifications ont été envoyées',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ [NOTIFICATION_CONTROLLER] Erreur lors de la création de l\'alerte: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'alerte',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Actualise manuellement les alertes
  Future<void> refreshAlerts() async {
    await _loadUserAlerts();
  }

  /// Récupère les alertes par sévérité
  List<AlertModel> getAlertsBySeverity(AlertSeverity severity) {
    return _activeAlerts.where((alert) => alert.severity == severity).toList();
  }

  /// Récupère les alertes critiques
  List<AlertModel> getCriticalAlerts() {
    return getAlertsBySeverity(AlertSeverity.critical);
  }

  /// Vérifie s'il y a des alertes critiques
  bool get hasCriticalAlerts => getCriticalAlerts().isNotEmpty;

  /// Récupère le texte de sévérité pour l'affichage
  String getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'Information';
      case AlertSeverity.medium:
        return 'Attention';
      case AlertSeverity.high:
        return 'Alerte';
      case AlertSeverity.critical:
        return 'CRITIQUE';
    }
  }

  /// Récupère la couleur de sévérité pour l'affichage
  String getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return '#4CAF50';
      case AlertSeverity.medium:
        return '#FF9800';
      case AlertSeverity.high:
        return '#F44336';
      case AlertSeverity.critical:
        return '#D32F2F';
    }
  }
}
