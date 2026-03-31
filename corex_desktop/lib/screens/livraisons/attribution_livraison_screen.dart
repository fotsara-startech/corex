import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/controllers/livraison_controller.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:corex_shared/models/user_model.dart';
import 'package:corex_shared/services/colis_service.dart';
import 'package:corex_shared/services/user_service.dart';
import 'package:corex_shared/services/livraison_service.dart';
import 'package:corex_shared/constants/types_livraison.dart';

class AttributionLivraisonScreen extends StatefulWidget {
  const AttributionLivraisonScreen({super.key});

  @override
  State<AttributionLivraisonScreen> createState() => _AttributionLivraisonScreenState();
}

class _AttributionLivraisonScreenState extends State<AttributionLivraisonScreen> {
  // Services et controllers - récupérés de manière lazy
  ColisService get _colisService => Get.find<ColisService>();
  UserService get _userService => Get.find<UserService>();
  AuthController get _authController => Get.find<AuthController>();
  LivraisonController get _livraisonController => Get.find<LivraisonController>();

  List<ColisModel> _colisALivrer = [];
  List<UserModel> _coursiers = [];
  List<ColisModel> _filteredColis = [];
  bool _isLoading = true;
  String _selectedZone = 'tous';
  final Set<String> _zones = {'tous'};

  // Nouveaux filtres
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriode = 'tous';
  DateTime? _dateDebut;
  DateTime? _dateFin;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Vérifier que les services sont disponibles avant de charger les données
    _ensureServicesAndLoadData();
  }

  Future<void> _ensureServicesAndLoadData() async {
    try {
      // Vérifier que les services essentiels sont disponibles
      if (!Get.isRegistered<ColisService>()) {
        Get.put(ColisService(), permanent: true);
      }
      if (!Get.isRegistered<UserService>()) {
        Get.put(UserService(), permanent: true);
      }
      if (!Get.isRegistered<LivraisonService>()) {
        Get.put(LivraisonService(), permanent: true);
      }
      if (!Get.isRegistered<LivraisonController>()) {
        Get.put(LivraisonController(), permanent: true);
      }

      // Attendre un peu pour s'assurer que tout est prêt
      await Future.delayed(const Duration(milliseconds: 100));

      await _loadData();
    } catch (e) {
      print('❌ [ATTRIBUTION] Erreur initialisation: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Erreur',
          'Impossible d\'initialiser les services: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final user = _authController.currentUser.value;
      if (user == null || user.agenceId == null) {
        if (mounted) {
          Get.snackbar(
            'Erreur',
            'Utilisateur non connecté ou sans agence',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Charger TOUS les colis de l'agence (pas de restriction par statut)
      final allColis = await _colisService.getColisByAgence(user.agenceId!);
      _colisALivrer = allColis;

      // Extraire les zones
      for (var colis in _colisALivrer) {
        if (colis.zoneId != null && colis.zoneId!.isNotEmpty) {
          _zones.add(colis.zoneId!);
        }
      }

      // Charger les coursiers actifs de l'agence
      final allUsers = await _userService.getUsersByAgence(user.agenceId!);
      _coursiers = allUsers.where((u) => u.role == 'coursier' && u.isActive).toList();

      _applyFilters();
    } catch (e) {
      print('❌ [ATTRIBUTION] Erreur chargement: $e');
      if (mounted) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger les données: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      var filtered = _colisALivrer;

      // Filtre par zone
      if (_selectedZone != 'tous') {
        filtered = filtered.where((c) => c.zoneId == _selectedZone).toList();
      }

      // Filtre par recherche (numéro de suivi, destinataire, téléphone)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filtered = filtered.where((c) {
          return c.numeroSuivi.toLowerCase().contains(query) ||
              c.destinataireNom.toLowerCase().contains(query) ||
              c.destinataireTelephone.contains(query) ||
              (c.destinataireAdresse.toLowerCase().contains(query));
        }).toList();
      }

      // Filtre par période
      if (_selectedPeriode != 'tous') {
        final now = DateTime.now();
        DateTime? debut;
        DateTime? fin = DateTime(now.year, now.month, now.day, 23, 59, 59);

        switch (_selectedPeriode) {
          case 'aujourd_hui':
            debut = DateTime(now.year, now.month, now.day);
            break;
          case 'hier':
            final hier = now.subtract(const Duration(days: 1));
            debut = DateTime(hier.year, hier.month, hier.day);
            fin = DateTime(hier.year, hier.month, hier.day, 23, 59, 59);
            break;
          case 'cette_semaine':
            debut = now.subtract(Duration(days: now.weekday - 1));
            debut = DateTime(debut.year, debut.month, debut.day);
            break;
          case 'ce_mois':
            debut = DateTime(now.year, now.month, 1);
            break;
          case 'personnalise':
            debut = _dateDebut;
            fin = _dateFin;
            break;
        }

        if (debut != null) {
          filtered = filtered.where((c) {
            // Utiliser dateEnregistrement en priorité, sinon dateCollecte
            final dateReference = c.dateEnregistrement ?? c.dateCollecte;
            if (fin != null) {
              return dateReference.isAfter(debut!) && dateReference.isBefore(fin);
            }
            return dateReference.isAfter(debut!);
          }).toList();
        }
      }

      // Tri par date (plus récent en premier)
      // Utiliser dateEnregistrement en priorité, sinon dateCollecte
      filtered.sort((a, b) {
        final dateA = a.dateEnregistrement ?? a.dateCollecte;
        final dateB = b.dateEnregistrement ?? b.dateCollecte;
        return dateB.compareTo(dateA);
      });

      _filteredColis = filtered;
    });
  }

  void _showAttributionDialog(ColisModel colis) {
    UserModel? selectedCoursier;
    String selectedTypeLivraison = TypesLivraison.livraisonFinale;
    bool paiementALaLivraison = false;
    final montantController = TextEditingController(text: colis.montantTarif.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Attribuer une livraison'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Colis: ${colis.numeroSuivi}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Statut actuel: ${colis.statut}',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Destinataire: ${colis.destinataireNom}'),
                  Text('Téléphone: ${colis.destinataireTelephone}'),
                  Text('Adresse: ${colis.destinataireAdresse}'),
                  if (colis.destinataireQuartier != null) Text('Quartier: ${colis.destinataireQuartier}'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Type de livraison:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTypeLivraison,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: TypesLivraison.all.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(TypesLivraison.getIcon(type), style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    TypesLivraison.getLibelle(type),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    TypesLivraison.getDescription(type),
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTypeLivraison = value ?? TypesLivraison.livraisonFinale;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Sélectionner un coursier:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserModel>(
                    value: selectedCoursier,
                    decoration: const InputDecoration(
                      labelText: 'Coursier',
                      border: OutlineInputBorder(),
                    ),
                    items: _coursiers.map((coursier) {
                      return DropdownMenuItem(
                        value: coursier,
                        child: Text(coursier.nomComplet),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCoursier = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Paiement à la livraison (COD)'),
                    subtitle: const Text('Le coursier collectera le paiement lors de la livraison'),
                    value: paiementALaLivraison,
                    onChanged: (value) {
                      setDialogState(() {
                        paiementALaLivraison = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (paiementALaLivraison) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: montantController,
                      decoration: const InputDecoration(
                        labelText: 'Montant à collecter (FCFA)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                montantController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedCoursier == null
                  ? null
                  : () async {
                      final montant = paiementALaLivraison ? double.tryParse(montantController.text) : null;
                      if (paiementALaLivraison && (montant == null || montant <= 0)) {
                        Get.snackbar(
                          'Erreur',
                          'Veuillez saisir un montant valide',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 3),
                        );
                        return;
                      }
                      montantController.dispose();
                      Navigator.pop(context);
                      await _attribuerLivraison(
                        colis,
                        selectedCoursier!,
                        typeLivraison: selectedTypeLivraison,
                        paiementALaLivraison: paiementALaLivraison,
                        montantACollecte: montant,
                      );
                    },
              child: const Text('Attribuer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _attribuerLivraison(
    ColisModel colis,
    UserModel coursier, {
    required String typeLivraison,
    bool paiementALaLivraison = false,
    double? montantACollecte,
  }) async {
    try {
      await _livraisonController.attribuerLivraison(
        colis: colis,
        coursier: coursier,
        typeLivraison: typeLivraison,
        paiementALaLivraison: paiementALaLivraison,
        montantACollecte: montantACollecte,
      );
      await _loadData();
    } catch (e) {
      // L'erreur est déjà gérée dans le controller
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attribution des Livraisons'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(child: _buildColisList()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Barre de recherche
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par numéro, destinataire, téléphone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _applyFilters();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Filtres
          Row(
            children: [
              // Filtre par zone
              const Text('Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: _selectedZone,
                  underline: const SizedBox(),
                  items: _zones.map((zone) {
                    return DropdownMenuItem(
                      value: zone,
                      child: Text(zone == 'tous' ? 'Toutes' : zone),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedZone = value ?? 'tous';
                      _applyFilters();
                    });
                  },
                ),
              ),
              const SizedBox(width: 24),
              // Filtre par période
              const Text('Période:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButton<String>(
                  value: _selectedPeriode,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'tous', child: Text('Toutes')),
                    DropdownMenuItem(value: 'aujourd_hui', child: Text('Aujourd\'hui')),
                    DropdownMenuItem(value: 'hier', child: Text('Hier')),
                    DropdownMenuItem(value: 'cette_semaine', child: Text('Cette semaine')),
                    DropdownMenuItem(value: 'ce_mois', child: Text('Ce mois')),
                    DropdownMenuItem(value: 'personnalise', child: Text('Personnalisé')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriode = value ?? 'tous';
                      if (_selectedPeriode == 'personnalise') {
                        _showDateRangePicker();
                      } else {
                        _dateDebut = null;
                        _dateFin = null;
                        _applyFilters();
                      }
                    });
                  },
                ),
              ),
              if (_selectedPeriode == 'personnalise' && _dateDebut != null && _dateFin != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year} - ${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}',
                        style: TextStyle(color: Colors.blue[900], fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _dateDebut = null;
                            _dateFin = null;
                            _selectedPeriode = 'tous';
                            _applyFilters();
                          });
                        },
                        child: Icon(Icons.close, size: 16, color: Colors.blue[900]),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Compteur
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2, size: 20, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredColis.length} colis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _dateDebut != null && _dateFin != null
          ? DateTimeRange(start: _dateDebut!, end: _dateFin!)
          : DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: now,
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _applyFilters();
      });
    } else {
      // Si l'utilisateur annule, revenir à "tous"
      setState(() {
        _selectedPeriode = 'tous';
        _dateDebut = null;
        _dateFin = null;
        _applyFilters();
      });
    }
  }

  Widget _buildColisList() {
    if (_filteredColis.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun colis à livrer', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredColis.length,
      itemBuilder: (context, index) {
        final colis = _filteredColis[index];
        return _buildColisCard(colis);
      },
    );
  }

  Widget _buildColisCard(ColisModel colis) {
    // Formater la date (utiliser dateEnregistrement en priorité, sinon dateCollecte)
    final dateReference = colis.dateEnregistrement ?? colis.dateCollecte;
    final dateStr =
        '${dateReference.day.toString().padLeft(2, '0')}/${dateReference.month.toString().padLeft(2, '0')}/${dateReference.year} ${dateReference.hour.toString().padLeft(2, '0')}:${dateReference.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        colis.numeroSuivi,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          colis.zoneId ?? 'Zone non définie',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[900],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          colis.statut,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    colis.dateEnregistrement != null ? 'Enregistré le: $dateStr' : 'Collecté le: $dateStr',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Destinataire: ${colis.destinataireNom}'),
                  Text('Téléphone: ${colis.destinataireTelephone}'),
                  Text('Adresse: ${colis.destinataireAdresse}'),
                  if (colis.destinataireQuartier != null) Text('Quartier: ${colis.destinataireQuartier}'),
                  const SizedBox(height: 4),
                  Text(
                    colis.poids != null ? 'Contenu: ${colis.contenu} (${colis.poids} kg)' : 'Contenu: ${colis.contenu}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  if (colis.valeurDeclaree != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Valeur: ${colis.valeurDeclaree!.toStringAsFixed(0)} FCFA',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showAttributionDialog(colis),
              icon: const Icon(Icons.person_add),
              label: const Text('Attribuer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
