import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/connection_indicator.dart';
import '../../widgets/client_selector.dart';
import '../../widgets/sync_indicator.dart';

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
  final _expediteurEmailController = TextEditingController();
  final _expediteurAdresseController = TextEditingController();
  final _expediteurVilleController = TextEditingController();

  // Destinataire
  final _destinataireNomController = TextEditingController();
  final _destinataireTelController = TextEditingController();
  final _destinataireEmailController = TextEditingController();
  final _destinataireAdresseController = TextEditingController();
  final _destinataireVilleController = TextEditingController();
  final _destinataireQuartierController = TextEditingController();

  // Colis
  final _contenuController = TextEditingController();
  final _poidsController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _tarifController = TextEditingController();

  String _modeLivraison = 'domicile';
  String? _selectedZoneId;
  String? _selectedAgenceTransportId;
  final RxList<ZoneModel> _zonesList = <ZoneModel>[].obs;
  final RxList<AgenceTransportModel> _agencesTransportList = <AgenceTransportModel>[].obs;
  bool _isPaye = false;
  bool _isLoading = false;

  // Note: Les clients sélectionnés sont gérés directement par les contrôleurs de texte

  @override
  void initState() {
    super.initState();
    _loadZones();
    _loadAgencesTransport();
  }

  Future<void> _loadZones() async {
    try {
      final zoneService = Get.find<ZoneService>();
      final zones = await zoneService.getAllZones();
      _zonesList.value = zones;
    } catch (e) {
      print('❌ [COLLECTE] Erreur chargement zones: $e');
    }
  }

  Future<void> _loadAgencesTransport() async {
    try {
      final agenceTransportService = Get.find<AgenceTransportService>();
      final agences = await agenceTransportService.getAllAgencesTransport();
      _agencesTransportList.value = agences.where((a) => a.isActive).toList();
    } catch (e) {
      print('❌ [COLLECTE] Erreur chargement agences transport: $e');
    }
  }

  @override
  void dispose() {
    _expediteurNomController.dispose();
    _expediteurTelController.dispose();
    _expediteurEmailController.dispose();
    _expediteurAdresseController.dispose();
    _expediteurVilleController.dispose();
    _destinataireNomController.dispose();
    _destinataireTelController.dispose();
    _destinataireEmailController.dispose();
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

      // Vérifier que l'utilisateur a une agence
      if (user.agenceId == null || user.agenceId!.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Vous devez être assigné à une agence pour collecter des colis',
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() => _isLoading = false);
        return;
      }

      // Initialiser le ColisController s'il n'existe pas
      if (!Get.isRegistered<ColisController>()) {
        Get.put(ColisController());
      }

      // Générer le numéro de suivi local pour garantir la création
      if (!Get.isRegistered<LocalColisRepository>()) {
        Get.snackbar(
          'Erreur',
          'Service de stockage local non disponible',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => _isLoading = false);
        return;
      }

      final localRepo = Get.find<LocalColisRepository>();
      final numeroSuivi = localRepo.generateLocalNumeroSuivi();
      print('📦 [COLLECTE] Numéro de suivi local généré: $numeroSuivi');

      // Récupérer les informations de l'agence transport si sélectionnée
      String? agenceTransportNom;
      double? tarifAgenceTransport;

      if (_selectedAgenceTransportId != null) {
        final agence = _agencesTransportList.firstWhereOrNull((a) => a.id == _selectedAgenceTransportId);
        if (agence != null) {
          agenceTransportNom = agence.nom;
          final ville = _destinataireVilleController.text.trim();
          tarifAgenceTransport = agence.tarifs[ville];
        }
      }

      final colis = ColisModel(
        id: const Uuid().v4(),
        numeroSuivi: numeroSuivi,
        expediteurNom: _expediteurNomController.text.trim(),
        expediteurTelephone: _expediteurTelController.text.trim(),
        expediteurEmail: _expediteurEmailController.text.trim().isEmpty ? null : _expediteurEmailController.text.trim(),
        expediteurAdresse: _expediteurAdresseController.text.trim(),
        destinataireNom: _destinataireNomController.text.trim(),
        destinataireTelephone: _destinataireTelController.text.trim(),
        destinataireEmail: _destinataireEmailController.text.trim().isEmpty ? null : _destinataireEmailController.text.trim(),
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
        zoneId: _selectedZoneId,
        agenceTransportId: _selectedAgenceTransportId,
        agenceTransportNom: agenceTransportNom,
        tarifAgenceTransport: tarifAgenceTransport,
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
        isRetour: false, // Nouveau colis, pas un retour
        colisInitialId: null, // Pas de colis initial pour un nouveau colis
        retourId: null, // Pas de retour associé pour l'instant
      );

      final colisController = Get.find<ColisController>();
      await colisController.createColis(colis);

      // Note: La transaction financière sera créée lors de l'enregistrement du colis
      // et non plus lors de la collecte

      if (mounted) {
        setState(() => _isLoading = false);
        Get.back();

        // Vérifier si le colis est en attente de synchronisation
        final isPendingSync = localRepo.isPendingSync(colis.id);

        Get.snackbar(
          'Succès',
          isPendingSync
              ? 'Colis collecté en mode hors ligne.\nNuméro local: $numeroSuivi\nSera synchronisé automatiquement au retour en ligne.'
              : _isPaye
                  ? 'Colis collecté et paiement enregistré.\nNuméro: $numeroSuivi'
                  : 'Colis collecté avec succès.\nNuméro: $numeroSuivi',
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: isPendingSync ? 5 : 3),
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
        actions: const [
          SyncIndicator(),
          ConnectionIndicator(),
          SizedBox(width: 16),
        ],
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
              content: ClientSelector(
                label: 'Expéditeur',
                type: 'expediteur',
                onClientSelected: (client) {
                  // Le client est automatiquement rempli dans les contrôleurs
                },
                nomController: _expediteurNomController,
                telephoneController: _expediteurTelController,
                emailController: _expediteurEmailController,
                adresseController: _expediteurAdresseController,
                villeController: _expediteurVilleController,
              ),
            ),

            // Étape 2 : Destinataire
            Step(
              title: const Text('Destinataire'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: ClientSelector(
                label: 'Destinataire',
                type: 'destinataire',
                onClientSelected: (client) {
                  // Le client est automatiquement rempli dans les contrôleurs
                },
                nomController: _destinataireNomController,
                telephoneController: _destinataireTelController,
                emailController: _destinataireEmailController,
                adresseController: _destinataireAdresseController,
                villeController: _destinataireVilleController,
                quartierController: _destinataireQuartierController,
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
                        setState(() {
                          _modeLivraison = value;
                          // Réinitialiser les sélections
                          _selectedZoneId = null;
                          _selectedAgenceTransportId = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Zone de livraison (si livraison à domicile)
                  if (_modeLivraison == 'domicile') ...[
                    Obx(() {
                      final zoneExists = _selectedZoneId == null || _zonesList.any((z) => z.id == _selectedZoneId);

                      return DropdownButtonFormField<String>(
                        value: zoneExists ? _selectedZoneId : null,
                        decoration: const InputDecoration(
                          labelText: 'Zone de livraison *',
                          prefixIcon: Icon(Icons.map),
                        ),
                        items: _zonesList
                            .map((zone) => DropdownMenuItem(
                                  value: zone.id,
                                  child: Text('${zone.nom} - ${zone.tarifLivraison.toStringAsFixed(0)} FCFA'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedZoneId = value);
                        },
                        validator: (value) {
                          if (_modeLivraison == 'domicile' && value == null) {
                            return 'Veuillez sélectionner une zone';
                          }
                          return null;
                        },
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Agence de transport (si livraison par agence transport)
                  if (_modeLivraison == 'agenceTransport') ...[
                    Obx(() {
                      final agenceExists = _selectedAgenceTransportId == null || _agencesTransportList.any((a) => a.id == _selectedAgenceTransportId);

                      return DropdownButtonFormField<String>(
                        value: agenceExists ? _selectedAgenceTransportId : null,
                        decoration: const InputDecoration(
                          labelText: 'Agence de transport *',
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: _agencesTransportList
                            .map((agence) => DropdownMenuItem(
                                  value: agence.id,
                                  child: Text(agence.nom),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedAgenceTransportId = value);
                        },
                        validator: (value) {
                          if (_modeLivraison == 'agenceTransport' && value == null) {
                            return 'Veuillez sélectionner une agence';
                          }
                          return null;
                        },
                      );
                    }),
                    const SizedBox(height: 16),

                    // Afficher le tarif de l'agence transport sélectionnée
                    if (_selectedAgenceTransportId != null)
                      Obx(() {
                        final agence = _agencesTransportList.firstWhereOrNull((a) => a.id == _selectedAgenceTransportId);
                        if (agence != null) {
                          final ville = _destinataireVilleController.text.trim();
                          final tarif = agence.tarifs[ville];

                          return Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tarif != null ? 'Tarif vers $ville: ${tarif.toStringAsFixed(0)} FCFA' : 'Aucun tarif défini pour $ville',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _tarifController,
                    decoration: const InputDecoration(
                      labelText: 'Montant (FCFA) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => Validators.validatePositiveNumber(value, 'Le montant'),
                  ),
                  const SizedBox(height: 24),

                  // Section Paiement
                  Card(
                    elevation: 2,
                    color: _isPaye ? Colors.green.shade50 : Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isPaye ? Icons.check_circle : Icons.payment,
                                color: _isPaye ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Paiement',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isPaye ? Colors.green.shade900 : Colors.grey.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: Text(
                              _isPaye ? 'Colis payé' : 'Colis non payé',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              _isPaye ? 'Une transaction financière sera créée automatiquement' : 'Le paiement pourra être enregistré plus tard',
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: _isPaye,
                            activeColor: Colors.green,
                            onChanged: (value) {
                              setState(() => _isPaye = value);
                            },
                          ),
                          if (_isPaye) ...[
                            const Divider(),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Montant: ${_tarifController.text.isEmpty ? "0" : _tarifController.text} FCFA',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
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
