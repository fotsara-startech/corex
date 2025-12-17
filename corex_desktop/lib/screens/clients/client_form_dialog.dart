import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:uuid/uuid.dart';

class ClientFormDialog extends StatefulWidget {
  final ClientModel? client;

  const ClientFormDialog({super.key, this.client});

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();

  String _selectedType = 'les_deux';
  bool _isLoading = false;

  bool get isEditMode => widget.client != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nomController.text = widget.client!.nom;
      _telephoneController.text = widget.client!.telephone;
      _emailController.text = widget.client!.email ?? '';
      _adresseController.text = widget.client!.adresse;
      _villeController.text = widget.client!.ville;
      _quartierController.text = widget.client!.quartier ?? '';
      _selectedType = widget.client!.type;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final clientController = Get.find<ClientController>();
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) {
        Get.snackbar(
          'Erreur',
          'Vous devez être assigné à une agence',
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() => _isLoading = false);
        return;
      }

      bool success;

      if (isEditMode) {
        // Mise à jour
        success = await clientController.updateClient(
          widget.client!.id,
          {
            'nom': _nomController.text.trim(),
            'telephone': _telephoneController.text.trim(),
            'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            'adresse': _adresseController.text.trim(),
            'ville': _villeController.text.trim(),
            'quartier': _quartierController.text.trim().isEmpty ? null : _quartierController.text.trim(),
            'type': _selectedType,
          },
        );
      } else {
        // Création
        final client = ClientModel(
          id: const Uuid().v4(),
          nom: _nomController.text.trim(),
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          adresse: _adresseController.text.trim(),
          ville: _villeController.text.trim(),
          quartier: _quartierController.text.trim().isEmpty ? null : _quartierController.text.trim(),
          type: _selectedType,
          agenceId: user.agenceId!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        success = await clientController.createClient(client);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('❌ [CLIENT_FORM] Erreur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  isEditMode ? 'Modifier le client' : 'Nouveau client',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Nom
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Le nom'),
                ),
                const SizedBox(height: 16),

                // Téléphone
                TextFormField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone *',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '6XXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
                  enabled: !isEditMode, // Téléphone non modifiable en édition
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optionnel)',
                    prefixIcon: Icon(Icons.email),
                    hintText: 'exemple@email.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return Validators.validateEmail(value);
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
                  ),
                  validator: (value) => Validators.validateRequired(value, 'La ville'),
                ),
                const SizedBox(height: 16),

                // Adresse
                TextFormField(
                  controller: _adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse *',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'L\'adresse'),
                ),
                const SizedBox(height: 16),

                // Quartier
                TextFormField(
                  controller: _quartierController,
                  decoration: const InputDecoration(
                    labelText: 'Quartier (optionnel)',
                    prefixIcon: Icon(Icons.map),
                  ),
                ),
                const SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'expediteur', child: Text('Expéditeur')),
                    DropdownMenuItem(value: 'destinataire', child: Text('Destinataire')),
                    DropdownMenuItem(value: 'les_deux', child: Text('Les deux')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Get.back(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditMode ? 'Modifier' : 'Créer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
