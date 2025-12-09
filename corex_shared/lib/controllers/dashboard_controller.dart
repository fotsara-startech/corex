import 'package:get/get.dart';
import '../models/colis_model.dart';
import '../models/transaction_model.dart';
import '../services/colis_service.dart';
import '../services/transaction_service.dart';
import '../services/livraison_service.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  final ColisService _colisService = Get.find<ColisService>();
  final TransactionService _transactionService = Get.find<TransactionService>();
  final LivraisonService _livraisonService = Get.find<LivraisonService>();

  final RxBool isLoading = false.obs;
  final RxString selectedPeriod = 'today'.obs; // today, week, month, year

  // KPI globaux
  final RxDouble caGlobal = 0.0.obs;
  final RxInt nombreColisTotal = 0.obs;
  final RxInt nombreLivraisonsTotal = 0.obs;
  final RxMap<String, int> colisParStatut = <String, int>{}.obs;

  // Données pour graphiques
  final RxList<Map<String, dynamic>> evolutionCA = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> evolutionColis = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> evolutionLivraisons = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();

    // Recharger les données quand la période change
    ever(selectedPeriod, (_) => loadDashboardData());
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      final period = _getPeriodDates();
      await Future.wait([
        _loadCAGlobal(period['debut']!, period['fin']!),
        _loadStatistiquesColis(period['debut']!, period['fin']!),
        _loadEvolutionData(period['debut']!, period['fin']!),
      ]);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les données du dashboard');
      print('❌ [DASHBOARD] Erreur: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, DateTime> _getPeriodDates() {
    final now = DateTime.now();
    DateTime debut;
    DateTime fin = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (selectedPeriod.value) {
      case 'today':
        debut = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        debut = now.subtract(Duration(days: now.weekday - 1));
        debut = DateTime(debut.year, debut.month, debut.day);
        break;
      case 'month':
        debut = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        debut = DateTime(now.year, 1, 1);
        break;
      default:
        debut = DateTime(now.year, now.month, now.day);
    }

    return {'debut': debut, 'fin': fin};
  }

  Future<void> _loadCAGlobal(DateTime debut, DateTime fin) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) return;

      double totalCA = 0.0;

      // Si PDG, récupérer le CA de toutes les agences
      if (user.role == 'pdg') {
        final allTransactions = await _transactionService.getAllTransactions(debut, fin);
        totalCA = allTransactions
            .where((t) => t.type == 'recette')
            .fold(0.0, (sum, t) => sum + t.montant);
      } else {
        // Sinon, CA de l'agence de l'utilisateur
        final agenceId = user.agenceId;
        if (agenceId != null) {
          final transactions = await _transactionService.getTransactionsByPeriod(agenceId, debut, fin);
          totalCA = transactions
              .where((t) => t.type == 'recette')
              .fold(0.0, (sum, t) => sum + t.montant);
        }
      }

      caGlobal.value = totalCA;
    } catch (e) {
      print('❌ [DASHBOARD] Erreur chargement CA: $e');
    }
  }

  Future<void> _loadStatistiquesColis(DateTime debut, DateTime fin) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) return;

      List<ColisModel> colis;

      // Si PDG, récupérer tous les colis
      if (user.role == 'pdg') {
        colis = await _colisService.getAllColis();
      } else {
        // Sinon, colis de l'agence
        final agenceId = user.agenceId;
        if (agenceId != null) {
          colis = await _colisService.getColisByAgence(agenceId);
        } else {
          colis = [];
        }
      }

      // Filtrer par période
      colis = colis.where((c) => 
        c.dateCollecte.isAfter(debut) && c.dateCollecte.isBefore(fin)
      ).toList();

      nombreColisTotal.value = colis.length;

      // Compter par statut
      final statutCounts = <String, int>{};
      for (var c in colis) {
        statutCounts[c.statut] = (statutCounts[c.statut] ?? 0) + 1;
      }
      colisParStatut.value = statutCounts;

      // Compter les livraisons
      if (user.role == 'pdg') {
        final livraisons = await _livraisonService.getAllLivraisons();
        final livraisonsPeriode = livraisons.where((l) =>
          l.dateCreation.isAfter(debut) && l.dateCreation.isBefore(fin)
        ).toList();
        nombreLivraisonsTotal.value = livraisonsPeriode.length;
      } else {
        final agenceId = user.agenceId;
        if (agenceId != null) {
          final livraisons = await _livraisonService.getLivraisonsByAgence(agenceId);
          final livraisonsPeriode = livraisons.where((l) =>
            l.dateCreation.isAfter(debut) && l.dateCreation.isBefore(fin)
          ).toList();
          nombreLivraisonsTotal.value = livraisonsPeriode.length;
        }
      }
    } catch (e) {
      print('❌ [DASHBOARD] Erreur chargement statistiques: $e');
    }
  }

  Future<void> _loadEvolutionData(DateTime debut, DateTime fin) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) return;

      // Générer les points de données selon la période
      final dataPoints = _generateDataPoints(debut, fin);

      List<Map<String, dynamic>> caData = [];
      List<Map<String, dynamic>> colisData = [];
      List<Map<String, dynamic>> livraisonsData = [];

      for (var point in dataPoints) {
        final pointDebut = point['debut'] as DateTime;
        final pointFin = point['fin'] as DateTime;
        final label = point['label'] as String;

        // CA pour ce point
        double ca = 0.0;
        if (user.role == 'pdg') {
          final transactions = await _transactionService.getAllTransactions(pointDebut, pointFin);
          ca = transactions
              .where((t) => t.type == 'recette')
              .fold(0.0, (sum, t) => sum + t.montant);
        } else {
          final agenceId = user.agenceId;
          if (agenceId != null) {
            final transactions = await _transactionService.getTransactionsByPeriod(agenceId, pointDebut, pointFin);
            ca = transactions
                .where((t) => t.type == 'recette')
                .fold(0.0, (sum, t) => sum + t.montant);
          }
        }

        // Colis pour ce point
        List<ColisModel> colis;
        if (user.role == 'pdg') {
          colis = await _colisService.getAllColis();
        } else {
          final agenceId = user.agenceId;
          colis = agenceId != null ? await _colisService.getColisByAgence(agenceId) : [];
        }
        colis = colis.where((c) => 
          c.dateCollecte.isAfter(pointDebut) && c.dateCollecte.isBefore(pointFin)
        ).toList();

        // Livraisons pour ce point
        int nbLivraisons = 0;
        if (user.role == 'pdg') {
          final livraisons = await _livraisonService.getAllLivraisons();
          nbLivraisons = livraisons.where((l) =>
            l.dateCreation.isAfter(pointDebut) && l.dateCreation.isBefore(pointFin)
          ).length;
        } else {
          final agenceId = user.agenceId;
          if (agenceId != null) {
            final livraisons = await _livraisonService.getLivraisonsByAgence(agenceId);
            nbLivraisons = livraisons.where((l) =>
              l.dateCreation.isAfter(pointDebut) && l.dateCreation.isBefore(pointFin)
            ).length;
          }
        }

        caData.add({'label': label, 'value': ca});
        colisData.add({'label': label, 'value': colis.length});
        livraisonsData.add({'label': label, 'value': nbLivraisons});
      }

      evolutionCA.value = caData;
      evolutionColis.value = colisData;
      evolutionLivraisons.value = livraisonsData;
    } catch (e) {
      print('❌ [DASHBOARD] Erreur chargement évolution: $e');
    }
  }

  List<Map<String, dynamic>> _generateDataPoints(DateTime debut, DateTime fin) {
    final points = <Map<String, dynamic>>[];

    switch (selectedPeriod.value) {
      case 'today':
        // Par heure (6h, 9h, 12h, 15h, 18h, 21h)
        for (int hour = 6; hour <= 21; hour += 3) {
          final pointDebut = DateTime(debut.year, debut.month, debut.day, hour);
          final pointFin = DateTime(debut.year, debut.month, debut.day, hour + 3);
          points.add({
            'debut': pointDebut,
            'fin': pointFin,
            'label': '${hour}h',
          });
        }
        break;

      case 'week':
        // Par jour
        for (int i = 0; i < 7; i++) {
          final day = debut.add(Duration(days: i));
          final pointDebut = DateTime(day.year, day.month, day.day);
          final pointFin = DateTime(day.year, day.month, day.day, 23, 59, 59);
          points.add({
            'debut': pointDebut,
            'fin': pointFin,
            'label': _getDayName(day.weekday),
          });
        }
        break;

      case 'month':
        // Par semaine
        DateTime current = debut;
        int weekNum = 1;
        while (current.isBefore(fin)) {
          final pointFin = current.add(Duration(days: 7));
          points.add({
            'debut': current,
            'fin': pointFin.isAfter(fin) ? fin : pointFin,
            'label': 'S$weekNum',
          });
          current = pointFin;
          weekNum++;
        }
        break;

      case 'year':
        // Par mois
        for (int month = 1; month <= 12; month++) {
          final pointDebut = DateTime(debut.year, month, 1);
          final pointFin = DateTime(debut.year, month + 1, 1).subtract(Duration(seconds: 1));
          points.add({
            'debut': pointDebut,
            'fin': pointFin,
            'label': _getMonthName(month),
          });
        }
        break;
    }

    return points;
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }

  void changePeriod(String period) {
    selectedPeriod.value = period;
  }
}
