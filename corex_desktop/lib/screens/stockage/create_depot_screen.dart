import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/models/client_model.dart';
import 'package:corex_shared/models/depot_model.dart';

class CreateDepotScreen extends StatefulWidget {
  final ClientModel client;

  const CreateDepotScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<CreateDepotScreen> createState() => _CreateDepotScreenState();
}

class _CreateDepotScreenState extends State<CreateDepotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emplacementController = TextEditingController();
  final _tarifController = TextEditingController();
  final _notesController = TextEditingController();

  String _typeTarif = 'global';
  final List<ProduitStocke> _produits = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _emplacementController.dispose();
    _tarifController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addProduit() {
    showDialog(
      context: context,
      builder: (context) => _AddProduitDialog(
        onAdd: (produit) {
          setState(() {
            _produits.add(produit);
          });
        },
        typeTarif: _typeTarif,
      ),
    );
  }

  void _removeProduit(int index) {
    setState(() {
      _produits.removeAt(index);
    });
  }

  Future<void> _saveDepot() async {
    if (!_formKey.currentState!.validate()) return;

    if (_produits.isEmpty) {
      Get.snackbar('Erreur', 'Ajoutez au moins un produit');
      return;
    }

    setState(() => _isLoading = true);

    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    if (user == null || user.agenceId == null) {
      Get.snackbar('Erreur', 'Utilisateur non connecté');
      setState(() => _isLoading = false);
      return;
    }

    final depot = DepotModel(
      id: '',
      clientId: widget.client.id,
      agenceId: user.agenceId!,
      produits: _produits,
      emplacement: _emplacementController.text.trim(),
      tarifMensuel: _typeTarif == 'global' ? double.parse(_tarifController.text) : 0.0,
      typeTarif: _typeTarif,
      dateDepot: DateTime.now(),
      userId: user.id,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final controller = Get.find<StockageController>();
    final success = await controller.createDepot(depot);

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Dépôt'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info client
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.client.nom,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(widget.client.telephone),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Emplacement
            TextFormField(
              controller: _emplacementController,
              decoration: const InputDecoration(
                labelText: 'Emplacement *',
                hintText: 'Ex: Zone A, Étagère 3',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'L\'emplacement est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Type de tarif
            DropdownButtonFormField<String>(
              value: _typeTarif,
              decoration: const InputDecoration(
                labelText: 'Type de tarif',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'global', child: Text('Tarif global')),
                DropdownMenuItem(value: 'par_produit', child: Text('Tarif par produit')),
              ],
              onChanged: (value) {
                setState(() {
                  _typeTarif = value!;
                  _produits.clear();
                });
              },
            ),
            const SizedBox(height: 16),

            // Tarif mensuel (si global)
            if (_typeTarif == 'global')
              TextFormField(
                controller: _tarifController,
                decoration: const InputDecoration(
                  labelText: 'Tarif mensuel (FCFA) *',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le tarif est requis';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),

            // Liste des produits
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Produits', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: _addProduit,
                    ),
                  ),
                  if (_produits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Aucun produit ajouté', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _produits.length,
                      itemBuilder: (context, index) {
                        final produit = _produits[index];
                        return ListTile(
                          leading: const Icon(Icons.inventory_2),
                          title: Text(produit.nom),
                          subtitle: Text(
                            '${produit.quantite} ${produit.unite}${produit.tarifUnitaire != null ? ' - ${produit.tarifUnitaire} FCFA/unité' : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeProduit(index),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.note),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDepot,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddProduitDialog extends StatefulWidget {
  final Function(ProduitStocke) onAdd;
  final String typeTarif;

  const _AddProduitDialog({required this.onAdd, required this.typeTarif});

  @override
  State<_AddProduitDialog> createState() => _AddProduitDialogState();
}

class _AddProduitDialogState extends State<_AddProduitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantiteController = TextEditingController();
  final _tarifController = TextEditingController();
  String _unite = 'pieces';

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _quantiteController.dispose();
    _tarifController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final produit = ProduitStocke(
      nom: _nomController.text.trim(),
      description: _descriptionController.text.trim(),
      quantite: double.parse(_quantiteController.text),
      unite: _unite,
      tarifUnitaire: widget.typeTarif == 'par_produit' ? double.parse(_tarifController.text) : null,
    );

    widget.onAdd(produit);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un produit'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantiteController,
                      decoration: const InputDecoration(
                        labelText: 'Quantité *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Requis';
                        if (double.tryParse(value!) == null) return 'Invalide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unite,
                      decoration: const InputDecoration(
                        labelText: 'Unité',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pieces', child: Text('Pièces')),
                        DropdownMenuItem(value: 'kg', child: Text('Kg')),
                        DropdownMenuItem(value: 'cartons', child: Text('Cartons')),
                        DropdownMenuItem(value: 'sacs', child: Text('Sacs')),
                      ],
                      onChanged: (value) => setState(() => _unite = value!),
                    ),
                  ),
                ],
              ),
              if (widget.typeTarif == 'par_produit') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tarifController,
                  decoration: const InputDecoration(
                    labelText: 'Tarif unitaire (FCFA) *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Requis';
                    if (double.tryParse(value!) == null) return 'Invalide';
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
