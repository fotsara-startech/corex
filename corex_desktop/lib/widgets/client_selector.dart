import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:uuid/uuid.dart';

class ClientSelector extends StatefulWidget {
  final String label;
  final String type; // 'expediteur' ou 'destinataire'
  final Function(ClientModel?) onClientSelected;
  final TextEditingController nomController;
  final TextEditingController telephoneController;
  final TextEditingController adresseController;
  final TextEditingController villeController;
  final TextEditingController? quartierController;

  const ClientSelector({
    super.key,
    required this.label,
    required this.type,
    required this.onClientSelected,
    required this.nomController,
    required this.telephoneController,
    required this.adresseController,
    required this.villeController,
    this.quartierController,
  });

  @override
  State<ClientSelector> createState() => _ClientSelectorState();
}

class _ClientSelectorState extends State<ClientSelector> {
  ClientModel? _selectedClient;
  bool _isSearching = false;
  bool _saveClient = false;

  Future<void> _searchByPhone() async {
    final phone = widget.telephoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      Get.snackbar(
        'Attention',
        'Veuillez entrer un numéro de téléphone valide',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Initialiser le controller si nécessaire
      if (!Get.isRegistered<ClientController>()) {
        Get.put(ClientController());
      }

      final clientController = Get.find<ClientController>();
      final client = await clientController.searchByPhone(phone);

      if (client != null) {
        setState(() {
          _selectedClient = client;
          widget.nomController.text = client.nom;
          widget.adresseController.text = client.adresse;
          widget.villeController.text = client.ville;
          if (widget.quartierController != null && client.quartier != null) {
            widget.quartierController!.text = client.quartier!;
          }
        });

        widget.onClientSelected(client);

        Get.snackbar(
          'Client trouvé',
          'Informations chargées: ${client.nom}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
      } else {
        Get.snackbar(
          'Nouveau client',
          'Aucun client trouvé avec ce numéro. Remplissez les informations.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blue.shade100,
        );
        setState(() => _saveClient = true);
      }
    } catch (e) {
      print('❌ [CLIENT_SELECTOR] Erreur recherche: $e');
      Get.snackbar(
        'Erreur',
        'Erreur lors de la recherche',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _saveNewClient() async {
    if (!_saveClient) return;

    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    if (user == null || user.agenceId == null) return;

    final client = ClientModel(
      id: const Uuid().v4(),
      nom: widget.nomController.text.trim(),
      telephone: widget.telephoneController.text.trim(),
      adresse: widget.adresseController.text.trim(),
      ville: widget.villeController.text.trim(),
      quartier: widget.quartierController?.text.trim().isEmpty == true ? null : widget.quartierController?.text.trim(),
      type: widget.type,
      agenceId: user.agenceId!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (!Get.isRegistered<ClientController>()) {
        Get.put(ClientController());
      }

      final clientController = Get.find<ClientController>();
      await clientController.createClient(client);

      setState(() {
        _selectedClient = client;
        _saveClient = false;
      });
    } catch (e) {
      print('❌ [CLIENT_SELECTOR] Erreur sauvegarde: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Téléphone avec bouton de recherche
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.telephoneController,
                decoration: InputDecoration(
                  labelText: 'Téléphone *',
                  prefixIcon: const Icon(Icons.phone),
                  hintText: '6XXXXXXXX',
                  suffixIcon: _selectedClient != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                ),
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
                onChanged: (value) {
                  // Réinitialiser si le numéro change
                  if (_selectedClient != null && value != _selectedClient!.telephone) {
                    setState(() {
                      _selectedClient = null;
                      _saveClient = false;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSearching ? null : _searchByPhone,
              icon: _isSearching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Rechercher'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Nom
        TextFormField(
          controller: widget.nomController,
          decoration: const InputDecoration(
            labelText: 'Nom complet *',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) => Validators.validateRequired(value, 'Le nom'),
          onChanged: (value) {
            if (_saveClient && value.isNotEmpty) {
              _saveNewClient();
            }
          },
        ),
        const SizedBox(height: 16),

        // Ville
        TextFormField(
          controller: widget.villeController,
          decoration: const InputDecoration(
            labelText: 'Ville *',
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) => Validators.validateRequired(value, 'La ville'),
        ),
        const SizedBox(height: 16),

        // Adresse
        TextFormField(
          controller: widget.adresseController,
          decoration: const InputDecoration(
            labelText: 'Adresse *',
            prefixIcon: Icon(Icons.location_on),
          ),
          validator: (value) => Validators.validateRequired(value, 'L\'adresse'),
        ),

        // Quartier (optionnel)
        if (widget.quartierController != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.quartierController,
            decoration: const InputDecoration(
              labelText: 'Quartier (optionnel)',
              prefixIcon: Icon(Icons.map),
            ),
          ),
        ],
      ],
    );
  }
}
