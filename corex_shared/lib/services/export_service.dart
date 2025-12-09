import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class ExportService extends GetxService {
  final dateFormat = DateFormat('dd/MM/yyyy');
  final currencyFormat = NumberFormat('#,##0', 'fr_FR');

  /// Génère un PDF de rapport financier consolidé
  Future<void> generateRapportFinancierPDF({
    required DateTime dateDebut,
    required DateTime dateFin,
    required double totalRecettes,
    required double totalDepenses,
    required double soldeGlobal,
    required List<Map<String, dynamic>> bilanParAgence,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // En-tête
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COREX',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2E7D32'),
                      ),
                    ),
                    pw.Text(
                      'Rapport Financier Consolidé',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Période'),
                    pw.Text(
                      '${dateFormat.format(dateDebut)} - ${dateFormat.format(dateFin)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Bilan global
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bilan Consolidé',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildPdfRow('Recettes', totalRecettes, PdfColors.green),
                pw.Divider(),
                _buildPdfRow('Dépenses', totalDepenses, PdfColors.red),
                pw.Divider(),
                _buildPdfRow('Solde', soldeGlobal, soldeGlobal >= 0 ? PdfColors.green : PdfColors.red),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Tableau par agence
          pw.Text(
            'Détail par Agence',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey),
            children: [
              // En-tête
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildTableCell('Agence', isHeader: true),
                  _buildTableCell('Recettes', isHeader: true),
                  _buildTableCell('Dépenses', isHeader: true),
                  _buildTableCell('Solde', isHeader: true),
                ],
              ),
              // Données
              ...bilanParAgence.map((agence) {
                return pw.TableRow(
                  children: [
                    _buildTableCell(agence['agenceNom']),
                    _buildTableCell('${currencyFormat.format(agence['recettes'])} FCFA'),
                    _buildTableCell('${currencyFormat.format(agence['depenses'])} FCFA'),
                    _buildTableCell(
                      '${currencyFormat.format(agence['solde'])} FCFA',
                      color: agence['solde'] >= 0 ? PdfColors.green : PdfColors.red,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 20),

          // Pied de page
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Généré le ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.Text(
                'COREX - Système de Gestion',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ],
      ),
    );

    // Afficher le PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'rapport_financier_${dateFormat.format(DateTime.now())}.pdf',
    );
  }

  /// Génère un PDF de rapport par agence
  Future<void> generateRapportAgencePDF({
    required String agenceNom,
    required DateTime dateDebut,
    required DateTime dateFin,
    required double caAgence,
    required int nombreColis,
    required int nombreLivraisons,
    required List<Map<String, dynamic>> statsCommerciaux,
    required List<Map<String, dynamic>> statsCoursiers,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // En-tête
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COREX',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2E7D32'),
                      ),
                    ),
                    pw.Text(
                      'Rapport d\'Agence',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      agenceNom,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Période'),
                    pw.Text(
                      '${dateFormat.format(dateDebut)} - ${dateFormat.format(dateFin)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Statistiques globales
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox('CA', '${currencyFormat.format(caAgence)} FCFA', PdfColors.green),
                _buildStatBox('Colis', '$nombreColis', PdfColors.blue),
                _buildStatBox('Livraisons', '$nombreLivraisons', PdfColors.orange),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Performance des commerciaux
          pw.Text(
            'Performance des Commerciaux',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          if (statsCommerciaux.isEmpty)
            pw.Text('Aucun commercial')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Commercial', isHeader: true),
                    _buildTableCell('Colis', isHeader: true),
                    _buildTableCell('CA', isHeader: true),
                  ],
                ),
                ...statsCommerciaux.map((stat) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(stat['nom']),
                      _buildTableCell('${stat['nombreColis']}'),
                      _buildTableCell('${currencyFormat.format(stat['ca'])} FCFA'),
                    ],
                  );
                }).toList(),
              ],
            ),
          pw.SizedBox(height: 20),

          // Performance des coursiers
          pw.Text(
            'Performance des Coursiers',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          if (statsCoursiers.isEmpty)
            pw.Text('Aucun coursier')
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _buildTableCell('Coursier', isHeader: true),
                    _buildTableCell('Livraisons', isHeader: true),
                    _buildTableCell('Réussies', isHeader: true),
                    _buildTableCell('Taux', isHeader: true),
                  ],
                ),
                ...statsCoursiers.map((stat) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(stat['nom']),
                      _buildTableCell('${stat['nombreLivraisons']}'),
                      _buildTableCell('${stat['livrees']}'),
                      _buildTableCell('${stat['tauxReussite'].toStringAsFixed(1)}%'),
                    ],
                  );
                }).toList(),
              ],
            ),
          pw.SizedBox(height: 20),

          // Pied de page
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Généré le ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
              pw.Text(
                'COREX - Système de Gestion',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ],
      ),
    );

    // Afficher le PDF
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'rapport_agence_${agenceNom}_${dateFormat.format(DateTime.now())}.pdf',
    );
  }

  pw.Widget _buildPdfRow(String label, double montant, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
          pw.Text(
            '${currencyFormat.format(montant)} FCFA',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Génère un fichier CSV des transactions
  String generateTransactionsCSV(List<Map<String, dynamic>> transactions) {
    final buffer = StringBuffer();

    // En-tête
    buffer.writeln('Date,Type,Catégorie,Montant,Description,Référence');

    // Données
    for (var transaction in transactions) {
      buffer.writeln(
        '${dateFormat.format(transaction['date'])},'
        '${transaction['type']},'
        '${transaction['categorie'] ?? ''},'
        '${transaction['montant']},'
        '"${transaction['description']}",'
        '${transaction['reference'] ?? ''}',
      );
    }

    return buffer.toString();
  }

  /// Sauvegarde un fichier CSV
  Future<void> saveCSV(String content, String filename) async {
    try {
      // Sur mobile, utiliser le partage
      await Printing.sharePdf(
        bytes: Uint8List.fromList(content.codeUnits),
        filename: filename,
      );
      Get.snackbar('Succès', 'Fichier exporté');
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'exporter le fichier');
      print('❌ [EXPORT] Erreur: $e');
    }
  }
}
