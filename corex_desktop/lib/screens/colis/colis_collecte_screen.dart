import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:uuid/uuid.dart';

class ColisCollecteScreen extends StatefulWidget {
  const ColisCollecteScreen({super.key});

  @override
  State<ColisCollecteScreen> createState() => _ColisCollecteScreenState();
}

class _ColisCollecteScreenState extends State<ColisCollecteScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Expéditeur
  final _expediteurNomController = TextEditingController();
  final _expediteurTelController = TextEditingController();
  final _expediteurAdresseController = TextEditingController();

  // Destinataire
  final _destinataireNomController = TextEditingController();
  final _destinataireTelController = TextEditingController();
  final _destinataireAdresseController = TextEditingController();
  final _destinataireVilleController = TextEditingController();
  final _destinataireQuartierController = TextEditingController();

  // Colis
  final _contenuController = TextEditingController();
  final _poidsController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _tarifController = TextEditingController();

  String _modeLivraison = 'domicile';
  // String? _selectedZoneId; // À utiliser dans la tâche 3.2
  String? _selectedAgenceTransportId;
  bool _isPaye = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _expediteurNomController.dispose();
    _expediteurTelController.dispose();
    _expediteurAdresseController.dispose();
    _destinataireNomController.dispose();
    _destinataireTelController.dispose();
    _destinataireAdresseController.dispose();
    _destinataireVilleController.dispose();
    _destinataireQuartierController.dispose();
    _contenuController.dispose();
    _poidsController.dispose();
    _dimensionsController.dispose();
    _tarifController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar(
        'Erreur',
        'Veuillez remplir tous les champs obligatoires',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value!;

      // Initialiser le ColisController s'il n'existe pas
      if (!Get.isRegistered<ColisController>()) {
        Get.put(ColisController());
      }

      final colis = ColisModel(
        id: const Uuid().v4(),
        numeroSuivi: '', // Sera généré lors de l'enregistrement
        expediteurNom: _expediteurNomController.text.trim(),
        expediteurTelephone: _expediteurTelController.text.trim(),
        expediteurAdresse: _expediteurAdresseController.text.trim(),
        destinataireNom: _destinataireNomController.text.trim(),
        destinataireTelephone: _destinataireTelController.text.trim(),
        destinataireAdresse: _destinataireAdresseController.text.trim(),
        destinataireVille: _destinataireVilleController.text.trim(),
        destinataireQuartier: _destinataireQuartierController.text.trim().isEmpty ? null : _destinataireQuartierController.text.trim(),
        contenu: _contenuController.text.trim(),
        poids: double.parse(_poidsController.text),
        dimensions: _dimensionsController.text.trim().isEmpty ? null : _dimensionsController.text.trim(),
        montantTarif: double.parse(_tarifController.text),
        isPaye: _isPaye,
        datePaiement: _isPaye ? DateTime.now() : null,
        modeLivraison: _modeLivraison,
        agenceTransportId: _selectedAgenceTransportId,
        agenceTransportNom: null, // À compléter
        tarifAgenceTransport: null, // À compléter
        statut: StatutsColis.collecte,
        agenceCorexId: user.agenceId!,
        commercialId: user.id,
        dateCollecte: DateTime.now(),
        historique: [
          HistoriqueStatut(
            statut: StatutsColis.collecte,
            date: DateTime.now(),
            userId: user.id,
            commentaire: 'Colis collecté par ${user.nomComplet}',
          ),
        ],
      );

      final colisController = Get.find<ColisController>();
      await colisController.createColis(colis);

      if (mounted) {
        setState(() => _isLoading = false);
        Get.back();
        Get.snackbar(
          'Succès',
          'Colis collecté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ [COLLECTE] Erreur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      Get.snackbar(
        'Erreur',
        'Impossible de créer le colis: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collecte de Colis'),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _handleSubmit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            } else {
              Get.back();
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep == 3 ? 'Enregistrer' : 'Suivant'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isLoading ? null : details.onStepCancel,
                    child: Text(_currentStep == 0 ? 'Annuler' : 'Précédent'),
                  ),
                ],
              ),
            );
          },
          steps: [
            // Étape 1 : Expéditeur
            Step(
              title: const Text('Expéditeur'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _expediteurNomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Le nom'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expediteurTelController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '6XXXXXXXX',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expediteurAdresseController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse *',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'L\'adresse'),
                  ),
                ],
              ),
            ),

            // Étape 2 : Destinataire
            Step(
              title: const Text('Destinataire'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _destinataireNomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom complet *',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Le nom'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destinataireTelController,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone *',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '6XXXXXXXX',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destinataireVilleController,
                    decoration: const InputDecoration(
                      labelText: 'Ville *',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'La ville'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destinataireAdresseController,
                    decoration: const InputDecoration(
                      labelText: 'Adresse *',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'L\'adresse'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destinataireQuartierController,
                    decoration: const InputDecoration(
                      labelText: 'Quartier (optionnel)',
                      prefixIcon: Icon(Icons.map),
                    ),
                  ),
                ],
              ),
            ),

            // Étape 3 : Détails du colis
            Step(
              title: const Text('Détails du colis'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _contenuController,
                    decoration: const InputDecoration(
                      labelText: 'Contenu *',
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Le contenu'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _poidsController,
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg) *',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => Validators.validatePositiveNumber(value, 'Le poids'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dimensionsController,
                    decoration: const InputDecoration(
                      labelText: 'Dimensions (optionnel)',
                      prefixIcon: Icon(Icons.straighten),
                      hintText: 'Ex: 30x20x10 cm',
                    ),
                  ),
                ],
              ),
            ),

            // Étape 4 : Tarif et paiement
            Step(
              title: const Text('Tarif et paiement'),
              isActive: _currentStep >= 3,
              content: Column(
                children: [
                  TextFormField(
                    controller: _tarifController,
                    decoration: const InputDecoration(
                      labelText: 'Montant (FCFA) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => Validators.validatePositiveNumber(value, 'Le montant'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _modeLivraison,
                    decoration: const InputDecoration(
                      labelText: 'Mode de livraison *',
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'domicile', child: Text('Livraison à domicile')),
                      DropdownMenuItem(value: 'bureauCorex', child: Text('Bureau COREX')),
                      DropdownMenuItem(value: 'agenceTransport', child: Text('Agence de transport')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _modeLivraison = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Payé'),
                    value: _isPaye,
                    onChanged: (value) {
                      setState(() => _isPaye = value ?? false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
