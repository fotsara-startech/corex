import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:uuid/uuid.dart';
import 'client_search_dialog.dart';

class ClientSelector extends StatefulWidget {
  final String label;
  final String type; // 'expediteur' ou 'destinataire'
  final Function(ClientModel?) onClientSelected;
  final TextEditingController nomController;
  final TextEditingController telephoneController;
  final TextEditingController adresseController;
  final TextEditingController villeController;
  final TextEditingController? quartierController;
  final TextEditingController? emailController;

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
    this.emailController,
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

    await _performSearch('phone', phone);
  }

  Future<void> _searchByEmail() async {
    final email = widget.emailController?.text.trim() ?? '';
    if (email.isEmpty || !Validators.isValidEmail(email)) {
      Get.snackbar(
        'Attention',
        'Veuillez entrer une adresse email valide',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _performSearch('email', email);
  }

  Future<void> _performSearch(String searchType, String searchValue) async {
    // Éviter les recherches multiples simultanées
    if (_isSearching) return;

    setState(() => _isSearching = true);

    try {
      // Initialiser le controller si nécessaire
      if (!Get.isRegistered<ClientController>()) {
        Get.put(ClientController());
      }

      final clientController = Get.find<ClientController>();
      ClientModel? client;

      if (searchType == 'phone') {
        // Normaliser le numéro avant la recherche
        final normalizedPhone = searchValue.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        client = await clientController.searchByPhone(normalizedPhone);
      } else if (searchType == 'email') {
        client = await clientController.searchByEmail(searchValue);
      }

      if (mounted) {
        if (client != null) {
          setState(() {
            _selectedClient = client;
            widget.nomController.text = client!.nom;
            widget.telephoneController.text = client.telephone;
            widget.adresseController.text = client.adresse;
            widget.villeController.text = client.ville;
            if (widget.quartierController != null && client.quartier != null) {
              widget.quartierController!.text = client.quartier!;
            }
            if (widget.emailController != null && client.email != null) {
              widget.emailController!.text = client.email!;
            }
            _saveClient = false; // Réinitialiser le flag
          });

          widget.onClientSelected(client);

          Get.snackbar(
            'Client trouvé',
            'Informations chargées: ${client.nom}${client.email != null ? ' (${client.email})' : ''}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
          );
        } else {
          setState(() {
            _selectedClient = null;
            _saveClient = true;
          });

          Get.snackbar(
            'Nouveau client',
            'Aucun client trouvé. Remplissez les informations.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.blue.shade100,
          );
        }
      }
    } catch (e) {
      print('❌ [CLIENT_SELECTOR] Erreur recherche: $e');
      if (mounted) {
        Get.snackbar(
          'Erreur',
          'Erreur lors de la recherche: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
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
      email: widget.emailController?.text.trim().isEmpty == true ? null : widget.emailController?.text.trim(),
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

  void _showAdvancedSearch() {
    showDialog(
      context: context,
      builder: (context) => ClientSearchDialog(
        onClientSelected: (client) {
          setState(() {
            _selectedClient = client;
            widget.nomController.text = client.nom;
            widget.telephoneController.text = client.telephone;
            widget.adresseController.text = client.adresse;
            widget.villeController.text = client.ville;
            if (widget.quartierController != null && client.quartier != null) {
              widget.quartierController!.text = client.quartier!;
            }
            if (widget.emailController != null && client.email != null) {
              widget.emailController!.text = client.email!;
            }
            _saveClient = false;
          });

          widget.onClientSelected(client);

          Get.snackbar(
            'Client sélectionné',
            'Informations chargées: ${client.nom}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.shade100,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bouton de recherche avancée
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: OutlinedButton.icon(
            onPressed: _showAdvancedSearch,
            icon: const Icon(Icons.search),
            label: const Text('Recherche avancée (nom, téléphone, email)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

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

        // Email (optionnel) avec recherche
        if (widget.emailController != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.emailController,
                  decoration: InputDecoration(
                    labelText: 'Email (optionnel)',
                    prefixIcon: const Icon(Icons.email),
                    hintText: 'exemple@email.com',
                    suffixIcon: _selectedClient?.email != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return Validators.validateEmail(value);
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Réinitialiser si l'email change
                    if (_selectedClient != null && value != _selectedClient!.email) {
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
                onPressed: _isSearching ? null : _searchByEmail,
                icon: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Rechercher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ],

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
