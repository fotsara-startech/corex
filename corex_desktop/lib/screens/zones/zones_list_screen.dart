import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'zone_form_dialog.dart';

class ZonesListScreen extends StatelessWidget {
  const ZonesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final zoneController = Get.put(ZoneController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Zones de Livraison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => zoneController.loadZones(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(zoneController),

          // Liste des zones
          Expanded(
            child: Obx(() {
              if (zoneController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (zoneController.zonesList.isEmpty) {
                return const Center(
                  child: Text('Aucune zone trouvée'),
                );
              }

              return _buildZonesList(zoneController);
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showZoneDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle zone'),
      ),
    );
  }

  Widget _buildSearchBar(ZoneController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Rechercher par nom, ville ou quartier...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => controller.searchQuery.value = value,
      ),
    );
  }

  Widget _buildZonesList(ZoneController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.zonesList.length,
      itemBuilder: (context, index) {
        final zone = controller.zonesList[index];
        return _buildZoneCard(context, zone, controller);
      },
    );
  }

  Widget _buildZoneCard(BuildContext context, ZoneModel zone, ZoneController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF2E7D32),
          child: Icon(Icons.location_on, color: Colors.white),
        ),
        title: Text(
          zone.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('📍 ${zone.ville} • ${zone.quartiers.length} quartier(s)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tarif
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${zone.tarifLivraison.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Menu actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value, zone, controller),
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
                  'Quartiers desservis :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: zone.quartiers.map((quartier) {
                    return Chip(
                      label: Text(quartier),
                      backgroundColor: Colors.grey.shade200,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action, ZoneModel zone, ZoneController controller) {
    switch (action) {
      case 'edit':
        _showZoneDialog(context, zone);
        break;
      case 'delete':
        _confirmDelete(context, zone, controller);
        break;
    }
  }

  void _showZoneDialog(BuildContext context, ZoneModel? zone) {
    showDialog(
      context: context,
      builder: (context) => ZoneFormDialog(zone: zone),
    );
  }

  void _confirmDelete(BuildContext context, ZoneModel zone, ZoneController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer la zone'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la zone "${zone.nom}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteZone(zone);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
