import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/dashboard_controller.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment),
            onPressed: () => Get.toNamed('/rapports/financiers'),
            tooltip: 'Rapports Financiers',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadDashboardData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélecteur de période
                _buildPeriodSelector(controller),
                const SizedBox(height: 20),

                // Cartes de statistiques
                _buildStatsCards(controller),
                const SizedBox(height: 20),

                // Graphique CA
                _buildCAChart(controller),
                const SizedBox(height: 20),

                // Graphique Colis
                _buildColisChart(controller),
                const SizedBox(height: 20),

                // Graphique Livraisons
                _buildLivraisonsChart(controller),
                const SizedBox(height: 20),

                // Répartition par statut
                _buildStatutDistribution(controller),
                const SizedBox(height: 20),

                // Bouton rapport par agence
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/rapports/agence'),
                    icon: const Icon(Icons.business),
                    label: const Text('Rapport par Agence'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector(DashboardController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPeriodButton(controller, 'Aujourd\'hui', 'today'),
            _buildPeriodButton(controller, 'Semaine', 'week'),
            _buildPeriodButton(controller, 'Mois', 'month'),
            _buildPeriodButton(controller, 'Année', 'year'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(DashboardController controller, String label, String value) {
    return Obx(() {
      final isSelected = controller.selectedPeriod.value == value;
      return ElevatedButton(
        onPressed: () => controller.changePeriod(value),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.grey[300],
          foregroundColor: isSelected ? Colors.white : Colors.black,
        ),
        child: Text(label),
      );
    });
  }

  Widget _buildStatsCards(DashboardController controller) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'CA Global',
                '${controller.caGlobal.value.toStringAsFixed(0)} FCFA',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Colis',
                '${controller.nombreColisTotal.value}',
                Icons.inventory_2,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildStatCard(
          'Livraisons',
          '${controller.nombreLivraisonsTotal.value}',
          Icons.local_shipping,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCAChart(DashboardController controller) {
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

  Widget _buildColisChart(DashboardController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution des Colis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Obx(() {
                if (controller.evolutionColis.isEmpty) {
                  return const Center(child: Text('Aucune donnée'));
                }

                return BarChart(
                  BarChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < controller.evolutionColis.length) {
                              return Text(
                                controller.evolutionColis[index]['label'],
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
                    barGroups: controller.evolutionColis.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value['value'].toDouble(),
                            color: Colors.blue,
                            width: 16,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivraisonsChart(DashboardController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution des Livraisons',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Obx(() {
                if (controller.evolutionLivraisons.isEmpty) {
                  return const Center(child: Text('Aucune donnée'));
                }

                return BarChart(
                  BarChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < controller.evolutionLivraisons.length) {
                              return Text(
                                controller.evolutionLivraisons[index]['label'],
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
                    barGroups: controller.evolutionLivraisons.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value['value'].toDouble(),
                            color: Colors.orange,
                            width: 16,
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutDistribution(DashboardController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition par Statut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.colisParStatut.isEmpty) {
                return const Center(child: Text('Aucune donnée'));
              }

              return Column(
                children: controller.colisParStatut.entries.map((entry) {
                  final percentage = (entry.value / controller.nombreColisTotal.value * 100).toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _getStatutLabel(entry.key),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: entry.value / controller.nombreColisTotal.value,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatutColor(entry.key),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value} ($percentage%)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
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

  String _getStatutLabel(String statut) {
    const labels = {
      'collecte': 'Collecte',
      'enregistre': 'Enregistré',
      'enTransit': 'En Transit',
      'arriveDestination': 'Arrivé',
      'enCoursLivraison': 'En Livraison',
      'livre': 'Livré',
      'retourne': 'Retourné',
    };
    return labels[statut] ?? statut;
  }

  Color _getStatutColor(String statut) {
    const colors = {
      'collecte': Colors.grey,
      'enregistre': Colors.blue,
      'enTransit': Colors.orange,
      'arriveDestination': Colors.purple,
      'enCoursLivraison': Colors.amber,
      'livre': Colors.green,
      'retourne': Colors.red,
    };
    return colors[statut] ?? Colors.grey;
  }
}
