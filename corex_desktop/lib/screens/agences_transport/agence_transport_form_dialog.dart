import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:uuid/uuid.dart';

class AgenceTransportFormDialog extends StatefulWidget {
  final AgenceTransportModel? agence;

  const AgenceTransportFormDialog({super.key, this.agence});

  @override
  State<AgenceTransportFormDialog> createState() => _AgenceTransportFormDialogState();
}

class _AgenceTransportFormDialogState extends State<AgenceTransportFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _contactController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _villeController = TextEditingController();
  final _tarifController = TextEditingController();

  final Map<String, double> _tarifs = {};
  bool _isLoading = false;

  bool get isEditMode => widget.agence != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nomController.text = widget.agence!.nom;
      _contactController.text = widget.agence!.contact;
      _telephoneController.text = widget.agence!.telephone;
      _tarifs.addAll(widget.agence!.tarifs);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _contactController.dispose();
    _telephoneController.dispose();
    _villeController.dispose();
    _tarifController.dispose();
    super.dispose();
  }

  void _addVille() {
    final ville = _villeController.text.trim();
    final tarifText = _tarifController.text.trim();

    if (ville.isEmpty || tarifText.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez remplir la ville et le tarif',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final tarif = double.tryParse(tarifText);
    if (tarif == null || tarif <= 0) {
      Get.snackbar(
        'Erreur',
        'Le tarif doit être un nombre positif',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_tarifs.containsKey(ville)) {
      Get.snackbar(
        'Erreur',
        'Cette ville existe déjà',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _tarifs[ville] = tarif;
      _villeController.clear();
      _tarifController.clear();
    });
  }

  void _removeVille(String ville) {
    setState(() {
      _tarifs.remove(ville);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tarifs.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez ajouter au moins une ville desservie',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final controller = Get.find<AgenceTransportController>();
      bool success;

      if (isEditMode) {
        success = await controller.updateAgence(
          widget.agence!.id,
          {
            'nom': _nomController.text.trim(),
            'contact': _contactController.text.trim(),
            'telephone': _telephoneController.text.trim(),
            'villesDesservies': _tarifs.keys.toList(),
            'tarifs': _tarifs,
          },
        );
      } else {
        final newAgence = AgenceTransportModel(
          id: const Uuid().v4(),
          nom: _nomController.text.trim(),
          contact: _contactController.text.trim(),
          telephone: _telephoneController.text.trim(),
          villesDesservies: _tarifs.keys.toList(),
          tarifs: _tarifs,
          isActive: true,
          createdAt: DateTime.now(),
        );
        success = await controller.createAgence(newAgence);
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
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
                Text(
                  isEditMode ? 'Modifier l\'agence' : 'Nouvelle agence de transport',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'agence *',
                    prefixIcon: Icon(Icons.local_shipping),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Le nom'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(
                    labelText: 'Personne de contact *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Le contact'),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                const Text(
                  'Villes desservies et tarifs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _villeController,
                        decoration: const InputDecoration(
                          hintText: 'Ville',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _tarifController,
                        decoration: const InputDecoration(
                          hintText: 'Tarif (FCFA)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addVille,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_tarifs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _tarifs.entries.map((entry) {
                        return ListTile(
                          dense: true,
                          title: Text(entry.key),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${entry.value.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _removeVille(entry.key),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 24),
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
