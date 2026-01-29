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

  print('🚀 [COREX] Demarrage de l\'application avec donnees reelles...');

  // Configuration de la fenetre Windows (desktop seulement)
  if (!kIsWeb) {
    try {
      await initializeDesktopWindow();
    } catch (e) {
      print('⚠️ [DESKTOP] Erreur initialisation fenetre: $e');
    }
  }

  runApp(const CorexRealApp());
}

class CorexRealApp extends StatelessWidget {
  const CorexRealApp({super.key});

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
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'COREX ${kIsWeb ? 'Web' : 'Desktop'}',
      theme: corexTheme,
      debugShowCheckedModeBanner: false,
      home: const RealInitializationScreen(),
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

class RealInitializationScreen extends StatefulWidget {
  const RealInitializationScreen({super.key});

  @override
  State<RealInitializationScreen> createState() => _RealInitializationScreenState();
}

class _RealInitializationScreenState extends State<RealInitializationScreen> {
  String _status = 'Initialisation...';
  String _currentStep = '';
  bool _isComplete = false;
  double _progress = 0.0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Etape 1: Hive (20%)
      await _updateStatus('Initialisation du stockage local...', 0.2);
      await _initializeHive();

      // Etape 2: Firebase (40%)
      await _updateStatus('Connexion a Firebase...', 0.4);
      await _initializeFirebase();

      // Etape 3: Repository Local (60%)
      await _updateStatus('Configuration du repository local...', 0.6);
      await _initializeRepository();

      // Etape 4: Services (80%)
      await _updateStatus('Chargement des services...', 0.8);
      await _initializeServices();

      // Etape 5: Controllers (100%)
      await _updateStatus('Initialisation des controllers...', 1.0);
      await _initializeControllers();

      await _updateStatus('Pret !', 1.0, isComplete: true);

      // Redirection vers login
      await Future.delayed(const Duration(milliseconds: 1000));
      Get.offAllNamed('/login');
    } catch (e, stackTrace) {
      print('❌ [INIT] Erreur d\'initialisation: $e');
      print('📍 [STACK] $stackTrace');

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _status = 'Erreur d\'initialisation';
      });

      // En cas d'erreur, aller quand meme au login apres 5 secondes
      await Future.delayed(const Duration(seconds: 5));
      Get.offAllNamed('/login');
    }
  }

  Future<void> _updateStatus(String status, double progress, {bool isComplete = false}) async {
    setState(() {
      _status = status;
      _progress = progress;
      _isComplete = isComplete;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _initializeHive() async {
    setState(() => _currentStep = 'Configuration Hive...');

    if (kIsWeb) {
      await Hive.initFlutter('corex_web');
    } else {
      await Hive.initFlutter();
    }

    // Enregistrer les adaptateurs avec verification
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ColisModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoriqueStatutAdapter());
    }

    print('✅ [HIVE] Initialise avec succes');
  }

  Future<void> _initializeFirebase() async {
    setState(() => _currentStep = 'Connexion Firebase...');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configuration Firestore
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: !kIsWeb, // Desactive sur web
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Test de connexion
    setState(() => _currentStep = 'Test connexion Firestore...');
    await FirebaseFirestore.instance.collection('_test').limit(1).get();

    print('✅ [FIREBASE] Initialise avec succes');
  }

  Future<void> _initializeRepository() async {
    setState(() => _currentStep = 'Repository local...');

    final localRepo = LocalColisRepository();
    await localRepo.initialize();
    Get.put(localRepo, permanent: true);

    print('✅ [REPOSITORY] Initialise avec succes');
  }

  Future<void> _initializeServices() async {
    setState(() => _currentStep = 'Services COREX...');

    // Services de base
    Get.put(ConnectivityService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(UserService(), permanent: true);

    // Services metier
    Get.put(AgenceService(), permanent: true);
    Get.put(ZoneService(), permanent: true);
    Get.put(AgenceTransportService(), permanent: true);
    Get.put(ColisService(), permanent: true);
    Get.put(LivraisonService(), permanent: true);
    Get.put(TransactionService(), permanent: true);
    Get.put(ClientService(), permanent: true);
    Get.put(StockageService(), permanent: true);
    Get.put(CourseService(), permanent: true);

    // Services utilitaires
    Get.put(SyncService(), permanent: true);
    Get.put(EmailService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.put(AlertService(), permanent: true);

    print('✅ [SERVICES] Initialises avec succes');
  }

  Future<void> _initializeControllers() async {
    setState(() => _currentStep = 'Controllers COREX...');

    // Controllers de base
    Get.put(AuthController(), permanent: true);
    Get.put(UserController(), permanent: true);

    // Controllers metier
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Center(
                  child: Text(
                    'COREX',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Système de Gestion de Colis',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),

              // Barre de progression
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Pourcentage
              Text(
                '${(_progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              // Indicateur de chargement ou succes
              if (_hasError)
                const Icon(
                  Icons.error,
                  size: 40,
                  color: Colors.red,
                )
              else if (!_isComplete)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 4,
                  ),
                )
              else
                const Icon(
                  Icons.check_circle,
                  size: 40,
                  color: Colors.white,
                ),

              const SizedBox(height: 20),

              // Status principal
              Text(
                _status,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              // Etape courante
              if (_currentStep.isNotEmpty && !_isComplete && !_hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _currentStep,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Message d'erreur
              if (_hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Erreur d\'initialisation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Redirection vers le login dans 5 secondes...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Info version
              Text(
                'Version ${kIsWeb ? 'Web' : 'Desktop'} - Donnees Reelles',
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
