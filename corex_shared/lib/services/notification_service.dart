import 'package:get/get.dart';
import '../models/colis_model.dart';
import '../models/livraison_model.dart';
import '../services/email_service.dart';
import '../services/user_service.dart';

class NotificationService extends GetxService {
  static NotificationService get instance => Get.find<NotificationService>();

  final EmailService _emailService = EmailService.instance;
  final UserService _userService = Get.find<UserService>();

  // Préférences de notifications par utilisateur
  final RxMap<String, NotificationPreferences> _userPreferences = <String, NotificationPreferences>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotificationPreferences();
  }

  /// Charge les préférences de notifications depuis Firebase
  Future<void> _loadNotificationPreferences() async {
    // TODO: Charger depuis Firebase les préférences de chaque utilisateur
    // Pour l'instant, utiliser des valeurs par défaut
  }

  /// Notification de changement de statut de colis
  Future<void> notifyColisStatusChange({
    required ColisModel colis,
    required String newStatus,
    required String changedBy,
  }) async {
    try {
      // Notifier l'expéditeur si il a un email
      if (colis.expediteurEmail != null && colis.expediteurEmail!.isNotEmpty) {
        final expediteurPrefs = await _getUserNotificationPreferences(colis.expediteurEmail!);
        if (expediteurPrefs.colisStatusUpdates) {
          await _emailService.sendColisStatusChangeEmail(
            colis: colis,
            newStatus: newStatus,
            recipientEmail: colis.expediteurEmail!,
            recipientName: colis.expediteurNom,
          );
        }
      }

      // Notifier le destinataire si il a un email et si le statut le concerne
      if (colis.destinataireEmail != null && colis.destinataireEmail!.isNotEmpty && _shouldNotifyDestinataire(newStatus)) {
        final destinatairePrefs = await _getUserNotificationPreferences(colis.destinataireEmail!);
        if (destinatairePrefs.colisStatusUpdates) {
          await _emailService.sendColisStatusChangeEmail(
            colis: colis,
            newStatus: newStatus,
            recipientEmail: colis.destinataireEmail!,
            recipientName: colis.destinataireNom,
          );
        }
      }

      print('✅ Notifications de changement de statut envoyées pour le colis ${colis.numeroSuivi}');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi des notifications de statut: $e');
    }
  }

  /// Notification d'arrivée à destination
  Future<void> notifyColisArrival({
    required ColisModel colis,
  }) async {
    try {
      if (colis.destinataireEmail != null && colis.destinataireEmail!.isNotEmpty) {
        final destinatairePrefs = await _getUserNotificationPreferences(colis.destinataireEmail!);
        if (destinatairePrefs.colisArrival) {
          await _emailService.sendColisArrivalEmail(
            colis: colis,
            destinataireEmail: colis.destinataireEmail!,
            destinataireName: colis.destinataireNom,
          );
        }
      }

      print('✅ Notification d\'arrivée envoyée pour le colis ${colis.numeroSuivi}');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la notification d\'arrivée: $e');
    }
  }

  /// Notification d'attribution de livraison au coursier
  Future<void> notifyLivraisonAttribution({
    required LivraisonModel livraison,
    required ColisModel colis,
    required String coursierId,
  }) async {
    try {
      final coursier = await _userService.getUserById(coursierId);
      if (coursier != null && coursier.email.isNotEmpty) {
        final coursierPrefs = await _getUserNotificationPreferences(coursier.email);
        if (coursierPrefs.livraisonAttribution) {
          await _emailService.sendLivraisonAttributionEmail(
            livraison: livraison,
            colis: colis,
            coursier: coursier,
          );
        }
      }

      print('✅ Notification d\'attribution envoyée au coursier pour la livraison ${livraison.id}');
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la notification d\'attribution: $e');
    }
  }

  /// Récupère les préférences de notification d'un utilisateur
  Future<NotificationPreferences> _getUserNotificationPreferences(String userEmail) async {
    if (_userPreferences.containsKey(userEmail)) {
      return _userPreferences[userEmail]!;
    }

    // Valeurs par défaut si pas de préférences trouvées
    final defaultPrefs = NotificationPreferences();
    _userPreferences[userEmail] = defaultPrefs;
    return defaultPrefs;
  }

  /// Met à jour les préférences de notification d'un utilisateur
  Future<void> updateNotificationPreferences({
    required String userEmail,
    required NotificationPreferences preferences,
  }) async {
    try {
      _userPreferences[userEmail] = preferences;

      // TODO: Sauvegarder dans Firebase
      // await FirebaseFirestore.instance
      //     .collection('notification_preferences')
      //     .doc(userEmail)
      //     .set(preferences.toMap());

      print('✅ Préférences de notification mises à jour pour $userEmail');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des préférences: $e');
    }
  }

  /// Détermine si le destinataire doit être notifié selon le statut
  bool _shouldNotifyDestinataire(String status) {
    return ['arriveDestination', 'enCoursLivraison', 'livre', 'retourne'].contains(status);
  }
}

/// Classe représentant les préférences de notification d'un utilisateur
class NotificationPreferences {
  bool colisStatusUpdates;
  bool colisArrival;
  bool livraisonAttribution;
  bool livraisonSuccess;
  bool livraisonEchec;
  bool factureStockage;
  bool courseAttribution;
  bool alertes;

  NotificationPreferences({
    this.colisStatusUpdates = true,
    this.colisArrival = true,
    this.livraisonAttribution = true,
    this.livraisonSuccess = true,
    this.livraisonEchec = true,
    this.factureStockage = true,
    this.courseAttribution = true,
    this.alertes = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'colisStatusUpdates': colisStatusUpdates,
      'colisArrival': colisArrival,
      'livraisonAttribution': livraisonAttribution,
      'livraisonSuccess': livraisonSuccess,
      'livraisonEchec': livraisonEchec,
      'factureStockage': factureStockage,
      'courseAttribution': courseAttribution,
      'alertes': alertes,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      colisStatusUpdates: map['colisStatusUpdates'] ?? true,
      colisArrival: map['colisArrival'] ?? true,
      livraisonAttribution: map['livraisonAttribution'] ?? true,
      livraisonSuccess: map['livraisonSuccess'] ?? true,
      livraisonEchec: map['livraisonEchec'] ?? true,
      factureStockage: map['factureStockage'] ?? true,
      courseAttribution: map['courseAttribution'] ?? true,
      alertes: map['alertes'] ?? true,
    );
  }
}
