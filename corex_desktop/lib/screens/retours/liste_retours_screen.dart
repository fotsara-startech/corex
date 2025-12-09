import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/retour_controller.dart';
import 'package:corex_shared/controllers/user_controller.dart';
import 'package:corex_shared/controllers/zone_controller.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:intl/intl.dart';

class ListeRetoursScreen extends StatefulWidget {
  const ListeRetoursScreen({Key? key}) : super(key: key);

  @override
  State<ListeRetoursScreen> createState() => _ListeRetoursScreenState();
}

class _ListeRetoursScreenState extends State<ListeRetoursScreen> {
  final RetourController _retourController = Get.put(RetourController());
  final UserController _userController = Get.find<UserController>();

  String _selectedStatut = 'tous';
  final List<String> _statuts = [
    'tous',
    'collecte',
    'enregistre',
    'enTransit',
    'arriveDestination',
    'enCoursLivraison',
    'livre',
  ];

  @override
  void initState() {
    super.initState();
    _retourController.loadRetours();
  }

  List<ColisModel> _getFilteredRetours() {
    if (_selectedStatut == 'tous') {
      return _retourController.retours;
    }
    return _retourController.getRetoursByStatut(_selectedStatut);
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'collecte':
        return 'Collecté';
      case 'enregistre':
        return 'Enregistré';
      case 'enTransit':
        return 'En Transit';
      case 'arriveDestination':
        return 'Arrivé';
      case 'enCoursLivraison':
        return 'En Livraison';
      case 'livre':
        return 'Livré';
      default:
        return statut;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'collecte':
        return Colors.orange;
      case 'enregistre':
        return Colors.blue;
      case 'enTransit':
        return Colors.purple;
      case 'arriveDestination':
        return Colors.teal;
      case 'enCoursLivraison':
        return Colors.indigo;
      case 'livre':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showAttribuerDialog(ColisModel retour) async {
    final coursiers = _userController.usersList.where((u) => u.role == 'coursier' && u.isActive).toList();

    if (coursiers.isEmpty) {
      Get.snackbar('Erreur', 'Aucun coursier actif disponible');
      return;
    }

    String? selectedCoursierId;
    String? selectedZoneId;

    // Charger les zones disponibles
    final zoneController = Get.find<ZoneController>();
    await zoneController.loadZones();
    final zones = zoneController.zonesList;

    await Get.dialog(
      AlertDialog(
        title: const Text('Attribuer le retour'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (retour.zoneId == null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Zone non définie. Veuillez sélectionner une zone de livraison.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Zone de livraison:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Zone',
                  ),
                  items: zones.map((zone) {
                    return DropdownMenuItem(
                      value: zone.id,
                      child: Text(zone.nom),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedZoneId = value;
                  },
                  validator: (value) {
                    if (retour.zoneId == null && value == null) {
                      return 'Veuillez sélectionner une zone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              const Text('Coursier:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Coursier',
                ),
                items: coursiers.map((coursier) {
                  return DropdownMenuItem(
                    value: coursier.id,
                    child: Text('${coursier.nom} ${coursier.prenom}'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCoursierId = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedCoursierId != null) {
                // Vérifier que la zone est définie
                if (retour.zoneId == null && selectedZoneId == null) {
                  Get.snackbar('Erreur', 'Veuillez sélectionner une zone de livraison');
                  return;
                }

                Get.back();
                await _retourController.attribuerRetour(
                  retour.id,
                  selectedCoursierId!,
                  zoneId: selectedZoneId,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Attribuer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetailsDialog(ColisModel retour) async {
    // Charger le colis initial
    ColisModel? colisInitial;
    if (retour.colisInitialId != null) {
      colisInitial = await _retourController.getColisInitial(retour.colisInitialId!);
    }

    await Get.dialog(
      Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Détails du Retour',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('Numéro de suivi', retour.numeroSuivi),
                _buildDetailRow('Statut', _getStatutLabel(retour.statut)),
                _buildDetailRow('Date de collecte', DateFormat('dd/MM/yyyy HH:mm').format(retour.dateCollecte)),
                if (colisInitial != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Colis Initial',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Numéro', colisInitial.numeroSuivi),
                  _buildDetailRow('Statut', _getStatutLabel(colisInitial.statut)),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Expéditeur',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Nom', retour.expediteurNom),
                _buildDetailRow('Téléphone', retour.expediteurTelephone),
                _buildDetailRow('Adresse', retour.expediteurAdresse),
                const SizedBox(height: 16),
                const Text(
                  'Destinataire',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Nom', retour.destinataireNom),
                _buildDetailRow('Téléphone', retour.destinataireTelephone),
                _buildDetailRow('Adresse', retour.destinataireAdresse),
                const SizedBox(height: 16),
                const Text(
                  'Détails',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow('Contenu', retour.contenu),
                _buildDetailRow('Poids', '${retour.poids} kg'),
                _buildDetailRow('Tarif', '${retour.montantTarif} FCFA'),
                if (retour.commentaire != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Commentaire',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(retour.commentaire!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Retours'),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            onPressed: () => _retourController.loadRetours(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtre par statut
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text(
                  'Filtrer par statut:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatut,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _statuts.map((statut) {
                      return DropdownMenuItem(
                        value: statut,
                        child: Text(
                          statut == 'tous' ? 'Tous' : _getStatutLabel(statut),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatut = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Liste des retours
          Expanded(
            child: Obx(() {
              if (_retourController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final retours = _getFilteredRetours();

              if (retours.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun retour trouvé',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: retours.length,
                itemBuilder: (context, index) {
                  final retour = retours[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatutColor(retour.statut),
                        child: const Icon(
                          Icons.keyboard_return,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        retour.numeroSuivi,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('De: ${retour.expediteurNom}'),
                          Text('À: ${retour.destinataireNom}'),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(
                              _getStatutLabel(retour.statut),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: _getStatutColor(retour.statut),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (retour.statut == 'arriveDestination')
                            IconButton(
                              onPressed: () => _showAttribuerDialog(retour),
                              icon: const Icon(Icons.person_add),
                              tooltip: 'Attribuer',
                              color: const Color(0xFF2E7D32),
                            ),
                          IconButton(
                            onPressed: () => _showDetailsDialog(retour),
                            icon: const Icon(Icons.visibility),
                            tooltip: 'Détails',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/retours/creer'),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add),
        label: const Text('Créer un Retour'),
      ),
    );
  }
}
