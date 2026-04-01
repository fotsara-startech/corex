import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:corex_shared/corex_shared.dart';
import 'firebase_options.dart';
import 'controllers/client_auth_controller.dart';
import 'screens/auth/client_login_screen.dart';
import 'screens/auth/client_register_screen.dart';
import 'screens/dashboard/client_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 [COREX CLIENT] Démarrage de l\'application client web...');

  // Initialisation Firebase
  await _initializeFirebase();

  // Initialisation GetStorage
  await GetStorage.init();
  print('✅ [COREX CLIENT] GetStorage initialisé');

  // Initialisation des services
  await _initializeServices();

  runApp(const CorexClientApp());
}

/// Initialise Firebase pour le web
Future<void> _initializeFirebase() async {
  try {
    print('🔥 [COREX CLIENT] Initialisation Firebase...');

    if (Firebase.apps.isNotEmpty) {
      print('✅ [COREX CLIENT] Firebase déjà initialisé');
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('✅ [COREX CLIENT] Firebase initialisé avec succès');
  } catch (e) {
    print('⚠️ [COREX CLIENT] Erreur Firebase: $e');
  }
}

/// Initialise les services nécessaires
Future<void> _initializeServices() async {
  print('🔧 [COREX CLIENT] Initialisation des services...');

  try {
    // Attendre un peu pour que GetX soit prêt sur le web
    await Future.delayed(const Duration(milliseconds: 500));

    // Services de base - avec vérification d'existence
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }

    if (!Get.isRegistered<DemandeService>()) {
      Get.put(DemandeService(), permanent: true);
    }

    if (!Get.isRegistered<EmailService>()) {
      Get.put(EmailService(), permanent: true);
    }

    // Controllers - avec vérification d'existence
    if (!Get.isRegistered<ClientAuthController>()) {
      Get.put(ClientAuthController(), permanent: true);
    }

    print('✅ [COREX CLIENT] Services initialisés avec succès');
  } catch (e) {
    print('❌ [COREX CLIENT] Erreur initialisation services: $e');
    // Ne pas bloquer l'application, continuer avec les services disponibles
  }
}

class CorexClientApp extends StatelessWidget {
  const CorexClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure services are available as fallback for web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureServicesAvailable();
    });

    return GetMaterialApp(
      title: 'COREX Client',
      theme: _buildTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        GetPage(
          name: '/login',
          page: () => const ClientLoginScreen(),
        ),
        GetPage(
          name: '/register',
          page: () => const ClientRegisterScreen(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => const ClientDashboardScreen(),
        ),
      ],
    );
  }

  /// Ensure services are available (fallback for web)
  void _ensureServicesAvailable() {
    try {
      if (!Get.isRegistered<AuthService>()) {
        print('⚠️ [COREX CLIENT] AuthService manquant, initialisation de secours');
        Get.put(AuthService(), permanent: true);
      }

      if (!Get.isRegistered<ClientAuthController>()) {
        print('⚠️ [COREX CLIENT] ClientAuthController manquant, initialisation de secours');
        Get.put(ClientAuthController(), permanent: true);
      }
    } catch (e) {
      print('❌ [COREX CLIENT] Erreur initialisation de secours: $e');
    }
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2E7D32),
        secondary: Color(0xFF4CAF50),
        surface: Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
