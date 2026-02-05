import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:intl/intl.dart';

class DemandeCourseForm extends StatefulWidget {
  const DemandeCourseForm({super.key});

  @override
  State<DemandeCourseForm> createState() => _DemandeCourseFormState();
}

class _DemandeCourseFormState extends State<DemandeCourseForm> {
  final _formKey = GlobalKey<FormState>();
  final _lieuController = TextEditingController();
  final _tacheController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();

  late final DemandeController _demandeController;
  late final AuthController _authController;

  String _typeTache = 'achat';
  String _priorite = 'normale';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isUrgent = false;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();

    try {
      _demandeController = Get.find<DemandeController>();
      _authController = Get.find<AuthController>();
    } catch (e) {
      print('⚠️ [DEMANDE COURSE] Controllers non trouvés: $e');
      // Créer les controllers si ils n'existent pas
      if (!Get.isRegistered<DemandeController>()) {
        Get.put(DemandeController());
        _demandeController = Get.find<DemandeController>();
      }
      if (!Get.isRegistered<AuthController>()) {
        Get.back();
        return;
      }
      _authController = Get.find<AuthController>();
    }

    // Vérifier que l'utilisateur est un client
    final user = _authController.currentUser.value;
    if (user == null || user.role != 'client') {
      Get.back();
      Get.snackbar('Erreur', 'Accès non autorisé');
      return;
    }
  }

  @override
  void dispose() {
    _lieuController.dispose();
    _tacheController.dispose();
    _instructionsController.dispose();
    _budgetController.dispose();
    _dateController.dispose();
    _heureController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 2)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionner la date limite',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Format français : jour/mois/année
        _dateController.text = DateFormat('dd/MM/yyyy', 'fr_FR').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Sélectionner l\'heure limite',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      hourLabelText: 'Heure',
      minuteLabelText: 'Minute',
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        // Format français 24h
        _heureController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitDemande() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedTime == null) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner une date et une heure limite',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _isLoading.value = true;

    try {
      final user = _authController.currentUser.value!;

      // Créer la date/heure limite
      final dateLimite = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final demande = DemandeCoursModel(
        clientId: user.id,
        clientNom: user.nomComplet,
        clientEmail: user.email,
        clientTelephone: user.telephone,
        lieu: _lieuController.text.trim(),
        tache: _tacheController.text.trim(),
        instructions:
            '${_instructionsController.text.trim()}\n\nDétails:\n- Type de tâche: $_typeTache\n- Budget estimé: ${_budgetController.text} FCFA\n- Date limite: ${DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(dateLimite)}\n- Priorité: $_priorite\n- Urgente: ${_isUrgent ? 'Oui' : 'Non'}',
        statut: 'enAttenteValidation',
      );

      await _demandeController.creerDemandeCourse(demande);

      Get.back();
      Get.snackbar(
        'Demande envoyée',
        'Votre demande de commissionnement a été envoyée avec succès. Vous recevrez une confirmation par email.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer la demande: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demande de Commissionnement'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          double padding = isMobile ? 16.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 600,
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // En-tête
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.assignment,
                                  color: Color(0xFF2E7D32),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nouvelle Demande de Commissionnement',
                                      style: TextStyle(
                                        fontSize: isMobile ? 18 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Décrivez la tâche à effectuer',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Lieu et tâche
                          TextFormField(
                            controller: _lieuController,
                            decoration: const InputDecoration(
                              labelText: 'Lieu de la tâche',
                              prefixIcon: Icon(Icons.location_on),
                              hintText: 'Ex: Marché de Cocody, Pharmacie du Plateau',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Lieu de la tâche requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _tacheController,
                            decoration: const InputDecoration(
                              labelText: 'Description de la tâche',
                              prefixIcon: Icon(Icons.task),
                              hintText: 'Ex: Acheter des médicaments, Retirer un document',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Description de la tâche requise';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _budgetController,
                            decoration: const InputDecoration(
                              labelText: 'Budget estimé (FCFA)',
                              prefixIcon: Icon(Icons.attach_money),
                              hintText: 'Ex: 50000',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Budget estimé requis';
                              }
                              final budget = double.tryParse(value);
                              if (budget == null || budget <= 0) {
                                return 'Budget invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Date et Heure
                          if (isMobile) ...[
                            // Mobile : Layout vertical
                            TextFormField(
                              controller: _dateController,
                              decoration: const InputDecoration(
                                labelText: 'Date limite',
                                prefixIcon: Icon(Icons.calendar_today),
                                hintText: 'Quand la tâche doit être terminée',
                              ),
                              readOnly: true,
                              onTap: _selectDate,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Date limite requise';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _heureController,
                              decoration: const InputDecoration(
                                labelText: 'Heure limite',
                                prefixIcon: Icon(Icons.access_time),
                                hintText: 'Heure limite pour la tâche',
                              ),
                              readOnly: true,
                              onTap: _selectTime,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Heure limite requise';
                                }
                                return null;
                              },
                            ),
                          ] else ...[
                            // Desktop : Layout horizontal
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _dateController,
                                    decoration: const InputDecoration(
                                      labelText: 'Date limite',
                                      prefixIcon: Icon(Icons.calendar_today),
                                      hintText: 'Quand la tâche doit être terminée',
                                    ),
                                    readOnly: true,
                                    onTap: _selectDate,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Date limite requise';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _heureController,
                                    decoration: const InputDecoration(
                                      labelText: 'Heure limite',
                                      prefixIcon: Icon(Icons.access_time),
                                      hintText: 'Heure limite pour la tâche',
                                    ),
                                    readOnly: true,
                                    onTap: _selectTime,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Heure limite requise';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Type de tâche
                          const Text(
                            'Type de tâche',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Achat'),
                                selected: _typeTache == 'achat',
                                selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: _typeTache == 'achat' ? const Color(0xFF2E7D32) : Colors.grey[700],
                                  fontWeight: _typeTache == 'achat' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _typeTache = 'achat');
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Retrait document'),
                                selected: _typeTache == 'retrait',
                                selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: _typeTache == 'retrait' ? const Color(0xFF2E7D32) : Colors.grey[700],
                                  fontWeight: _typeTache == 'retrait' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _typeTache = 'retrait');
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Livraison'),
                                selected: _typeTache == 'livraison',
                                selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: _typeTache == 'livraison' ? const Color(0xFF2E7D32) : Colors.grey[700],
                                  fontWeight: _typeTache == 'livraison' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _typeTache = 'livraison');
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Autre'),
                                selected: _typeTache == 'autre',
                                selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: _typeTache == 'autre' ? const Color(0xFF2E7D32) : Colors.grey[700],
                                  fontWeight: _typeTache == 'autre' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _typeTache = 'autre');
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Priorité
                          const Text(
                            'Priorité',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Normale'),
                                selected: _priorite == 'normale',
                                selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: _priorite == 'normale' ? const Color(0xFF2E7D32) : Colors.grey[700],
                                  fontWeight: _priorite == 'normale' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _priorite = 'normale');
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Élevée'),
                                selected: _priorite == 'elevee',
                                selectedColor: Colors.orange.withOpacity(0.2),
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: _priorite == 'elevee' ? Colors.orange[700] : Colors.grey[700],
                                  fontWeight: _priorite == 'elevee' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _priorite = 'elevee');
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Urgente'),
                                selected: _priorite == 'urgente',
                                selectedColor: Colors.red.withOpacity(0.2),
                                backgroundColor: Colors.grey[200],
                                labelStyle: TextStyle(
                                  color: _priorite == 'urgente' ? Colors.red[700] : Colors.grey[700],
                                  fontWeight: _priorite == 'urgente' ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _priorite = 'urgente');
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Options
                          SwitchListTile(
                            title: const Text('Tâche urgente'),
                            subtitle: const Text('Priorité maximale (commission majorée)'),
                            value: _isUrgent,
                            onChanged: (value) {
                              setState(() => _isUrgent = value);
                            },
                            activeColor: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(height: 16),

                          // Instructions détaillées
                          TextFormField(
                            controller: _instructionsController,
                            decoration: const InputDecoration(
                              labelText: 'Instructions détaillées',
                              prefixIcon: Icon(Icons.description),
                              hintText: 'Précisions importantes, liste d\'achats, etc.',
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Instructions détaillées requises';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Bouton de soumission
                          Obx(() => SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isLoading.value ? null : _submitDemande,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading.value
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Envoyer la demande',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
