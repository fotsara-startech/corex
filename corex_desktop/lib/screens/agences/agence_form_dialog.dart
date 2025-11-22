import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:uuid/uuid.dart';

class AgenceFormDialog extends StatefulWidget {
  final AgenceModel? agence;

  const AgenceFormDialog({super.key, this.agence});

  @override
  State<AgenceFormDialog> createState() => _AgenceFormDialogState();
}

class _AgenceFormDialogState extends State<AgenceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  bool get isEditMode => widget.agence != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nomController.text = widget.agence!.nom;
      _adresseController.text = widget.agence!.adresse;
      _villeController.text = widget.agence!.ville;
      _telephoneController.text = widget.agence!.telephone;
      _emailController.text = widget.agence!.email;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ [AGENCE_FORM] Validation échouée');
      return;
    }

    print('📝 [AGENCE_FORM] Début de la soumission...');
    setState(() => _isLoading = true);

    try {
      final agenceController = Get.find<AgenceController>();
      bool success;

      if (isEditMode) {
        print('✏️ [AGENCE_FORM] Mode édition');
        success = await agenceController.updateAgence(
          widget.agence!.id,
          {
            'nom': _nomController.text.trim(),
            'adresse': _adresseController.text.trim(),
            'ville': _villeController.text.trim(),
            'telephone': _telephoneController.text.trim(),
            'email': _emailController.text.trim(),
          },
        );
      } else {
        print('➕ [AGENCE_FORM] Mode création');
        final newAgence = AgenceModel(
          id: const Uuid().v4(),
          nom: _nomController.text.trim(),
          adresse: _adresseController.text.trim(),
          ville: _villeController.text.trim(),
          telephone: _telephoneController.text.trim(),
          email: _emailController.text.trim(),
          isActive: true,
          createdAt: DateTime.now(),
        );
        success = await agenceController.createAgence(newAgence);
      }

      print('✅ [AGENCE_FORM] Opération terminée: success=$success');

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success) {
        print('🚪 [AGENCE_FORM] Fermeture du dialog');
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e, stackTrace) {
      print('❌ [AGENCE_FORM] Erreur: $e');
      print('📍 [STACK] $stackTrace');
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
                  isEditMode ? 'Modifier l\'agence' : 'Nouvelle agence',
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
                    labelText: 'Nom de l\'agence *',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Le nom'),
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

                // Téléphone
                TextFormField(
                  controller: _telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone *',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '6XXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
