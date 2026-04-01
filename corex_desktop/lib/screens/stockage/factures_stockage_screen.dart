import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/stockage_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/models/facture_stockage_model.dart';
import 'package:corex_shared/models/transaction_model.dart';
import 'package:corex_shared/services/transaction_service.dart';
import 'package:corex_shared/services/client_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'generate_facture_screen.dart';

class FacturesStockageScreen extends StatefulWidget {
  const FacturesStockageScreen({Key? key}) : super(key: key);

  @override
  State<FacturesStockageScreen> createState() => _FacturesStockageScreenState();
}

class _FacturesStockageScreenState extends State<FacturesStockageScreen> {
  String _filtre = 'toutes';

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
    controller.loadFactures();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures de Stockage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => const GenerateFactureScreen()),
            tooltip: 'Generer une facture',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FiltreBtn(label: 'Toutes', value: 'toutes', selected: _filtre, onTap: (v) => setState(() => _filtre = v)),
                const SizedBox(width: 8),
                _FiltreBtn(label: 'Impayees', value: 'impayee', selected: _filtre, onTap: (v) => setState(() => _filtre = v)),
                const SizedBox(width: 8),
                _FiltreBtn(label: 'Payees', value: 'payee', selected: _filtre, onTap: (v) => setState(() => _filtre = v)),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());

              final factures = controller.facturesList.where((f) {
                if (_filtre == 'toutes') return true;
                return f.statut == _filtre;
              }).toList();

              if (factures.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucune facture', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Get.to(() => const GenerateFactureScreen()),
                        icon: const Icon(Icons.add),
                        label: const Text('Generer une facture'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: factures.length,
                itemBuilder: (context, index) => _FactureCard(facture: factures[index]),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FiltreBtn extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _FiltreBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FactureCard extends StatelessWidget {
  final FactureStockageModel facture;
  const _FactureCard({required this.facture});

  @override
  Widget build(BuildContext context) {
    final isPaye = facture.statut == 'payee';
    final isAnnulee = facture.statut == 'annulee';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isPaye
              ? Colors.green[100]
              : isAnnulee
                  ? Colors.grey[300]
                  : Colors.red[100],
          child: Icon(
            isPaye
                ? Icons.check_circle
                : isAnnulee
                    ? Icons.cancel
                    : Icons.pending,
            color: isPaye
                ? Colors.green[700]
                : isAnnulee
                    ? Colors.grey[600]
                    : Colors.red[700],
          ),
        ),
        title: Text(facture.numeroFacture, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Emise le ${DateFormat('dd/MM/yyyy').format(facture.dateEmission)}'),
            Text('Periode: ${DateFormat('dd/MM').format(facture.periodeDebut)} - ${DateFormat('dd/MM/yyyy').format(facture.periodeFin)}'),
            const SizedBox(height: 4),
            Text('${NumberFormat('#,###').format(facture.montantTotal)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
            if (isPaye && facture.datePaiement != null) Text('Payee le ${DateFormat('dd/MM/yyyy').format(facture.datePaiement!)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
        trailing: Chip(
          label: Text(isPaye
              ? 'Payee'
              : isAnnulee
                  ? 'Annulee'
                  : 'Impayee'),
          backgroundColor: isPaye
              ? Colors.green[100]
              : isAnnulee
                  ? Colors.grey[300]
                  : Colors.red[100],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (facture.notes != null) ...[
                  const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(facture.notes!),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!isPaye && !isAnnulee)
                      ElevatedButton.icon(
                        onPressed: () => showDialog(context: context, builder: (_) => _PayerFactureDialog(facture: facture)),
                        icon: const Icon(Icons.check),
                        label: const Text('Marquer payee'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _imprimerFacture(facture),
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _telechargerFacture(facture),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _imprimerFacture(FactureStockageModel facture) async {
    await Printing.layoutPdf(
      name: 'Facture_${facture.numeroFacture}',
      onLayout: (_) async => _genererPdf(facture),
    );
  }

  Future<void> _telechargerFacture(FactureStockageModel facture) async {
    final bytes = await _genererPdf(facture);
    await Printing.sharePdf(bytes: bytes, filename: 'Facture_${facture.numeroFacture}.pdf');
  }

  Future<Uint8List> _genererPdf(FactureStockageModel facture) async {
    final fmt = NumberFormat('#,###');
    final isPaye = facture.statut == 'payee';

    // Récupérer le nom du client
    String clientNom = 'Client';
    String clientTel = '';
    String clientVille = '';
    try {
      if (Get.isRegistered<ClientService>()) {
        final c = await Get.find<ClientService>().getClientById(facture.clientId);
        if (c != null) {
          clientNom = c.nom;
          clientTel = c.telephone;
          clientVille = c.ville;
        }
      }
    } catch (_) {}

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
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
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('FACTURE A:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(clientNom, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            if (clientTel.isNotEmpty) pw.Text(clientTel, style: const pw.TextStyle(fontSize: 10)),
            if (clientVille.isNotEmpty) pw.Text(clientVille, style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
        pw.SizedBox(height: 16),
        pw.Row(children: [
          pw.Text('Periode: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.Text('${DateFormat('dd/MM/yyyy').format(facture.periodeDebut)} au ${DateFormat('dd/MM/yyyy').format(facture.periodeFin)}', style: const pw.TextStyle(fontSize: 10)),
        ]),
        pw.SizedBox(height: 16),
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          color: isPaye ? PdfColors.green100 : PdfColors.red100,
          child: pw.Text(isPaye ? 'PAYEE' : 'IMPAYEE',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: isPaye ? PdfColors.green800 : PdfColors.red800), textAlign: pw.TextAlign.center),
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
}

class _PayerFactureDialog extends StatefulWidget {
  final FactureStockageModel facture;
  const _PayerFactureDialog({required this.facture});

  @override
  State<_PayerFactureDialog> createState() => _PayerFactureDialogState();
}

class _PayerFactureDialogState extends State<_PayerFactureDialog> {
  bool _isLoading = false;
  bool _creerTransaction = true;
  bool _done = false; // garde contre double validation

  Future<void> _confirmerPaiement() async {
    if (_done) return; // bloquer tout appel supplémentaire
    setState(() {
      _isLoading = true;
      _done = true;
    });

    try {
      String? transactionId;

      if (_creerTransaction) {
        final authController = Get.find<AuthController>();
        final user = authController.currentUser.value;

        if (user != null && user.agenceId != null) {
          if (!Get.isRegistered<TransactionService>()) {
            Get.put(TransactionService(), permanent: true);
          }
          final transactionService = Get.find<TransactionService>();
          transactionId = const Uuid().v4();

          final transaction = TransactionModel(
            id: transactionId,
            agenceId: user.agenceId!,
            type: 'recette',
            montant: widget.facture.montantTotal,
            date: DateTime.now(),
            categorieRecette: 'stockage',
            description: 'Paiement facture stockage ${widget.facture.numeroFacture}',
            reference: widget.facture.numeroFacture,
            userId: user.id,
          );

          await transactionService.createTransaction(transaction);
        }
      }

      final controller = Get.isRegistered<StockageController>() ? Get.find<StockageController>() : Get.put(StockageController(), permanent: true);
      await controller.marquerFacturePayee(widget.facture.id, transactionId ?? '');

      // Fermer avec Navigator pour garantir la fermeture du dialog standard
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _done = false;
      });
      Get.snackbar('Erreur', 'Impossible d\'enregistrer le paiement: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer le paiement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Facture: ${widget.facture.numeroFacture}'),
          const SizedBox(height: 8),
          Text('Montant: ${NumberFormat('#,###').format(widget.facture.montantTotal)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _creerTransaction,
            onChanged: (v) => setState(() => _creerTransaction = v ?? true),
            title: const Text('Créer une transaction en caisse'),
            subtitle: const Text('Enregistrer automatiquement la recette'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: (_isLoading || _done) ? null : _confirmerPaiement,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirmer'),
        ),
      ],
    );
  }
}
