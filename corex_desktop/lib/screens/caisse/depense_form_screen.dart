import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/transaction_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

class DepenseFormScreen extends StatefulWidget {
  const DepenseFormScreen({Key? key}) : super(key: key);

  @override
  State<DepenseFormScreen> createState() => _DepenseFormScreenState();
}

class _DepenseFormScreenState extends State<DepenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategorie;
  final List<String> _categories = [
    'transport',
    'salaires',
    'loyer',
    'carburant',
    'internet',
    'electricite',
    'autre',
  ];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitDepense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authController = Get.find<AuthController>();
      final transactionController = Get.find<TransactionController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté ou agence non définie');
        return;
      }

      final transaction = TransactionModel(
        id: const Uuid().v4(),
        agenceId: user.agenceId!,
        type: 'depense',
        montant: double.parse(_montantController.text),
        date: DateTime.now(),
        categorieDepense: _selectedCategorie,
        description: _descriptionController.text,
        userId: user.id,
      );

      await transactionController.createTransaction(transaction);

      // Afficher le nouveau solde
      Get.snackbar(
        'Succès',
        'Dépense enregistrée avec succès\nNouveau solde: ${transactionController.soldeActuel.value.toStringAsFixed(0)} FCFA',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      Get.back();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'enregistrer la dépense: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer une Dépense'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informations de la Dépense',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Montant
              TextFormField(
                controller: _montantController,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le montant';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Montant invalide';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Le montant doit être positif';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                value: _selectedCategorie,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(_getCategorieLabel(cat)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategorie = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Note sur le justificatif
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Un justificatif est obligatoire pour les dépenses (à implémenter)',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Get.back(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitDepense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategorieLabel(String categorie) {
    switch (categorie) {
      case 'transport':
        return 'Transport';
      case 'salaires':
        return 'Salaires';
      case 'loyer':
        return 'Loyer';
      case 'carburant':
        return 'Carburant';
      case 'internet':
        return 'Internet';
      case 'electricite':
        return 'Électricité';
      case 'autre':
        return 'Autre';
      default:
        return categorie;
    }
  }
}
