import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/services/client_service.dart';
import 'package:corex_shared/services/colis_service.dart';
import 'package:corex_shared/services/zone_service.dart';
import 'package:corex_shared/services/agence_transport_service.dart';
import 'package:corex_shared/models/client_model.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:corex_shared/models/zone_model.dart';
import 'package:corex_shared/models/agence_transport_model.dart';
import 'package:uuid/uuid.dart';
import '../../theme/corex_theme.dart';
import 'colis_details_screen.dart';

class NouvelleCollecteScreen extends StatefulWidget {
  final ClientModel? expediteurPreRempli;
  final void Function(String colisId)? onCollecteCreee;
  final String? contenuPreRempli;
  final double? valeurDeclareePreRemplie;

  const NouvelleCollecteScreen({
    super.key,
    this.expediteurPreRempli,
    this.onCollecteCreee,
    this.contenuPreRempli,
    this.valeurDeclareePreRemplie,
  });

  @override
  State<NouvelleCollecteScreen> createState() => _NouvelleCollecteScreenState();
}

class _NouvelleCollecteScreenState extends State<NouvelleCollecteScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Services
  late final ClientService _clientService;
  late final ColisService _colisService;
  late final AuthController _authController;

  // Expéditeur
  final _expediteurSearchController = TextEditingController();
  final _expediteurNomController = TextEditingController();
  final _expediteurTelController = TextEditingController();
  final _expediteurAdresseController = TextEditingController();
  final _expediteurVilleController = TextEditingController();
  final _expediteurEmailController = TextEditingController();
  ClientModel? _expediteurExistant;

  // Destinataire
  final _destinataireSearchController = TextEditingController();
  final _destinataireNomController = TextEditingController();
  final _destinataireTelController = TextEditingController();
  final _destinataireAdresseController = TextEditingController();
  final _destinataireVilleController = TextEditingController();
  final _destinataireQuartierController = TextEditingController();
  final _destinataireEmailController = TextEditingController();
  ClientModel? _destinataireExistant;

  // Détails du colis
  final _contenuController = TextEditingController();
  final _poidsController = TextEditingController();
  final _dimensionsController = TextEditingController();
  final _valeurDeclareeController = TextEditingController();

  // Tarification
  final _fraisLivraisonController = TextEditingController();
  final _fraisCollecteController = TextEditingController();
  final _commissionVenteController = TextEditingController();
  String _modeLivraison = 'domicile';
  String? _selectedZoneId;
  String? _selectedAgenceTransportId;
  final RxList<ZoneModel> _zonesList = <ZoneModel>[].obs;
  final RxList<AgenceTransportModel> _agencesTransportList = <AgenceTransportModel>[].obs;

  // État
  final _isLoading = false.obs;

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<ClientService>()) Get.put(ClientService(), permanent: true);
    if (!Get.isRegistered<ColisService>()) Get.put(ColisService(), permanent: true);
    if (!Get.isRegistered<AuthController>()) Get.put(AuthController(), permanent: true);

    _loadZones();
    _loadAgencesTransport();

    _clientService = Get.find<ClientService>();
    _colisService = Get.find<ColisService>();
    _authController = Get.find<AuthController>();

    // Pré-remplir l'expéditeur si fourni (ex: depuis un retrait de stock)
    if (widget.expediteurPreRempli != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _remplirExpediteur(widget.expediteurPreRempli!);
      });
    }

    // Pré-remplir contenu et valeur déclarée si fournis (ex: depuis un dépôt)
    if (widget.contenuPreRempli != null) {
      _contenuController.text = widget.contenuPreRempli!;
    }
    if (widget.valeurDeclareePreRemplie != null) {
      _valeurDeclareeController.text = widget.valeurDeclareePreRemplie!.toStringAsFixed(0);
    }
  }

  Future<void> _loadZones() async {
    try {
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
    _expediteurSearchController.dispose();
    _expediteurNomController.dispose();
    _expediteurTelController.dispose();
    _expediteurAdresseController.dispose();
    _expediteurVilleController.dispose();
    _expediteurEmailController.dispose();
    _destinataireSearchController.dispose();
    _destinataireNomController.dispose();
    _destinataireTelController.dispose();
    _destinataireAdresseController.dispose();
    _destinataireVilleController.dispose();
    _destinataireQuartierController.dispose();
    _destinataireEmailController.dispose();
    _contenuController.dispose();
    _poidsController.dispose();
    _dimensionsController.dispose();
    _valeurDeclareeController.dispose();
    _fraisLivraisonController.dispose();
    _fraisCollecteController.dispose();
    _commissionVenteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Collecte de Colis'),
        backgroundColor: CorexTheme.primaryGreen,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CorexTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_currentStep == 2 ? 'Valider' : 'Suivant'),
                    ),
                    const SizedBox(width: 12),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Retour'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Expéditeur'),
                content: _buildExpediteurStep(),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Destinataire'),
                content: _buildDestinataireStep(),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Détails du colis'),
                content: _buildColisDetailsStep(),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpediteurStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rechercher un expéditeur existant',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Autocomplete<ClientModel>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty || textEditingValue.text.length < 2) {
              return const Iterable<ClientModel>.empty();
            }
            try {
              final agenceId = _authController.currentUser.value?.agenceId;
              if (agenceId == null) return const Iterable<ClientModel>.empty();

              final clients = await _clientService.searchClientsMultiCriteria(
                textEditingValue.text,
                agenceId,
              );
              return clients;
            } catch (e) {
              print('❌ Erreur recherche expéditeur: $e');
              return const Iterable<ClientModel>.empty();
            }
          },
          displayStringForOption: (ClientModel client) => '${client.nom} - ${client.telephone}',
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _expediteurSearchController.text = controller.text;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Tapez le nom, téléphone ou email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          _expediteurSearchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                helperText: 'Minimum 2 caractères pour la recherche',
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final client = options.elementAt(index);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: CorexTheme.primaryGreen,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          client.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${client.telephone}\n${client.ville} - ${client.adresse}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        onTap: () => onSelected(client),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (ClientModel client) {
            _remplirExpediteur(client);
          },
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Informations de l\'expéditeur',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _expediteurNomController,
          decoration: InputDecoration(
            labelText: 'Nom complet *',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Nom requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _expediteurTelController,
          decoration: InputDecoration(
            labelText: 'Téléphone *',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty ?? true ? 'Téléphone requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _expediteurVilleController,
          decoration: InputDecoration(
            labelText: 'Ville *',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Ville requise' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _expediteurAdresseController,
          decoration: InputDecoration(
            labelText: 'Adresse *',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Adresse requise' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _expediteurEmailController,
          decoration: InputDecoration(
            labelText: 'Email (optionnel)',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildDestinataireStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rechercher un destinataire existant',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Autocomplete<ClientModel>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty || textEditingValue.text.length < 2) {
              return const Iterable<ClientModel>.empty();
            }
            try {
              final agenceId = _authController.currentUser.value?.agenceId;
              if (agenceId == null) return const Iterable<ClientModel>.empty();

              final clients = await _clientService.searchClientsMultiCriteria(
                textEditingValue.text,
                agenceId,
              );
              return clients;
            } catch (e) {
              print('❌ Erreur recherche destinataire: $e');
              return const Iterable<ClientModel>.empty();
            }
          },
          displayStringForOption: (ClientModel client) => '${client.nom} - ${client.telephone}',
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _destinataireSearchController.text = controller.text;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Tapez le nom, téléphone ou email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          _destinataireSearchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                helperText: 'Minimum 2 caractères pour la recherche',
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final client = options.elementAt(index);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: CorexTheme.primaryGreen,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          client.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${client.telephone}\n${client.ville} - ${client.adresse}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        onTap: () => onSelected(client),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (ClientModel client) {
            _remplirDestinataire(client);
          },
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Informations du destinataire',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _destinataireNomController,
          decoration: InputDecoration(
            labelText: 'Nom complet *',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Nom requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _destinataireTelController,
          decoration: InputDecoration(
            labelText: 'Téléphone *',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty ?? true ? 'Téléphone requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _destinataireVilleController,
          decoration: InputDecoration(
            labelText: 'Ville *',
            prefixIcon: const Icon(Icons.location_city),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Ville requise' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _destinataireAdresseController,
          decoration: InputDecoration(
            labelText: 'Adresse *',
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Adresse requise' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _destinataireQuartierController,
          decoration: InputDecoration(
            labelText: 'Quartier (optionnel)',
            prefixIcon: const Icon(Icons.map),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _destinataireEmailController,
          decoration: InputDecoration(
            labelText: 'Email (optionnel)',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildColisDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails du colis',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contenuController,
          decoration: InputDecoration(
            labelText: 'Contenu *',
            prefixIcon: const Icon(Icons.inventory),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Contenu requis' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _poidsController,
          decoration: InputDecoration(
            labelText: 'Poids (kg) - Optionnel',
            prefixIcon: const Icon(Icons.scale),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            helperText: 'Laissez vide si non pesé',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
              return 'Poids invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _valeurDeclareeController,
          decoration: InputDecoration(
            labelText: 'Valeur déclarée (FCFA) - Optionnel',
            prefixIcon: const Icon(Icons.monetization_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            helperText: 'Valeur estimée du contenu du colis',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
              return 'Valeur invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dimensionsController,
          decoration: InputDecoration(
            labelText: 'Dimensions (optionnel)',
            prefixIcon: const Icon(Icons.straighten),
            hintText: 'Ex: 30x20x10 cm',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Mode de livraison',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _modeLivraison,
          decoration: InputDecoration(
            labelText: 'Mode de livraison *',
            prefixIcon: const Icon(Icons.local_shipping),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              decoration: InputDecoration(
                labelText: 'Zone de livraison *',
                prefixIcon: const Icon(Icons.map),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
              decoration: InputDecoration(
                labelText: 'Agence de transport *',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Tarification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

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
                    Text('Frais de livraison', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Montant encaissé par Corex pour le service de livraison.', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _fraisLivraisonController,
                  decoration: InputDecoration(
                    labelText: 'Frais de livraison (FCFA) *',
                    prefixIcon: const Icon(Icons.local_shipping),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Montant requis';
                    if (double.tryParse(value!) == null) return 'Montant invalide';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Frais de collecte
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
                    Text('Frais de collecte (transit)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Montant collecté pour le compte du vendeur — à lui reverser. Ne rentre pas dans la caisse Corex.', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _fraisCollecteController,
                  decoration: InputDecoration(
                    labelText: 'Montant à collecter (FCFA)',
                    hintText: 'Ex: valeur de la marchandise',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && double.tryParse(value) == null) return 'Montant invalide';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Commission vente
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
                    Text('Commission vente (optionnel)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade800, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Montant que le vendeur paie à Corex en tant qu\'intermédiaire dans la vente.', style: TextStyle(fontSize: 12, color: Colors.purple.shade700)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _commissionVenteController,
                  decoration: InputDecoration(
                    labelText: 'Commission (FCFA)',
                    hintText: '0 si non applicable',
                    prefixIcon: const Icon(Icons.handshake),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && double.tryParse(value) == null) return 'Montant invalide';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

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
                    const Text('Récapitulatif', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blue)),
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
    );
  }

  Widget _recapLigne(String label, String valeur, Color color, {bool bold = false}) {
    final montant = double.tryParse(valeur) ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('${montant.toStringAsFixed(0)} FCFA', style: TextStyle(fontSize: 13, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  void _remplirExpediteur(ClientModel client) {
    setState(() {
      _expediteurExistant = client;
      _expediteurNomController.text = client.nom;
      _expediteurTelController.text = client.telephone;
      _expediteurAdresseController.text = client.adresse;
      _expediteurVilleController.text = client.ville;
      _expediteurEmailController.text = client.email ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Client sélectionné: ${client.nom}'),
        backgroundColor: CorexTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _remplirDestinataire(ClientModel client) {
    setState(() {
      _destinataireExistant = client;
      _destinataireNomController.text = client.nom;
      _destinataireTelController.text = client.telephone;
      _destinataireAdresseController.text = client.adresse;
      _destinataireVilleController.text = client.ville;
      _destinataireQuartierController.text = client.quartier ?? '';
      _destinataireEmailController.text = client.email ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Client sélectionné: ${client.nom}'),
        backgroundColor: CorexTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
      }
    } else {
      _validerEtCreer();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Get.back();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _expediteurNomController.text.isNotEmpty && _expediteurTelController.text.isNotEmpty && _expediteurVilleController.text.isNotEmpty && _expediteurAdresseController.text.isNotEmpty;
      case 1:
        return _destinataireNomController.text.isNotEmpty &&
            _destinataireTelController.text.isNotEmpty &&
            _destinataireVilleController.text.isNotEmpty &&
            _destinataireAdresseController.text.isNotEmpty;
      case 2:
        return _formKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  Future<void> _validerEtCreer() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;
    try {
      final agenceId = _authController.currentUser.value?.agenceId;
      final userId = _authController.currentUser.value?.id;
      if (agenceId == null || userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // 1. Créer ou récupérer l'expéditeur
      String expediteurId;
      if (_expediteurExistant != null) {
        expediteurId = _expediteurExistant!.id;
        print('✅ Expéditeur existant utilisé: ${_expediteurExistant!.nom}');
      } else {
        final expediteur = ClientModel(
          id: '',
          nom: _expediteurNomController.text.trim(),
          telephone: _expediteurTelController.text.trim(),
          email: _expediteurEmailController.text.trim().isEmpty ? null : _expediteurEmailController.text.trim(),
          adresse: _expediteurAdresseController.text.trim(),
          ville: _expediteurVilleController.text.trim(),
          quartier: null,
          type: 'expediteur',
          agenceId: agenceId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expediteurId = await _clientService.createClient(expediteur);
        print('✅ Nouvel expéditeur créé: ${expediteur.nom}');
      }

      // 2. Créer ou récupérer le destinataire
      String destinataireId;
      if (_destinataireExistant != null) {
        destinataireId = _destinataireExistant!.id;
        print('✅ Destinataire existant utilisé: ${_destinataireExistant!.nom}');
      } else {
        final destinataire = ClientModel(
          id: '',
          nom: _destinataireNomController.text.trim(),
          telephone: _destinataireTelController.text.trim(),
          email: _destinataireEmailController.text.trim().isEmpty ? null : _destinataireEmailController.text.trim(),
          adresse: _destinataireAdresseController.text.trim(),
          ville: _destinataireVilleController.text.trim(),
          quartier: _destinataireQuartierController.text.trim().isEmpty ? null : _destinataireQuartierController.text.trim(),
          type: 'destinataire',
          agenceId: agenceId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        destinataireId = await _clientService.createClient(destinataire);
        print('✅ Nouveau destinataire créé: ${destinataire.nom}');
      }

      // 3. Créer le colis
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

      final fraisLivraison = double.tryParse(_fraisLivraisonController.text.trim()) ?? 0;
      final fraisCollecte = double.tryParse(_fraisCollecteController.text.trim()) ?? 0;
      final commissionVente = double.tryParse(_commissionVenteController.text.trim()) ?? 0;
      final montantTotal = fraisLivraison + fraisCollecte + commissionVente;

      final colis = ColisModel(
        id: const Uuid().v4(),
        numeroSuivi: '',
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
        poids: _poidsController.text.trim().isEmpty ? null : double.tryParse(_poidsController.text.trim()),
        dimensions: _dimensionsController.text.trim().isEmpty ? null : _dimensionsController.text.trim(),
        valeurDeclaree: _valeurDeclareeController.text.trim().isEmpty ? null : double.tryParse(_valeurDeclareeController.text.trim()),
        modeLivraison: _modeLivraison,
        zoneId: _selectedZoneId,
        agenceTransportId: _selectedAgenceTransportId,
        agenceTransportNom: agenceTransportNom,
        tarifAgenceTransport: tarifAgenceTransport,
        statut: 'collecte',
        montantTarif: montantTotal,
        fraisLivraison: fraisLivraison,
        fraisCollecte: fraisCollecte,
        commissionVente: commissionVente,
        isPaye: false,
        agenceCorexId: agenceId,
        commercialId: userId,
        dateCollecte: DateTime.now(),
        historique: [
          HistoriqueStatut(
            statut: 'collecte',
            date: DateTime.now(),
            userId: userId,
            commentaire: 'Colis collecté',
          ),
        ],
        isRetour: false,
      );

      await _colisService.createColis(colis);
      print('✅ Colis créé avec succès');

      if (mounted) {
        _isLoading.value = false;
        // Déclencher le callback de stock si fourni (retrait via collecte)
        if (widget.onCollecteCreee != null) {
          widget.onCollecteCreee!(colis.id);
        }
        _showPostCollecteDialog(colis);
      }
    } catch (e) {
      print('❌ Erreur création colis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible de créer le colis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void _showPostCollecteDialog(ColisModel colis) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('Colis collecté'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Numéro: ${colis.numeroSuivi}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Expéditeur: ${colis.expediteurNom}'),
            Text('Destinataire: ${colis.destinataireNom}'),
            const SizedBox(height: 12),
            const Text('Que souhaitez-vous faire ?'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Get.back(); // fermer dialog
              // Nouvelle collecte : rester sur l'écran (reset form)
              _resetForm();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle collecte'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back(); // fermer dialog
              // Naviguer vers ColisDetailsScreen (page complète avec impression)
              Get.to(() => ColisDetailsScreen(colis: colis));
            },
            icon: const Icon(Icons.assignment_turned_in),
            label: const Text('Enregistrer le colis'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _resetForm() {
    _expediteurNomController.clear();
    _expediteurTelController.clear();
    _expediteurAdresseController.clear();
    _expediteurVilleController.clear();
    _expediteurEmailController.clear();
    _expediteurSearchController.clear();
    _expediteurExistant = null;
    _destinataireNomController.clear();
    _destinataireTelController.clear();
    _destinataireAdresseController.clear();
    _destinataireVilleController.clear();
    _destinataireQuartierController.clear();
    _destinataireEmailController.clear();
    _destinataireSearchController.clear();
    _destinataireExistant = null;
    _contenuController.clear();
    _poidsController.clear();
    _dimensionsController.clear();
    _fraisLivraisonController.clear();
    _fraisCollecteController.clear();
    _commissionVenteController.clear();
    setState(() {
      _currentStep = 0;
      _modeLivraison = 'domicile';
      _selectedZoneId = null;
      _selectedAgenceTransportId = null;
    });
  }
}
