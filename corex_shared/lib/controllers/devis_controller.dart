import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../models/devis_model.dart';
import '../models/transaction_model.dart';
import '../models/facture_stockage_model.dart';
import '../services/devis_service.dart';
import '../services/transaction_service.dart';
import '../services/stockage_service.dart';
import 'auth_controller.dart';

class DevisController extends GetxController {
  late final DevisService _devisService;

  final RxList<DevisModel> devisList = <DevisModel>[].obs;
  final RxList<DevisModel> filteredList = <DevisModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedStatut = 'tous'.obs;
  final Rx<DevisModel?> selectedDevis = Rx<DevisModel?>(null);

  @override
  void onInit() {
    super.onInit();
    try {
      if (!Get.isRegistered<DevisService>()) Get.put(DevisService(), permanent: true);
      _devisService = Get.find<DevisService>();
      ever(selectedStatut, (_) => _applyFilter());
      loadDevis();
    } catch (e) {
      print('❌ [DEVIS_CONTROLLER] Erreur initialisation: $e');
    }
  }

  Future<void> loadDevis() async {
    try {
      isLoading.value = true;
      final authController = Get.find<AuthController>();
      final agenceId = authController.currentUser.value?.agenceId;
      if (agenceId == null) return;

      _devisService.getDevisByAgence(agenceId).listen((list) {
        devisList.value = list;
        _applyFilter();
        isLoading.value = false;
      });
    } catch (e) {
      isLoading.value = false;
      print('❌ [DEVIS_CONTROLLER] Erreur chargement: $e');
    }
  }

  void setFiltreStatut(String statut) => selectedStatut.value = statut;

  void _applyFilter() {
    if (selectedStatut.value == 'tous') {
      filteredList.value = List.from(devisList);
    } else {
      filteredList.value = devisList.where((d) => d.statut == selectedStatut.value).toList();
    }
    // Mettre à jour selectedDevis si présent dans la liste
    if (selectedDevis.value != null) {
      final updated = devisList.firstWhereOrNull((d) => d.id == selectedDevis.value!.id);
      if (updated != null) selectedDevis.value = updated;
    }
  }

  Future<bool> createDevis(DevisModel devis) async {
    if (devis.clientNom.trim().isEmpty) {
      Get.snackbar('Erreur', 'Le nom du client est obligatoire');
      return false;
    }
    if (devis.lignes.isEmpty) {
      Get.snackbar('Erreur', 'Ajoutez au moins une ligne au devis');
      return false;
    }
    try {
      final authController = Get.find<AuthController>();
      final agenceId = authController.currentUser.value?.agenceId ?? '';
      final userId = authController.currentUser.value?.id ?? '';
      final numero = await _devisService.generateNumeroDevis();
      final now = DateTime.now();
      final newDevis = DevisModel(
        id: '',
        numeroDevis: numero,
        clientNom: devis.clientNom,
        clientTelephone: devis.clientTelephone,
        agenceId: agenceId,
        userId: userId,
        lignes: devis.lignes,
        montantTotal: devis.montantTotal,
        statut: 'brouillon',
        dateCreation: now,
        dateModification: now,
        notes: devis.notes,
      );
      await _devisService.createDevis(newDevis);
      Get.snackbar('Succès', 'Devis $numero créé', backgroundColor: const Color(0xFF4CAF50), colorText: Colors.white);
      return true;
    } catch (e) {
      print('❌ [DEVIS_CONTROLLER] Erreur création: $e');
      Get.snackbar('Erreur', 'Impossible de créer le devis: $e', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<bool> updateDevis(String id, Map<String, dynamic> data, {required String currentStatut}) async {
    if (currentStatut == 'valide' || currentStatut == 'converti') {
      Get.snackbar('Devis verrouillé', 'Ce devis ne peut plus être modifié');
      return false;
    }
    try {
      await _devisService.updateDevis(id, data);
      Get.snackbar('Succès', 'Devis mis à jour');
      return true;
    } catch (e) {
      print('❌ [DEVIS_CONTROLLER] Erreur mise à jour: $e');
      Get.snackbar('Erreur', 'Impossible de mettre à jour: $e', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<bool> deleteDevis(DevisModel devis) async {
    if (!devis.canDelete) {
      Get.snackbar('Devis verrouillé', 'Ce devis ne peut pas être supprimé');
      return false;
    }
    try {
      await _devisService.deleteDevis(devis.id);
      Get.snackbar('Succès', 'Devis supprimé');
      return true;
    } catch (e) {
      print('❌ [DEVIS_CONTROLLER] Erreur suppression: $e');
      Get.snackbar('Erreur', 'Impossible de supprimer: $e', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<bool> validerDevis(DevisModel devis) async {
    if (!devis.canValider) {
      Get.snackbar('Erreur', 'Ce devis ne peut pas être validé dans son état actuel');
      return false;
    }
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Créer la transaction en caisse
      if (!Get.isRegistered<TransactionService>()) Get.put(TransactionService(), permanent: true);
      final transactionService = Get.find<TransactionService>();
      final transactionId = const Uuid().v4();

      final transaction = TransactionModel(
        id: transactionId,
        agenceId: user.agenceId!,
        type: 'recette',
        montant: devis.montantTotal,
        date: DateTime.now(),
        categorieRecette: 'devis',
        description: 'Validation devis ${devis.numeroDevis} - ${devis.clientNom}',
        reference: devis.numeroDevis,
        userId: user.id,
      );

      await transactionService.createTransaction(transaction);

      // Mettre à jour le devis
      await _devisService.updateDevis(devis.id, {
        'statut': 'valide',
        'transactionId': transactionId,
        'dateValidation': DateTime.now(),
      });

      Get.snackbar('Succès', 'Devis validé et recette enregistrée en caisse', backgroundColor: const Color(0xFF4CAF50), colorText: Colors.white);
      return true;
    } catch (e) {
      print('❌ [DEVIS_CONTROLLER] Erreur validation: $e');
      Get.snackbar('Erreur', 'Impossible de valider le devis: $e', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<bool> convertirEnFacture(DevisModel devis) async {
    if (!devis.canConvertir) {
      Get.snackbar('Erreur', 'Seul un devis validé peut être converti en facture');
      return false;
    }
    try {
      if (!Get.isRegistered<StockageService>()) Get.put(StockageService(), permanent: true);
      final stockageService = Get.find<StockageService>();
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Générer numéro facture
      final numeroFacture = await stockageService.generateNumeroFacture();
      final now = DateTime.now();

      final facture = FactureStockageModel(
        id: '',
        numeroFacture: numeroFacture,
        clientId: devis.clientNom, // référence par nom (pas d'ID client dans le devis)
        agenceId: devis.agenceId,
        depotIds: [],
        periodeDebut: devis.dateCreation,
        periodeFin: now,
        montantTotal: devis.montantTotal,
        statut: 'impayee',
        dateEmission: now,
        userId: user.id,
        notes: 'Converti depuis devis ${devis.numeroDevis}',
        createdAt: now,
        updatedAt: now,
      );

      final factureId = await stockageService.createFacture(facture);

      await _devisService.updateDevis(devis.id, {
        'statut': 'converti',
        'factureId': factureId,
      });

      Get.snackbar('Succès', 'Facture $numeroFacture créée', backgroundColor: const Color(0xFF4CAF50), colorText: Colors.white);
      return true;
    } catch (e) {
      print('❌ [DEVIS_CONTROLLER] Erreur conversion: $e');
      Get.snackbar('Erreur', 'Impossible de convertir: $e', backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  Future<void> imprimerDevis(DevisModel devis) async {
    try {
      await Printing.layoutPdf(
        name: devis.statut == 'converti' ? 'Facture_${devis.numeroDevis}' : 'Devis_${devis.numeroDevis}',
        onLayout: (_) async => _genererPdf(devis),
      );
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'imprimer: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> exporterDevis(DevisModel devis) async {
    try {
      final bytes = await _genererPdf(devis);
      final filename = devis.statut == 'converti' ? 'Facture_${devis.numeroDevis}.pdf' : 'Devis_${devis.numeroDevis}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'exporter: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<Uint8List> _genererPdf(DevisModel devis) async {
    final fmt = NumberFormat('#,###');
    final dateStr = DateFormat('dd/MM/yyyy').format(devis.dateCreation);
    final isFacture = devis.statut == 'converti';
    final titreDoc = isFacture ? 'FACTURE' : 'DEVIS';
    final sousTitre = isFacture ? 'Facture commerciale' : 'Devis commercial';
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        // En-tête
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('COREX', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.Text(sousTitre, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(titreDoc, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text(devis.numeroDevis, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 9)),
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
            pw.Text('CLIENT:', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(devis.clientNom, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            if (devis.clientTelephone.isNotEmpty) pw.Text(devis.clientTelephone, style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
        pw.SizedBox(height: 16),

        // Tableau des lignes
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.green800),
              children: ['Designation', 'Qte', 'Prix unit.', 'Total']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(h, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ))
                  .toList(),
            ),
            ...devis.lignes.map((l) => pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(l.designation, style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(l.quantite.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${fmt.format(l.prixUnitaire)} FCFA', style: const pw.TextStyle(fontSize: 10))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${fmt.format(l.total)} FCFA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                ])),
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
              pw.Text('${fmt.format(devis.montantTotal)} FCFA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            ]),
          ),
        ),
        pw.SizedBox(height: 12),

        // Statut
        // pw.Container(
        //   width: double.infinity,
        //   padding: const pw.EdgeInsets.all(6),
        //   color: _statutPdfColor(devis.statut),
        //   child: pw.Text(_statutLabel(devis.statut), style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white), textAlign: pw.TextAlign.center),
        // ),

        if (devis.notes != null && devis.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text('Notes: ${devis.notes}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
        ],

        pw.Spacer(),
        pw.Container(height: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Text(
          isFacture ? 'COREX - Merci de votre confiance' : 'COREX - Ce devis est valable 30 jours',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          textAlign: pw.TextAlign.center,
        ),
      ]),
    ));
    return pdf.save();
  }

  PdfColor _statutPdfColor(String statut) {
    switch (statut) {
      case 'valide':
        return PdfColors.green700;
      case 'converti':
        return PdfColors.blue700;
      case 'refuse':
        return PdfColors.red700;
      case 'envoye':
        return PdfColors.orange700;
      default:
        return PdfColors.grey600;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'brouillon':
        return 'BROUILLON';
      case 'envoye':
        return 'ENVOYE';
      case 'valide':
        return 'VALIDE';
      case 'refuse':
        return 'REFUSE';
      case 'converti':
        return 'CONVERTI EN FACTURE';
      default:
        return statut.toUpperCase();
    }
  }
}
