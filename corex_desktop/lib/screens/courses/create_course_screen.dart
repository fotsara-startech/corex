import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import '../../theme/corex_theme.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final CourseController _courseController = Get.find<CourseController>();
  final ClientController _clientController = Get.find<ClientController>();

  ClientModel? _selectedClient;
  final _lieuController = TextEditingController();
  final _tacheController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _montantController = TextEditingController();
  final _commissionController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _clientController.loadClients();
  }

  @override
  void dispose() {
    _lieuController.dispose();
    _tacheController.dispose();
    _instructionsController.dispose();
    _montantController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  double get _commission {
    final montant = double.tryParse(_montantController.text) ?? 0;
    final pourcentage = double.tryParse(_commissionController.text) ?? 10;
    return montant * (pourcentage / 100);
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClient == null) {
      Get.snackbar('Erreur', 'Veuillez sélectionner un client');
      return;
    }

    try {
      await _courseController.createCourse(
        clientId: _selectedClient!.id,
        clientNom: _selectedClient!.nom,
        clientTelephone: _selectedClient!.telephone,
        instructions: _instructionsController.text.trim(),
        lieu: _lieuController.text.trim(),
        tache: _tacheController.text.trim(),
        montantEstime: double.parse(_montantController.text),
        commissionPourcentage: double.parse(_commissionController.text),
      );

      Get.back();
    } catch (e) {
      // Erreur déjà gérée dans le controller
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Course'),
        backgroundColor: CorexTheme.primaryGreen,
      ),
      body: Obx(() {
        if (_clientController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélection du client
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<ClientModel>(
                          value: _selectedClient,
                          decoration: const InputDecoration(
                            labelText: 'Sélectionner un client',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: _clientController.clientsList.map((client) {
                            return DropdownMenuItem(
                              value: client,
                              child: Text('${client.nom} - ${client.telephone}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClient = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Veuillez sélectionner un client';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Détails de la course
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détails de la Course',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lieuController,
                          decoration: const InputDecoration(
                            labelText: 'Lieu',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                            hintText: 'Ex: Marché central, Rue 123',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez saisir le lieu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tacheController,
                          decoration: const InputDecoration(
                            labelText: 'Tâche',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.task),
                            hintText: 'Ex: Acheter des fournitures',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez saisir la tâche';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _instructionsController,
                          decoration: const InputDecoration(
                            labelText: 'Instructions détaillées',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                            hintText: 'Détails supplémentaires...',
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez saisir les instructions';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tarification
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarification',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _montantController,
                                decoration: const InputDecoration(
                                  labelText: 'Montant estimé (FCFA)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez saisir le montant';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Montant invalide';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _commissionController,
                                decoration: const InputDecoration(
                                  labelText: 'Commission (%)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.percent),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {}),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez saisir la commission';
                                  }
                                  final commission = double.tryParse(value);
                                  if (commission == null || commission < 0 || commission > 100) {
                                    return 'Commission invalide (0-100)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CorexTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Commission COREX:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_commission.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: CorexTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 16),
                    Obx(() => ElevatedButton.icon(
                          onPressed: _courseController.isLoading.value ? null : _createCourse,
                          icon: _courseController.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Créer la Course'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CorexTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
