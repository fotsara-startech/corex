import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

/// Mixin pour initialiser les services GetX de manière sécurisée
/// Évite les erreurs "Service not found" lors de la navigation
mixin ServiceInitializerMixin<T extends StatefulWidget> on State<T> {
  /// Initialise les services essentiels si nécessaire
  Future<void> ensureServices(List<Type> serviceTypes) async {
    try {
      for (var serviceType in serviceTypes) {
        final isRegistered = _checkIfRegistered(serviceType);
        if (!isRegistered) {
          print('🔧 [SERVICE_INIT] Initialisation de $serviceType...');
          _registerService(serviceType);
        } else {
          print('✅ [SERVICE_INIT] $serviceType déjà enregistré');
        }
      }

      // Attendre un peu pour s'assurer que tout est prêt
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      print('❌ [SERVICE_INIT] Erreur initialisation: $e');
      rethrow;
    }
  }

  bool _checkIfRegistered(Type serviceType) {
    switch (serviceType) {
      case ColisService:
        return Get.isRegistered<ColisService>();
      case UserService:
        return Get.isRegistered<UserService>();
      case ClientService:
        return Get.isRegistered<ClientService>();
      case CourseService:
        return Get.isRegistered<CourseService>();
      case LivraisonService:
        return Get.isRegistered<LivraisonService>();
      case AgenceService:
        return Get.isRegistered<AgenceService>();
      case ZoneService:
        return Get.isRegistered<ZoneService>();
      case TransactionService:
        return Get.isRegistered<TransactionService>();
      case DemandeService:
        return Get.isRegistered<DemandeService>();
      case StockageService:
        return Get.isRegistered<StockageService>();
      case AgenceTransportService:
        return Get.isRegistered<AgenceTransportService>();
      case NotificationService:
        return Get.isRegistered<NotificationService>();
      case SyncService:
        return Get.isRegistered<SyncService>();
      case AlertService:
        return Get.isRegistered<AlertService>();
      case EmailService:
        return Get.isRegistered<EmailService>();
      case ColisController:
        return Get.isRegistered<ColisController>();
      case UserController:
        return Get.isRegistered<UserController>();
      case ClientController:
        return Get.isRegistered<ClientController>();
      case CourseController:
        return Get.isRegistered<CourseController>();
      case LivraisonController:
        return Get.isRegistered<LivraisonController>();
      case AgenceController:
        return Get.isRegistered<AgenceController>();
      case ZoneController:
        return Get.isRegistered<ZoneController>();
      case TransactionController:
        return Get.isRegistered<TransactionController>();
      case DemandeController:
        return Get.isRegistered<DemandeController>();
      case StockageController:
        return Get.isRegistered<StockageController>();
      case AgenceTransportController:
        return Get.isRegistered<AgenceTransportController>();
      case NotificationController:
        return Get.isRegistered<NotificationController>();
      case RetourController:
        return Get.isRegistered<RetourController>();
      case SuiviController:
        return Get.isRegistered<SuiviController>();
      case DashboardController:
        return Get.isRegistered<DashboardController>();
      case PdgDashboardController:
        return Get.isRegistered<PdgDashboardController>();
      case AuthController:
        return Get.isRegistered<AuthController>();
      default:
        return false;
    }
  }

  void _registerService(Type serviceType) {
    switch (serviceType) {
      // Services
      case ColisService:
        Get.put(ColisService(), permanent: true);
        break;
      case UserService:
        Get.put(UserService(), permanent: true);
        break;
      case ClientService:
        Get.put(ClientService(), permanent: true);
        break;
      case CourseService:
        Get.put(CourseService(), permanent: true);
        break;
      case LivraisonService:
        Get.put(LivraisonService(), permanent: true);
        break;
      case AgenceService:
        Get.put(AgenceService(), permanent: true);
        break;
      case ZoneService:
        Get.put(ZoneService(), permanent: true);
        break;
      case TransactionService:
        Get.put(TransactionService(), permanent: true);
        break;
      case DemandeService:
        Get.put(DemandeService(), permanent: true);
        break;
      case StockageService:
        Get.put(StockageService(), permanent: true);
        break;
      case AgenceTransportService:
        Get.put(AgenceTransportService(), permanent: true);
        break;
      case NotificationService:
        Get.put(NotificationService(), permanent: true);
        break;
      case SyncService:
        Get.put(SyncService(), permanent: true);
        break;
      case AlertService:
        Get.put(AlertService(), permanent: true);
        break;
      case EmailService:
        Get.put(EmailService(), permanent: true);
        break;

      // Controllers
      case ColisController:
        Get.put(ColisController(), permanent: true);
        break;
      case UserController:
        Get.put(UserController(), permanent: true);
        break;
      case ClientController:
        Get.put(ClientController(), permanent: true);
        break;
      case CourseController:
        Get.put(CourseController(), permanent: true);
        break;
      case LivraisonController:
        Get.put(LivraisonController(), permanent: true);
        break;
      case AgenceController:
        Get.put(AgenceController(), permanent: true);
        break;
      case ZoneController:
        Get.put(ZoneController(), permanent: true);
        break;
      case TransactionController:
        Get.put(TransactionController(), permanent: true);
        break;
      case DemandeController:
        Get.put(DemandeController(), permanent: true);
        break;
      case StockageController:
        Get.put(StockageController(), permanent: true);
        break;
      case AgenceTransportController:
        Get.put(AgenceTransportController(), permanent: true);
        break;
      case NotificationController:
        Get.put(NotificationController(), permanent: true);
        break;
      case RetourController:
        Get.put(RetourController(), permanent: true);
        break;
      case SuiviController:
        Get.put(SuiviController(), permanent: true);
        break;
      case DashboardController:
        Get.put(DashboardController(), permanent: true);
        break;
      case PdgDashboardController:
        Get.put(PdgDashboardController(), permanent: true);
        break;
      case AuthController:
        Get.put(AuthController(), permanent: true);
        break;

      default:
        print('⚠️ [SERVICE_INIT] Type de service non reconnu: $serviceType');
    }
  }

  /// Affiche un message d'erreur si l'initialisation échoue
  void showInitializationError(String message) {
    if (mounted) {
      Get.snackbar(
        'Erreur d\'initialisation',
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
