import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/models/client_model.dart';
import 'package:corex_shared/models/depot_model.dart';
import 'package:intl/intl.dart';

class GenerateFactureScreen extends StatefulWidget {
  const GenerateFactureScreen({Key? key}) : super(key: key);

  @override
  State<GenerateFactureScreen> createState() => _GenerateFactureScreenState();
}

class _GenerateFactureScreenState extends State<GenerateFactureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  ClientModel? _selectedClient;
  DateTime _periodeDebut = DateTime.now().subtract(const Duration(days: 30));
  DateTime _periodeFin = DateTime.now();
  final Set<String> _selectedDepots = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectPeriodeDebut() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _periodeDebut,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _periodeDebut = date);
    }
  }

  Future<void> _selectPeriodeFin() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _periodeFin,
      firstDate: _periodeDebut,
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _periodeFin = date);
    }
  }

  double _calculateTotal() {
    final controller = Get.find<StockageController>();
    final depots = controller.depotsList
        .where((d) => _selectedDepots.contains(d.id))
        .toList();

    return depots.fold(0.0, (sum, depot) => sum + depot.tarifMensuel);
  }

  Future<void> _generateFacture() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClient == null) {
      Get.snackbar('Erreur', 'Sélectionnez un client');
      return;
    }

    if (_selectedDepots.isEmpty) {
      Get.snackbar('Erreur', 'Sélectionnez au moins un dépôt');
      return;
    }

    setState(() => _isLoading = true);

    final controller = Get.find<StockageController>();
    final success = await controller.generateFactureMensuelle(
      _selectedClient!.id,
      _selectedDepots.toList(),
      _periodeDebut,
      _periodeFin,
      _calculateTotal(),
      _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Générer une Facture'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sélection du client
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Client',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      return DropdownButtonFormField<ClientModel>(
                        value: _selectedClient,
                        decoration: const InputDecoration(
                          labelText: 'Sélectionner un client *',
                          border: OutlineInputBorder(),
                        ),
                        items: controller.clientsStockeurs.map((client) {
                          return DropdownMenuItem(
                            value: client,
                            child: Text('${client.nom} - ${client.telephone}'),
                          );
                        }).toList(),
                        onChanged: (client) {
                          setState(() {
                            _selectedClient = client;
                            _selectedDepots.clear();
                          });
                          if (client != null) {
                            controller.loadDepotsByClient(client.id);
                          }
                        },
                        validator: (value) => value == null ? 'Requis' : null,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Période
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Période de facturation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Début'),
                            subtitle: Text(DateFormat('dd/MM/yyyy').format(_periodeDebut)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _selectPeriodeDebut,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ListTile(
                            title: const Text('Fin'),
                            subtitle: Text(DateFormat('dd/MM/yyyy').format(_periodeFin)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _selectPeriodeFin,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sélection des dépôts
            if (_selectedClient != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dépôts à facturer',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        final depots = controller.depotsList
                            .where((d) => d.clientId == _selectedClient!.id)
                            .toList();

                        if (depots.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Aucun dépôt pour ce client',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children: depots.map((depot) {
                            return CheckboxListTile(
                              value: _selectedDepots.contains(depot.id),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedDepots.add(depot.id);
                                  } else {
                                    _selectedDepots.remove(depot.id);
                                  }
                                });
                              },
                              title: Text(
                                'Dépôt du ${DateFormat('dd/MM/yyyy').format(depot.dateDepot)}',
                              ),
                              subtitle: Text(
                                '${depot.emplacement} - ${NumberFormat('#,###').format(depot.tarifMensuel)} FCFA/mois',
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Montant total
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Montant total:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(_calculateTotal())} FCFA',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
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
                    onPressed: _isLoading ? null : _generateFacture,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Générer'),
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
