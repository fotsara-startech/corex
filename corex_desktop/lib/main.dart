import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:corex_shared/models/colis_hive_adapter.dart';
import 'package:corex_shared/repositories/local_colis_repository.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'theme/corex_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/coursier/details_livraison_screen.dart';
import 'screens/caisse/caisse_dashboard_screen.dart';
import 'screens/retours/creer_retour_screen.dart';
import 'screens/retours/liste_retours_screen.dart';
import 'screens/notifications/notifications_screen.dart';

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

  // Initialiser Hive
  print('� [HIIVE] Initialisation de Hive...');
  await Hive.initFlutter();

  // Enregistrer les adaptateurs Hive
  Hive.registerAdapter(ColisModelAdapter());
  Hive.registerAdapter(HistoriqueStatutAdapter());
  print('✅ [HIVE] Hive initialisé avec succès');

  // Initialiser Firebase
  print('🔥 [FIREBASE] Initialisation de Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ [FIREBASE] Firebase initialisé avec succès');

  // Configurer Firestore avec persistance pour le mode offline
  print('📦 [FIRESTORE] Configuration de Firestore...');
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Activé pour le mode offline
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  print('✅ [FIRESTORE] Firestore configuré avec persistance offline');

  // Tester la connexion Firestore
  try {
    print('🔍 [FIRESTORE] Test de connexion...');
    await FirebaseFirestore.instance.collection('_test').limit(1).get();
    print('✅ [FIRESTORE] Connexion réussie !');
  } catch (e) {
    print('⚠️ [FIRESTORE] Erreur de connexion: $e');
    print('💡 [HINT] Vérifiez que Firestore est activé dans Firebase Console');
  }

  // Initialiser le repository local
  print('💾 [LOCAL_REPO] Initialisation du repository local...');
  final localRepo = LocalColisRepository();
  await localRepo.initialize();
  Get.put(localRepo, permanent: true);
  print('✅ [LOCAL_REPO] Repository local initialisé');

  // Initialiser les services GetX
  print('⚙️ [GETX] Initialisation des services...');
  Get.put(ConnectivityService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(UserService(), permanent: true);
  Get.put(AgenceService(), permanent: true);
  Get.put(ZoneService(), permanent: true);
  Get.put(AgenceTransportService(), permanent: true);
  Get.put(ColisService(), permanent: true);
  Get.put(LivraisonService(), permanent: true);
  Get.put(TransactionService(), permanent: true);
  Get.put(ClientService(), permanent: true);
  Get.put(StockageService(), permanent: true);
  Get.put(CourseService(), permanent: true);
  Get.put(SyncService(), permanent: true);
  Get.put(EmailService(), permanent: true);
  Get.put(NotificationService(), permanent: true);
  Get.put(AlertService(), permanent: true);
  print('✅ [GETX] Services initialisés');

  // Initialiser les controllers
  print('🎮 [GETX] Initialisation des controllers...');
  Get.put(AuthController(), permanent: true);
  Get.put(UserController(), permanent: true);
  Get.put(AgenceController(), permanent: true);
  Get.put(ZoneController(), permanent: true);
  Get.put(AgenceTransportController(), permanent: true);
  Get.put(ColisController(), permanent: true);
  Get.put(LivraisonController(), permanent: true);
  Get.put(TransactionController(), permanent: true);
  Get.put(ClientController(), permanent: true);
  Get.put(StockageController(), permanent: true);
  Get.put(CourseController(), permanent: true);
  Get.put(RetourController(), permanent: true);
  Get.put(NotificationController(), permanent: true);
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
