import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/models/client_model.dart';
import 'package:corex_shared/models/depot_model.dart';
import 'package:intl/intl.dart';
import 'create_depot_screen.dart';
import 'depot_details_screen.dart';

class DepotClientScreen extends StatelessWidget {
  final ClientModel client;

  const DepotClientScreen({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();
    controller.loadDepotsByClient(client.id);
    controller.loadFacturesByClient(client.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dépôts - ${client.nom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () => Get.to(() => CreateDepotScreen(client: client)),
            tooltip: 'Nouveau dépôt',
          ),
        ],
      ),
      body: Column(
        children: [
          // Informations client
          _ClientInfoCard(client: client),
          
          // Onglets
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Dépôts', icon: Icon(Icons.inventory)),
                      Tab(text: 'Mouvements', icon: Icon(Icons.swap_horiz)),
                      Tab(text: 'Factures', icon: Icon(Icons.receipt)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _DepotsTab(client: client),
                        _MouvementsTab(client: client),
                        _FacturesTab(client: client),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientInfoCard extends StatelessWidget {
  final ClientModel client;

  const _ClientInfoCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.person, size: 32, color: Colors.green[700]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.nom,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(client.telephone),
                      Text('${client.ville}${client.quartier != null ? ', ${client.quartier}' : ''}'),
                    ],
                  ),
                ),
                Obx(() {
                  final total = controller.getTotalStockageClient(client.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Tarif mensuel', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '${NumberFormat('#,###').format(total)} FCFA',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DepotsTab extends StatelessWidget {
  final ClientModel client;

  const _DepotsTab({required this.client});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();

    return Obx(() {
      final depots = controller.depotsList.where((d) => d.clientId == client.id).toList();

      if (depots.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Aucun dépôt', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Get.to(() => CreateDepotScreen(client: client)),
                icon: const Icon(Icons.add),
                label: const Text('Créer un dépôt'),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: depots.length,
        itemBuilder: (context, index) {
          final depot = depots[index];
          return _DepotCard(depot: depot);
        },
      );
    });
  }
}

class _DepotCard extends StatelessWidget {
  final DepotModel depot;

  const _DepotCard({required this.depot});

  @override
  Widget build(BuildContext context) {
    final totalQuantite = depot.produits.fold(0.0, (sum, p) => sum + p.quantite);
    final isActif = totalQuantite > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActif ? Colors.green[100] : Colors.grey[300],
          child: Icon(
            Icons.inventory,
            color: isActif ? Colors.green[700] : Colors.grey[600],
          ),
        ),
        title: Text(
          'Dépôt du ${DateFormat('dd/MM/yyyy').format(depot.dateDepot)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Emplacement: ${depot.emplacement}'),
            Text('${depot.produits.length} produit(s) - Total: ${totalQuantite.toStringAsFixed(0)} unités'),
            Text(
              'Tarif: ${NumberFormat('#,###').format(depot.tarifMensuel)} FCFA/mois',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(isActif ? 'Actif' : 'Vide'),
          backgroundColor: isActif ? Colors.green[100] : Colors.grey[300],
        ),
        onTap: () {
          final controller = Get.find<StockageController>();
          controller.selectDepot(depot);
          Get.to(() => DepotDetailsScreen(depot: depot));
        },
      ),
    );
  }
}

class _MouvementsTab extends StatelessWidget {
  final ClientModel client;

  const _MouvementsTab({required this.client});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();
    controller.loadMouvementsByClient(client.id);

    return Obx(() {
      if (controller.mouvementsList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swap_horiz, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Aucun mouvement', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.mouvementsList.length,
        itemBuilder: (context, index) {
          final mouvement = controller.mouvementsList[index];
          final isDepot = mouvement.type == 'depot';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isDepot ? Colors.blue[100] : Colors.orange[100],
                child: Icon(
                  isDepot ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isDepot ? Colors.blue[700] : Colors.orange[700],
                ),
              ),
              title: Text(
                isDepot ? 'Dépôt' : 'Retrait',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(mouvement.dateMouvement)),
                  Text('${mouvement.produits.length} produit(s)'),
                  if (mouvement.notes != null) Text(mouvement.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

class _FacturesTab extends StatelessWidget {
  final ClientModel client;

  const _FacturesTab({required this.client});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockageController>();

    return Obx(() {
      final factures = controller.facturesList.where((f) => f.clientId == client.id).toList();

      if (factures.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Aucune facture', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: factures.length,
        itemBuilder: (context, index) {
          final facture = factures[index];
          final isPaye = facture.statut == 'payee';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPaye ? Colors.green[100] : Colors.red[100],
                child: Icon(
                  isPaye ? Icons.check_circle : Icons.pending,
                  color: isPaye ? Colors.green[700] : Colors.red[700],
                ),
              ),
              title: Text(
                facture.numeroFacture,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Émise le ${DateFormat('dd/MM/yyyy').format(facture.dateEmission)}'),
                  Text('Période: ${DateFormat('dd/MM').format(facture.periodeDebut)} - ${DateFormat('dd/MM/yyyy').format(facture.periodeFin)}'),
                  Text(
                    '${NumberFormat('#,###').format(facture.montantTotal)} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              trailing: Chip(
                label: Text(isPaye ? 'Payée' : 'Impayée'),
                backgroundColor: isPaye ? Colors.green[100] : Colors.red[100],
              ),
            ),
          );
        },
      );
    });
  }
}
