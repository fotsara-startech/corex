import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/coursier/details_livraison_screen.dart';
import 'screens/caisse/caisse_dashboard_screen.dart';
import 'screens/retours/creer_retour_screen.dart';
import 'screens/retours/liste_retours_screen.dart';
import 'screens/notifications/notifications_screen.dart';

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

  runApp(const CorexDesktopApp());
}

class CorexDesktopApp extends StatelessWidget {
  const CorexDesktopApp({super.key});

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
      home: const InitializationScreen(),
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

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  String _status = 'Initialisation...';
  bool _isComplete = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Etape 1: Hive (25%)
      setState(() {
        _status = 'Initialisation du stockage local...';
        _progress = 0.25;
      });
      await _initializeHive();
      await Future.delayed(const Duration(milliseconds: 500));

      // Etape 2: Firebase (50%)
      setState(() {
        _status = 'Connexion a Firebase...';
        _progress = 0.5;
      });
      await _initializeFirebase();
      await Future.delayed(const Duration(milliseconds: 500));

      // Etape 3: Services (75%)
      setState(() {
        _status = 'Chargement des services...';
        _progress = 0.75;
      });
      await _initializeServices();
      await Future.delayed(const Duration(milliseconds: 500));

      // Etape 4: Controllers (100%)
      setState(() {
        _status = 'Finalisation...';
        _progress = 1.0;
      });
      await _initializeControllers();
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _status = 'Pret !';
        _isComplete = true;
      });

      // Redirection vers login
      await Future.delayed(const Duration(milliseconds: 1000));
      Get.offAllNamed('/login');
    } catch (e) {
      setState(() => _status = 'Erreur: $e');
      print('❌ [INIT] Erreur d\'initialisation: $e');

      // En cas d'erreur, aller quand meme au login apres 3 secondes
      await Future.delayed(const Duration(seconds: 3));
      Get.offAllNamed('/login');
    }
  }

  Future<void> _initializeHive() async {
    try {
      if (kIsWeb) {
        await Hive.initFlutter('corex_web');
      } else {
        await Hive.initFlutter();
      }

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ColisModelAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(HistoriqueStatutAdapter());
      }
      print('✅ [HIVE] Initialise avec succes');
    } catch (e) {
      print('⚠️ [HIVE] Erreur: $e');
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: !kIsWeb,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('✅ [FIREBASE] Initialise avec succes');
    } catch (e) {
      print('⚠️ [FIREBASE] Erreur: $e');
      // Continue sans Firebase
    }
  }

  Future<void> _initializeServices() async {
    try {
      final localRepo = LocalColisRepository();
      await localRepo.initialize();
      Get.put(localRepo, permanent: true);

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
      print('✅ [SERVICES] Initialises avec succes');
    } catch (e) {
      print('⚠️ [SERVICES] Erreur: $e');
    }
  }

  Future<void> _initializeControllers() async {
    try {
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
      print('✅ [CONTROLLERS] Initialises avec succes');
    } catch (e) {
      print('⚠️ [CONTROLLERS] Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'COREX',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Système de Gestion de Colis',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),

              // Indicateur de progression
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              if (!_isComplete)
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle,
                  size: 40,
                  color: Colors.white,
                ),

              const SizedBox(height: 20),
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),
              Text(
                'Version Web - ${kIsWeb ? 'Navigateur' : 'Desktop'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
