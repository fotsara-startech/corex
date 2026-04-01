import 'package:get/get.dart';
import 'dart:async';
import '../models/transaction_model.dart';
import '../services/colis_service.dart';
import '../services/transaction_service.dart';
import '../services/livraison_service.dart';
import '../services/user_service.dart';
import '../services/agence_service.dart';

class PdgDashboardController extends GetxController {
  // Services - Initialisation sécurisée
  ColisService? _colisService;
  TransactionService? _transactionService;
  LivraisonService? _livraisonService;
  UserService? _userService;
  AgenceService? _agenceService;

  final RxBool isLoading = false.obs;
  final RxString selectedPeriod = 'today'.obs; // today, week, month, year
  final RxString selectedAgence = 'toutes'.obs;

  // KPIs Financiers
  final RxDouble caTotal = 0.0.obs;
  final RxDouble caAujourdhui = 0.0.obs;
  final RxDouble caMois = 0.0.obs;
  final RxDouble caAnnee = 0.0.obs;
  final RxDouble margeNette = 0.0.obs;
  final RxDouble creances = 0.0.obs;
  final RxDouble commissionsTotales = 0.0.obs;
  final RxDouble croissanceCA = 0.0.obs;

  // KPIs Opérationnels
  final RxInt colisTotal = 0.obs;
  final RxInt colisAujourdhui = 0.obs;
  final RxInt colisMois = 0.obs;
  final RxInt livraisonsTotal = 0.obs;
  final RxInt livraisonsReussies = 0.obs;
  final RxDouble tauxLivraison = 0.0.obs;
  final RxDouble delaiMoyen = 0.0.obs;
  final RxInt retours = 0.obs;
  final RxDouble tauxRetours = 0.0.obs;

  // KPIs Croissance
  final RxInt nouveauxClients = 0.obs;
  final RxInt clientsActifs = 0.obs;
  final RxDouble croissanceVolume = 0.0.obs;
  final RxInt agencesActives = 0.obs;
  final RxInt zonesDesservies = 0.obs;
  // KPIs RH
  final RxInt utilisateursActifs = 0.obs;
  final RxInt coursiersActifs = 0.obs;
  final RxDouble productiviteMoyenne = 0.0.obs;

  // Données pour graphiques
  final RxList<Map<String, dynamic>> evolutionCA = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> evolutionVolume = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> repartitionStatuts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> performanceAgences = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topCoursiers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> motifsEchec = <Map<String, dynamic>>[].obs;

  // Alertes critiques
  final RxList<Map<String, dynamic>> alertesCritiques = <Map<String, dynamic>>[].obs;

  Timer? _autoRefreshTimer;

  @override
  void onInit() {
    super.onInit();

    // Attendre que les services soient disponibles avant d'initialiser
    _waitForServicesAndInitialize();

    // Recharger les données quand la période change
    ever(selectedPeriod, (_) => loadDashboardData());
    ever(selectedAgence, (_) => loadDashboardData());

    // Actualisation automatique toutes les 5 minutes
    _startAutoRefresh();
  }

  /// Attend que les services soient disponibles avant d'initialiser
  Future<void> _waitForServicesAndInitialize() async {
    int attempts = 0;
    const maxAttempts = 15;
    const delayBetweenAttempts = Duration(milliseconds: 800);

    while (attempts < maxAttempts) {
      attempts++;
      print('🔄 [PDG_DASHBOARD] Tentative $attempts/$maxAttempts d\'initialisation des services...');

      // Vérifier d'abord si les services sont enregistrés dans GetX
      print('   Vérification GetX:');
      print('   - ColisService: ${Get.isRegistered<ColisService>()}');
      print('   - TransactionService: ${Get.isRegistered<TransactionService>()}');
      print('   - LivraisonService: ${Get.isRegistered<LivraisonService>()}');
      print('   - UserService: ${Get.isRegistered<UserService>()}');
      print('   - AgenceService: ${Get.isRegistered<AgenceService>()}');

      _initializeServices();

      // Vérifier si tous les services essentiels sont disponibles
      if (_colisService != null && _transactionService != null && _livraisonService != null && _userService != null && _agenceService != null) {
        print('✅ [PDG_DASHBOARD] Tous les services sont disponibles, chargement des données...');

        // Délai supplémentaire pour s'assurer que tout est prêt
        await Future.delayed(const Duration(milliseconds: 500));

        // Charger les données
        loadDashboardData();
        return;
      }

      if (attempts < maxAttempts) {
        print('⚠️ [PDG_DASHBOARD] Services manquants, nouvelle tentative dans ${delayBetweenAttempts.inMilliseconds}ms...');
        await Future.delayed(delayBetweenAttempts);
      }
    }

    print('❌ [PDG_DASHBOARD] Impossible d\'initialiser tous les services après $maxAttempts tentatives');
    print('   - ColisService: ${_colisService != null ? "✅" : "❌"}');
    print('   - TransactionService: ${_transactionService != null ? "✅" : "❌"}');
    print('   - LivraisonService: ${_livraisonService != null ? "✅" : "❌"}');
    print('   - UserService: ${_userService != null ? "✅" : "❌"}');
    print('   - AgenceService: ${_agenceService != null ? "✅" : "❌"}');
  }

  @override
  void onClose() {
    _autoRefreshTimer?.cancel();
    super.onClose();
  }

  /// Initialise les services de manière sécurisée
  void _initializeServices() {
    try {
      if (Get.isRegistered<ColisService>()) {
        _colisService = Get.find<ColisService>();
      }
      if (Get.isRegistered<TransactionService>()) {
        _transactionService = Get.find<TransactionService>();
      }
      if (Get.isRegistered<LivraisonService>()) {
        _livraisonService = Get.find<LivraisonService>();
      }
      if (Get.isRegistered<UserService>()) {
        _userService = Get.find<UserService>();
      }
      if (Get.isRegistered<AgenceService>()) {
        _agenceService = Get.find<AgenceService>();
      }

      // Log détaillé du statut
      if (_colisService != null && _transactionService != null && _livraisonService != null && _userService != null && _agenceService != null) {
        print('✅ [PDG_DASHBOARD] Tous les services sont disponibles');
      } else {
        print('⚠️ [PDG_DASHBOARD] Services manquants:');
        if (_colisService == null) print('   - ColisService: ❌');
        if (_transactionService == null) print('   - TransactionService: ❌');
        if (_livraisonService == null) print('   - LivraisonService: ❌');
        if (_userService == null) print('   - UserService: ❌');
        if (_agenceService == null) print('   - AgenceService: ❌');
      }
    } catch (e) {
      print('⚠️ [PDG_DASHBOARD] Erreur initialisation services: $e');
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      if (!isLoading.value) {
        loadDashboardData();
      }
    });
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      print('🔄 [PDG_DASHBOARD] Chargement des données...');

      // Charger les données de base avec des valeurs par défaut
      await _loadBasicData();

      print('✅ [PDG_DASHBOARD] Données chargées avec succès');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] Erreur: $e');
      _setDefaultValues();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadBasicData() async {
    final period = _getPeriodDates();

    // Charger les données de manière sécurisée
    await Future.wait([
      _loadKPIsFinanciers(period['debut']!, period['fin']!),
      _loadKPIsOperationnels(period['debut']!, period['fin']!),
      _loadKPIsCroissance(period['debut']!, period['fin']!),
      _loadKPIsRH(),
      _loadGraphiquesData(period['debut']!, period['fin']!),
      _loadAlertesCritiques(),
    ]);
  }

  void _setDefaultValues() {
    // Valeurs à 0 en cas d'erreur (pas de données de démo)
    caTotal.value = 0.0;
    caAujourdhui.value = 0.0;
    caMois.value = 0.0;
    margeNette.value = 0.0;
    colisTotal.value = 0;
    colisAujourdhui.value = 0;
    tauxLivraison.value = 0.0;
    clientsActifs.value = 0;

    // Vider les graphiques
    evolutionCA.clear();
    evolutionVolume.clear();
    repartitionStatuts.clear();
    performanceAgences.clear();
    topCoursiers.clear();
  }

  List<Map<String, dynamic>> _generateDemoEvolutionData(String type) {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return {
        'date': date,
        'label': '${date.day}/${date.month}',
        type == 'CA' ? 'ca' : 'volume': type == 'CA' ? (50000 + (index * 10000)).toDouble() : (20 + (index * 5)),
      };
    });
  }

  List<Map<String, dynamic>> _generateDemoStatusData() {
    return [
      {'statut': 'livre', 'count': 45, 'pourcentage': 60.0},
      {'statut': 'enCours', 'count': 20, 'pourcentage': 26.7},
      {'statut': 'collecte', 'count': 10, 'pourcentage': 13.3},
    ];
  }

  List<Map<String, dynamic>> _generateDemoAgenceData() {
    return [
      {'agence': 'Agence Centre', 'ca': 150000.0, 'volume': 45},
      {'agence': 'Agence Nord', 'ca': 120000.0, 'volume': 38},
      {'agence': 'Agence Sud', 'ca': 95000.0, 'volume': 32},
    ];
  }

  List<Map<String, dynamic>> _generateDemoCoursierData() {
    return [
      {'nom': 'Coursier A', 'livraisons': 25, 'tauxReussite': 95.0},
      {'nom': 'Coursier B', 'livraisons': 22, 'tauxReussite': 92.0},
      {'nom': 'Coursier C', 'livraisons': 18, 'tauxReussite': 88.0},
    ];
  }

  Map<String, DateTime> _getPeriodDates() {
    final now = DateTime.now();
    DateTime debut, fin;

    switch (selectedPeriod.value) {
      case 'today':
        debut = DateTime(now.year, now.month, now.day);
        fin = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        debut = DateTime(weekStart.year, weekStart.month, weekStart.day);
        fin = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'month':
        debut = DateTime(now.year, now.month, 1);
        fin = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case 'year':
        debut = DateTime(now.year, 1, 1);
        fin = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      default:
        debut = DateTime(now.year, now.month, now.day);
        fin = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    return {'debut': debut, 'fin': fin};
  }

  Future<void> _loadKPIsFinanciers(DateTime debut, DateTime fin) async {
    try {
      if (_transactionService == null || _agenceService == null) {
        throw Exception('Services TransactionService ou AgenceService non initialisés');
      }

      print('🔄 [PDG_DASHBOARD] Chargement KPIs financiers...');

      // Récupérer les vraies données
      final transactions = await _getTransactionsByPeriod(debut, fin);
      final recettes = transactions.where((t) => t.type == 'recette').toList();
      final depenses = transactions.where((t) => t.type == 'depense').toList();

      caTotal.value = recettes.fold(0.0, (sum, t) => sum + t.montant);
      final totalDepenses = depenses.fold(0.0, (sum, t) => sum + t.montant);
      margeNette.value = caTotal.value - totalDepenses;

      // CA aujourd'hui
      final aujourdhui = DateTime.now();
      final debutJour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
      final finJour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day, 23, 59, 59);
      final transactionsJour = await _getTransactionsByPeriod(debutJour, finJour);
      caAujourdhui.value = transactionsJour.where((t) => t.type == 'recette').fold(0.0, (sum, t) => sum + t.montant);

      // CA mois
      final debutMois = DateTime(aujourdhui.year, aujourdhui.month, 1);
      final finMois = DateTime(aujourdhui.year, aujourdhui.month + 1, 0, 23, 59, 59);
      final transactionsMois = await _getTransactionsByPeriod(debutMois, finMois);
      caMois.value = transactionsMois.where((t) => t.type == 'recette').fold(0.0, (sum, t) => sum + t.montant);

      // CA année
      final debutAnnee = DateTime(aujourdhui.year, 1, 1);
      final finAnnee = DateTime(aujourdhui.year, 12, 31, 23, 59, 59);
      final transactionsAnnee = await _getTransactionsByPeriod(debutAnnee, finAnnee);
      caAnnee.value = transactionsAnnee.where((t) => t.type == 'recette').fold(0.0, (sum, t) => sum + t.montant);

      // Commissions COREX
      commissionsTotales.value = recettes.where((t) => t.categorieRecette?.contains('commission') == true).fold(0.0, (sum, t) => sum + t.montant);

      // Créances (colis non payés)
      if (_colisService != null) {
        final colisNonPayes = await _colisService!.getColisNonPayes();
        creances.value = colisNonPayes.fold(0.0, (sum, c) => sum + c.montantTarif);
      } else {
        creances.value = 0.0;
      }

      // Croissance CA (comparaison avec période précédente)
      await _calculateCroissanceCA(debut, fin);

      print('✅ [PDG_DASHBOARD] KPIs financiers chargés: CA Aujourd\'hui=${caAujourdhui.value}, CA Mois=${caMois.value}, CA Année=${caAnnee.value}');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR CRITIQUE KPIs financiers: $e');
      // Mettre à 0 au lieu de charger des données de démo
      caTotal.value = 0.0;
      caAujourdhui.value = 0.0;
      caMois.value = 0.0;
      caAnnee.value = 0.0;
      margeNette.value = 0.0;
      creances.value = 0.0;
      commissionsTotales.value = 0.0;
      croissanceCA.value = 0.0;
      rethrow;
    }
  }

  void _loadDemoKPIsFinanciers() {
    // Valeurs de démonstration
    caAujourdhui.value = 75000.0;
    caMois.value = 850000.0;
    caAnnee.value = 5200000.0;
    margeNette.value = 125000.0;
    creances.value = 45000.0;
    commissionsTotales.value = 85000.0;
    croissanceCA.value = 12.5;
  }

  Future<void> _loadKPIsOperationnels(DateTime debut, DateTime fin) async {
    try {
      if (_colisService == null || _livraisonService == null) {
        throw Exception('Services ColisService ou LivraisonService non initialisés');
      }

      print('🔄 [PDG_DASHBOARD] Chargement KPIs opérationnels...');

      // Récupérer les vraies données
      final colis = await _colisService!.getColisByPeriod(debut, fin);
      colisTotal.value = colis.length;

      // Colis aujourd'hui
      final aujourdhui = DateTime.now();
      final debutJour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
      final finJour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day, 23, 59, 59);
      final colisJour = await _colisService!.getColisByPeriod(debutJour, finJour);
      colisAujourdhui.value = colisJour.length;

      // Colis mois
      final debutMois = DateTime(aujourdhui.year, aujourdhui.month, 1);
      final finMois = DateTime(aujourdhui.year, aujourdhui.month + 1, 0, 23, 59, 59);
      final colisMoisData = await _colisService!.getColisByPeriod(debutMois, finMois);
      colisMois.value = colisMoisData.length;

      // Livraisons
      final livraisons = await _livraisonService!.getLivraisonsByPeriod(debut, fin);
      livraisonsTotal.value = livraisons.length;
      livraisonsReussies.value = livraisons.where((l) => l.statut == 'livree').length;

      if (livraisonsTotal.value > 0) {
        tauxLivraison.value = (livraisonsReussies.value / livraisonsTotal.value) * 100;
      } else {
        tauxLivraison.value = 0.0;
      }

      // Délai moyen de livraison
      final colisLivres = colis.where((c) => c.dateLivraison != null).toList();
      if (colisLivres.isNotEmpty) {
        final delais = colisLivres.map((c) => c.dateLivraison!.difference(c.dateCollecte).inHours).toList();
        delaiMoyen.value = delais.reduce((a, b) => a + b) / delais.length;
      } else {
        delaiMoyen.value = 0.0;
      }

      // Retours
      retours.value = colis.where((c) => c.isRetour).length;
      if (colisTotal.value > 0) {
        tauxRetours.value = (retours.value / colisTotal.value) * 100;
      } else {
        tauxRetours.value = 0.0;
      }

      print('✅ [PDG_DASHBOARD] KPIs opérationnels chargés: Colis Aujourd\'hui=${colisAujourdhui.value}, Taux Livraison=${tauxLivraison.value.toStringAsFixed(1)}%');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR CRITIQUE KPIs opérationnels: $e');
      // Mettre à 0 au lieu de charger des données de démo
      colisAujourdhui.value = 0;
      colisMois.value = 0;
      colisTotal.value = 0;
      livraisonsTotal.value = 0;
      livraisonsReussies.value = 0;
      tauxLivraison.value = 0.0;
      delaiMoyen.value = 0.0;
      retours.value = 0;
      tauxRetours.value = 0.0;
      rethrow;
    }
  }

  void _loadDemoKPIsOperationnels() {
    // Valeurs de démonstration
    colisAujourdhui.value = 45;
    colisMois.value = 1250;
    colisTotal.value = 1250;
    livraisonsTotal.value = 1180;
    livraisonsReussies.value = 1062;
    tauxLivraison.value = 90.0;
    delaiMoyen.value = 18.5;
    retours.value = 25;
    tauxRetours.value = 2.0;
  }

  Future<void> _loadKPIsCroissance(DateTime debut, DateTime fin) async {
    try {
      if (_colisService == null || _agenceService == null) {
        throw Exception('Services ColisService ou AgenceService non initialisés');
      }

      print('🔄 [PDG_DASHBOARD] Chargement KPIs croissance...');

      // Nouveaux clients (basé sur première commande)
      final colis = await _colisService!.getColisByPeriod(debut, fin);
      final clientsIds = colis.map((c) => c.expediteurTelephone).toSet();

      // Clients actifs (ayant envoyé au moins un colis)
      clientsActifs.value = clientsIds.length;

      // Croissance volume (comparaison avec période précédente)
      await _calculateCroissanceVolume(debut, fin);

      // Agences actives
      final agences = await _agenceService!.getAllAgences();
      agencesActives.value = agences.where((a) => a.isActive).length;

      // Zones desservies (approximation basée sur les livraisons)
      if (_livraisonService != null) {
        final livraisons = await _livraisonService!.getLivraisonsByPeriod(debut, fin);
        final zones = livraisons.map((l) => l.zone).toSet();
        zonesDesservies.value = zones.length;
      } else {
        zonesDesservies.value = 0;
      }

      print('✅ [PDG_DASHBOARD] KPIs croissance chargés: Clients Actifs=${clientsActifs.value}, Agences=${agencesActives.value}');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR CRITIQUE KPIs croissance: $e');
      // Mettre à 0 au lieu de charger des données de démo
      clientsActifs.value = 0;
      nouveauxClients.value = 0;
      croissanceVolume.value = 0.0;
      agencesActives.value = 0;
      zonesDesservies.value = 0;
      rethrow;
    }
  }

  void _loadDemoKPIsCroissance() {
    // Valeurs de démonstration
    clientsActifs.value = 245;
    nouveauxClients.value = 18;
    croissanceVolume.value = 8.3;
    agencesActives.value = 5;
    zonesDesservies.value = 12;
  }

  Future<void> _loadKPIsRH() async {
    try {
      if (_userService == null) {
        throw Exception('Service UserService non initialisé');
      }

      print('🔄 [PDG_DASHBOARD] Chargement KPIs RH...');

      final users = await _userService!.getAllUsers();

      // Utilisateurs actifs (connectés dans les 7 derniers jours)
      final seuilActivite = DateTime.now().subtract(const Duration(days: 7));
      utilisateursActifs.value = users.where((u) => u.isActive && (u.lastLogin?.isAfter(seuilActivite) ?? false)).length;

      // Coursiers actifs
      coursiersActifs.value = users.where((u) => u.role == 'coursier' && u.isActive).length;

      // Productivité moyenne (livraisons par coursier par jour)
      if (coursiersActifs.value > 0 && _livraisonService != null) {
        final aujourdhui = DateTime.now();
        final debutJour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
        final finJour = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day, 23, 59, 59);
        final livraisonsJour = await _livraisonService!.getLivraisonsByPeriod(debutJour, finJour);
        productiviteMoyenne.value = livraisonsJour.length / coursiersActifs.value;
      } else {
        productiviteMoyenne.value = 0.0;
      }

      print('✅ [PDG_DASHBOARD] KPIs RH chargés: Utilisateurs Actifs=${utilisateursActifs.value}, Coursiers=${coursiersActifs.value}');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR CRITIQUE KPIs RH: $e');
      // Mettre à 0 au lieu de charger des données de démo
      utilisateursActifs.value = 0;
      coursiersActifs.value = 0;
      productiviteMoyenne.value = 0.0;
      rethrow;
    }
  }

  void _loadDemoKPIsRH() {
    // Valeurs de démonstration
    utilisateursActifs.value = 28;
    coursiersActifs.value = 12;
    productiviteMoyenne.value = 3.8;
  }

  Future<void> _loadGraphiquesData(DateTime debut, DateTime fin) async {
    try {
      if (_colisService == null || _livraisonService == null || _agenceService == null) {
        throw Exception('Services non initialisés pour les graphiques');
      }

      print('🔄 [PDG_DASHBOARD] Chargement graphiques...');

      // Évolution CA (7 derniers jours) - Données réelles
      await _loadRealEvolutionCA();

      // Évolution volume (7 derniers jours) - Données réelles
      await _loadRealEvolutionVolume();

      // Répartition statuts colis - Données réelles
      await _loadRealRepartitionStatuts(debut, fin);

      // Performance agences - Données réelles
      await _loadRealPerformanceAgences(debut, fin);

      // Top coursiers - Données réelles
      await _loadRealTopCoursiers(debut, fin);

      // Motifs d'échec - Données réelles
      await _loadRealMotifsEchec(debut, fin);

      print('✅ [PDG_DASHBOARD] Graphiques chargés depuis Firebase');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR CRITIQUE graphiques: $e');
      // Vider les listes au lieu de charger des données de démo
      evolutionCA.clear();
      evolutionVolume.clear();
      repartitionStatuts.clear();
      performanceAgences.clear();
      topCoursiers.clear();
      motifsEchec.clear();
      rethrow;
    }
  }

  void _loadDemoGraphiquesData() {
    // Données de démonstration
    evolutionCA.value = _generateDemoEvolutionData('CA');
    evolutionVolume.value = _generateDemoEvolutionData('Volume');
    repartitionStatuts.value = _generateDemoStatusData();
    performanceAgences.value = _generateDemoAgenceData();
    topCoursiers.value = _generateDemoCoursierData();
    motifsEchec.value = [
      {'motif': 'Destinataire absent', 'count': 15},
      {'motif': 'Adresse incorrecte', 'count': 8},
      {'motif': 'Refus du colis', 'count': 5},
    ];
  }

  Future<void> _loadAlertesCritiques() async {
    try {
      alertesCritiques.clear();

      // Exemple d'alertes basées sur les KPIs
      if (tauxLivraison.value < 85) {
        alertesCritiques.add({'type': 'warning', 'titre': 'Taux de livraison faible', 'message': 'Taux actuel: ${tauxLivraison.value.toStringAsFixed(1)}%', 'action': 'Analyser les motifs d\'échec'});
      }

      if (creances.value > caAujourdhui.value * 2) {
        alertesCritiques.add({'type': 'error', 'titre': 'Créances élevées', 'message': '${creances.value.toStringAsFixed(0)} FCFA en impayés', 'action': 'Relancer les paiements'});
      }
    } catch (e) {
      print('⚠️ [PDG_DASHBOARD] Erreur alertes: $e');
    }
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
  }

  void changeAgence(String agenceId) {
    selectedAgence.value = agenceId;
  }

  void refreshData() {
    loadDashboardData();
  }

  // Méthodes utilitaires pour récupérer les données Firebase
  Future<List<TransactionModel>> _getTransactionsByPeriod(DateTime debut, DateTime fin) async {
    if (_agenceService == null || _transactionService == null) return [];

    try {
      // Récupérer toutes les transactions de toutes les agences pour le PDG
      final agences = await _agenceService!.getAllAgences();
      List<TransactionModel> allTransactions = [];

      for (final agence in agences) {
        try {
          final transactions = await _transactionService!.getTransactionsByPeriod(agence.id, debut, fin);
          allTransactions.addAll(transactions);
        } catch (e) {
          print('⚠️ Erreur agence ${agence.id}: $e');
        }
      }

      return allTransactions;
    } catch (e) {
      print('⚠️ Erreur récupération transactions: $e');
      return [];
    }
  }

  Future<void> _calculateCroissanceCA(DateTime debut, DateTime fin) async {
    try {
      final duree = fin.difference(debut);
      final debutPrecedent = debut.subtract(duree);
      final finPrecedent = debut.subtract(const Duration(seconds: 1));

      final transactionsPrecedentes = await _getTransactionsByPeriod(debutPrecedent, finPrecedent);
      final caPrecedent = transactionsPrecedentes.where((t) => t.type == 'recette').fold(0.0, (sum, t) => sum + t.montant);

      if (caPrecedent > 0) {
        croissanceCA.value = ((caTotal.value - caPrecedent) / caPrecedent) * 100;
      }
    } catch (e) {
      print('⚠️ Erreur calcul croissance CA: $e');
      croissanceCA.value = 0.0;
    }
  }

  Future<void> _calculateCroissanceVolume(DateTime debut, DateTime fin) async {
    try {
      if (_colisService == null) return;

      final duree = fin.difference(debut);
      final debutPrecedent = debut.subtract(duree);
      final finPrecedent = debut.subtract(const Duration(seconds: 1));

      final colisPrecedents = await _colisService!.getColisByPeriod(debutPrecedent, finPrecedent);
      final volumePrecedent = colisPrecedents.length;

      if (volumePrecedent > 0) {
        croissanceVolume.value = ((colisTotal.value - volumePrecedent) / volumePrecedent) * 100;
      }
    } catch (e) {
      print('⚠️ Erreur calcul croissance volume: $e');
      croissanceVolume.value = 0.0;
    }
  }

  Future<void> _loadRealEvolutionCA() async {
    try {
      if (_transactionService == null) {
        throw Exception('TransactionService non initialisé');
      }

      evolutionCA.clear();
      final maintenant = DateTime.now();

      for (int i = 6; i >= 0; i--) {
        final jour = maintenant.subtract(Duration(days: i));
        final debut = DateTime(jour.year, jour.month, jour.day);
        final fin = DateTime(jour.year, jour.month, jour.day, 23, 59, 59);

        final transactions = await _getTransactionsByPeriod(debut, fin);
        final ca = transactions.where((t) => t.type == 'recette').fold(0.0, (sum, t) => sum + t.montant);

        evolutionCA.add({'date': jour, 'ca': ca, 'label': '${jour.day}/${jour.month}'});
      }

      print('✅ [PDG_DASHBOARD] Évolution CA chargée: ${evolutionCA.length} jours');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR évolution CA: $e');
      evolutionCA.clear();
      rethrow;
    }
  }

  Future<void> _loadRealEvolutionVolume() async {
    try {
      if (_colisService == null) {
        throw Exception('ColisService non initialisé');
      }

      evolutionVolume.clear();
      final maintenant = DateTime.now();

      for (int i = 6; i >= 0; i--) {
        final jour = maintenant.subtract(Duration(days: i));
        final debut = DateTime(jour.year, jour.month, jour.day);
        final fin = DateTime(jour.year, jour.month, jour.day, 23, 59, 59);

        final colis = await _colisService!.getColisByPeriod(debut, fin);

        evolutionVolume.add({'date': jour, 'volume': colis.length, 'label': '${jour.day}/${jour.month}'});
      }

      print('✅ [PDG_DASHBOARD] Évolution volume chargée: ${evolutionVolume.length} jours');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR évolution volume: $e');
      evolutionVolume.clear();
      rethrow;
    }
  }

  Future<void> _loadRealRepartitionStatuts(DateTime debut, DateTime fin) async {
    try {
      if (_colisService == null) {
        throw Exception('ColisService non initialisé');
      }

      final colis = await _colisService!.getColisByPeriod(debut, fin);
      final Map<String, int> statuts = {};

      for (final c in colis) {
        statuts[c.statut] = (statuts[c.statut] ?? 0) + 1;
      }

      repartitionStatuts.value = statuts.entries.map((e) => {'statut': e.key, 'count': e.value, 'pourcentage': colis.isNotEmpty ? (e.value / colis.length) * 100 : 0}).toList();

      print('✅ [PDG_DASHBOARD] Répartition statuts chargée: ${statuts.length} statuts');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR répartition statuts: $e');
      repartitionStatuts.clear();
      rethrow;
    }
  }

  Future<void> _loadRealPerformanceAgences(DateTime debut, DateTime fin) async {
    try {
      if (_agenceService == null || _transactionService == null || _colisService == null) {
        throw Exception('Services non initialisés pour performance agences');
      }

      final agences = await _agenceService!.getAllAgences();
      performanceAgences.clear();

      for (final agence in agences) {
        try {
          final transactions = await _transactionService!.getTransactionsByPeriod(agence.id, debut, fin);
          final ca = transactions.where((t) => t.type == 'recette').fold(0.0, (sum, t) => sum + t.montant);

          final colis = await _colisService!.getColisByAgence(agence.id);
          final colisLivres = colis.where((c) => c.statut == 'livre').length;
          final tauxLivraison = colis.isNotEmpty ? (colisLivres / colis.length) * 100 : 0;

          performanceAgences.add({'agence': agence.nom, 'ca': ca, 'volume': colis.length, 'tauxLivraison': tauxLivraison});
        } catch (e) {
          print('⚠️ Erreur agence ${agence.nom}: $e');
        }
      }

      // Trier par CA décroissant
      performanceAgences.sort((a, b) => (b['ca'] as double).compareTo(a['ca'] as double));

      print('✅ [PDG_DASHBOARD] Performance agences chargée: ${performanceAgences.length} agences');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR performance agences: $e');
      performanceAgences.clear();
      rethrow;
    }
  }

  Future<void> _loadRealTopCoursiers(DateTime debut, DateTime fin) async {
    try {
      if (_livraisonService == null) {
        throw Exception('LivraisonService non initialisé');
      }

      final livraisons = await _livraisonService!.getLivraisonsByPeriod(debut, fin);
      final Map<String, Map<String, dynamic>> coursiersStats = {};

      for (final livraison in livraisons) {
        if (livraison.coursierId.isNotEmpty) {
          if (!coursiersStats.containsKey(livraison.coursierId)) {
            coursiersStats[livraison.coursierId] = {'id': livraison.coursierId, 'total': 0, 'reussies': 0, 'nom': 'Coursier ${livraison.coursierId.substring(0, 8)}'};
          }

          coursiersStats[livraison.coursierId]!['total']++;
          if (livraison.statut == 'livree') {
            coursiersStats[livraison.coursierId]!['reussies']++;
          }
        }
      }

      topCoursiers.value = coursiersStats.values.map((stats) {
        final total = stats['total'] as int;
        final reussies = stats['reussies'] as int;
        final tauxReussite = total > 0 ? (reussies / total) * 100 : 0;

        return {'nom': stats['nom'], 'livraisons': total, 'tauxReussite': tauxReussite};
      }).toList();

      // Trier par nombre de livraisons décroissant
      topCoursiers.sort((a, b) => (b['livraisons'] as int).compareTo(a['livraisons'] as int));

      // Garder seulement le top 10
      if (topCoursiers.length > 10) {
        topCoursiers.value = topCoursiers.take(10).toList();
      }

      print('✅ [PDG_DASHBOARD] Top coursiers chargé: ${topCoursiers.length} coursiers');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR top coursiers: $e');
      topCoursiers.clear();
      rethrow;
    }
  }

  Future<void> _loadRealMotifsEchec(DateTime debut, DateTime fin) async {
    try {
      if (_livraisonService == null) {
        throw Exception('LivraisonService non initialisé');
      }

      final livraisons = await _livraisonService!.getLivraisonsByPeriod(debut, fin);
      final Map<String, int> motifs = {};

      for (final livraison in livraisons) {
        if (livraison.statut == 'echec' && livraison.motifEchec != null) {
          motifs[livraison.motifEchec!] = (motifs[livraison.motifEchec!] ?? 0) + 1;
        }
      }

      motifsEchec.value = motifs.entries.map((e) => {'motif': e.key, 'count': e.value}).toList();

      // Trier par count décroissant
      motifsEchec.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      print('✅ [PDG_DASHBOARD] Motifs échec chargés: ${motifs.length} motifs');
    } catch (e) {
      print('❌ [PDG_DASHBOARD] ERREUR motifs échec: $e');
      motifsEchec.clear();
      rethrow;
    }
  }
}
