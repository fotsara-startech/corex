import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:uuid/uuid.dart';

class ZoneFormDialog extends StatefulWidget {
  final ZoneModel? zone;

  const ZoneFormDialog({super.key, this.zone});

  @override
  State<ZoneFormDialog> createState() => _ZoneFormDialogState();
}

class _ZoneFormDialogState extends State<ZoneFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _villeController = TextEditingController();
  final _tarifController = TextEditingController();
  final _quartierController = TextEditingController();

  final List<String> _quartiers = [];
  bool _isLoading = false;
  String? _selectedAgenceId;

  bool get isEditMode => widget.zone != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nomController.text = widget.zone!.nom;
      _villeController.text = widget.zone!.ville;
      _tarifController.text = widget.zone!.tarifLivraison.toString();
      _quartiers.addAll(widget.zone!.quartiers);
      _selectedAgenceId = widget.zone!.agenceId;
    } else {
      // Pour une nouvelle zone, utiliser l'agence de l'utilisateur connecté
      final authController = Get.find<AuthController>();
      _selectedAgenceId = authController.currentUser.value?.agenceId;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _villeController.dispose();
    _tarifController.dispose();
    _quartierController.dispose();
    super.dispose();
  }

  void _addQuartier() {
    final quartier = _quartierController.text.trim();
    if (quartier.isNotEmpty && !_quartiers.contains(quartier)) {
      setState(() {
        _quartiers.add(quartier);
        _quartierController.clear();
      });
    }
  }

  void _removeQuartier(String quartier) {
    setState(() {
      _quartiers.remove(quartier);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      print('❌ [ZONE_FORM] Validation échouée');
      return;
    }

    if (_quartiers.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez ajouter au moins un quartier',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_selectedAgenceId == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner une agence',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    print('📝 [ZONE_FORM] Début de la soumission...');
    setState(() => _isLoading = true);

    try {
      final zoneController = Get.find<ZoneController>();
      bool success;

      if (isEditMode) {
        print('✏️ [ZONE_FORM] Mode édition');
        success = await zoneController.updateZone(
          widget.zone!.id,
          {
            'nom': _nomController.text.trim(),
            'ville': _villeController.text.trim(),
            'quartiers': _quartiers,
            'tarifLivraison': double.parse(_tarifController.text),
          },
        );
      } else {
        print('➕ [ZONE_FORM] Mode création');
        final newZone = ZoneModel(
          id: const Uuid().v4(),
          nom: _nomController.text.trim(),
          ville: _villeController.text.trim(),
          quartiers: _quartiers,
          agenceId: _selectedAgenceId!,
          tarifLivraison: double.parse(_tarifController.text),
        );
        success = await zoneController.createZone(newZone);
      }

      print('✅ [ZONE_FORM] Opération terminée: success=$success');

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success && mounted) {
        print('🚪 [ZONE_FORM] Fermeture du dialog');
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      print('❌ [ZONE_FORM] Erreur: $e');
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
        width: 600,
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
                  isEditMode ? 'Modifier la zone' : 'Nouvelle zone',
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
                    labelText: 'Nom de la zone *',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Le nom'),
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

                // Tarif
                TextFormField(
                  controller: _tarifController,
                  decoration: const InputDecoration(
                    labelText: 'Tarif de livraison (FCFA) *',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.validatePositiveNumber(value, 'Le tarif'),
                ),
                const SizedBox(height: 24),

                // Section Quartiers
                const Text(
                  'Quartiers desservis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Ajouter un quartier
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _quartierController,
                        decoration: const InputDecoration(
                          hintText: 'Nom du quartier',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addQuartier(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addQuartier,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Liste des quartiers
                if (_quartiers.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quartiers.map((quartier) {
                        return Chip(
                          label: Text(quartier),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _removeQuartier(quartier),
                        );
                      }).toList(),
                    ),
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
