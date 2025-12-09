import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/controllers/livraison_controller.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:corex_shared/models/user_model.dart';
import 'package:corex_shared/services/colis_service.dart';
import 'package:corex_shared/services/user_service.dart';

class AttributionLivraisonScreen extends StatefulWidget {
  const AttributionLivraisonScreen({super.key});

  @override
  State<AttributionLivraisonScreen> createState() => _AttributionLivraisonScreenState();
}

class _AttributionLivraisonScreenState extends State<AttributionLivraisonScreen> {
  final ColisService _colisService = Get.find<ColisService>();
  final UserService _userService = Get.find<UserService>();
  final AuthController _authController = Get.find<AuthController>();
  final LivraisonController _livraisonController = Get.find<LivraisonController>();

  List<ColisModel> _colisALivrer = [];
  List<UserModel> _coursiers = [];
  List<ColisModel> _filteredColis = [];
  bool _isLoading = true;
  String _selectedZone = 'tous';
  final Set<String> _zones = {'tous'};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = _authController.currentUser.value;
      if (user == null || user.agenceId == null) return;

      // Charger les colis avec statut "arriveDestination"
      final allColis = await _colisService.getColisByAgence(user.agenceId!);
      _colisALivrer = allColis.where((c) => c.statut == 'arriveDestination').toList();

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
      Get.snackbar('Erreur', 'Impossible de charger les données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      if (_selectedZone == 'tous') {
        _filteredColis = _colisALivrer;
      } else {
        _filteredColis = _colisALivrer.where((c) => c.zoneId == _selectedZone).toList();
      }
    });
  }

  void _showAttributionDialog(ColisModel colis) {
    UserModel? selectedCoursier;
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
                  const SizedBox(height: 8),
                  Text('Destinataire: ${colis.destinataireNom}'),
                  Text('Téléphone: ${colis.destinataireTelephone}'),
                  Text('Adresse: ${colis.destinataireAdresse}'),
                  if (colis.destinataireQuartier != null) Text('Quartier: ${colis.destinataireQuartier}'),
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
                        Get.snackbar('Erreur', 'Veuillez saisir un montant valide');
                        return;
                      }
                      montantController.dispose();
                      Navigator.pop(context);
                      await _attribuerLivraison(
                        colis,
                        selectedCoursier!,
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
    bool paiementALaLivraison = false,
    double? montantACollecte,
  }) async {
    try {
      await _livraisonController.attribuerLivraison(
        colis: colis,
        coursier: coursier,
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
      child: Row(
        children: [
          const Text('Filtrer par zone:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _selectedZone,
            items: _zones.map((zone) {
              return DropdownMenuItem(
                value: zone,
                child: Text(zone == 'tous' ? 'Toutes les zones' : zone),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedZone = value ?? 'tous';
                _applyFilters();
              });
            },
          ),
          const Spacer(),
          Text(
            '${_filteredColis.length} colis à livrer',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Destinataire: ${colis.destinataireNom}'),
                  Text('Téléphone: ${colis.destinataireTelephone}'),
                  Text('Adresse: ${colis.destinataireAdresse}'),
                  if (colis.destinataireQuartier != null) Text('Quartier: ${colis.destinataireQuartier}'),
                  const SizedBox(height: 4),
                  Text(
                    'Contenu: ${colis.contenu} (${colis.poids} kg)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
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
