import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'theme/corex_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration de la fenêtre Windows
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'COREX Desktop',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialiser Firebase
  print('🔥 [FIREBASE] Initialisation de Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ [FIREBASE] Firebase initialisé avec succès');

  // Configurer Firestore
  print('📦 [FIRESTORE] Configuration de Firestore...');
  // Note: La persistance est désactivée sur Windows Desktop car elle cause des problèmes de connexion
  // Elle sera activée automatiquement sur mobile
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false, // Désactivé pour Windows
  );
  print('✅ [FIRESTORE] Firestore configuré avec succès');

  // Tester la connexion Firestore
  try {
    print('🔍 [FIRESTORE] Test de connexion...');
    await FirebaseFirestore.instance.collection('_test').limit(1).get();
    print('✅ [FIRESTORE] Connexion réussie !');
  } catch (e) {
    print('⚠️ [FIRESTORE] Erreur de connexion: $e');
    print('💡 [HINT] Vérifiez que Firestore est activé dans Firebase Console');
  }

  // Initialiser les services GetX
  print('⚙️ [GETX] Initialisation des services...');
  Get.put(AuthService(), permanent: true);
  Get.put(UserService(), permanent: true);
  Get.put(AgenceService(), permanent: true);
  Get.put(ZoneService(), permanent: true);
  Get.put(AgenceTransportService(), permanent: true);
  Get.put(ColisService(), permanent: true);
  Get.put(LivraisonService(), permanent: true);
  Get.put(TransactionService(), permanent: true);
  print('✅ [GETX] Services initialisés');

  // Initialiser les controllers
  print('🎮 [GETX] Initialisation des controllers...');
  Get.put(AuthController(), permanent: true);
  print('✅ [GETX] Controllers initialisés');

  runApp(const CorexDesktopApp());
}

class CorexDesktopApp extends StatelessWidget {
  const CorexDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'COREX Desktop',
      theme: CorexTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
      ],
    );
  }
}
