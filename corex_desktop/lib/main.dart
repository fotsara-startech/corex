import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/client_register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/coursier/details_livraison_screen.dart';
import 'screens/caisse/caisse_dashboard_screen.dart';
import 'screens/retours/creer_retour_screen.dart';
import 'screens/retours/liste_retours_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/pdg/pdg_dashboard_screen.dart';
import 'screens/demandes/demandes_dashboard_screen.dart';
import 'screens/client/demande_course_form.dart';
import 'screens/client/demande_colis_form.dart';
import 'screens/client/mes_demandes_screen.dart';
import 'screens/client/historique_client_screen.dart';
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

  // Attendre un délai pour s'assurer que tous les modules sont chargés (important pour le web)
  if (kIsWeb) {
    await Future.delayed(const Duration(milliseconds: 2000));
    print('⏳ [COREX] Délai d\'initialisation web terminé');
  }

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

    // Initialiser Firebase avec gestion d'erreur spécifique pour Windows
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ [COREX] Firebase initialisé avec succès');
    } catch (e) {
      print('⚠️ [COREX] Erreur Firebase spécifique: $e');
      // Essayer une initialisation alternative pour Windows
      if (!kIsWeb) {
        try {
          await Firebase.initializeApp();
          print('✅ [COREX] Firebase initialisé avec configuration par défaut');
        } catch (e2) {
          print('❌ [COREX] Échec total Firebase: $e2');
          throw e2;
        }
      } else {
        throw e;
      }
    }

    // Attendre un peu pour que Firebase Auth soit prêt
    await Future.delayed(const Duration(milliseconds: 500));
  } catch (e) {
    print('⚠️ [COREX] Erreur Firebase finale: $e');
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

    // Services de base avec gestion d'erreurs individuelle
    final services = [
      () => _safeInitialize('AuthService', () => Get.put(AuthService(), permanent: true)),
      () => _safeInitialize('DemandeService', () => Get.put(DemandeService(), permanent: true)),
      () => _safeInitialize('ColisService', () => Get.put(ColisService(), permanent: true)),
      () => _safeInitialize('UserService', () => Get.put(UserService(), permanent: true)),
      () => _safeInitialize('ClientService', () => Get.put(ClientService(), permanent: true)),
      () => _safeInitialize('TransactionService', () => Get.put(TransactionService(), permanent: true)),
      () => _safeInitialize('LivraisonService', () => Get.put(LivraisonService(), permanent: true)),
      () => _safeInitialize('AgenceService', () => Get.put(AgenceService(), permanent: true)),
      () => _safeInitialize('ZoneService', () => Get.put(ZoneService(), permanent: true)),
      () => _safeInitialize('CourseService', () => Get.put(CourseService(), permanent: true)),
      () => _safeInitialize('AgenceTransportService', () => Get.put(AgenceTransportService(), permanent: true)),
      () => _safeInitialize('NotificationService', () => Get.put(NotificationService(), permanent: true)),
      () => _safeInitialize('StockageService', () => Get.put(StockageService(), permanent: true)),
      () => _safeInitialize('AlertService', () => Get.put(AlertService(), permanent: true)),
      () => _safeInitialize('EmailService', () => Get.put(EmailService(), permanent: true)),
    ];

    for (var serviceInit in services) {
      await serviceInit();
    }

    // Attendre un peu avant d'initialiser les controllers
    await Future.delayed(const Duration(milliseconds: 500));

    // Controllers avec gestion d'erreurs individuelle
    final controllers = [
      () => _safeInitialize('AuthController', () => Get.put(AuthController(), permanent: true)),
      () => _safeInitialize('DemandeController', () => Get.put(DemandeController(), permanent: true)),
      () => _safeInitialize('TransactionController', () => Get.put(TransactionController(), permanent: true)),
      () => _safeInitialize('ColisController', () => Get.put(ColisController(), permanent: true)),
      () => _safeInitialize('ClientController', () => Get.put(ClientController(), permanent: true)),
      () => _safeInitialize('UserController', () => Get.put(UserController(), permanent: true)),
      () => _safeInitialize('LivraisonController', () => Get.put(LivraisonController(), permanent: true)),
      () => _safeInitialize('ZoneController', () => Get.put(ZoneController(), permanent: true)),
      () => _safeInitialize('AgenceController', () => Get.put(AgenceController(), permanent: true)),
      () => _safeInitialize('CourseController', () => Get.put(CourseController(), permanent: true)),
      () => _safeInitialize('AgenceTransportController', () => Get.put(AgenceTransportController(), permanent: true)),
      () => _safeInitialize('DashboardController', () => Get.put(DashboardController(), permanent: true)),
      () => _safeInitialize('NotificationController', () => Get.put(NotificationController(), permanent: true)),
      () => _safeInitialize('PdgDashboardController', () => Get.put(PdgDashboardController(), permanent: true)),
      () => _safeInitialize('RetourController', () => Get.put(RetourController(), permanent: true)),
      () => _safeInitialize('StockageController', () => Get.put(StockageController(), permanent: true)),
      () => _safeInitialize('SuiviController', () => Get.put(SuiviController(), permanent: true)),
    ];

    for (var controllerInit in controllers) {
      await controllerInit();
    }

    print('✅ [COREX] Services et controllers initialisés avec succès');
  } catch (e) {
    print('❌ [COREX] Erreur initialisation services: $e');
    // Ne pas bloquer l'application, certains services peuvent être rtrtrtrtr
  }
}

/// Initialise un service/controller de manière sécurisée
Future<void> _safeInitialize(String name, Function initFunction) async {
  try {
    await initFunction();
    print('✅ [COREX] $name initialisé');
  } catch (e) {
    print('⚠️ [COREX] Erreur $name: $e');
    // Continuer même en cas d'erreur
  }
}

/// Initialisation de secours pour les contrôleurs manquants
void _initializeFallbackControllers() {
  print('🔄 [COREX] Initialisation de secours des contrôleurs...');

  final fallbackControllers = [
    () => !Get.isRegistered<CourseController>() ? Get.put(CourseController(), permanent: true) : null,
    () => !Get.isRegistered<AgenceTransportController>() ? Get.put(AgenceTransportController(), permanent: true) : null,
    () => !Get.isRegistered<DashboardController>() ? Get.put(DashboardController(), permanent: true) : null,
    () => !Get.isRegistered<NotificationController>() ? Get.put(NotificationController(), permanent: true) : null,
    () => !Get.isRegistered<PdgDashboardController>() ? Get.put(PdgDashboardController(), permanent: true) : null,
    () => !Get.isRegistered<RetourController>() ? Get.put(RetourController(), permanent: true) : null,
    () => !Get.isRegistered<StockageController>() ? Get.put(StockageController(), permanent: true) : null,
    () => !Get.isRegistered<SuiviController>() ? Get.put(SuiviController(), permanent: true) : null,
  ];

  for (var controllerInit in fallbackControllers) {
    try {
      controllerInit();
    } catch (e) {
      print('⚠️ [COREX] Erreur controller de secours: $e');
    }
  }
}

/// S'assure que les services essentiels sont disponibles
Future<void> _ensureEssentialServices() async {
  try {
    print('🔍 [COREX] Vérification des services essentiels...');

    // Attendre un délai pour s'assurer que GetX est prêt
    await Future.delayed(const Duration(milliseconds: 100));

    // Vérifier et initialiser les services essentiels
    final essentialServices = [
      () => !Get.isRegistered<AuthService>() ? Get.put(AuthService(), permanent: true) : null,
      () => !Get.isRegistered<UserService>() ? Get.put(UserService(), permanent: true) : null,
      () => !Get.isRegistered<ClientService>() ? Get.put(ClientService(), permanent: true) : null,
      () => !Get.isRegistered<CourseService>() ? Get.put(CourseService(), permanent: true) : null,
    ];

    for (var serviceInit in essentialServices) {
      try {
        await serviceInit();
      } catch (e) {
        print('⚠️ [COREX] Erreur service essentiel: $e');
      }
    }

    // Vérifier et initialiser les contrôleurs essentiels
    final essentialControllers = [
      () => !Get.isRegistered<AuthController>() ? Get.put(AuthController(), permanent: true) : null,
      () => !Get.isRegistered<UserController>() ? Get.put(UserController(), permanent: true) : null,
      () => !Get.isRegistered<ClientController>() ? Get.put(ClientController(), permanent: true) : null,
      () => !Get.isRegistered<CourseController>() ? Get.put(CourseController(), permanent: true) : null,
    ];

    for (var controllerInit in essentialControllers) {
      try {
        await controllerInit();
      } catch (e) {
        print('⚠️ [COREX] Erreur controller essentiel: $e');
      }
    }

    print('✅ [COREX] Services essentiels vérifiés');
  } catch (e) {
    print('❌ [COREX] Erreur vérification services essentiels: $e');
  }
}

/// Initialise les services essentiels si nécessaire
void _initializeEssentialServicesIfNeeded() {
  try {
    print('🔍 [COREX] Vérification des services essentiels...');

    // Vérifier et initialiser les services essentiels
    final essentialServices = [
      () => !Get.isRegistered<AuthService>() ? Get.put(AuthService(), permanent: true) : null,
      () => !Get.isRegistered<UserService>() ? Get.put(UserService(), permanent: true) : null,
      () => !Get.isRegistered<ClientService>() ? Get.put(ClientService(), permanent: true) : null,
      () => !Get.isRegistered<CourseService>() ? Get.put(CourseService(), permanent: true) : null,
    ];

    for (var serviceInit in essentialServices) {
      try {
        serviceInit();
      } catch (e) {
        print('⚠️ [COREX] Erreur service essentiel: $e');
      }
    }

    // Vérifier et initialiser les contrôleurs essentiels
    final essentialControllers = [
      () => !Get.isRegistered<AuthController>() ? Get.put(AuthController(), permanent: true) : null,
      () => !Get.isRegistered<UserController>() ? Get.put(UserController(), permanent: true) : null,
      () => !Get.isRegistered<ClientController>() ? Get.put(ClientController(), permanent: true) : null,
      () => !Get.isRegistered<CourseController>() ? Get.put(CourseController(), permanent: true) : null,
    ];

    for (var controllerInit in essentialControllers) {
      try {
        controllerInit();
      } catch (e) {
        print('⚠️ [COREX] Erreur controller essentiel: $e');
      }
    }

    print('✅ [COREX] Services essentiels vérifiés');
  } catch (e) {
    print('❌ [COREX] Erreur vérification services essentiels: $e');
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
    return FutureBuilder<void>(
        future: _ensureEssentialServices(),
        builder: (context, snapshot) {
          // Afficher un écran de chargement pendant l'initialisation
          if (snapshot.connectionState == ConnectionState.waiting) {
            return MaterialApp(
              title: 'COREX Desktop',
              theme: corexTheme,
              debugShowCheckedModeBanner: false,
              home: const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Initialisation de COREX...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Une fois l'initialisation terminée, afficher l'app GetX
          return GetMaterialApp(
            title: 'COREX Desktop',
            theme: corexTheme,
            debugShowCheckedModeBanner: false,
            locale: const Locale('fr', 'FR'),
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/login',
            getPages: [
              GetPage(
                name: '/login',
                page: () => const LoginScreen(),
              ),
              GetPage(
                name: '/register',
                page: () => const ClientRegisterScreen(),
              ),
              GetPage(
                name: '/home',
                page: () => const HomeScreen(),
              ),
              GetPage(
                name: '/pdg/dashboard',
                page: () => const PdgDashboardScreen(),
              ),
              GetPage(
                name: '/livraison/details',
                page: () => const DetailsLivraisonScreen(),
              ),
              GetPage(
                name: '/caisse',
                page: () => const CaisseDashboardScreen(),
              ),
              GetPage(
                name: '/retours',
                page: () => const ListeRetoursScreen(),
              ),
              GetPage(
                name: '/retours/creer',
                page: () => const CreerRetourScreen(),
              ),
              GetPage(
                name: '/notifications',
                page: () => const NotificationsScreen(),
              ),
              GetPage(
                name: '/demandes',
                page: () => const DemandesDashboardScreen(),
              ),
              // Routes client
              GetPage(
                name: '/client/demande-course',
                page: () => const DemandeCourseForm(),
              ),
              GetPage(
                name: '/client/demande-colis',
                page: () => const DemandeColisForm(),
              ),
              GetPage(
                name: '/client/mes-demandes',
                page: () => const MesDemandesScreen(),
              ),
              GetPage(
                name: '/client/historique',
                page: () => const HistoriqueClientScreen(),
              ),
            ],
          );
        });
  }
}
