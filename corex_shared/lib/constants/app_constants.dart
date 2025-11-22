class AppConstants {
  // Couleurs COREX
  static const int primaryGreenValue = 0xFF2E7D32;
  static const int darkBlackValue = 0xFF212121;
  static const int whiteValue = 0xFFFFFFFF;
  static const int lightGreyValue = 0xFFF5F5F5;

  // Rôles utilisateurs
  static const String roleAdmin = 'admin';
  static const String roleGestionnaire = 'gestionnaire';
  static const String roleCommercial = 'commercial';
  static const String roleCoursier = 'coursier';
  static const String roleAgent = 'agent';

  static const List<String> allRoles = [
    roleAdmin,
    roleGestionnaire,
    roleCommercial,
    roleCoursier,
    roleAgent,
  ];

  // Modes de livraison
  static const String modeDomicile = 'domicile';
  static const String modeBureauCorex = 'bureauCorex';
  static const String modeAgenceTransport = 'agenceTransport';

  // Types de transaction
  static const String typeRecette = 'recette';
  static const String typeDepense = 'depense';

  // Catégories de recettes
  static const String categorieExpedition = 'expedition';
  static const String categorieLivraison = 'livraison';
  static const String categorieRetour = 'retour';
  static const String categorieCourses = 'courses';
  static const String categorieStockage = 'stockage';
  static const String categorieAutre = 'autre';

  // Catégories de dépenses
  static const String categorieTransport = 'transport';
  static const String categorieSalaires = 'salaires';
  static const String categorieLoyer = 'loyer';
  static const String categorieCarburant = 'carburant';
  static const String categorieInternet = 'internet';
  static const String categorieElectricite = 'electricite';

  // Timeout
  static const int sessionTimeoutMinutes = 30;
}
