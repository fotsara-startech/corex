import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/client_register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/pdg/pdg_dashboard_screen.dart';
import 'screens/client/demande_course_form.dart';
import 'screens/client/demande_colis_form.dart';
import 'screens/client/mes_demandes_screen.dart';
import 'screens/client/historique_client_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 [COREX WEB] Démarrage de l\'application web...');

  // Initialisation Firebase
  await _initializeFirebase();

  // Initialisation GetStorage pour la persistance
  await GetStorage.init();
  print('✅ [COREX WEB] GetStorage initialisé');

  // Initialisation des services et contrôleurs
  await _initializeServices();

  runApp(const CorexWebApp());
}

/// Initialise Firebase
Future<void> _initializeFirebase() async {
  try {
    print('🔥 [COREX WEB] Initialisation Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ [COREX WEB] Firebase initialisé avec succès');
  } catch (e) {
    print('❌ [COREX WEB] Erreur Firebase: $e');
    // Ne pas bloquer l'application si Firebase échoue
  }
}

/// Initialise tous les services nécessaires pour l'application web
Future<void> _initializeServices() async {
  print('🔧 [COREX WEB] Initialisation des services...');

  try {
    // Services de base
    final services = [
      () => Get.put(AuthService(), permanent: true),
      () => Get.put(DemandeService(), permanent: true),
      () => Get.put(ColisService(), permanent: true),
      () => Get.put(UserService(), permanent: true),
      () => Get.put(ClientService(), permanent: true),
      () => Get.put(TransactionService(), permanent: true),
      () => Get.put(CourseService(), permanent: true),
      () => Get.put(EmailService(), permanent: true),
    ];

    for (var serviceInit in services) {
      try {
        serviceInit();
      } catch (e) {
        print('⚠️ [COREX WEB] Erreur service: $e');
      }
    }

    // Attendre un peu avant d'initialiser les controllers
    await Future.delayed(const Duration(milliseconds: 500));

    // Controllers
    final controllers = [
      () => Get.put(AuthController(), permanent: true),
      () => Get.put(DemandeController(), permanent: true),
      () => Get.put(TransactionController(), permanent: true),
      () => Get.put(ColisController(), permanent: true),
      () => Get.put(ClientController(), permanent: true),
      () => Get.put(UserController(), permanent: true),
      () => Get.put(CourseController(), permanent: true),
    ];

    for (var controllerInit in controllers) {
      try {
        controllerInit();
      } catch (e) {
        print('⚠️ [COREX WEB] Erreur controller: $e');
      }
    }

    print('✅ [COREX WEB] Services et controllers initialisés avec succès');
  } catch (e) {
    print('❌ [COREX WEB] Erreur initialisation services: $e');
  }
}

class CorexWebApp extends StatelessWidget {
  const CorexWebApp({super.key});

  // Theme COREX pour le web
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
      title: 'COREX - Système de Gestion Logistique',
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
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => const Scaffold(
          body: Center(
            child: Text('Page non trouvée'),
          ),
        ),
      ),
    );
  }
}
