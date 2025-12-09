import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/models/depot_model.dart';
import 'package:corex_shared/models/mouvement_stock_model.dart';
import 'package:intl/intl.dart';

class DepotDetailsScreen extends StatefulWidget {
  final DepotModel depot;

  const DepotDetailsScreen({Key? key, required this.depot}) : super(key: key);

  @override
  State<DepotDetailsScreen> createState() => _DepotDetailsScreenState();
}

class _DepotDetailsScreenState extends State<DepotDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.find<StockageController>();
    controller.selectDepot(widget.depot);
    controller.loadMouvementsByDepot(widget.depot.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Dépôt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_circle),
            onPressed: () => _showRetraitDialog(context),
            tooltip: 'Retrait',
          ),
        ],
      ),
      body: Obx(() {
        // Utiliser le dépôt sélectionné du contrôleur pour avoir les données à jour
        final currentDepot = controller.selectedDepot.value ?? widget.depot;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informations générales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    _InfoRow(label: 'Date de dépôt', value: DateFormat('dd/MM/yyyy').format(currentDepot.dateDepot)),
                    _InfoRow(label: 'Emplacement', value: currentDepot.emplacement),
                    _InfoRow(
                      label: 'Tarif mensuel',
                      value: '${NumberFormat('#,###').format(currentDepot.tarifMensuel)} FCFA',
                    ),
                    _InfoRow(label: 'Type de tarif', value: currentDepot.typeTarif == 'global' ? 'Global' : 'Par produit'),
                    if (currentDepot.notes != null) _InfoRow(label: 'Notes', value: currentDepot.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Liste des produits
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Produits en stock',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ...currentDepot.produits.map((produit) => _ProduitTile(produit: produit)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Historique des mouvements
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historique des mouvements',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    Obx(() {
                      if (controller.mouvementsList.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text('Aucun mouvement', style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      return Column(
                        children: controller.mouvementsList.map((mouvement) {
                          return _MouvementTile(mouvement: mouvement);
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showRetraitDialog(BuildContext context) {
    final controller = Get.find<StockageController>();
    final currentDepot = controller.selectedDepot.value ?? widget.depot;

    showDialog(
      context: context,
      builder: (context) => _RetraitDialog(depot: currentDepot),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProduitTile extends StatelessWidget {
  final ProduitStocke produit;

  const _ProduitTile({required this.produit});

  @override
  Widget build(BuildContext context) {
    final isVide = produit.quantite <= 0;

    return ListTile(
      leading: Icon(
        Icons.inventory_2,
        color: isVide ? Colors.grey : Colors.green,
      ),
      title: Text(
        produit.nom,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isVide ? Colors.grey : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (produit.description.isNotEmpty) Text(produit.description),
          Text(
            '${produit.quantite} ${produit.unite}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isVide ? Colors.red : Colors.green,
            ),
          ),
          if (produit.tarifUnitaire != null) Text('${NumberFormat('#,###').format(produit.tarifUnitaire)} FCFA/unité'),
        ],
      ),
      trailing: isVide
          ? const Chip(
              label: Text('Vide'),
              backgroundColor: Colors.grey,
            )
          : null,
    );
  }
}

class _MouvementTile extends StatelessWidget {
  final MouvementStockModel mouvement;

  const _MouvementTile({required this.mouvement});

  @override
  Widget build(BuildContext context) {
    final isDepot = mouvement.type == 'depot';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDepot ? Colors.blue[100] : Colors.orange[100],
        child: Icon(
          isDepot ? Icons.arrow_downward : Icons.arrow_upward,
          color: isDepot ? Colors.blue[700] : Colors.orange[700],
        ),
      ),
      title: Text(
        isDepot ? 'Dépôt' : 'Retrait',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd/MM/yyyy HH:mm').format(mouvement.dateMouvement)),
          ...mouvement.produits.map((p) => Text('• ${p.nom}: ${p.quantite} ${p.unite}')),
          if (mouvement.notes != null)
            Text(
              mouvement.notes!,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}

class _RetraitDialog extends StatefulWidget {
  final DepotModel depot;

  const _RetraitDialog({required this.depot});

  @override
  State<_RetraitDialog> createState() => _RetraitDialogState();
}

class _RetraitDialogState extends State<_RetraitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final Map<String, double> _quantitesRetrait = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRetrait() async {
    if (!_formKey.currentState!.validate()) return;

    final produitsRetrait = _quantitesRetrait.entries.where((e) => e.value > 0).map((e) {
      final produit = widget.depot.produits.firstWhere((p) => p.nom == e.key);
      return ProduitMouvement(
        nom: e.key,
        quantite: e.value,
        unite: produit.unite,
      );
    }).toList();

    if (produitsRetrait.isEmpty) {
      Get.snackbar('Erreur', 'Saisissez au moins une quantité à retirer');
      return;
    }

    setState(() => _isLoading = true);

    final controller = Get.find<StockageController>();
    final success = await controller.createRetrait(
      widget.depot.id,
      widget.depot.clientId,
      produitsRetrait,
      _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Retrait de produits'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Saisissez les quantités à retirer:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...widget.depot.produits.where((p) => p.quantite > 0).map((produit) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${produit.nom} (Disponible: ${produit.quantite} ${produit.unite})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Quantité à retirer',
                          suffixText: produit.unite,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _quantitesRetrait[produit.nom] = double.tryParse(value) ?? 0;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final quantite = double.tryParse(value);
                          if (quantite == null) return 'Invalide';
                          if (quantite > produit.quantite) {
                            return 'Max: ${produit.quantite}';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRetrait,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
