import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'agence_form_dialog.dart';

class AgencesListScreen extends StatelessWidget {
  const AgencesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final agenceController = Get.put(AgenceController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Agences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => agenceController.loadAgences(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(agenceController),

          // Liste des agences
          Expanded(
            child: Obx(() {
              if (agenceController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (agenceController.agencesList.isEmpty) {
                return const Center(
                  child: Text('Aucune agence trouvée'),
                );
              }

              return _buildAgencesList(agenceController);
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

  Widget _buildSearchAndFilters(AgenceController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom, ville, téléphone ou email...',
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

  Widget _buildAgencesList(AgenceController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.agencesList.length,
      itemBuilder: (context, index) {
        final agence = controller.agencesList[index];
        return _buildAgenceCard(context, agence, controller);
      },
    );
  }

  Widget _buildAgenceCard(BuildContext context, AgenceModel agence, AgenceController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: agence.isActive ? const Color(0xFF2E7D32) : Colors.grey,
          child: const Icon(Icons.business, color: Colors.white),
        ),
        title: Text(
          agence.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${agence.adresse}, ${agence.ville}'),
            Text('📞 ${agence.telephone} • 📧 ${agence.email}'),
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
        isThreeLine: true,
      ),
    );
  }

  void _handleAction(BuildContext context, String action, AgenceModel agence, AgenceController controller) {
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

  void _showAgenceDialog(BuildContext context, AgenceModel? agence) {
    showDialog(
      context: context,
      builder: (context) => AgenceFormDialog(agence: agence),
    );
  }

  void _confirmToggleStatus(BuildContext context, AgenceModel agence, AgenceController controller) {
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
              controller.toggleAgenceStatus(agence);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AgenceModel agence, AgenceController controller) {
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
