# Document de Conception - COREX

## Vue d'Ensemble

COREX adopte une architecture moderne basée sur Flutter pour les clients (desktop Windows et mobile Android) et Firebase Realtime Database comme backend. Cette architecture garantit la scalabilité, la synchronisation temps réel, le mode hors ligne automatique et une maintenance simplifiée. Le système utilise GetX pour la gestion d'état, la navigation et l'injection de dépendances côté Flutter.

## Architecture

### Architecture Globale

```
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Cloud                            │
│  ┌──────────────────────┐    ┌──────────────────────┐      │
│  │  Authentication      │    │  Realtime Database   │      │
│  │  (Email/Password)    │    │  (JSON Structure)    │      │
│  └──────────────────────┘    └──────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                    ▲                        ▲
                    │                        │
        ┌───────────┴────────────┬───────────┴──────────┐
        │                        │                       │
┌───────▼────────┐      ┌────────▼───────┐     ┌────────▼───────┐
│ Flutter Desktop│      │ Flutter Desktop│     │ Flutter Mobile │
│  (Commercial)  │      │  (Agent/Gest.) │     │     (PDG)      │
│   + GetX       │      │    + GetX      │     │    + GetX      │
└────────────────┘      └────────────────┘     └────────────────┘
```

### Stack Technologique

**Frontend (Flutter):**
- Flutter 3.24.0+ pour desktop Windows et mobile Android
- GetX 4.7.2 pour state management, navigation et DI
- Firebase Core, Auth, Realtime Database
- PDF generation (pdf, printing packages)
- Mailer pour envoi d'emails
- Window Manager (desktop), Connectivity Plus (mobile)

**Backend (Firebase):**
- Firebase Authentication pour la gestion des utilisateurs
- Firebase Realtime Database pour la persistance
- Firebase Rules pour la sécurité et les permissions
- Persistance locale automatique pour le mode hors ligne

**Outils de Développement:**
- FlutterFire CLI pour la configuration
- GetX CLI pour la génération de code (optionnel)
- Git pour le versioning

## Composants et Interfaces

### 1. Structure du Projet

```
corex_soft/
├── corex_desktop/              # Application Windows
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── routes/        # Routes GetX
│   │   │   └── bindings/      # Bindings GetX
│   │   ├── modules/
│   │   │   ├── auth/          # Authentification
│   │   │   ├── home/          # Dashboard
│   │   │   ├── colis/         # Gestion colis
│   │   │   ├── livraison/     # Livraisons
│   │   │   ├── caisse/        # Gestion financière
│   │   │   ├── stockage/      # Stockage
│   │   │   ├── courses/       # Service courses
│   │   │   └── settings/      # Paramètres
│   │   └── shared/
│   │       └── widgets/       # Composants réutilisables
│   └── windows/               # Configuration Windows
│
├── corex_mobile/              # Application Android (PDG)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   ├── dashboard/     # Vue globale
│   │   │   ├── rapports/      # Rapports financiers
│   │   │   └── statistiques/  # Statistiques
│   │   └── shared/
│   └── android/               # Configuration Android
│
└── corex_shared/              # Package partagé
    ├── lib/
    │   ├── models/            # Modèles de données
    │   ├── services/          # Services Firebase
    │   ├── controllers/       # Controllers GetX
    │   ├── constants/         # Constantes
    │   └── utils/             # Utilitaires
    └── pubspec.yaml
```


### 2. Architecture GetX

#### Controllers (State Management)

```dart
// AuthController - Gestion de l'authentification
class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }
  
  Future<void> signIn(String email, String password) async {
    isLoading.value = true;
    try {
      final user = await _authService.signIn(email, password);
      currentUser.value = user;
      isAuthenticated.value = true;
      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar('Erreur', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> signOut() async {
    await _authService.signOut();
    currentUser.value = null;
    isAuthenticated.value = false;
    Get.offAll(() => LoginScreen());
  }
  
  bool hasRole(List<String> roles) {
    return currentUser.value != null && 
           roles.contains(currentUser.value!.role);
  }
}

// ColisController - Gestion des colis
class ColisController extends GetxController {
  final ColisService _colisService = Get.find<ColisService>();
  
  final RxList<ColisModel> colisList = <ColisModel>[].obs;
  final Rx<ColisModel?> selectedColis = Rx<ColisModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString filterStatut = 'tous'.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadColis();
    
    // Écouter les changements en temps réel
    ever(searchQuery, (_) => loadColis());
    ever(filterStatut, (_) => loadColis());
  }
  
  Future<void> loadColis() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value!;
      
      // Filtrer selon le rôle
      if (user.role == 'commercial') {
        colisList.value = await _colisService.getColisByCommercial(user.id);
      } else if (user.role == 'agent') {
        colisList.value = await _colisService.getColisByAgence(user.agenceId!);
      } else {
        colisList.value = await _colisService.getAllColis();
      }
      
      // Appliquer les filtres
      if (filterStatut.value != 'tous') {
        colisList.value = colisList.where((c) => c.statut == filterStatut.value).toList();
      }
      
      if (searchQuery.value.isNotEmpty) {
        colisList.value = colisList.where((c) => 
          c.numeroSuivi.contains(searchQuery.value) ||
          c.expediteurNom.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          c.destinataireNom.toLowerCase().contains(searchQuery.value.toLowerCase())
        ).toList();
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les colis');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> createColis(ColisModel colis) async {
    try {
      await _colisService.createColis(colis);
      Get.snackbar('Succès', 'Colis créé avec succès');
      await loadColis();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer le colis');
    }
  }
  
  Future<void> updateStatut(String colisId, String newStatut, String? commentaire) async {
    try {
      final authController = Get.find<AuthController>();
      await _colisService.updateStatut(
        colisId, 
        newStatut, 
        authController.currentUser.value!.id,
        commentaire
      );
      Get.snackbar('Succès', 'Statut mis à jour');
      await loadColis();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de mettre à jour le statut');
    }
  }
}

// LivraisonController - Gestion des livraisons
class LivraisonController extends GetxController {
  final LivraisonService _livraisonService = Get.find<LivraisonService>();
  
  final RxList<LivraisonModel> livraisonsList = <LivraisonModel>[].obs;
  final RxBool isLoading = false.obs;
  
  Future<void> createLivraison(LivraisonModel livraison) async {
    try {
      await _livraisonService.createLivraison(livraison);
      
      // Mettre à jour le statut du colis
      final colisController = Get.find<ColisController>();
      await colisController.updateStatut(
        livraison.colisId, 
        'enCoursLivraison',
        'Attribué au coursier'
      );
      
      Get.snackbar('Succès', 'Livraison créée et attribuée');
      await loadLivraisons();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de créer la livraison');
    }
  }
  
  Future<void> loadLivraisons() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value!;
      
      if (user.role == 'coursier') {
        livraisonsList.value = await _livraisonService.getLivraisonsByCoursier(user.id);
      } else {
        livraisonsList.value = await _livraisonService.getLivraisonsByAgence(user.agenceId!);
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les livraisons');
    } finally {
      isLoading.value = false;
    }
  }
}

// TransactionController - Gestion financière
class TransactionController extends GetxController {
  final TransactionService _transactionService = Get.find<TransactionService>();
  
  final RxList<TransactionModel> transactionsList = <TransactionModel>[].obs;
  final RxDouble soldeActuel = 0.0.obs;
  final RxBool isLoading = false.obs;
  
  Future<void> loadTransactions() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final agenceId = authController.currentUser.value!.agenceId!;
      
      transactionsList.value = await _transactionService.getTransactionsByAgence(agenceId);
      _calculateSolde();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les transactions');
    } finally {
      isLoading.value = false;
    }
  }
  
  void _calculateSolde() {
    double recettes = transactionsList
        .where((t) => t.type == 'recette')
        .fold(0, (sum, t) => sum + t.montant);
    
    double depenses = transactionsList
        .where((t) => t.type == 'depense')
        .fold(0, (sum, t) => sum + t.montant);
    
    soldeActuel.value = recettes - depenses;
  }
  
  Future<void> createTransaction(TransactionModel transaction) async {
    try {
      await _transactionService.createTransaction(transaction);
      Get.snackbar('Succès', 'Transaction enregistrée');
      await loadTransactions();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'enregistrer la transaction');
    }
  }
}
```

#### Routes et Navigation GetX

```dart
// app/routes/app_routes.dart
class AppRoutes {
  static const LOGIN = '/login';
  static const HOME = '/home';
  static const COLIS_LIST = '/colis';
  static const COLIS_CREATE = '/colis/create';
  static const COLIS_DETAIL = '/colis/:id';
  static const LIVRAISON_LIST = '/livraisons';
  static const LIVRAISON_CREATE = '/livraisons/create';
  static const CAISSE = '/caisse';
  static const RAPPORTS = '/rapports';
  static const SETTINGS = '/settings';
}

// app/routes/app_pages.dart
class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => HomeScreen(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.COLIS_LIST,
      page: () => ColisListScreen(),
      binding: ColisBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.COLIS_CREATE,
      page: () => ColisCreateScreen(),
      binding: ColisBinding(),
      middlewares: [AuthMiddleware(), RoleMiddleware(['commercial', 'agent'])],
    ),
    // ... autres routes
  ];
}

// Middleware d'authentification
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    if (!authController.isAuthenticated.value) {
      return const RouteSettings(name: AppRoutes.LOGIN);
    }
    return null;
  }
}

// Middleware de rôle
class RoleMiddleware extends GetMiddleware {
  final List<String> allowedRoles;
  
  RoleMiddleware(this.allowedRoles);
  
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    if (!authController.hasRole(allowedRoles)) {
      Get.snackbar('Accès refusé', 'Vous n\'avez pas les permissions nécessaires');
      return const RouteSettings(name: AppRoutes.HOME);
    }
    return null;
  }
}
```

#### Bindings (Dependency Injection)

```dart
// app/bindings/initial_binding.dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put(FirebaseService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(ColisService(), permanent: true);
    Get.put(LivraisonService(), permanent: true);
    Get.put(TransactionService(), permanent: true);
    
    // Controllers
    Get.put(AuthController(), permanent: true);
  }
}

// app/bindings/colis_binding.dart
class ColisBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ColisController());
  }
}

// app/bindings/livraison_binding.dart
class LivraisonBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LivraisonController());
  }
}
```


### 3. Modèles de Données

#### Modèles Flutter (Dart)

```dart
// UserModel
class UserModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String role; // admin, gestionnaire, commercial, coursier, agent
  final String? agenceId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.role,
    this.agenceId,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    email: json['email'],
    nom: json['nom'],
    prenom: json['prenom'],
    telephone: json['telephone'],
    role: json['role'],
    agenceId: json['agenceId'],
    isActive: json['isActive'],
    createdAt: DateTime.parse(json['createdAt']),
    lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nom': nom,
    'prenom': prenom,
    'telephone': telephone,
    'role': role,
    'agenceId': agenceId,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
  };

  String get nomComplet => '$prenom $nom';
}

// ColisModel
class ColisModel {
  final String id;
  final String numeroSuivi;
  final String expediteurNom;
  final String expediteurTelephone;
  final String expediteurAdresse;
  final String destinataireNom;
  final String destinataireTelephone;
  final String destinataireAdresse;
  final String destinataireVille;
  final String? destinataireQuartier;
  final String contenu;
  final double poids;
  final String? dimensions;
  final double montantTarif;
  final bool isPaye;
  final DateTime? datePaiement;
  final String modeLivraison; // domicile, bureauCorex, agenceTransport
  final String? agenceTransportId;
  final String? agenceTransportNom;
  final double? tarifAgenceTransport;
  final String statut; // collecte, enregistre, deposeAgence, enTransit, arriveDestination, enCoursLivraison, livre, retire, retourne
  final String agenceCorexId;
  final String commercialId;
  final String? coursierId;
  final DateTime dateCollecte;
  final DateTime? dateEnregistrement;
  final DateTime? dateLivraison;
  final List<HistoriqueStatut> historique;
  final String? commentaire;

  ColisModel({
    required this.id,
    required this.numeroSuivi,
    required this.expediteurNom,
    required this.expediteurTelephone,
    required this.expediteurAdresse,
    required this.destinataireNom,
    required this.destinataireTelephone,
    required this.destinataireAdresse,
    required this.destinataireVille,
    this.destinataireQuartier,
    required this.contenu,
    required this.poids,
    this.dimensions,
    required this.montantTarif,
    required this.isPaye,
    this.datePaiement,
    required this.modeLivraison,
    this.agenceTransportId,
    this.agenceTransportNom,
    this.tarifAgenceTransport,
    required this.statut,
    required this.agenceCorexId,
    required this.commercialId,
    this.coursierId,
    required this.dateCollecte,
    this.dateEnregistrement,
    this.dateLivraison,
    required this.historique,
    this.commentaire,
  });

  factory ColisModel.fromJson(Map<String, dynamic> json) => ColisModel(
    id: json['id'],
    numeroSuivi: json['numeroSuivi'],
    expediteurNom: json['expediteurNom'],
    expediteurTelephone: json['expediteurTelephone'],
    expediteurAdresse: json['expediteurAdresse'],
    destinataireNom: json['destinataireNom'],
    destinataireTelephone: json['destinataireTelephone'],
    destinataireAdresse: json['destinataireAdresse'],
    destinataireVille: json['destinataireVille'],
    destinataireQuartier: json['destinataireQuartier'],
    contenu: json['contenu'],
    poids: json['poids'].toDouble(),
    dimensions: json['dimensions'],
    montantTarif: json['montantTarif'].toDouble(),
    isPaye: json['isPaye'],
    datePaiement: json['datePaiement'] != null ? DateTime.parse(json['datePaiement']) : null,
    modeLivraison: json['modeLivraison'],
    agenceTransportId: json['agenceTransportId'],
    agenceTransportNom: json['agenceTransportNom'],
    tarifAgenceTransport: json['tarifAgenceTransport']?.toDouble(),
    statut: json['statut'],
    agenceCorexId: json['agenceCorexId'],
    commercialId: json['commercialId'],
    coursierId: json['coursierId'],
    dateCollecte: DateTime.parse(json['dateCollecte']),
    dateEnregistrement: json['dateEnregistrement'] != null ? DateTime.parse(json['dateEnregistrement']) : null,
    dateLivraison: json['dateLivraison'] != null ? DateTime.parse(json['dateLivraison']) : null,
    historique: (json['historique'] as List).map((h) => HistoriqueStatut.fromJson(h)).toList(),
    commentaire: json['commentaire'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'numeroSuivi': numeroSuivi,
    'expediteurNom': expediteurNom,
    'expediteurTelephone': expediteurTelephone,
    'expediteurAdresse': expediteurAdresse,
    'destinataireNom': destinataireNom,
    'destinataireTelephone': destinataireTelephone,
    'destinataireAdresse': destinataireAdresse,
    'destinataireVille': destinataireVille,
    'destinataireQuartier': destinataireQuartier,
    'contenu': contenu,
    'poids': poids,
    'dimensions': dimensions,
    'montantTarif': montantTarif,
    'isPaye': isPaye,
    'datePaiement': datePaiement?.toIso8601String(),
    'modeLivraison': modeLivraison,
    'agenceTransportId': agenceTransportId,
    'agenceTransportNom': agenceTransportNom,
    'tarifAgenceTransport': tarifAgenceTransport,
    'statut': statut,
    'agenceCorexId': agenceCorexId,
    'commercialId': commercialId,
    'coursierId': coursierId,
    'dateCollecte': dateCollecte.toIso8601String(),
    'dateEnregistrement': dateEnregistrement?.toIso8601String(),
    'dateLivraison': dateLivraison?.toIso8601String(),
    'historique': historique.map((h) => h.toJson()).toList(),
    'commentaire': commentaire,
  };
}

// HistoriqueStatut
class HistoriqueStatut {
  final String statut;
  final DateTime date;
  final String userId;
  final String? commentaire;

  HistoriqueStatut({
    required this.statut,
    required this.date,
    required this.userId,
    this.commentaire,
  });

  factory HistoriqueStatut.fromJson(Map<String, dynamic> json) => HistoriqueStatut(
    statut: json['statut'],
    date: DateTime.parse(json['date']),
    userId: json['userId'],
    commentaire: json['commentaire'],
  );

  Map<String, dynamic> toJson() => {
    'statut': statut,
    'date': date.toIso8601String(),
    'userId': userId,
    'commentaire': commentaire,
  };
}

// TransactionModel
class TransactionModel {
  final String id;
  final String agenceId;
  final String type; // recette, depense
  final double montant;
  final DateTime date;
  final String? categorieRecette; // expedition, livraison, retour, courses, stockage, autre
  final String? categorieDepense; // transport, salaires, loyer, carburant, internet, electricite, autre
  final String description;
  final String? reference;
  final String userId;
  final String? justificatifUrl;

  TransactionModel({
    required this.id,
    required this.agenceId,
    required this.type,
    required this.montant,
    required this.date,
    this.categorieRecette,
    this.categorieDepense,
    required this.description,
    this.reference,
    required this.userId,
    this.justificatifUrl,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    id: json['id'],
    agenceId: json['agenceId'],
    type: json['type'],
    montant: json['montant'].toDouble(),
    date: DateTime.parse(json['date']),
    categorieRecette: json['categorieRecette'],
    categorieDepense: json['categorieDepense'],
    description: json['description'],
    reference: json['reference'],
    userId: json['userId'],
    justificatifUrl: json['justificatifUrl'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'agenceId': agenceId,
    'type': type,
    'montant': montant,
    'date': date.toIso8601String(),
    'categorieRecette': categorieRecette,
    'categorieDepense': categorieDepense,
    'description': description,
    'reference': reference,
    'userId': userId,
    'justificatifUrl': justificatifUrl,
  };
}
```


### 4. Services Firebase

#### FirebaseService (Base)

```dart
class FirebaseService {
  static FirebaseDatabase get database => FirebaseDatabase.instance;
  
  static DatabaseReference ref(String path) {
    return database.ref(path);
  }
  
  static Future<void> enablePersistence() async {
    await database.setPersistenceEnabled(true);
    await database.setPersistenceCacheSizeBytes(10000000); // 10MB
  }
}

#### AuthService

```dart
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Récupérer les données utilisateur depuis Realtime Database
      final snapshot = await FirebaseService.ref('users/${credential.user!.uid}').get();
      
      if (!snapshot.exists) {
        throw Exception('Utilisateur non trouvé dans la base de données');
      }
      
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final user = UserModel.fromJson(userData);
      
      if (!user.isActive) {
        await _auth.signOut();
        throw Exception('Compte désactivé. Contactez l\'administrateur');
      }
      
      // Mettre à jour lastLogin
      await FirebaseService.ref('users/${user.id}').update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
      
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Aucun utilisateur trouvé avec cet email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Mot de passe incorrect');
      } else {
        throw Exception('Erreur de connexion: ${e.message}');
      }
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String role,
    String? agenceId,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        role: role,
        agenceId: agenceId,
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      await FirebaseService.ref('users/${user.id}').set(user.toJson());
      
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Cet email est déjà utilisé');
      } else if (e.code == 'weak-password') {
        throw Exception('Le mot de passe est trop faible');
      } else {
        throw Exception('Erreur de création: ${e.message}');
      }
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Erreur: ${e.message}');
    }
  }
}
```

#### ColisService

```dart
class ColisService extends GetxService {
  Future<String> generateNumeroSuivi() async {
    final year = DateTime.now().year;
    final counterRef = FirebaseService.ref('counters/colis_$year');
    
    final snapshot = await counterRef.get();
    int counter = snapshot.exists ? snapshot.value as int : 0;
    counter++;
    
    await counterRef.set(counter);
    
    return 'COL-$year-${counter.toString().padLeft(6, '0')}';
  }
  
  Future<void> createColis(ColisModel colis) async {
    final colisRef = FirebaseService.ref('colis/${colis.id}');
    await colisRef.set(colis.toJson());
  }
  
  Future<List<ColisModel>> getAllColis() async {
    final snapshot = await FirebaseService.ref('colis').get();
    
    if (!snapshot.exists) return [];
    
    final colisMap = Map<String, dynamic>.from(snapshot.value as Map);
    return colisMap.values
        .map((data) => ColisModel.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }
  
  Future<List<ColisModel>> getColisByAgence(String agenceId) async {
    final snapshot = await FirebaseService.ref('colis')
        .orderByChild('agenceCorexId')
        .equalTo(agenceId)
        .get();
    
    if (!snapshot.exists) return [];
    
    final colisMap = Map<String, dynamic>.from(snapshot.value as Map);
    return colisMap.values
        .map((data) => ColisModel.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }
  
  Future<List<ColisModel>> getColisByCommercial(String commercialId) async {
    final snapshot = await FirebaseService.ref('colis')
        .orderByChild('commercialId')
        .equalTo(commercialId)
        .get();
    
    if (!snapshot.exists) return [];
    
    final colisMap = Map<String, dynamic>.from(snapshot.value as Map);
    return colisMap.values
        .map((data) => ColisModel.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }
  
  Future<ColisModel?> searchColisByNumero(String numeroSuivi) async {
    final snapshot = await FirebaseService.ref('colis')
        .orderByChild('numeroSuivi')
        .equalTo(numeroSuivi)
        .get();
    
    if (!snapshot.exists) return null;
    
    final colisMap = Map<String, dynamic>.from(snapshot.value as Map);
    final firstColis = colisMap.values.first;
    return ColisModel.fromJson(Map<String, dynamic>.from(firstColis));
  }
  
  Future<void> updateStatut(
    String colisId,
    String newStatut,
    String userId,
    String? commentaire,
  ) async {
    final colisRef = FirebaseService.ref('colis/$colisId');
    final snapshot = await colisRef.get();
    
    if (!snapshot.exists) {
      throw Exception('Colis non trouvé');
    }
    
    final colis = ColisModel.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    
    // Ajouter à l'historique
    final historique = List<HistoriqueStatut>.from(colis.historique);
    historique.add(HistoriqueStatut(
      statut: newStatut,
      date: DateTime.now(),
      userId: userId,
      commentaire: commentaire,
    ));
    
    // Mettre à jour
    await colisRef.update({
      'statut': newStatut,
      'historique': historique.map((h) => h.toJson()).toList(),
      if (newStatut == 'enregistre') 'dateEnregistrement': DateTime.now().toIso8601String(),
      if (newStatut == 'livre' || newStatut == 'retire') 'dateLivraison': DateTime.now().toIso8601String(),
    });
  }
  
  Stream<List<ColisModel>> watchColisByAgence(String agenceId) {
    return FirebaseService.ref('colis')
        .orderByChild('agenceCorexId')
        .equalTo(agenceId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) return <ColisModel>[];
      
      final colisMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      return colisMap.values
          .map((data) => ColisModel.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    });
  }
}
```

#### TransactionService

```dart
class TransactionService extends GetxService {
  Future<void> createTransaction(TransactionModel transaction) async {
    final transactionRef = FirebaseService.ref('transactions/${transaction.id}');
    await transactionRef.set(transaction.toJson());
  }
  
  Future<List<TransactionModel>> getTransactionsByAgence(String agenceId) async {
    final snapshot = await FirebaseService.ref('transactions')
        .orderByChild('agenceId')
        .equalTo(agenceId)
        .get();
    
    if (!snapshot.exists) return [];
    
    final transactionsMap = Map<String, dynamic>.from(snapshot.value as Map);
    return transactionsMap.values
        .map((data) => TransactionModel.fromJson(Map<String, dynamic>.from(data)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
  
  Future<Map<String, double>> getBilanAgence(String agenceId, DateTime debut, DateTime fin) async {
    final transactions = await getTransactionsByAgence(agenceId);
    
    final transactionsPeriode = transactions.where((t) =>
      t.date.isAfter(debut) && t.date.isBefore(fin)
    ).toList();
    
    double recettes = transactionsPeriode
        .where((t) => t.type == 'recette')
        .fold(0, (sum, t) => sum + t.montant);
    
    double depenses = transactionsPeriode
        .where((t) => t.type == 'depense')
        .fold(0, (sum, t) => sum + t.montant);
    
    return {
      'recettes': recettes,
      'depenses': depenses,
      'solde': recettes - depenses,
    };
  }
}
```


### 5. Structure de la Base de Données Firebase

#### Collections Principales

```json
{
  "users": {
    "userId": {
      "id": "string",
      "email": "string",
      "nom": "string",
      "prenom": "string",
      "telephone": "string",
      "role": "admin|gestionnaire|commercial|coursier|agent",
      "agenceId": "string|null",
      "isActive": "boolean",
      "createdAt": "ISO8601",
      "lastLogin": "ISO8601|null"
    }
  },
  
  "agences": {
    "agenceId": {
      "id": "string",
      "nom": "string",
      "adresse": "string",
      "ville": "string",
      "telephone": "string",
      "email": "string",
      "isActive": "boolean",
      "createdAt": "ISO8601"
    }
  },
  
  "colis": {
    "colisId": {
      "id": "string",
      "numeroSuivi": "COL-2025-XXXXXX",
      "expediteurNom": "string",
      "expediteurTelephone": "string",
      "expediteurAdresse": "string",
      "destinataireNom": "string",
      "destinataireTelephone": "string",
      "destinataireAdresse": "string",
      "destinataireVille": "string",
      "destinataireQuartier": "string|null",
      "contenu": "string",
      "poids": "number",
      "dimensions": "string|null",
      "montantTarif": "number",
      "isPaye": "boolean",
      "datePaiement": "ISO8601|null",
      "modeLivraison": "domicile|bureauCorex|agenceTransport",
      "agenceTransportId": "string|null",
      "agenceTransportNom": "string|null",
      "tarifAgenceTransport": "number|null",
      "statut": "collecte|enregistre|deposeAgence|enTransit|arriveDestination|enCoursLivraison|livre|retire|retourne",
      "agenceCorexId": "string",
      "commercialId": "string",
      "coursierId": "string|null",
      "dateCollecte": "ISO8601",
      "dateEnregistrement": "ISO8601|null",
      "dateLivraison": "ISO8601|null",
      "historique": [
        {
          "statut": "string",
          "date": "ISO8601",
          "userId": "string",
          "commentaire": "string|null"
        }
      ],
      "commentaire": "string|null"
    }
  },
  
  "livraisons": {
    "livraisonId": {
      "id": "string",
      "colisId": "string",
      "coursierId": "string",
      "agenceId": "string",
      "zone": "string",
      "dateCreation": "ISO8601",
      "heureDepart": "ISO8601|null",
      "heureRetour": "ISO8601|null",
      "statut": "enAttente|enCours|livree|echec",
      "motifEchec": "string|null",
      "commentaire": "string|null"
    }
  },
  
  "transactions": {
    "transactionId": {
      "id": "string",
      "agenceId": "string",
      "type": "recette|depense",
      "montant": "number",
      "date": "ISO8601",
      "categorieRecette": "expedition|livraison|retour|courses|stockage|autre|null",
      "categorieDepense": "transport|salaires|loyer|carburant|internet|electricite|autre|null",
      "description": "string",
      "reference": "string|null",
      "userId": "string",
      "justificatifUrl": "string|null"
    }
  },
  
  "zones": {
    "zoneId": {
      "id": "string",
      "nom": "string",
      "ville": "string",
      "quartiers": ["string"],
      "agenceId": "string",
      "tarifLivraison": "number"
    }
  },
  
  "agencesTransport": {
    "agenceTransportId": {
      "id": "string",
      "nom": "string",
      "contact": "string",
      "telephone": "string",
      "villesDesservies": ["string"],
      "tarifs": {
        "ville1": "number",
        "ville2": "number"
      },
      "isActive": "boolean",
      "createdAt": "ISO8601"
    }
  },
  
  "counters": {
    "colis_2025": "number",
    "colis_2026": "number"
  }
}
```

#### Règles de Sécurité Firebase

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "$uid === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'",
        ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin'"
      }
    },
    "agences": {
      ".read": "auth != null",
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin'"
    },
    "colis": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["agenceCorexId", "commercialId", "coursierId", "numeroSuivi", "statut"]
    },
    "livraisons": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["coursierId", "agenceId", "statut"]
    },
    "transactions": {
      ".read": "auth != null",
      ".write": "auth != null",
      ".indexOn": ["agenceId", "date", "type"]
    },
    "zones": {
      ".read": "auth != null",
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin' || root.child('users').child(auth.uid).child('role').val() === 'gestionnaire'"
    },
    "agencesTransport": {
      ".read": "auth != null",
      ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin' || root.child('users').child(auth.uid).child('role').val() === 'gestionnaire'"
    },
    "counters": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### 6. Génération de Documents PDF

#### Service PDF

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService extends GetxService {
  Future<void> generateRecuCollecte(ColisModel colis, UserModel commercial) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Container(
                color: PdfColor.fromHex('#2E7D32'),
                padding: const pw.Edgevision
pour superons, mobile ératiur opsktop po: De** cessibilitée
- ✅ **AcebasFirt règles tification e* : Authenrité*- ✅ **Sécue
uitivace int Interfté** :**Simplici
- ✅ es lignonne hor : Foncti**bilité ✅ **Fia
-idenative raption pplicaance** : Aform*Per
- ✅ *ateursr les Utiliss

### Pou donnéematique deson autochronisati: Synel** ps réTem**ebase
- ✅ ue avec Firtomatiq* : Auhors ligne* **Mode intenir
- ✅eur à mas de serv, paackend géré : Brebase**Fi✅ **formant
-  et perimpleagement s : State mantX**✅ **Geile
- sktop et mobés entre deilises réutes et servicdèlMo* : gé*rtapa
- ✅ **Code entemoppour le Dévelre

### Pl'Architectuages de vant
## A
rmetefoe plapour chaqugure` ire confirfteut`fl Exécuter écurité
5.les de srègs er leConfigurse
4. ime Databalt Activer Rea
3./Password)mailion (E Authenticat
2. Activerbaset Fire le projeCréer
1. ebase
uration Fir
### Config`
``apk
pp-release.-apk/autterputs/flld/app/out:
# buidanse  trouv'APK se
# Lelease
ndle --r appbuter builde)
flutay Storr Plle (pouApp Bund# Build elease

--rild apk flutter bux_mobile
K
cd cored APash
# Buil

```bdroid)le (Anbion Motilica
### App
```
sktop.exe/corex_deer/Releasewindows/runnild/
# butrouve dans: se utable

# L'exéc-releaseld windows -flutter buiktop
cd corex_des
'applicationde lsh
# Build ```ba

ndows)Desktop (Wilication 
### Appnt
meoie## Dépl
```

;
  });
}neWidget) findsO bord'),leau detext('Tabct(find.peex
    accueil'écran d'vers lgation naviier la  Vérif    
    //ttle();
umpAndSer.pte   await tester'));
 econnxt('Se c(find.tet tester.tap awaixion
   on de conner le boutr suique 
    // Cl');
   23 'password1).last,e(TextField(find.byTypenterTextster. await teom');
   t@corex.crst, 'tesxtField).fiype(Teext(find.byTer.enterTt testaials
    awtir les credenisi // Sa 
   );
   ndsOneWidget'), fionnexionext('C.txpect(findché
    est affinnexion e coe l'écran dequier if  // Vér
    xApp());
  nst Coreget(coster.pumpWidwait te a
   ync {) asster testerWidgetTet', (flow tess('Login Widget) {
  testn(t
void mai``daron

`d'IntégratiTests ``

#### );
}
`);
  });
    }se.value, falLoadingntroller.isexpect(co 1);
      ength,List.liser.colrollont(cpect  
      ex
    lis();oller.loadCocontr    await     
     ]);
  
   .. */),* .el(/Mod      Colis
   [ =>(_) asyncnAnswer(is()).thelColgetAlce.Servi(mock    when
   {t', () asyncate colisLis populolis should test('loadC
       
    });
er();ntrollCo= Colistroller ;
      conkService)e>(moc<ColisServic Get.put    
 ervice(); MockColisSice =ervockS
      metUp(() {
    
    srvice;kSeice mocColisServ late Mockller;
   ler controlisControl Cote
    lats', () {ntroller TesolisCoroup('C
  gd main() {rt
voi)

```daicesrvllers et Se (Controtairess Uni### Test

#ie de Testsratég St0.```

### 1);
  }
}
   }      }
  activé');
igneors lde he', 'Mognors lisnackbar('H     Get.e {
    } else');
      en lign'Vous êtesn', io('ConnexGet.snackbar      ue) {
  .val(isOnlineif 
      
      lt.none;ectivityResuConn result != .value =  isOnline
    ult) {essten((rChanged.litivity.onConnectivity()nnec) {
    Conectivity(listenToCon  
  void _ }
.none;
 ivityResultonnect!= C result value =isOnline.();
    nectivity().checkConctivityawait Connet = sulnal re
    fisync {ctivity() anneCoitd> _in  Future<voi
);
  }
  nnectivity(listenToCo   _
 ivity();ct _initConne
   nInit();    super.onit() {
d onI
  voi@overridebs;
  
  ue.o= tr isOnline inal RxBool
  fxService {tends Getce exctivityServinneclass Coart
```d

uésea l'état r détecters` pourectivity_plue `connon dUtilisati : ion**exn de conn **Détectionnexion
3.tour de conisées au rero synchgne sontors liifications h* : Les modutomatique*onisation achr. **Synche
2n cant mises etiquememaes sont autos donné Le* : locale*cersistan
1. **Pevec :
s ligne a mode hortiquement lemaère auto gbaseealtime Data
Firebase Rors Ligne
ode H M 9.
```

###),
  );
}),
    
      ,, width: 2)imaryGreencolor: prBorderSide(: const   borderSide(8),
      lars.circuerRadius: BordRadiu    border(
    ordernputBineIorder: OutldB    focuse
  ,
      ),circular(8)us.Radidius: BorderorderRa  b
      nputBorder(OutlineIer: rd   bo(
   nThemetDecoratioe: InputionThemcora    inputDe,
    ),
    )),
         
 ircular(8),ius.c BorderRads:iu  borderRadr(
        angleBordeedRectpe: Round        sha 12),
ical:, vertntal: 24ric(horizosets.symmetgeIn const Eddding:      pawhite,
  Color: ground        foremaryGreen,
 prior:oundColkgrbac(
        Fromton.styleedButElevat    style: (
  ThemeDataonatedButt ElevButtonTheme:levated
    e: 0,
    ),   elevation
   te,r: whioloroundC  foreg    ryGreen,
lor: primakgroundCo    bac
  e(BarThemonst ApprTheme: cappBa),
    ,
    d: lightGreykgroun    bacite,
   whrface:     suarkBlack,
 secondary: d  
    en,ryGre primamary:pright(
      me.lilorScherScheme: Coloite,
    coor: whoundColfoldBackgrcaf  seen,
  : primaryGrimaryColor  prmeData(
  eme => Theget thData c Theme
  
  statiF5F5F5);0xFFr( = ColohtGreyt Color lig static cons);
 xFFFFFFFFolor(0ite = Cnst Color whcoc 1);
  statior(0xFF21212= Colack olor darkBlc const C2);
  stati2E7D3(0xFFn = Color primaryGreeconst Color{
  static exTheme 
class Cor
```dartème COREX
r

#### ThteusaUtili Interface . Thème et
### 8```
}
}
     }
';
 sebare? 'Erreur Fissage ?.meturn error    refault:
    
      deéseau';nexion rur de conrn 'Erre retud':
       t-faileueseqwork-re 'net
      casponible';ent indisiremce temporaturn 'Servi        reble':
se 'unavaila     ca
 écessaires'; nionsrmiss les pez pasus n\'aveeturn 'Vo      r
  enied':ission-dse 'perm ca) {
     ror.code  switch (er  r) {
rroion exceptirebaseEge(FsaErrorMestFirebaseng _geic Stri stat
  
 
    }
  };te,
      )hi Colors.worText:ol     c   ed,
r: Colors.roundColo  backgr    .BOTTOM,
  nackPositiontion: SackPosi sne',
       duitro'est ps\tendue reur inat   'Une err',
     reu
        'Ernackbar( Get.s{
     } else   );
    e,
    lors.whitext: CoorT    cols.red,
    orolor: ColackgroundC
        bon.BOTTOM,ositickPsition: Sna  snackPo   ),
   ssage(errorMeErrorse _getFirebae',
       Firebas  'Erreur 
      ckbar(   Get.sna    {
ception)FirebaseEx is f (errorse i
    } el   );ds: 3),
   ion(secon const Duratn:     duratio.white,
   Text: Colors     colored,
   : Colors.rndColorkgrou  bacTOM,
      OTon.BitiackPosition: SnsnackPos,
        message    error.
    Erreur',(
        'Get.snackbar    tion) {
  xcepxECore(error is 
    if  error) {namicdye(dlvoid hanc atir {
  strorHandleEr
class 

```darts Erreursalisée deCentrn Gestio

#### 
```}
');ION_ERROR, 'VALIDATer(message) : supssageString menException(atio {
  ValidxceptionexEextends Coreption idationExcass Val}

clND');
T_FOUmessage, 'NOper(su : ge)messang on(StridExceptiataNotFounon {
  DptiexExce extends CordExceptiontFounaNoss Dat
}

claENIED');_D'PERMISSION(message, ) : superg messageon(StrinceptiPermissionEx {
  Exceptiontends Corextion exepissionExcPermclass );
}

AUTH_ERROR'e, 'ssagper(me) : su messageing(StrxceptionicationEAuthenton {
  eptixExcextends Coreeption nticationExclass Authege;
}

cmessang() => ing toStri
  Str@overridede);
  
  co, this..messagetion(thisxExcep  
  Core code;
tring  final Sage;
ssString me{
  final ption ements Excetion implCorexExceps rt
clas`da``eption

asses d'Exc
#### Cles Erreurs
Gestion d## 7. 
#
```
 }
}ar}';
 }/${date.ye, '0')t(2adLefoString().ph.tontte.m'0')}/${da2, ).padLeft(toString(day.ate.rn '${d   retudate) {
 DateTime formatDate(ring _
  
  St
  }pdf.save());) async => rmat formatPdfPageFo: (Pdf(onLayoutnting.layout  await Pri  ;
    
   )
   ),   },
    
              );
           ],
  : 10)),e(fontSizeylextStw.T p: consttyle', slephone}cial.tee: ${commerphonéléext('T        pw.T   : 10)),
   ontSizeextStyle(fpw.T const t}', style:plel.nomCommmercia{coal: $t('Commerci.Texpw             r(),
 vide  pw.Di          age
  de ped    // Pi             
           
 .Spacer(),  pw    
                      ),
             ),
                s.red,
 orPdfCol) : D32'ex('#2E7mHdfColor.froe ? P colis.isPay  color:                old,
ontWeight.b.FWeight: pw       font      16,
     Size:        font
           .TextStyle(   style: pw         
    ', : 'NON PAYÉPAYÉ'sPaye ? '   colis.i          .Text(
             pw  
                 10),
ight:ox(he pw.SizedB       
            
                ),,
                )],
               
            ),            ,
     ight.bold)ontWe pw.Ft: fontWeighSize: 18,(fonttStyle: pw.Tex       style        
       FA',ixed(0)} FC.toStringAsFrifis.montantTa  '${col               xt(
         pw.Te              .bold)),
  ntWeightFopw.ght: Weityle(fonttSexstyle: pw.T', ANT TOTAL'MONTpw.Text(                    : [
renild ch                 en,
.spaceBetwesAlignmentpw.MainAximent: sAligninAxi     ma            .Row(
 : pwldchi               ,
 '#F5F5F5')mHex(Color.fro: Pdfor   col           (10),
  llgeInsets.aEdst pw.: conng paddi               
Container(        pw.      if
    // Tar       
               t: 20),
  zedBox(heigh       pw.Si     
            
    mensions}'),is.di: ${colnssioent('Dim.Texnull) pwns != .dimensiocolis  if (        ,
    ids} kg')s.pos: ${coli('Poid pw.Text             
'),nu}colis.conte'Contenu: ${.Text(    pw         d)),
 ght.bol: pw.FontWei(fontWeightxtStyle pw.Te style:U COLIS',DÉTAILS D('   pw.Text         colis
  du // Détails                    
        : 20),
 (heightSizedBox   pw.          
                     ),
 
                ),
       ],                 lle}'),
 tinataireVi ${colis.dese:('Vill    pw.Text              ,
  reAdresse}')inatai{colis.destesse: $dr.Text('A     pw         }'),
      ireTelephonenata.destiis ${coléléphone:pw.Text('T                    ),
aireNom}'inatolis.dest ${ct('Nom:pw.Tex                   ,
 t.bold))tWeighht: pw.FoneigntWxtStyle(fo pw.TeRE', style:'DESTINATAIText(     pw.       [
         children:           rt,
       taignment.ssAxisAlw.Cros: pmentAxisAlignross      c            umn(
w.Cold: pchil          ),
               
       ors.grey),dfColl(color: Pr.al pw.Borderder:        bo         (
 tionw.BoxDecoran: p   decoratio          ),
   .all(10nsetsdgeIst pw.Eg: condin         pad
       ainer(w.Cont    p       nataire
   ti    // Des         
              
 ght: 10),(heiSizedBox        pw.          
            ),
        ),
                
       ],         ,
      ')se}esediteurAdr ${colis.exp'Adresse:ext(w.T p              
     ),e}'urTelephoniteis.expedphone: ${colélét('Tpw.Tex            
        '),diteurNom}is.expe'Nom: ${colt(  pw.Tex            ,
      d))bolntWeight.ight: pw.FotWeextStyle(fone: pw.TEUR', stylDIT('EXPÉ   pw.Text               : [
   children       
          t.start,isAlignmenAxw.Cross pgnment:isAlisAx    cros        (
      mn: pw.Coluchild        ),
              
          .grey),fColors: Pder.all(colorr: pw.Bord    borde            ation(
  ecoron: pw.BoxD   decorati          
   ,ll(10)ts.a.EdgeInseonst pwding: c         pad     ner(
  Contai      pw.
        urte/ Expédi    /        
           20),
     ht: zedBox(heig pw.Si       
                  )}'),
  llecteolis.dateCo(cformatDateollecte: ${_'Date de c pw.Text(       ),
                    .bold),
eighttWt: pw.FonfontWeighze: 18, (fontSiStyleTextw.e: p       styl  
       uivi}',meroS${colis.nue suivi: ro d     'Numé   
           pw.Text(          olis
 tions du cma // Infor             
           ,
   t: 20)edBox(heigh    pw.Siz            
                  ),
       
         ),         ],
                      ),
          ),
                        
   ors.white,olor: PdfCol        c      
          : 16,    fontSize                    xtStyle(
st pw.Te  style: con                   llecte',
 Reçu de Co   '               
    .Text(  pw              ),
    x(height: 5Bo   pw.Sized                 ),
              
           ),       
          ite,.whPdfColorscolor:                        
 .bold,ontWeightght: pw.F fontWei                      : 24,
 ontSize f                      extStyle(
 style: pw.T              
        RL',   'COREX SA               xt(
       pw.Te                [
   children:         t,
        .starentsAxisAlignment: pw.CrosxisAlignm   crossA         
       pw.Column(ld:chi           
     ts.all(20),Inse