import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'agence_transport_form_dialog.dart';

class AgencesTransportListScreen extends StatelessWidget {
  const AgencesTransportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AgenceTransportController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agences de Transport Partenaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadAgences(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(controller),

          // Liste des agences
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.agencesList.isEmpty) {
                return const Center(
                  child: Text('Aucune agence de transport trouvée'),
                );
              }

              return _buildAgencesList(controller);
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAgenceDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle agence'),
      ),
    );
  }

  Widget _buildSearchAndFilters(AgenceTransportController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom, contact, téléphone ou ville...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => controller.searchQuery.value = value,
          ),
          const SizedBox(height: 16),

          // Filtre par statut
          Row(
            children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.filterStatus.value,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'tous', child: Text('Toutes')),
                        DropdownMenuItem(value: 'actif', child: Text('Actives')),
                        DropdownMenuItem(value: 'inactif', child: Text('Inactives')),
                      ],
                      onChanged: (value) {
                        if (value != null) controller.filterStatus.value = value;
                      },
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgencesList(AgenceTransportController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.agencesList.length,
      itemBuilder: (context, index) {
        final agence = controller.agencesList[index];
        return _buildAgenceCard(context, agence, controller);
      },
    );
  }

  Widget _buildAgenceCard(BuildContext context, AgenceTransportModel agence, AgenceTransportController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: agence.isActive ? const Color(0xFF2E7D32) : Colors.grey,
          child: const Icon(Icons.local_shipping, color: Colors.white),
        ),
        title: Text(
          agence.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👤 ${agence.contact}'),
            Text('📞 ${agence.telephone}'),
            Text('🌍 ${agence.villesDesservies.length} ville(s) desservie(s)'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: agence.isActive ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                agence.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: agence.isActive ? Colors.green.shade900 : Colors.red.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Menu actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value, agence, controller),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(agence.isActive ? Icons.block : Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      Text(agence.isActive ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Villes desservies et tarifs :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...agence.villesDesservies.map((ville) {
                  final tarif = agence.tarifs[ville] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('📍 $ville'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${tarif.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action, AgenceTransportModel agence, AgenceTransportController controller) {
    switch (action) {
      case 'edit':
        _showAgenceDialog(context, agence);
        break;
      case 'toggle':
        _confirmToggleStatus(context, agence, controller);
        break;
      case 'delete':
        _confirmDelete(context, agence, controller);
        break;
    }
  }

  void _showAgenceDialog(BuildContext context, AgenceTransportModel? agence) {
    showDialog(
      context: context,
      builder: (context) => AgenceTransportFormDialog(agence: agence),
    );
  }

  void _confirmToggleStatus(BuildContext context, AgenceTransportModel agence, AgenceTransportController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(agence.isActive ? 'Désactiver l\'agence' : 'Activer l\'agence'),
        content: Text(
          agence.isActive ? 'Êtes-vous sûr de vouloir désactiver ${agence.nom} ?' : 'Êtes-vous sûr de vouloir activer ${agence.nom} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.toggleStatus(agence);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AgenceTransportModel agence, AgenceTransportController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer l\'agence'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${agence.nom} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteAgence(agence);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
