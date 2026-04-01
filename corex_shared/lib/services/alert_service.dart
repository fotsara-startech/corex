import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/email_service.dart';
import '../services/user_service.dart';

class AlertService extends GetxService {
  static AlertService get instance => Get.find<AlertService>();

  final EmailService _emailService = EmailService.instance;
  final UserService _userService = Get.find<UserService>();

  // Alertes en cours
  final RxList<AlertModel> _activeAlerts = <AlertModel>[].obs;

  // Configuration des seuils d'alerte
  final RxMap<String, AlertThreshold> _alertThresholds = <String, AlertThreshold>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeDefaultThresholds();
    _startAlertMonitoring();
  }

  /// Initialise les seuils d'alerte par défaut
  void _initializeDefaultThresholds() {
    _alertThresholds.addAll({
      'stock_bas': AlertThreshold(
        type: AlertType.stockBas,
        threshold: 10.0,
        enabled: true,
        checkInterval: const Duration(hours: 6),
      ),
      'credit_depasse': AlertThreshold(
        type: AlertType.creditDepasse,
        threshold: 0.0,
        enabled: true,
        checkInterval: const Duration(hours: 1),
      ),
      'colis_en_retard': AlertThreshold(
        type: AlertType.colisEnRetard,
        threshold: 7.0, // 7 jours
        enabled: true,
        checkInterval: const Duration(hours: 12),
      ),
      'livraison_en_retard': AlertThreshold(
        type: AlertType.livraisonEnRetard,
        threshold: 2.0, // 2 jours
        enabled: true,
        checkInterval: const Duration(hours: 6),
      ),
      'caisse_negative': AlertThreshold(
        type: AlertType.caisseNegative,
        threshold: 0.0,
        enabled: true,
        checkInterval: const Duration(hours: 1),
      ),
    });
  }

  /// Démarre la surveillance des alertes
  void _startAlertMonitoring() {
    // Vérifier les alertes toutes les heures
    Stream.periodic(const Duration(hours: 1)).listen((_) {
      _checkAllAlerts();
    });

    // Vérification initiale
    Future.delayed(const Duration(seconds: 30), () {
      _checkAllAlerts();
    });
  }

  /// Vérifie toutes les alertes configurées
  Future<void> _checkAllAlerts() async {
    for (final threshold in _alertThresholds.values) {
      if (threshold.enabled && _shouldCheckAlert(threshold)) {
        await _checkSpecificAlert(threshold);
      }
    }
  }

  /// Détermine si une alerte doit être vérifiée
  bool _shouldCheckAlert(AlertThreshold threshold) {
    final now = DateTime.now();
    return threshold.lastCheck == null || now.difference(threshold.lastCheck!).compareTo(threshold.checkInterval) >= 0;
  }

  /// Vérifie une alerte spécifique
  Future<void> _checkSpecificAlert(AlertThreshold threshold) async {
    threshold.lastCheck = DateTime.now();

    switch (threshold.type) {
      case AlertType.stockBas:
        await _checkStockBas(threshold);
        break;
      case AlertType.creditDepasse:
        await _checkCreditDepasse(threshold);
        break;
      case AlertType.colisEnRetard:
        await _checkColisEnRetard(threshold);
        break;
      case AlertType.livraisonEnRetard:
        await _checkLivraisonEnRetard(threshold);
        break;
      case AlertType.caisseNegative:
        await _checkCaisseNegative(threshold);
        break;
      case AlertType.connexionSuspecte:
      case AlertType.erreurSysteme:
      case AlertType.maintenanceProgrammee:
        // Ces types d'alertes ne sont pas surveillés automatiquement
        break;
    }
  }

  /// Vérifie les stocks bas
  Future<void> _checkStockBas(AlertThreshold threshold) async {
    try {
      // TODO: Implémenter la vérification des stocks
      // Cette logique dépendra de l'implémentation du module de stockage
      print('🔍 Vérification des stocks bas...');
    } catch (e) {
      print('❌ Erreur lors de la vérification des stocks: $e');
    }
  }

  /// Vérifie les crédits dépassés
  Future<void> _checkCreditDepasse(AlertThreshold threshold) async {
    try {
      // TODO: Implémenter la vérification des crédits clients
      print('🔍 Vérification des crédits dépassés...');
    } catch (e) {
      print('❌ Erreur lors de la vérification des crédits: $e');
    }
  }

  /// Vérifie les colis en retard
  Future<void> _checkColisEnRetard(AlertThreshold threshold) async {
    try {
      // TODO: Implémenter la vérification des colis en retard
      // Rechercher les colis avec statut != 'livre' et date > seuil
      print('🔍 Vérification des colis en retard...');
    } catch (e) {
      print('❌ Erreur lors de la vérification des colis en retard: $e');
    }
  }

  /// Vérifie les livraisons en retard
  Future<void> _checkLivraisonEnRetard(AlertThreshold threshold) async {
    try {
      // TODO: Implémenter la vérification des livraisons en retard
      print('🔍 Vérification des livraisons en retard...');
    } catch (e) {
      print('❌ Erreur lors de la vérification des livraisons en retard: $e');
    }
  }

  /// Vérifie les caisses négatives
  Future<void> _checkCaisseNegative(AlertThreshold threshold) async {
    try {
      // TODO: Implémenter la vérification des soldes de caisse
      print('🔍 Vérification des caisses négatives...');
    } catch (e) {
      print('❌ Erreur lors de la vérification des caisses: $e');
    }
  }

  /// Crée une nouvelle alerte
  Future<void> createAlert({
    required AlertType type,
    required String title,
    required String message,
    required AlertSeverity severity,
    String? agenceId,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    final alert = AlertModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: message,
      severity: severity,
      createdAt: DateTime.now(),
      agenceId: agenceId,
      userId: userId,
      data: data ?? {},
      isRead: false,
      isResolved: false,
    );

    _activeAlerts.add(alert);

    // Envoyer les notifications selon la sévérité
    await _sendAlertNotifications(alert);

    print('🚨 Alerte créée: ${alert.title}');
  }

  /// Envoie les notifications pour une alerte
  Future<void> _sendAlertNotifications(AlertModel alert) async {
    try {
      List<UserModel> recipients = [];

      // Déterminer les destinataires selon le type et la sévérité
      switch (alert.severity) {
        case AlertSeverity.low:
          // Notifications in-app seulement
          break;
        case AlertSeverity.medium:
          // Notifier les gestionnaires de l'agence concernée
          if (alert.agenceId != null) {
            final gestionnaires = await _userService.getUsersByRole('gestionnaire');
            recipients = gestionnaires.where((u) => u.agenceId == alert.agenceId).toList();
          }
          break;
        case AlertSeverity.high:
          // Notifier les gestionnaires et le PDG
          final gestionnaires = await _userService.getUsersByRole('gestionnaire');
          final pdgs = await _userService.getUsersByRole('pdg');
          recipients = [...gestionnaires, ...pdgs];
          break;
        case AlertSeverity.critical:
          // Notifier tout le monde (admins, PDG, gestionnaires)
          final admins = await _userService.getUsersByRole('admin');
          final gestionnaires = await _userService.getUsersByRole('gestionnaire');
          final pdgs = await _userService.getUsersByRole('pdg');
          recipients = [...admins, ...gestionnaires, ...pdgs];
          break;
      }

      // Envoyer les emails
      for (final recipient in recipients) {
        if (recipient.email.isNotEmpty) {
          await _emailService.sendCustomEmail(
            to: recipient.email,
            toName: recipient.nom,
            subject: 'COREX - Alerte ${alert.severity.name.toUpperCase()}: ${alert.title}',
            body: _buildAlertEmailBody(alert, recipient.nom),
          );
        }
      }

      print('✅ Notifications d\'alerte envoyées à ${recipients.length} destinataires');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi des notifications d\'alerte: $e');
    }
  }

  /// Marque une alerte comme lue
  Future<void> markAlertAsRead(String alertId, String userId) async {
    final alertIndex = _activeAlerts.indexWhere((a) => a.id == alertId);
    if (alertIndex != -1) {
      _activeAlerts[alertIndex] = _activeAlerts[alertIndex].copyWith(
        isRead: true,
        readBy: userId,
        readAt: DateTime.now(),
      );

      // TODO: Sauvegarder dans Firebase
      print('✅ Alerte $alertId marquée comme lue par $userId');
    }
  }

  /// Marque une alerte comme résolue
  Future<void> resolveAlert(String alertId, String userId, String resolution) async {
    final alertIndex = _activeAlerts.indexWhere((a) => a.id == alertId);
    if (alertIndex != -1) {
      _activeAlerts[alertIndex] = _activeAlerts[alertIndex].copyWith(
        isResolved: true,
        resolvedBy: userId,
        resolvedAt: DateTime.now(),
        resolution: resolution,
      );

      // TODO: Sauvegarder dans Firebase
      print('✅ Alerte $alertId résolue par $userId');
    }
  }

  /// Récupère les alertes actives pour un utilisateur
  List<AlertModel> getActiveAlertsForUser(String userId, String userRole, String? agenceId) {
    return _activeAlerts.where((alert) {
      if (alert.isResolved) return false;

      // Filtrer selon le rôle et l'agence
      switch (userRole) {
        case 'admin':
        case 'pdg':
          return true; // Voir toutes les alertes
        case 'gestionnaire':
          return alert.agenceId == null || alert.agenceId == agenceId;
        default:
          return alert.userId == userId; // Voir seulement ses propres alertes
      }
    }).toList();
  }

  /// Met à jour la configuration d'une alerte
  Future<void> updateAlertThreshold({
    required String alertType,
    required double threshold,
    required bool enabled,
    Duration? checkInterval,
  }) async {
    if (_alertThresholds.containsKey(alertType)) {
      _alertThresholds[alertType] = _alertThresholds[alertType]!.copyWith(
        threshold: threshold,
        enabled: enabled,
        checkInterval: checkInterval,
      );

      // TODO: Sauvegarder dans Firebase
      print('✅ Configuration d\'alerte mise à jour: $alertType');
    }
  }

  /// Construit le corps de l'email d'alerte
  String _buildAlertEmailBody(AlertModel alert, String recipientName) {
    final severityColor = _getSeverityColor(alert.severity);
    final severityText = _getSeverityText(alert.severity);

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
            .header { text-align: center; margin-bottom: 30px; }
            .logo { color: #2E7D32; font-size: 24px; font-weight: bold; }
            .alert { background-color: $severityColor; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center; }
            .details { background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">COREX</div>
                <h2>Alerte Système</h2>
            </div>
            
            <p>Bonjour $recipientName,</p>
            
            <div class="alert">
                <h3>🚨 $severityText</h3>
                <h4>${alert.title}</h4>
            </div>
            
            <div class="details">
                <p><strong>Message :</strong> ${alert.message}</p>
                <p><strong>Type :</strong> ${alert.type.name}</p>
                <p><strong>Date :</strong> ${alert.createdAt.toString().split(' ')[0]}</p>
                ${alert.agenceId != null ? '<p><strong>Agence :</strong> ${alert.agenceId}</p>' : ''}
            </div>
            
            <p>Veuillez vous connecter à l'application COREX pour voir les détails complets et prendre les mesures nécessaires.</p>
            
            <div class="footer">
                <p>Cet email a été envoyé automatiquement par le système d'alertes COREX.</p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  /// Récupère la couleur selon la sévérité
  String _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return '#E8F5E8';
      case AlertSeverity.medium:
        return '#FFF3E0';
      case AlertSeverity.high:
        return '#FFEBEE';
      case AlertSeverity.critical:
        return '#FFCDD2';
    }
  }

  /// Récupère le texte selon la sévérité
  String _getSeverityText(AlertSeverity severity) {
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
}

/// Modèle d'alerte
class AlertModel {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;
  final String? agenceId;
  final String? userId;
  final Map<String, dynamic> data;
  final bool isRead;
  final bool isResolved;
  final String? readBy;
  final DateTime? readAt;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolution;

  AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.agenceId,
    this.userId,
    required this.data,
    required this.isRead,
    required this.isResolved,
    this.readBy,
    this.readAt,
    this.resolvedBy,
    this.resolvedAt,
    this.resolution,
  });

  AlertModel copyWith({
    bool? isRead,
    bool? isResolved,
    String? readBy,
    DateTime? readAt,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolution,
  }) {
    return AlertModel(
      id: id,
      type: type,
      title: title,
      message: message,
      severity: severity,
      createdAt: createdAt,
      agenceId: agenceId,
      userId: userId,
      data: data,
      isRead: isRead ?? this.isRead,
      isResolved: isResolved ?? this.isResolved,
      readBy: readBy ?? this.readBy,
      readAt: readAt ?? this.readAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolution: resolution ?? this.resolution,
    );
  }
}

/// Configuration de seuil d'alerte
class AlertThreshold {
  final AlertType type;
  final double threshold;
  final bool enabled;
  final Duration checkInterval;
  DateTime? lastCheck;

  AlertThreshold({
    required this.type,
    required this.threshold,
    required this.enabled,
    required this.checkInterval,
    this.lastCheck,
  });

  AlertThreshold copyWith({
    double? threshold,
    bool? enabled,
    Duration? checkInterval,
  }) {
    return AlertThreshold(
      type: type,
      threshold: threshold ?? this.threshold,
      enabled: enabled ?? this.enabled,
      checkInterval: checkInterval ?? this.checkInterval,
      lastCheck: lastCheck,
    );
  }
}

/// Types d'alertes
enum AlertType {
  stockBas,
  creditDepasse,
  colisEnRetard,
  livraisonEnRetard,
  caisseNegative,
  connexionSuspecte,
  erreurSysteme,
  maintenanceProgrammee,
}

/// Niveaux de sévérité des alertes
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}
