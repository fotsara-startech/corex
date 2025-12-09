import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:intl/intl.dart';

class RapportsFinanciersController extends GetxController {
  final TransactionService _transactionService = Get.find<TransactionService>();
  final AgenceService _agenceService = Get.find<AgenceService>();

  final RxBool isLoading = false.obs;
  final Rx<DateTime> dateDebut = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> dateFin = DateTime.now().obs;

  final RxList<Map<String, dynamic>> bilanParAgence = <Map<String, dynamic>>[].obs;
  final RxDouble totalRecettes = 0.0.obs;
  final RxDouble totalDepenses = 0.0.obs;
  final RxDouble soldeGlobal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadRapportFinancier();
  }

  Future<void> loadRapportFinancier() async {
    isLoading.value = true;
    try {
      // Récupérer toutes les agences
      final agences = await _agenceService.getAllAgences();

      // Calculer le bilan pour chaque agence
      final bilans = <Map<String, dynamic>>[];
      double totalRec = 0.0;
      double totalDep = 0.0;

      for (var agence in agences) {
        final bilan = await _transactionService.getBilanAgence(
          agence.id,
          dateDebut.value,
          dateFin.value,
        );

        bilans.add({
          'agenceId': agence.id,
          'agenceNom': agence.nom,
          'recettes': bilan['recettes'] ?? 0.0,
          'depenses': bilan['depenses'] ?? 0.0,
          'solde': bilan['solde'] ?? 0.0,
        });

        totalRec += bilan['recettes'] ?? 0.0;
        totalDep += bilan['depenses'] ?? 0.0;
      }

      // Trier par CA décroissant
      bilans.sort((a, b) => (b['recettes'] as double).compareTo(a['recettes'] as double));

      bilanParAgence.value = bilans;
      totalRecettes.value = totalRec;
      totalDepenses.value = totalDep;
      soldeGlobal.value = totalRec - totalDep;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger le rapport financier');
      print('❌ [RAPPORTS] Erreur: $e');
    } finally {
      isLoading.value = false;
    }
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
      await loadRapportFinancier();
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
      await loadRapportFinancier();
    }
  }

  List<Map<String, dynamic>> getTop5Agences() {
    return bilanParAgence.take(5).toList();
  }
}

class RapportsFinanciersScreen extends StatelessWidget {
  const RapportsFinanciersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RapportsFinanciersController());
    final exportService = Get.put(ExportService());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports Financiers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await exportService.generateRapportFinancierPDF(
                dateDebut: controller.dateDebut.value,
                dateFin: controller.dateFin.value,
                totalRecettes: controller.totalRecettes.value,
                totalDepenses: controller.totalDepenses.value,
                soldeGlobal: controller.soldeGlobal.value,
                bilanParAgence: controller.bilanParAgence,
              );
            },
            tooltip: 'Exporter en PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadRapportFinancier(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadRapportFinancier(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélection de période
                _buildPeriodSelector(controller, context),
                const SizedBox(height: 20),

                // Totaux globaux
                _buildTotauxGlobaux(controller),
                const SizedBox(height: 20),

                // Top 5 agences
                _buildTop5Agences(controller),
                const SizedBox(height: 20),

                // Bilan par agence
                _buildBilanParAgence(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector(RapportsFinanciersController controller, BuildContext context) {
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

  Widget _buildTotauxGlobaux(RapportsFinanciersController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bilan Consolidé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTotalRow('Recettes', controller.totalRecettes.value, Colors.green),
            const Divider(),
            _buildTotalRow('Dépenses', controller.totalDepenses.value, Colors.red),
            const Divider(),
            _buildTotalRow('Solde', controller.soldeGlobal.value, controller.soldeGlobal.value >= 0 ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double montant, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '${montant.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop5Agences(RapportsFinanciersController controller) {
    final top5 = controller.getTop5Agences();

    if (top5.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top 5 Agences par CA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...top5.asMap().entries.map((entry) {
              final index = entry.key;
              final agence = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _getMedalColor(index),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        agence['agenceNom'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      '${agence['recettes'].toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getMedalColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Or
      case 1:
        return Colors.grey; // Argent
      case 2:
        return Colors.brown; // Bronze
      default:
        return Colors.blue;
    }
  }

  Widget _buildBilanParAgence(RapportsFinanciersController controller) {
    if (controller.bilanParAgence.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('Aucune donnée disponible'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bilan par Agence',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...controller.bilanParAgence.map((agence) {
              return ExpansionTile(
                title: Text(
                  agence['agenceNom'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'CA: ${agence['recettes'].toStringAsFixed(0)} FCFA',
                  style: const TextStyle(color: Colors.green),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildAgenceRow('Recettes', agence['recettes'], Colors.green),
                        const SizedBox(height: 8),
                        _buildAgenceRow('Dépenses', agence['depenses'], Colors.red),
                        const Divider(),
                        _buildAgenceRow('Solde', agence['solde'], agence['solde'] >= 0 ? Colors.green : Colors.red),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgenceRow(String label, double montant, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '${montant.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
