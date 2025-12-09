import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/transaction_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:intl/intl.dart';
import 'recette_form_screen.dart';
import 'depense_form_screen.dart';
import 'historique_transactions_screen.dart';

class CaisseDashboardScreen extends StatefulWidget {
  const CaisseDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CaisseDashboardScreen> createState() => _CaisseDashboardScreenState();
}

class _CaisseDashboardScreenState extends State<CaisseDashboardScreen> {
  final transactionController = Get.find<TransactionController>();
  final authController = Get.find<AuthController>();
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    // Recharger les transactions à chaque fois qu'on arrive sur cet écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      transactionController.loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion de Caisse'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Obx(() {
        if (transactionController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Calculer les statistiques du jour
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);
        final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

        final transactionsDuJour = transactionController.transactionsList.where((t) => t.date.isAfter(startOfDay) && t.date.isBefore(endOfDay)).toList();

        final recettesDuJour = transactionsDuJour.where((t) => t.type == 'recette').fold(0.0, (sum, t) => sum + t.montant);

        final depensesDuJour = transactionsDuJour.where((t) => t.type == 'depense').fold(0.0, (sum, t) => sum + t.montant);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom de l'agence
              Obx(() {
                final user = authController.currentUser.value;
                return Text(
                  'Agence: ${user?.agenceId ?? "N/A"}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                );
              }),
              const SizedBox(height: 24),

              // Cartes de statistiques
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Solde Actuel',
                      currencyFormat.format(transactionController.soldeActuel.value),
                      Icons.account_balance_wallet,
                      transactionController.soldeActuel.value >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Recettes du Jour',
                      currencyFormat.format(recettesDuJour),
                      Icons.arrow_upward,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Dépenses du Jour',
                      currencyFormat.format(depensesDuJour),
                      Icons.arrow_downward,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(() => const RecetteFormScreen()),
                      icon: const Icon(Icons.add_circle),
                      label: const Text('Enregistrer une Recette'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Get.to(() => const DepenseFormScreen()),
                      icon: const Icon(Icons.remove_circle),
                      label: const Text('Enregistrer une Dépense'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => const HistoriqueTransactionsScreen()),
                  icon: const Icon(Icons.history),
                  label: const Text('Voir l\'Historique et Rapprochement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Dernières transactions
              const Text(
                'Dernières Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildRecentTransactions(transactionController, currencyFormat),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(TransactionController controller, NumberFormat currencyFormat) {
    final recentTransactions = controller.transactionsList.take(5).toList();

    if (recentTransactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('Aucune transaction enregistrée'),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentTransactions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = recentTransactions[index];
          final isRecette = transaction.type == 'recette';

          return ListTile(
            leading: Icon(
              isRecette ? Icons.arrow_upward : Icons.arrow_downward,
              color: isRecette ? Colors.green : Colors.red,
            ),
            title: Text(transaction.description),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)} - ${isRecette ? transaction.categorieRecette : transaction.categorieDepense}',
            ),
            trailing: Text(
              currencyFormat.format(transaction.montant),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isRecette ? Colors.green : Colors.red,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}
