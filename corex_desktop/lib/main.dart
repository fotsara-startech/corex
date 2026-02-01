import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/coursier/details_livraison_screen.dart';
import 'screens/caisse/caisse_dashboard_screen.dart';
import 'screens/retours/creer_retour_screen.dart';
import 'screens/retours/liste_retours_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/pdg/pdg_dashboard_screen.dart';
import 'utils/cache_cleaner.dart';

// Import conditionnel pour l'initialisation desktop/web
import 'desktop_init.dart' if (dart.library.html) 'web_init.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 [COREX] Demarrage de l\'application...');

  // Configuration de la fenetre Windows (desktop seulement)
  if (!kIsWeb) {
    try {
      await initializeDesktopWindow();
    } catch (e) {
      print('⚠️ [DESKTOP] Erreur initialisation fenetre: $e');
    }
  }

  // Initialisation Firebase
  await _initializeFirebase();

  // Initialisation GetStorage pour la persistance
  await GetStorage.init();
  print('✅ [COREX] GetStorage initialisé');

  // Initialisation Hive
  await _initializeHive();

  // Initialisation des services GetX
  await _initializeServices();

  runApp(const CorexDesktopApp());
}

/// Initialise Firebase avec gestion d'erreurs améliorée
Future<void> _initializeFirebase() async {
  try {
    print('🔥 [COREX] Initialisation Firebase...');

    // Vérifier si Firebase est déjà initialisé
    if (Firebase.apps.isNotEmpty) {
      print('✅ [COREX] Firebase déjà initialisé');
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('✅ [COREX] Firebase initialisé avec succès');

    // Attendre un peu pour que Firebase Auth soit prêt
    await Future.delayed(const Duration(milliseconds: 500));
  } catch (e) {
    print('⚠️ [COREX] Erreur Firebase: $e');
    // Ne pas bloquer l'application si Firebase échoue
    // L'application fonctionnera en mode offline/démo
  }
}

/// Initialise Hive pour le stockage local
Future<void> _initializeHive() async {
  try {
    print('📦 [COREX] Initialisation Hive...');

    // Initialiser Hive
    if (kIsWeb) {
      await Hive.initFlutter('corex_web');
    } else {
      await Hive.initFlutter();
    }

    // Enregistrer les adaptateurs avec vérification
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ColisModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoriqueStatutAdapter());
    }

    print('✅ [COREX] Hive initialisé avec succès');
  } catch (e) {
    print('⚠️ [COREX] Erreur Hive: $e');
    // Ne pas bloquer l'application si Hive échoue
  }
}

/// Initialise tous les services nécessaires pour l'application
Future<void> _initializeServices() async {
  print('🔧 [COREX] Initialisation des services...');

  try {
    // Attendre que Firebase soit complètement prêt
    await Future.delayed(const Duration(milliseconds: 1000));

    // Repository local (doit être initialisé en premier)
    try {
      final localRepo = LocalColisRepository();
      await localRepo.initialize();
      Get.put(localRepo, permanent: true);
      print('✅ [COREX] Repository local initialisé');

      // Nettoyer le cache si nécessaire
      await CacheCleaner.cleanCacheIfNeeded();
    } catch (e) {
      print('⚠️ [COREX] Repository local non disponible: $e');
    }

    // Services de base (ordre important)
    Get.put(AuthService(), permanent: true);
    Get.put(AuthController(), permanent: true);

    // Services métier - Initialisation conditionnelle
    try {
      Get.put(ColisService(), permanent: true);
      Get.put(TransactionService(), permanent: true);
      Get.put(TransactionController(), permanent: true); // Ajouter le contrôleur
      Get.put(LivraisonService(), permanent: true);
      Get.put(CourseService(), permanent: true);
      Get.put(UserService(), permanent: true);
      Get.put(AgenceService(), permanent: true);
      Get.put(ClientService(), permanent: true);
      Get.put(ZoneService(), permanent: true);
      Get.put(AgenceTransportService(), permanent: true);
      Get.put(StockageService(), permanent: true);
      Get.put(NotificationService(), permanent: true);
    } catch (e) {
      print('⚠️ [COREX] Certains services métier non disponibles: $e');
    }

    // Services utilitaires - Optionnels
    try {
      Get.put(ConnectivityService(), permanent: true);
      Get.put(SyncService(), permanent: true);
    } catch (e) {
      print('⚠️ [COREX] Services utilitaires non disponibles: $e');
    }

    print('✅ [COREX] Services initialisés avec succès');
  } catch (e) {
    print('❌ [COREX] Erreur initialisation services: $e');
    // Ne pas bloquer l'application, certains services peuvent être optionnels
  }
}

class CorexDesktopApp extends StatelessWidget {
  const CorexDesktopApp({super.key});

  // Theme COREX simple
  static ThemeData get corexTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E7D32),
          secondary: Color(0xFF212121),
          surface: Color(0xFFFFFFFF),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Color(0xFFFFFFFF),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'COREX Desktop',
      theme: corexTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/pdg/dashboard', page: () => const PdgDashboardScreen()),
        GetPage(
          name: '/livraison/details',
          page: () => const DetailsLivraisonScreen(),
        ),
        GetPage(name: '/caisse', page: () => const CaisseDashboardScreen()),
        GetPage(name: '/retours', page: () => const ListeRetoursScreen()),
        GetPage(name: '/retours/creer', page: () => const CreerRetourScreen()),
        GetPage(name: '/notifications', page: () => const NotificationsScreen()),
      ],
    );
  }
}
