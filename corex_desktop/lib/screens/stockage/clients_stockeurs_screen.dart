import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/models/client_model.dart';
import 'create_client_stockeur_screen.dart';
import 'depot_client_screen.dart';

class ClientsStockeursScreen extends StatefulWidget {
  const ClientsStockeursScreen({Key? key}) : super(key: key);

  @override
  State<ClientsStockeursScreen> createState() => _ClientsStockeursScreenState();
}

class _ClientsStockeursScreenState extends State<ClientsStockeursScreen> {
  @override
  void initState() {
    super.initState();
    // Recharger les clients à chaque fois que l'écran est affiché
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<StockageController>();
      controller.loadClientsStockeurs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients Stockeurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const CreateClientStockeurScreen()),
            tooltip: 'Nouveau client',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.clientsStockeurs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun client stockeur',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => const CreateClientStockeurScreen()),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un client'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou téléphone...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  // TODO: Implémenter la recherche
                },
              ),
            ),
            // Liste des clients
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.clientsStockeurs.length,
                itemBuilder: (context, index) {
                  final client = controller.clientsStockeurs[index];
                  return _ClientCard(client: client);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final ClientModel client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(Icons.person, color: Colors.green[700]),
        ),
        title: Text(
          client.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(client.telephone),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${client.ville}${client.quartier != null ? ', ${client.quartier}' : ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.inventory),
              onPressed: () {
                controller.selectedClient.value = client;
                Get.to(() => DepotClientScreen(client: client));
              },
              tooltip: 'Voir les dépôts',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          controller.selectedClient.value = client;
          Get.to(() => DepotClientScreen(client: client));
        },
      ),
    );
  }
}
