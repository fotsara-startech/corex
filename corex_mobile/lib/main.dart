import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corex_shared/corex_shared.dart';
import 'firebase_options.dart';
import 'theme/corex_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/coursier/mes_livraisons_screen.dart';
import 'screens/coursier/details_livraison_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/rapports/rapports_financiers_screen.dart';
import 'screens/rapports/rapport_agence_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configurer Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialiser les services GetX
  Get.put(AuthService(), permanent: true);
  Get.put(UserService(), permanent: true);
  Get.put(ColisService(), permanent: true);
  Get.put(LivraisonService(), permanent: true);
  Get.put(TransactionService(), permanent: true);
  Get.put(AgenceService(), permanent: true);
  Get.put(ExportService(), permanent: true);

  // Initialiser les controllers
  Get.put(AuthController(), permanent: true);
  Get.put(ColisController(), permanent: true);
  Get.put(LivraisonController(), permanent: true);

  runApp(const CorexMobileApp());
}

class CorexMobileApp extends StatelessWidget {
  const CorexMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'COREX Mobile',
      theme: CorexTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/rapports/financiers', page: () => const RapportsFinanciersScreen()),
        GetPage(name: '/rapports/agence', page: () => const RapportAgenceScreen()),
        GetPage(
          name: '/coursier/livraisons',
          page: () => const MesLivraisonsScreen(),
        ),
        GetPage(
          name: '/coursier/livraison/details',
          page: () => const DetailsLivraisonScreen(),
        ),
      ],
    );
  }
}
