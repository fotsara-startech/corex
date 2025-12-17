import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'client_form_dialog.dart';

class ClientsListScreen extends StatefulWidget {
  const ClientsListScreen({super.key});

  @override
  State<ClientsListScreen> createState() => _ClientsListScreenState();
}

class _ClientsListScreenState extends State<ClientsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser le controller
    if (!Get.isRegistered<ClientController>()) {
      Get.put(ClientController());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientController = Get.find<ClientController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => clientController.loadClients(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ClientFormDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouveau client'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un client',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Liste des clients
          Expanded(
            child: Obx(() {
              if (clientController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var clients = clientController.clientsList;

              // Filtrer par recherche
              if (_searchController.text.isNotEmpty) {
                final query = _searchController.text.toLowerCase();
                clients = clients
                    .where((c) => c.nom.toLowerCase().contains(query) || c.telephone.contains(query) || c.ville.toLowerCase().contains(query) || (c.email?.toLowerCase().contains(query) ?? false))
                    .toList()
                    .obs;
              }

              if (clients.isEmpty) {
                return const Center(
                  child: Text('Aucun client trouvé'),
                );
              }

              return ListView.builder(
                itemCount: clients.length,
                itemBuilder: (context, index) {
                  final client = clients[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(client.nom[0].toUpperCase()),
                      ),
                      title: Text(client.nom),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📞 ${client.telephone}'),
                          if (client.email != null && client.email!.isNotEmpty) Text('📧 ${client.email}'),
                          Text('📍 ${client.ville} - ${client.adresse}'),
                          if (client.quartier != null) Text('🏘️ ${client.quartier}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          client.type == 'expediteur'
                              ? 'Expéditeur'
                              : client.type == 'destinataire'
                                  ? 'Destinataire'
                                  : 'Les deux',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      isThreeLine: true,
                      onTap: () {
                        // Afficher les détails
                        _showClientDetails(client);
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showClientDetails(ClientModel client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client.nom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Téléphone', client.telephone),
            if (client.email != null && client.email!.isNotEmpty) _buildDetailRow('Email', client.email!),
            _buildDetailRow('Ville', client.ville),
            _buildDetailRow('Adresse', client.adresse),
            if (client.quartier != null) _buildDetailRow('Quartier', client.quartier!),
            _buildDetailRow('Type', _getTypeLabel(client.type)),
            _buildDetailRow(
              'Créé le',
              DateFormatter.formatDateTime(client.createdAt),
            ),
            _buildDetailRow(
              'Modifié le',
              DateFormatter.formatDateTime(client.updatedAt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              showDialog(
                context: context,
                builder: (context) => ClientFormDialog(client: client),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'expediteur':
        return 'Expéditeur';
      case 'destinataire':
        return 'Destinataire';
      case 'les_deux':
        return 'Les deux';
      default:
        return type;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
