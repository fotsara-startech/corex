import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class RapportAgenceController extends GetxController {
  final ColisService _colisService = Get.find<ColisService>();
  final TransactionService _transactionService = Get.find<TransactionService>();
  final LivraisonService _livraisonService = Get.find<LivraisonService>();
  final UserService _userService = Get.find<UserService>();
  final AgenceService _agenceService = Get.find<AgenceService>();

  final RxBool isLoading = false.obs;
  final Rx<AgenceModel?> selectedAgence = Rx<AgenceModel?>(null);
  final RxList<AgenceModel> agences = <AgenceModel>[].obs;

  final Rx<DateTime> dateDebut = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> dateFin = DateTime.now().obs;

  // Statistiques
  final RxDouble caAgence = 0.0.obs;
  final RxInt nombreColis = 0.obs;
  final RxInt nombreLivraisons = 0.obs;
  final RxList<Map<String, dynamic>> statsCommerciaux = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> statsCoursiers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> evolutionCA = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAgences();
  }

  Future<void> loadAgences() async {
    try {
      agences.value = await _agenceService.getAllAgences();
      if (agences.isNotEmpty) {
        selectedAgence.value = agences.first;
        await loadRapportAgence();
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les agences');
      print('❌ [RAPPORT_AGENCE] Erreur: $e');
    }
  }

  Future<void> selectAgence(AgenceModel? agence) async {
    if (agence != null) {
      selectedAgence.value = agence;
      await loadRapportAgence();
    }
  }

  Future<void> loadRapportAgence() async {
    if (selectedAgence.value == null) return;

    isLoading.value = true;
    try {
      final agenceId = selectedAgence.value!.id;

      await Future.wait([
        _loadCAAgence(agenceId),
        _loadStatsColis(agenceId),
        _loadStatsCommerciaux(agenceId),
        _loadStatsCoursiers(agenceId),
        _loadEvolutionCA(agenceId),
      ]);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger le rapport');
      print('❌ [RAPPORT_AGENCE] Erreur: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCAAgence(String agenceId) async {
    final bilan = await _transactionService.getBilanAgence(
      agenceId,
      dateDebut.value,
      dateFin.value,
    );
    caAgence.value = bilan['recettes'] ?? 0.0;
  }

  Future<void> _loadStatsColis(String agenceId) async {
    final colis = await _colisService.getColisByAgence(agenceId);
    final colisPeriode = colis.where((c) =>
      c.dateCollecte.isAfter(dateDebut.value) &&
      c.dateCollecte.isBefore(dateFin.value)
    ).toList();
    nombreColis.value = colisPeriode.length;

    final livraisons = await _livraisonService.getLivraisonsByAgence(agenceId);
    final livraisonsPeriode = livraisons.where((l) =>
      l.dateCreation.isAfter(dateDebut.value) &&
      l.dateCreation.isBefore(dateFin.value)
    ).toList();
    nombreLivraisons.value = livraisonsPeriode.length;
  }

  Future<void> _loadStatsCommerciaux(String agenceId) async {
    final users = await _userService.getUsersByAgence(agenceId);
    final commerciaux = users.where((u) => u.role == 'commercial').toList();

    final stats = <Map<String, dynamic>>[];

    for (var commercial in commerciaux) {
      final colis = await _colisService.getColisByCommercial(commercial.id);
      final colisPeriode = colis.where((c) =>
        c.dateCollecte.isAfter(dateDebut.value) &&
        c.dateCollecte.isBefore(dateFin.value)
      ).toList();

      final ca = colisPeriode.fold(0.0, (sum, c) => sum + c.montantTarif);

      stats.add({
        'nom': commercial.nomComplet,
        'nombreColis': colisPeriode.length,
        'ca': ca,
      });
    }

    // Trier par CA décroissant
    stats.sort((a, b) => (b['ca'] as double).compareTo(a['ca'] as double));
    statsCommerciaux.value = stats;
  }

  Future<void> _loadStatsCoursiers(String agenceId) async {
    final users = await _userService.getUsersByAgence(agenceId);
    final coursiers = users.where((u) => u.role == 'coursier').toList();

    final stats = <Map<String, dynamic>>[];

    for (var coursier in coursiers) {
      final livraisons = await _livraisonService.getLivraisonsByCoursier(coursier.id);
      final livraisonsPeriode = livraisons.where((l) =>
        l.dateCreation.isAfter(dateDebut.value) &&
        l.dateCreation.isBefore(dateFin.value)
      ).toList();

      final livreesCount = livraisonsPeriode.where((l) => l.statut == 'livree').length;
      final tauxReussite = livraisonsPeriode.isEmpty
          ? 0.0
          : (livreesCount / livraisonsPeriode.length * 100);

      stats.add({
        'nom': coursier.nomComplet,
        'nombreLivraisons': livraisonsPeriode.length,
        'livrees': livreesCount,
        'tauxReussite': tauxReussite,
      });
    }

    // Trier par nombre de livraisons décroissant
    stats.sort((a, b) => (b['nombreLivraisons'] as int).compareTo(a['nombreLivraisons'] as int));
    statsCoursiers.value = stats;
  }

  Future<void> _loadEvolutionCA(String agenceId) async {
    final dataPoints = _generateDataPoints();
    final caData = <Map<String, dynamic>>[];

    for (var point in dataPoints) {
      final pointDebut = point['debut'] as DateTime;
      final pointFin = point['fin'] as DateTime;
      final label = point['label'] as String;

      final transactions = await _transactionService.getTransactionsByPeriod(
        agenceId,
        pointDebut,
        pointFin,
      );

      final ca = transactions
          .where((t) => t.type == 'recette')
          .fold(0.0, (sum, t) => sum + t.montant);

      caData.add({'label': label, 'value': ca});
    }

    evolutionCA.value = caData;
  }

  List<Map<String, dynamic>> _generateDataPoints() {
    final points = <Map<String, dynamic>>[];
    final duration = dateFin.value.difference(dateDebut.value).inDays;

    if (duration <= 7) {
      // Par jour
      for (int i = 0; i <= duration; i++) {
        final day = dateDebut.value.add(Duration(days: i));
        final pointDebut = DateTime(day.year, day.month, day.day);
        final pointFin = DateTime(day.year, day.month, day.day, 23, 59, 59);
        points.add({
          'debut': pointDebut,
          'fin': pointFin,
          'label': DateFormat('dd/MM').format(day),
        });
      }
    } else if (duration <= 31) {
      // Par semaine
      DateTime current = dateDebut.value;
      int weekNum = 1;
      while (current.isBefore(dateFin.value)) {
        final pointFin = current.add(const Duration(days: 7));
        points.add({
          'debut': current,
          'fin': pointFin.isAfter(dateFin.value) ? dateFin.value : pointFin,
          'label': 'S$weekNum',
        });
        current = pointFin;
        weekNum++;
      }
    } else {
      // Par mois
      DateTime current = dateDebut.value;
      while (current.isBefore(dateFin.value)) {
        final pointFin = DateTime(current.year, current.month + 1, 1).subtract(const Duration(seconds: 1));
        points.add({
          'debut': current,
          'fin': pointFin.isAfter(dateFin.value) ? dateFin.value : pointFin,
          'label': DateFormat('MMM').format(current),
        });
        current = DateTime(current.year, current.month + 1, 1);
      }
    }

    return points;
  }

  Future<void> selectDateDebut(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dateDebut.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      dateDebut.value = date;
      await loadRapportAgence();
    }
  }

  Future<void> selectDateFin(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dateFin.value,
      firstDate: dateDebut.value,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      dateFin.value = date;
      await loadRapportAgence();
    }
  }
}

class RapportAgenceScreen extends StatelessWidget {
  const RapportAgenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RapportAgenceController());
    final exportService = Get.put(ExportService());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport par Agence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              if (controller.selectedAgence.value != null) {
                await exportService.generateRapportAgencePDF(
                  agenceNom: controller.selectedAgence.value!.nom,
                  dateDebut: controller.dateDebut.value,
                  dateFin: controller.dateFin.value,
                  caAgence: controller.caAgence.value,
                  nombreColis: controller.nombreColis.value,
                  nombreLivraisons: controller.nombreLivraisons.value,
                  statsCommerciaux: controller.statsCommerciaux,
                  statsCoursiers: controller.statsCoursiers,
                );
              }
            },
            tooltip: 'Exporter en PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadRapportAgence(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadRapportAgence(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélection d'agence
                _buildAgenceSelector(controller),
                const SizedBox(height: 20),

                // Sélection de période
                _buildPeriodSelector(controller, context),
                const SizedBox(height: 20),

                // Statistiques globales
                _buildStatsGlobales(controller),
                const SizedBox(height: 20),

                // Graphique évolution CA
                _buildEvolutionCAChart(controller),
                const SizedBox(height: 20),

                // Stats commerciaux
                _buildStatsCommerciaux(controller),
                const SizedBox(height: 20),

                // Stats coursiers
                _buildStatsCoursiers(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAgenceSelector(RapportAgenceController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(() => DropdownButtonFormField<AgenceModel>(
              value: controller.selectedAgence.value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: controller.agences.map((agence) {
                return DropdownMenuItem(
                  value: agence,
                  child: Text(agence.nom),
                );
              }).toList(),
              onChanged: (agence) => controller.selectAgence(agence),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(RapportAgenceController controller, BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Période',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => controller.selectDateDebut(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date début',
                        border: OutlineInputBorder(),
                      ),
                      child: Obx(() => Text(dateFormat.format(controller.dateDebut.value))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => controller.selectDateFin(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Obx(() => Text(dateFormat.format(controller.dateFin.value))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGlobales(RapportAgenceController controller) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'CA',
            '${controller.caAgence.value.toStringAsFixed(0)} FCFA',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'Colis',
            '${controller.nombreColis.value}',
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            'Livraisons',
            '${controller.nombreLivraisons.value}',
            Icons.local_shipping,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionCAChart(RapportAgenceController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution du CA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Obx(() {
                if (controller.evolutionCA.isEmpty) {
                  return const Center(child: Text('Aucune donnée'));
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${(value / 1000).toStringAsFixed(0)}k',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < controller.evolutionCA.length) {
                              return Text(
                                controller.evolutionCA[index]['label'],
                                style: const TextStyle(fontSize: 10),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: controller.evolutionCA.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            entry.value['value'].toDouble(),
                          );
                        }).toList(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCommerciaux(RapportAgenceController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance des Commerciaux',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.statsCommerciaux.isEmpty) {
                return const Center(child: Text('Aucun commercial'));
              }

              return Column(
                children: controller.statsCommerciaux.map((stat) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(stat['nom']),
                      subtitle: Text('${stat['nombreColis']} colis'),
                      trailing: Text(
                        '${stat['ca'].toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCoursiers(RapportAgenceController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance des Coursiers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.statsCoursiers.isEmpty) {
                return const Center(child: Text('Aucun coursier'));
              }

              return Column(
                children: controller.statsCoursiers.map((stat) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.delivery_dining),
                      ),
                      title: Text(stat['nom']),
                      subtitle: Text(
                        '${stat['nombreLivraisons']} livraisons • ${stat['livrees']} réussies',
                      ),
                      trailing: Text(
                        '${stat['tauxReussite'].toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: stat['tauxReussite'] >= 80 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
