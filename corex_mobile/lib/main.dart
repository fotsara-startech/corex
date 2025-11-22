import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corex_shared/corex_shared.dart';
import 'firebase_options.dart';
import 'theme/corex_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

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
  Get.put(ColisService(), permanent: true);
  Get.put(LivraisonService(), permanent: true);
  Get.put(TransactionService(), permanent: true);

  // Initialiser les controllers
  Get.put(AuthController(), permanent: true);

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
      ],
    );
  }
}
