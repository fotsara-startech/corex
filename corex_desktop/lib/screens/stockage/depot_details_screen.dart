import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/models/depot_model.dart';
import 'package:corex_shared/models/mouvement_stock_model.dart';
import 'package:corex_shared/models/client_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../agent/nouvelle_collecte_screen.dart';

class DepotDetailsScreen extends StatefulWidget {
  final DepotModel depot;
  final ClientModel? client;

  const DepotDetailsScreen({Key? key, required this.depot, this.client}) : super(key: key);

  @override
  State<DepotDetailsScreen> createState() => _DepotDetailsScreenState();
}

class _DepotDetailsScreenState extends State<DepotDetailsScreen> {
  final fmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
    controller.selectDepot(widget.depot);
    controller.loadMouvementsByDepot(widget.depot.id);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Dépôt'),
        actions: [
          IconButton(icon: const Icon(Icons.local_shipping), onPressed: () => _showRetraitViaCollecteDialog(context), tooltip: 'Retrait via collecte'),
          IconButton(icon: const Icon(Icons.remove_circle), onPressed: () => _showRetraitDialog(context), tooltip: 'Retrait direct'),
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _showModifierDepotDialog(context), tooltip: 'Modifier le dépôt'),
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () => _exporterMouvementsPdf(controller), tooltip: 'Exporter mouvements PDF'),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: () => _confirmerSuppressionDepot(context, controller),
            tooltip: 'Supprimer le dépôt',
          ),
        ],
      ),
      body: Obx(() {
        final currentDepot = controller.selectedDepot.value ?? widget.depot;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildInfoCard(currentDepot),
            const SizedBox(height: 16),
            _buildProduitsCard(currentDepot),
            const SizedBox(height: 16),
            _buildMouvementsCard(controller),
          ],
        );
      }),
    );
  }

  Widget _buildInfoCard(DepotModel depot) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _InfoRow(label: 'Date de dépôt', value: DateFormat('dd/MM/yyyy').format(depot.dateDepot)),
            _InfoRow(label: 'Emplacement', value: depot.emplacement),
            _InfoRow(label: 'Tarif mensuel', value: '${fmt.format(depot.tarifMensuel)} FCFA'),
            _InfoRow(label: 'Type de tarif', value: depot.typeTarif == 'global' ? 'Global' : 'Par produit'),
            if (depot.notes != null) _InfoRow(label: 'Notes', value: depot.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildProduitsCard(DepotModel depot) {
    final valeurDepot = depot.produits.fold(0.0, (s, p) => s + (p.tarifUnitaire ?? 0) * p.quantite);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Produits en stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (valeurDepot > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                    child: Text('Valeur: ${fmt.format(valeurDepot)} FCFA', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
            const Divider(),
            ...depot.produits.map((p) => _ProduitTile(produit: p)),
          ],
        ),
      ),
    );
  }

  Widget _buildMouvementsCard(StockageController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historique des mouvements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Obx(() {
              if (controller.mouvementsList.isEmpty) {
                return const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('Aucun mouvement', style: TextStyle(color: Colors.grey))));
              }
              return Column(
                children: controller.mouvementsList
                    .map((m) => _MouvementTile(
                          mouvement: m,
                          onDelete: () => _confirmerSuppressionMouvement(m, controller),
                          onPrint: () => _imprimerMouvement(m),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── ACTIONS ──────────────────────────────────────────────────────────────

  void _confirmerSuppressionDepot(BuildContext context, StockageController controller) {
    Get.dialog(AlertDialog(
      title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Supprimer le dépôt')]),
      content: const Text('Cette action est irréversible. Tous les mouvements liés seront conservés mais le dépôt sera supprimé.'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final ok = await controller.deleteDepot(widget.depot.id);
            if (ok) Get.back();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Supprimer'),
        ),
      ],
    ));
  }

  void _confirmerSuppressionMouvement(MouvementStockModel mouvement, StockageController controller) {
    Get.dialog(AlertDialog(
      title: const Text('Supprimer ce mouvement ?'),
      content: Text('${mouvement.type == 'depot' ? 'Dépôt' : 'Retrait'} du ${DateFormat('dd/MM/yyyy').format(mouvement.dateMouvement)}'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            await controller.deleteMouvement(mouvement.id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Supprimer'),
        ),
      ],
    ));
  }

  Future<void> _imprimerMouvement(MouvementStockModel mouvement) async {
    final isDepot = mouvement.type == 'depot';
    await Printing.layoutPdf(
      name: 'Mouvement_${mouvement.type}_${DateFormat('yyyyMMdd').format(mouvement.dateMouvement)}',
      onLayout: (_) async {
        final pdf = pw.Document();
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(20),
          build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: isDepot ? PdfColors.blue800 : PdfColors.orange800,
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('COREX — ${isDepot ? 'DEPOT' : 'RETRAIT'}', style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(mouvement.dateMouvement), style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
              ]),
            ),
            pw.SizedBox(height: 12),
            if (mouvement.notes != null) pw.Text('Note: ${mouvement.notes}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: ['Produit', 'Quantite', 'Unite']
                      .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))))
                      .toList(),
                ),
                ...mouvement.produits.map((p) => pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.nom, style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.quantite.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(p.unite, style: const pw.TextStyle(fontSize: 9))),
                    ])),
              ],
            ),
          ]),
        ));
        return pdf.save();
      },
    );
  }

  Future<void> _exporterMouvementsPdf(StockageController controller) async {
    final mouvements = controller.mouvementsList;
    if (mouvements.isEmpty) {
      Get.snackbar('Info', 'Aucun mouvement à exporter');
      return;
    }
    final depot = controller.selectedDepot.value ?? widget.depot;
    final now = DateTime.now();

    await Printing.layoutPdf(
      name: 'Mouvements_Depot_${DateFormat('yyyyMMdd').format(now)}',
      onLayout: (_) async {
        final pdf = pw.Document();
        pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              color: PdfColors.green800,
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('COREX - MOUVEMENTS DE STOCK', style: pw.TextStyle(color: PdfColors.white, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(now), style: pw.TextStyle(color: PdfColors.white, fontSize: 9)),
              ]),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Depot: ${depot.emplacement} | Cree le ${DateFormat('dd/MM/yyyy').format(depot.dateDepot)}', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(1.5), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(3), 3: const pw.FlexColumnWidth(2)},
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: ['Date', 'Type', 'Produits', 'Notes']
                      .map((h) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))))
                      .toList(),
                ),
                ...mouvements.map((m) {
                  final isD = m.type == 'depot';
                  final produitsStr = m.produits.map((p) => '${p.nom}: ${p.quantite.toStringAsFixed(0)} ${p.unite}').join('\n');
                  return pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(DateFormat('dd/MM/yyyy\nHH:mm').format(m.dateMouvement), style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(isD ? 'Depot' : 'Retrait', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isD ? PdfColors.blue800 : PdfColors.orange800)),
                    ),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(produitsStr, style: const pw.TextStyle(fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m.notes ?? '', style: const pw.TextStyle(fontSize: 8))),
                  ]);
                }),
              ],
            ),
          ],
        ));
        return pdf.save();
      },
    );
  }

  void _showModifierDepotDialog(BuildContext context) {
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
    final currentDepot = controller.selectedDepot.value ?? widget.depot;
    showDialog(context: context, builder: (_) => _ModifierDepotDialog(depot: currentDepot, controller: controller));
  }

  void _showRetraitViaCollecteDialog(BuildContext context) {
    if (widget.client == null) {
      Get.snackbar('Information', 'Informations client non disponibles', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
    final currentDepot = controller.selectedDepot.value ?? widget.depot;
    final client = widget.client!;
    showDialog(
      context: context,
      builder: (_) => _RetraitDialog(
        depot: currentDepot,
        viaCollecte: true,
        onProduitsSelectionnes: (produits, notes) async {
          final contenu = produits.map((p) => '${p.nom} (${p.quantite.toStringAsFixed(0)} ${p.unite})').join(', ');
          double valeur = 0;
          for (final p in produits) {
            final pd = currentDepot.produits.firstWhereOrNull((d) => d.nom == p.nom);
            if (pd?.tarifUnitaire != null) valeur += pd!.tarifUnitaire! * p.quantite;
          }
          Get.to(() => NouvelleCollecteScreen(
                expediteurPreRempli: client,
                contenuPreRempli: contenu,
                valeurDeclareePreRemplie: valeur > 0 ? valeur : null,
                onCollecteCreee: (colisId) async {
                  final ok = await controller.createRetrait(currentDepot.id, currentDepot.clientId, produits, notes.isEmpty ? 'Retrait via collecte $colisId' : '$notes (collecte $colisId)');
                  if (ok) Get.snackbar('Stock mis a jour', 'Mouvement de retrait cree', backgroundColor: const Color(0xFF4CAF50), colorText: Colors.white);
                },
              ));
        },
      ),
    );
  }

  void _showRetraitDialog(BuildContext context) {
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
    final currentDepot = controller.selectedDepot.value ?? widget.depot;
    showDialog(context: context, builder: (_) => _RetraitDialog(depot: currentDepot));
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _ProduitTile extends StatelessWidget {
  final ProduitStocke produit;
  const _ProduitTile({required this.produit});
  @override
  Widget build(BuildContext context) {
    final isVide = produit.quantite <= 0;
    return ListTile(
      leading: Icon(Icons.inventory_2, color: isVide ? Colors.grey : Colors.green),
      title: Text(produit.nom, style: TextStyle(fontWeight: FontWeight.bold, color: isVide ? Colors.grey : null)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (produit.description.isNotEmpty) Text(produit.description),
          Text('${produit.quantite} ${produit.unite}', style: TextStyle(fontWeight: FontWeight.bold, color: isVide ? Colors.red : Colors.green)),
          if (produit.tarifUnitaire != null) Text('${NumberFormat('#,###').format(produit.tarifUnitaire)} FCFA/unite'),
        ],
      ),
      trailing: isVide ? const Chip(label: Text('Vide'), backgroundColor: Colors.grey) : null,
    );
  }
}

class _MouvementTile extends StatelessWidget {
  final MouvementStockModel mouvement;
  final VoidCallback onDelete;
  final VoidCallback onPrint;
  const _MouvementTile({required this.mouvement, required this.onDelete, required this.onPrint});
  @override
  Widget build(BuildContext context) {
    final isDepot = mouvement.type == 'depot';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDepot ? Colors.blue[100] : Colors.orange[100],
        child: Icon(isDepot ? Icons.arrow_downward : Icons.arrow_upward, color: isDepot ? Colors.blue[700] : Colors.orange[700]),
      ),
      title: Text(isDepot ? 'Depot' : 'Retrait', style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd/MM/yyyy HH:mm').format(mouvement.dateMouvement)),
          ...mouvement.produits.map((p) => Text('- ${p.nom}: ${p.quantite} ${p.unite}')),
          if (mouvement.notes != null) Text(mouvement.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.print, size: 18), onPressed: onPrint, tooltip: 'Imprimer'),
          IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: onDelete, tooltip: 'Supprimer'),
        ],
      ),
    );
  }
}

// ── DIALOGS ──────────────────────────────────────────────────────────────

class _RetraitDialog extends StatefulWidget {
  final DepotModel depot;
  final bool viaCollecte;
  final void Function(List<ProduitMouvement> produits, String notes)? onProduitsSelectionnes;
  const _RetraitDialog({required this.depot, this.viaCollecte = false, this.onProduitsSelectionnes});
  @override
  State<_RetraitDialog> createState() => _RetraitDialogState();
}

class _RetraitDialogState extends State<_RetraitDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final Map<String, double> _quantitesRetrait = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRetrait() async {
    if (!_formKey.currentState!.validate()) return;
    final produitsRetrait = _quantitesRetrait.entries.where((e) => e.value > 0).map((e) {
      final produit = widget.depot.produits.firstWhere((p) => p.nom == e.key);
      return ProduitMouvement(nom: e.key, quantite: e.value, unite: produit.unite);
    }).toList();
    if (produitsRetrait.isEmpty) {
      Get.snackbar('Erreur', 'Saisissez au moins une quantite a retirer');
      return;
    }
    final notes = _notesController.text.trim();
    if (widget.viaCollecte && widget.onProduitsSelectionnes != null) {
      Get.back();
      widget.onProduitsSelectionnes!(produitsRetrait, notes);
      return;
    }
    setState(() => _isLoading = true);
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
    final ok = await controller.createRetrait(widget.depot.id, widget.depot.clientId, produitsRetrait, notes.isEmpty ? null : notes);
    setState(() => _isLoading = false);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.viaCollecte ? 'Retrait via collecte' : 'Retrait de produits'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Saisissez les quantites a retirer:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...widget.depot.produits.where((p) => p.quantite > 0).map((produit) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${produit.nom} (Disponible: ${produit.quantite} ${produit.unite})', style: const TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Quantite a retirer', suffixText: produit.unite, border: const OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _quantitesRetrait[produit.nom] = double.tryParse(value) ?? 0,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final q = double.tryParse(value);
                          if (q == null) return 'Invalide';
                          if (q > produit.quantite) return 'Max: ${produit.quantite}';
                          return null;
                        },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()), maxLines: 2),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRetrait,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.viaCollecte ? 'Continuer vers collecte' : 'Enregistrer'),
        ),
      ],
    );
  }
}

class _ModifierDepotDialog extends StatefulWidget {
  final DepotModel depot;
  final StockageController controller;
  const _ModifierDepotDialog({required this.depot, required this.controller});
  @override
  State<_ModifierDepotDialog> createState() => _ModifierDepotDialogState();
}

class _ModifierDepotDialogState extends State<_ModifierDepotDialog> {
  late List<ProduitStocke> _produits;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _produits = widget.depot.produits.map((p) => p.copyWith()).toList();
  }

  void _ajouterProduit() {
    setState(() {
      _produits.add(ProduitStocke(nom: '', description: '', quantite: 0, unite: 'pieces'));
    });
  }

  void _supprimerProduit(int index) {
    setState(() => _produits.removeAt(index));
  }

  Future<void> _sauvegarder() async {
    if (_produits.any((p) => p.nom.trim().isEmpty)) {
      Get.snackbar('Erreur', 'Tous les produits doivent avoir un nom');
      return;
    }
    setState(() => _isLoading = true);
    final ok = await widget.controller.updateDepot(widget.depot.id, {
      'produits': _produits.map((p) => p.toMap()).toList(),
    });
    if (ok) {
      await widget.controller.reloadSelectedDepot();
    }
    setState(() => _isLoading = false);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le depot'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._produits.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return _ProduitEditRow(
                  key: ValueKey(i),
                  produit: p,
                  onChanged: (updated) => setState(() => _produits[i] = updated),
                  onDelete: () => _supprimerProduit(i),
                );
              }),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _ajouterProduit,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un produit'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _isLoading ? null : _sauvegarder,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sauvegarder'),
        ),
      ],
    );
  }
}

class _ProduitEditRow extends StatefulWidget {
  final ProduitStocke produit;
  final void Function(ProduitStocke) onChanged;
  final VoidCallback onDelete;
  const _ProduitEditRow({super.key, required this.produit, required this.onChanged, required this.onDelete});
  @override
  State<_ProduitEditRow> createState() => _ProduitEditRowState();
}

class _ProduitEditRowState extends State<_ProduitEditRow> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _qteCtrl;
  late final TextEditingController _uniteCtrl;
  late final TextEditingController _tarifCtrl;

  @override
  void initState() {
    super.initState();
    _nomCtrl = TextEditingController(text: widget.produit.nom);
    _descCtrl = TextEditingController(text: widget.produit.description);
    _qteCtrl = TextEditingController(text: widget.produit.quantite.toStringAsFixed(0));
    _uniteCtrl = TextEditingController(text: widget.produit.unite);
    _tarifCtrl = TextEditingController(text: widget.produit.tarifUnitaire?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    _qteCtrl.dispose();
    _uniteCtrl.dispose();
    _tarifCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(ProduitStocke(
      nom: _nomCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      quantite: double.tryParse(_qteCtrl.text) ?? widget.produit.quantite,
      unite: _uniteCtrl.text.trim().isEmpty ? 'pieces' : _uniteCtrl.text.trim(),
      tarifUnitaire: _tarifCtrl.text.trim().isEmpty ? null : double.tryParse(_tarifCtrl.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'Designation *', isDense: true, border: OutlineInputBorder()), onChanged: (_) => _notify())),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description', isDense: true, border: OutlineInputBorder()), onChanged: (_) => _notify())),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: widget.onDelete),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _qteCtrl,
                        decoration: const InputDecoration(labelText: 'Quantite', isDense: true, border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _notify())),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _uniteCtrl, decoration: const InputDecoration(labelText: 'Unite', isDense: true, border: OutlineInputBorder()), onChanged: (_) => _notify())),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _tarifCtrl,
                        decoration: const InputDecoration(labelText: 'Tarif unit. (FCFA)', isDense: true, border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _notify())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
