import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/models/client_model.dart';

class CreateClientStockeurScreen extends StatefulWidget {
  const CreateClientStockeurScreen({Key? key}) : super(key: key);

  @override
  State<CreateClientStockeurScreen> createState() => _CreateClientStockeurScreenState();
}

class _CreateClientStockeurScreenState extends State<CreateClientStockeurScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  Future<List<ClientModel>> _searchClients(String query) async {
    if (query.length < 2) return [];

    setState(() => _isSearching = true);

    try {
      final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);

      // Recherche multi-critères (nom, téléphone, email)
      final clients = await controller.searchClientsMultiCriteria(query);

      setState(() => _isSearching = false);

      return clients;
    } catch (e) {
      print('❌ [CREATE_CLIENT_STOCKEUR] Erreur recherche: $e');
      setState(() => _isSearching = false);
      return [];
    }
  }

  void _fillClientData(ClientModel client) {
    _telephoneController.text = client.telephone;
    _nomController.text = client.nom;
    _adresseController.text = client.adresse;
    _villeController.text = client.ville;
    _quartierController.text = client.quartier ?? '';

    Get.snackbar(
      'Client trouvé',
      'Les informations ont été remplies automatiquement',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    if (user == null || user.agenceId == null) {
      Get.snackbar('Erreur', 'Utilisateur non connecté');
      setState(() => _isLoading = false);
      return;
    }

    final client = ClientModel(
      id: '',
      nom: _nomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      adresse: _adresseController.text.trim(),
      ville: _villeController.text.trim(),
      quartier: _quartierController.text.trim().isEmpty ? null : _quartierController.text.trim(),
      type: 'stockeur',
      agenceId: user.agenceId!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
    final success = await controller.createClientStockeur(client);

    setState(() => _isLoading = false);

    if (success) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Client Stockeur'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Recherchez un client par son nom ou téléphone. Si le client existe déjà, ses informations seront remplies automatiquement.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Téléphone avec autocomplétion
            Autocomplete<ClientModel>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.length < 2) {
                  return const Iterable<ClientModel>.empty();
                }
                return await _searchClients(textEditingValue.text);
              },
              displayStringForOption: (ClientModel client) => client.telephone,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                // Synchroniser avec notre controller
                if (_telephoneController.text.isEmpty && controller.text.isNotEmpty) {
                  _telephoneController.text = controller.text;
                }

                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Téléphone ou Nom *',
                    hintText: 'Rechercher par téléphone ou nom...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  onChanged: (value) {
                    _telephoneController.text = value;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le téléphone est requis';
                    }
                    return null;
                  },
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: MediaQuery.of(context).size.width - 32,
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final client = options.elementAt(index);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: Icon(Icons.person, color: Colors.green.shade700),
                            ),
                            title: Text(
                              client.nom,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📞 ${client.telephone}'),
                                Text('📍 ${client.ville}${client.quartier != null ? ', ${client.quartier}' : ''}'),
                              ],
                            ),
                            onTap: () {
                              onSelected(client);
                              _fillClientData(client);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (ClientModel client) {
                _fillClientData(client);
              },
            ),
            const SizedBox(height: 16),

            // Nom
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Adresse
            TextFormField(
              controller: _adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'L\'adresse est requise';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Ville
            TextFormField(
              controller: _villeController,
              decoration: const InputDecoration(
                labelText: 'Ville *',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La ville est requise';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quartier
            TextFormField(
              controller: _quartierController,
              decoration: const InputDecoration(
                labelText: 'Quartier',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
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
                    onPressed: _isLoading ? null : _saveClient,
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
