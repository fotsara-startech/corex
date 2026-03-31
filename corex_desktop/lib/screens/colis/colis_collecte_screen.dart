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

  // Tarification
  final _fraisLivraisonController = TextEditingController();
  final _fraisCollecteController = TextEditingController();
  final _commissionVenteController = TextEditingController();

  String _modeLivraison = 'domicile';
  String? _selectedZoneId;
  String? _selectedAgenceTransportId;
  final RxList<ZoneModel> _zonesList = <ZoneModel>[].obs;
  final RxList<AgenceTransportModel> _agencesTransportList = <AgenceTransportModel>[].obs;
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
      // Vérifier et initialiser le service si nécessaire
      if (!Get.isRegistered<ZoneService>()) {
        Get.put(ZoneService(), permanent: true);
      }
      final zoneService = Get.find<ZoneService>();
      final zones = await zoneService.getAllZones();
      _zonesList.value = zones;
    } catch (e) {
      print('❌ [COLLECTE] Erreur chargement zones: $e');
    }
  }

  Future<void> _loadAgencesTransport() async {
    try {
      // Vérifier et initialiser le service si nécessaire
      if (!Get.isRegistered<AgenceTransportService>()) {
        Get.put(AgenceTransportService(), permanent: true);
      }
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
    _fraisLivraisonController.dispose();
    _fraisCollecteController.dispose();
    _commissionVenteController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        Get.snackbar(
          'Erreur',
          'Veuillez remplir tous les champs obligatoires',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value!;

      // Vérifier que l'utilisateur a une agence
      if (user.agenceId == null || user.agenceId!.isEmpty) {
        if (mounted) {
          Get.snackbar(
            'Erreur',
            'Vous devez être assigné à une agence pour collecter des colis',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Initialiser le ColisController s'il n'existe pas
      if (!Get.isRegistered<ColisController>()) {
        Get.put(ColisController());
      }

      // Générer le numéro de suivi local pour garantir la création
      if (!Get.isRegistered<LocalColisRepository>()) {
        if (mounted) {
          Get.snackbar(
            'Erreur',
            'Service de stockage local non disponible',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
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

      final fraisLivraison = double.tryParse(_fraisLivraisonController.text) ?? 0;
      final fraisCollecte = double.tryParse(_fraisCollecteController.text) ?? 0;
      final commissionVente = double.tryParse(_commissionVenteController.text) ?? 0;
      final montantTotal = fraisLivraison + fraisCollecte + commissionVente;

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
        montantTarif: montantTotal,
        fraisLivraison: fraisLivraison,
        fraisCollecte: fraisCollecte,
        commissionVente: commissionVente,
        isPaye: false,
        datePaiement: null,
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
        isRetour: false,
        colisInitialId: null,
        retourId: null,
      );

      final colisController = Get.find<ColisController>();
      await colisController.createColis(colis);

      if (mounted) {
        setState(() => _isLoading = false);
        Get.back();

        // Vérifier si le colis est en attente de synchronisation
        final isPendingSync = localRepo.isPendingSync(colis.id);

        // Attendre un peu avant d'afficher le snackbar pour éviter les conflits
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Get.snackbar(
              'Succès',
              isPendingSync
                  ? 'Colis collecté en mode hors ligne.\nNuméro local: $numeroSuivi\nSera synchronisé automatiquement au retour en ligne.'
                  : 'Colis collecté avec succès.\nNuméro: $numeroSuivi\nPaiement à effectuer lors de l\'enregistrement.',
              snackPosition: SnackPosition.BOTTOM,
              duration: Duration(seconds: isPendingSync ? 5 : 3),
            );
          }
        });
      }
    } catch (e) {
      print('❌ [COLLECTE] Erreur: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Erreur',
          'Impossible de créer le colis: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Widget _recapLigne(String label, String valeur, Color color, {bool bold = false}) {
    final montant = double.tryParse(valeur) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${montant.toStringAsFixed(0)} FCFA',
            style: TextStyle(fontSize: 13, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collecte de Colis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () {
              _loadZones();
              _loadAgencesTransport();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Données actualisées'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SyncIndicator(),
          const ConnectionIndicator(),
          const SizedBox(width: 16),
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

            // Étape 4 : Tarif et livraison
            Step(
              title: const Text('Livraison & Tarification'),
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

                  // Tarification
                  const Text(
                    'Tarification',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Frais de livraison
                  Card(
                    elevation: 0,
                    color: Colors.green.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.green.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store, color: Colors.green.shade700, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Frais de livraison',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Montant encaissé par Corex pour le service de livraison.',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _fraisLivraisonController,
                            decoration: const InputDecoration(
                              labelText: 'Frais de livraison (FCFA) *',
                              prefixIcon: Icon(Icons.local_shipping),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (value) => Validators.validatePositiveNumber(value, 'Les frais de livraison'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Frais de collecte (montant de la vente à reverser au vendeur)
                  Card(
                    elevation: 0,
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.swap_horiz, color: Colors.orange.shade700, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Frais de collecte (transit)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Montant collecté pour le compte du vendeur — à lui reverser. Ne rentre pas dans la caisse Corex.',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _fraisCollecteController,
                            decoration: const InputDecoration(
                              labelText: 'Montant à collecter (FCFA)',
                              hintText: 'Ex: valeur de la marchandise',
                              prefixIcon: Icon(Icons.account_balance_wallet),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Commission vente (optionnelle)
                  Card(
                    elevation: 0,
                    color: Colors.purple.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.purple.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.percent, color: Colors.purple.shade700, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Commission vente (optionnel)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Montant que le vendeur paie à Corex en tant qu\'intermédiaire dans la vente.',
                            style: TextStyle(fontSize: 12, color: Colors.purple.shade700),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _commissionVenteController,
                            decoration: const InputDecoration(
                              labelText: 'Commission (FCFA)',
                              hintText: '0 si non applicable',
                              prefixIcon: Icon(Icons.handshake),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Récapitulatif
                  Card(
                    elevation: 2,
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Récapitulatif',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _recapLigne('Frais de livraison (Corex)', _fraisLivraisonController.text, Colors.green.shade700),
                          _recapLigne('Frais de collecte (transit vendeur)', _fraisCollecteController.text, Colors.orange.shade700),
                          _recapLigne('Commission vente', _commissionVenteController.text, Colors.purple.shade700),
                          const Divider(height: 16),
                          _recapLigne(
                            'Total à encaisser',
                            ((double.tryParse(_fraisLivraisonController.text) ?? 0) + (double.tryParse(_fraisCollecteController.text) ?? 0) + (double.tryParse(_commissionVenteController.text) ?? 0))
                                .toStringAsFixed(0),
                            Colors.blue.shade800,
                            bold: true,
                          ),
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
