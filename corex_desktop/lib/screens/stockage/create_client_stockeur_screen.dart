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

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  Future<void> _searchByPhone() async {
    if (_telephoneController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final controller = Get.find<StockageController>();
    final client = await controller.searchClientByPhone(_telephoneController.text);

    setState(() => _isLoading = false);

    if (client != null) {
      _nomController.text = client.nom;
      _adresseController.text = client.adresse;
      _villeController.text = client.ville;
      _quartierController.text = client.quartier ?? '';
      
      Get.snackbar('Client trouvé', 'Les informations ont été remplies automatiquement');
    }
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

    final controller = Get.find<StockageController>();
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
            // Téléphone avec recherche
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _telephoneController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le téléphone est requis';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _isLoading ? null : _searchByPhone,
                  tooltip: 'Rechercher',
                ),
              ],
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
