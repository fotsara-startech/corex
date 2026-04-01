import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:typed_data';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/models/client_model.dart';
import 'package:corex_shared/models/depot_model.dart';
import 'package:corex_shared/models/facture_stockage_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'create_depot_screen.dart';
import 'depot_details_screen.dart';

class DepotClientScreen extends StatelessWidget {
  final ClientModel client;

  const DepotClientScreen({Key? key, required this.client}) : super(key: key);

  Future<void> _imprimerEtatStock(List<DepotModel> depots) async {
    final fmt = NumberFormat('#,###');
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);

    double valeurTotale = 0;
    for (final depot in depots) {
      for (final p in depot.produits) {
        if (p.tarifUnitaire != null) valeurTotale += p.tarifUnitaire! * p.quantite;
      }
    }

    await Printing.layoutPdf(
      name: 'Etat_Stock_${client.nom}_${DateFormat('yyyyMMdd').format(now)}',
      onLayout: (format) async {
        final pdf = pw.Document();
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(color: PdfColors.green800, borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('COREX - ETAT DE STOCK', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Edite le $dateStr', style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                ]),
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text(client.nom, style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.Text(client.telephone, style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                  pw.Text(client.ville, style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
                ]),
              ]),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green300), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Valeur totale du stock:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text('${fmt.format(valeurTotale)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.green800)),
              ]),
            ),
            pw.SizedBox(height: 16),
            ...depots.map((depot) {
              final depotValeur = depot.produits.fold(0.0, (s, p) => s + (p.tarifUnitaire ?? 0) * p.quantite);
              return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: PdfColors.grey200,
                  child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text('Depot du ${DateFormat('dd/MM/yyyy').format(depot.dateDepot)} - ${depot.emplacement}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Tarif: ${fmt.format(depot.tarifMensuel)} FCFA/mois', style: const pw.TextStyle(fontSize: 9)),
                  ]),
                ),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: ['Produit', 'Description', 'Qte', 'Tarif unit.', 'Valeur']
                          .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))))
                          .toList(),
                    ),
                    ...depot.produits.map((p) {
                      final valeur = (p.tarifUnitaire ?? 0) * p.quantite;
                      final isVide = p.quantite <= 0;
                      return pw.TableRow(children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.nom, style: pw.TextStyle(fontSize: 9, color: isVide ? PdfColors.grey : PdfColors.black))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.description, style: const pw.TextStyle(fontSize: 8))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${p.quantite.toStringAsFixed(0)} ${p.unite}',
                              style: pw.TextStyle(fontSize: 9, color: isVide ? PdfColors.red : PdfColors.green800, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.tarifUnitaire != null ? '${fmt.format(p.tarifUnitaire)} FCFA' : '-', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(p.tarifUnitaire != null ? '${fmt.format(valeur)} FCFA' : '-', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      ]);
                    }),
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.green50),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Sous-total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                        pw.SizedBox(),
                        pw.SizedBox(),
                        pw.SizedBox(),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('${fmt.format(depotValeur)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.green800))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
              ]);
            }),
          ],
        ));
        return pdf.save();
      },
    );
  }

  Future<void> _telechargerEtatStock(List<DepotModel> depots) async {
    final fmt = NumberFormat('#,###');
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(now);
    double valeurTotale = 0;
    for (final depot in depots) {
      for (final p in depot.produits) {
        if (p.tarifUnitaire != null) valeurTotale += p.tarifUnitaire! * p.quantite;
      }
    }
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: PdfColors.green800, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('COREX - ETAT DE STOCK', style: pw.TextStyle(color: PdfColors.white, fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('Edite le $dateStr', style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(client.nom, style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.Text(client.telephone, style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
              pw.Text(client.ville, style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
            ]),
          ]),
        ),
        pw.SizedBox(height: 16),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green300), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Valeur totale du stock:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.Text('${fmt.format(valeurTotale)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.green800)),
          ]),
        ),
        pw.SizedBox(height: 16),
        ...depots.map((depot) {
          final depotValeur = depot.produits.fold(0.0, (s, p) => s + (p.tarifUnitaire ?? 0) * p.quantite);
          return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: PdfColors.grey200,
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Depot du ${DateFormat('dd/MM/yyyy').format(depot.dateDepot)} - ${depot.emplacement}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('Tarif: ${fmt.format(depot.tarifMensuel)} FCFA/mois', style: const pw.TextStyle(fontSize: 9)),
              ]),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(2), 2: const pw.FlexColumnWidth(1.5), 3: const pw.FlexColumnWidth(2), 4: const pw.FlexColumnWidth(2)},
              children: [
                pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: ['Produit', 'Description', 'Qte', 'Tarif unit.', 'Valeur']
                        .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))))
                        .toList()),
                ...depot.produits.map((p) {
                  final valeur = (p.tarifUnitaire ?? 0) * p.quantite;
                  final isVide = p.quantite <= 0;
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.nom, style: pw.TextStyle(fontSize: 9, color: isVide ? PdfColors.grey : PdfColors.black))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.description, style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${p.quantite.toStringAsFixed(0)} ${p.unite}',
                            style: pw.TextStyle(fontSize: 9, color: isVide ? PdfColors.red : PdfColors.green800, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.tarifUnitaire != null ? '${fmt.format(p.tarifUnitaire)} FCFA' : '-', style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(p.tarifUnitaire != null ? '${fmt.format(valeur)} FCFA' : '-', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  ]);
                }),
                pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.green50), children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Sous-total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.SizedBox(),
                  pw.SizedBox(),
                  pw.SizedBox(),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${fmt.format(depotValeur)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.green800))),
                ]),
              ],
            ),
            pw.SizedBox(height: 12),
          ]);
        }),
      ],
    ));
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'Etat_Stock_${client.nom}_${DateFormat('yyyyMMdd').format(now)}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
    controller.loadDepotsByClient(client.id);
    controller.loadFacturesByClient(client.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('Depots - ${client.nom}'),
        actions: [
          Obx(() {
            final depots = controller.depotsList.where((d) => d.clientId == client.id).toList();
            return Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.print), onPressed: depots.isEmpty ? null : () => _imprimerEtatStock(depots), tooltip: 'Imprimer etat de stock'),
              IconButton(icon: const Icon(Icons.download), onPressed: depots.isEmpty ? null : () => _telechargerEtatStock(depots), tooltip: 'Telecharger PDF'),
            ]);
          }),
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: () => Get.to(() => CreateDepotScreen(client: client)),
            tooltip: 'Nouveau depot',
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
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);

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
                  final depots = controller.depotsList.where((d) => d.clientId == client.id).toList();
                  final tarifMensuel = controller.getTotalStockageClient(client.id);

                  // Valorisation totale = somme(quantité × tarifUnitaire) pour tous les produits
                  double valeurStock = 0;
                  for (final depot in depots) {
                    for (final p in depot.produits) {
                      if (p.tarifUnitaire != null) valeurStock += p.tarifUnitaire! * p.quantite;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Tarif mensuel', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        '${NumberFormat('#,###').format(tarifMensuel)} FCFA',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      if (valeurStock > 0) ...[
                        const SizedBox(height: 4),
                        const Text('Valeur du stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          '${NumberFormat('#,###').format(valeurStock)} FCFA',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
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
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);

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
          return _DepotCard(depot: depot, client: client);
        },
      );
    });
  }
}

class _DepotCard extends StatelessWidget {
  final DepotModel depot;
  final ClientModel client;

  const _DepotCard({required this.depot, required this.client});

  @override
  Widget build(BuildContext context) {
    final totalQuantite = depot.produits.fold(0.0, (sum, p) => sum + p.quantite);
    final isActif = totalQuantite > 0;

    // Valorisation du dépôt
    final valeurDepot = depot.produits.fold(0.0, (sum, p) => sum + (p.tarifUnitaire ?? 0) * p.quantite);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActif ? Colors.green[100] : Colors.grey[300],
          child: Icon(Icons.inventory, color: isActif ? Colors.green[700] : Colors.grey[600]),
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
            Text('${depot.produits.length} produit(s) - ${totalQuantite.toStringAsFixed(0)} unites'),
            Text('Tarif: ${NumberFormat('#,###').format(depot.tarifMensuel)} FCFA/mois', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            if (valeurDepot > 0) Text('Valeur: ${NumberFormat('#,###').format(valeurDepot)} FCFA', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
          ],
        ),
        trailing: Chip(
          label: Text(isActif ? 'Actif' : 'Vide'),
          backgroundColor: isActif ? Colors.green[100] : Colors.grey[300],
        ),
        onTap: () {
          final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
          controller.selectDepot(depot);
          Get.to(() => DepotDetailsScreen(depot: depot, client: client));
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
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
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

  Future<void> _imprimerFacture(FactureStockageModel facture) async {
    await Printing.layoutPdf(
      name: 'Facture_${facture.numeroFacture}',
      onLayout: (_) async => _genererPdfFacture(facture),
    );
  }

  Future<void> _telechargerFacture(FactureStockageModel facture) async {
    final bytes = await _genererPdfFacture(facture);
    await Printing.sharePdf(bytes: bytes, filename: 'Facture_${facture.numeroFacture}.pdf');
  }

  Future<Uint8List> _genererPdfFacture(FactureStockageModel facture) async {
    final fmt = NumberFormat('#,###');
    final isPaye = facture.statut == 'payee';
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        // En-tête
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('COREX', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.Text('Service de Stockage', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('FACTURE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(facture.numeroFacture, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.Text('Emise le ${DateFormat('dd/MM/yyyy').format(facture.dateEmission)}', style: const pw.TextStyle(fontSize: 9)),
          ]),
        ]),
        pw.SizedBox(height: 8),
        pw.Container(height: 2, color: PdfColors.green800),
        pw.SizedBox(height: 16),

        // Client
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('FACTURE A:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(client.nom, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.Text(client.telephone, style: const pw.TextStyle(fontSize: 10)),
            pw.Text(client.ville, style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
        pw.SizedBox(height: 16),

        // Période
        pw.Row(children: [
          pw.Text('Periode: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${DateFormat('dd/MM/yyyy').format(facture.periodeDebut)} au ${DateFormat('dd/MM/yyyy').format(facture.periodeFin)}', style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.SizedBox(height: 16),

        // Tableau
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green800),
              children: ['Description', 'Montant']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ))
                  .toList(),
            ),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Service de stockage - ${facture.depotIds.length} depot(s)', style: const pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${fmt.format(facture.montantTotal)} FCFA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
            ]),
          ],
        ),
        pw.SizedBox(height: 8),

        // Total
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(color: PdfColors.green50, border: pw.Border.all(color: PdfColors.green300)),
            child: pw.Row(children: [
              pw.Text('TOTAL: ', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('${fmt.format(facture.montantTotal)} FCFA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            ]),
          ),
        ),
        pw.SizedBox(height: 16),

        // Statut
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          color: isPaye ? PdfColors.green100 : PdfColors.red100,
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
            pw.Text(isPaye ? 'PAYEE' : 'IMPAYEE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: isPaye ? PdfColors.green800 : PdfColors.red800)),
          ]),
        ),

        if (facture.notes != null) ...[
          pw.SizedBox(height: 12),
          pw.Text('Notes: ${facture.notes}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        ],

        pw.Spacer(),
        pw.Container(height: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Text('COREX - Merci de votre confiance', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey), textAlign: pw.TextAlign.center),
      ]),
    ));
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);

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
                child: Icon(isPaye ? Icons.check_circle : Icons.pending, color: isPaye ? Colors.green[700] : Colors.red[700]),
              ),
              title: Text(facture.numeroFacture, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Emise le ${DateFormat('dd/MM/yyyy').format(facture.dateEmission)}'),
                  Text('Periode: ${DateFormat('dd/MM').format(facture.periodeDebut)} - ${DateFormat('dd/MM/yyyy').format(facture.periodeFin)}'),
                  Text('${NumberFormat('#,###').format(facture.montantTotal)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(label: Text(isPaye ? 'Payee' : 'Impayee'), backgroundColor: isPaye ? Colors.green[100] : Colors.red[100]),
                  const SizedBox(width: 4),
                  IconButton(icon: const Icon(Icons.print, size: 20), onPressed: () => _imprimerFacture(facture), tooltip: 'Imprimer'),
                  IconButton(icon: const Icon(Icons.download, size: 20), onPressed: () => _telechargerFacture(facture), tooltip: 'Telecharger PDF'),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
