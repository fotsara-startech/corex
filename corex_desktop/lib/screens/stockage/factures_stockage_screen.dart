import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/models/facture_stockage_model.dart';
import 'package:intl/intl.dart';
import 'generate_facture_screen.dart';

class FacturesStockageScreen extends StatelessWidget {
  const FacturesStockageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockageController());
    controller.loadFactures();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures de Stockage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const GenerateFactureScreen()),
            tooltip: 'Générer une facture',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'toutes', label: Text('Toutes')),
                      ButtonSegment(value: 'impayees', label: Text('Impayées')),
                      ButtonSegment(value: 'payees', label: Text('Payées')),
                    ],
                    selected: const {'toutes'},
                    onSelectionChanged: (Set<String> newSelection) {
                      // TODO: Implémenter le filtrage
                    },
                  ),
                ),
              ],
            ),
          ),

          // Liste des factures
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.facturesList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune facture',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Get.to(() => const GenerateFactureScreen()),
                        icon: const Icon(Icons.add),
                        label: const Text('Générer une facture'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.facturesList.length,
                itemBuilder: (context, index) {
                  final facture = controller.facturesList[index];
                  return _FactureCard(facture: facture);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FactureCard extends StatelessWidget {
  final FactureStockageModel facture;

  const _FactureCard({required this.facture});

  @override
  Widget build(BuildContext context) {
    final isPaye = facture.statut == 'payee';
    final isAnnulee = facture.statut == 'annulee';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isPaye
              ? Colors.green[100]
              : isAnnulee
                  ? Colors.grey[300]
                  : Colors.red[100],
          child: Icon(
            isPaye
                ? Icons.check_circle
                : isAnnulee
                    ? Icons.cancel
                    : Icons.pending,
            color: isPaye
                ? Colors.green[700]
                : isAnnulee
                    ? Colors.grey[600]
                    : Colors.red[700],
          ),
        ),
        title: Text(
          facture.numeroFacture,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Émise le ${DateFormat('dd/MM/yyyy').format(facture.dateEmission)}'),
            Text(
              'Période: ${DateFormat('dd/MM').format(facture.periodeDebut)} - ${DateFormat('dd/MM/yyyy').format(facture.periodeFin)}',
            ),
            const SizedBox(height: 4),
            Text(
              '${NumberFormat('#,###').format(facture.montantTotal)} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            isPaye ? 'Payée' : isAnnulee ? 'Annulée' : 'Impayée',
          ),
          backgroundColor: isPaye
              ? Colors.green[100]
              : isAnnulee
                  ? Colors.grey[300]
                  : Colors.red[100],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (facture.notes != null) ...[
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(facture.notes!),
                  const SizedBox(height: 8),
                ],
                if (isPaye && facture.datePaiement != null) ...[
                  Text(
                    'Payée le ${DateFormat('dd/MM/yyyy').format(facture.datePaiement!)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isPaye && !isAnnulee)
                      ElevatedButton.icon(
                        onPressed: () => _marquerPayee(context, facture),
                        icon: const Icon(Icons.check),
                        label: const Text('Marquer payée'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Générer et afficher le PDF
                        Get.snackbar('Info', 'Génération du PDF en cours...');
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _marquerPayee(BuildContext context, FactureStockageModel facture) {
    showDialog(
      context: context,
      builder: (context) => _PayerFactureDialog(facture: facture),
    );
  }
}

class _PayerFactureDialog extends StatefulWidget {
  final FactureStockageModel facture;

  const _PayerFactureDialog({required this.facture});

  @override
  State<_PayerFactureDialog> createState() => _PayerFactureDialogState();
}

class _PayerFactureDialogState extends State<_PayerFactureDialog> {
  bool _isLoading = false;
  bool _creerTransaction = true;

  Future<void> _confirmerPaiement() async {
    setState(() => _isLoading = true);

    // TODO: Créer une transaction financière si _creerTransaction est true
    String? transactionId;
    if (_creerTransaction) {
      // Créer la transaction
      transactionId = 'TRANS-${DateTime.now().millisecondsSinceEpoch}';
    }

    final controller = Get.find<StockageController>();
    final success = await controller.marquerFacturePayee(
      widget.facture.id,
      transactionId ?? '',
    );

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer le paiement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Facture: ${widget.facture.numeroFacture}'),
          const SizedBox(height: 8),
          Text(
            'Montant: ${NumberFormat('#,###').format(widget.facture.montantTotal)} FCFA',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _creerTransaction,
            onChanged: (value) => setState(() => _creerTransaction = value ?? true),
            title: const Text('Créer une transaction financière'),
            subtitle: const Text('Enregistrer automatiquement la recette'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmerPaiement,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}
