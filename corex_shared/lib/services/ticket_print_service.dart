import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/colis_model.dart';
import '../models/agence_model.dart';

class TicketPrintService {
  // Format de ticket de caisse 80mm (largeur standard)
  static const PdfPageFormat ticketFormat = PdfPageFormat(
    80 * PdfPageFormat.mm, // 80mm de largeur
    double.infinity, // Hauteur variable selon le contenu
    marginAll: 5 * PdfPageFormat.mm, // Marges réduites
  );

  /// Génère et imprime un ticket de caisse avec sélection d'imprimante
  static Future<void> printTicket({
    required ColisModel colis,
    AgenceModel? agence,
  }) async {
    try {
      print('🖨️ [PRINT_SERVICE] Génération du ticket 80mm pour impression');

      // Ouvrir le dialogue d'impression avec format ticket
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          // Utiliser notre format de ticket personnalisé
          return await _generateTicketPDF(colis: colis, agence: agence);
        },
        name: 'Ticket_COREX_${colis.numeroSuivi}',
        format: ticketFormat, // Format ticket 80mm
      );

      print('✅ [PRINT_SERVICE] Dialogue d\'impression ouvert (format 80mm)');
    } catch (e) {
      print('❌ [PRINT_SERVICE] Erreur impression: $e');
      throw Exception('Erreur lors de l\'impression du ticket: $e');
    }
  }

  /// Génère le PDF du ticket au format 80mm
  static Future<Uint8List> _generateTicketPDF({
    required ColisModel colis,
    AgenceModel? agence,
  }) async {
    final pdf = pw.Document();

    // Informations de l'agence
    final agenceNom = agence?.nom ?? 'COREX';
    final agenceAdresse = agence?.adresse ?? 'Adresse non spécifiée';
    final agenceTelephone = agence?.telephone ?? 'Tel: +225 XX XX XX XX';
    final agenceEmail = agence?.email ?? 'contact@corex.com';

    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.Page(
        pageFormat: ticketFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // En-tête centré
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      agenceNom,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      agenceAdresse,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      agenceTelephone,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      agenceEmail,
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '$dateStr - $timeStr',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              // Numéro de suivi - Très visible
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
                child: pw.Text(
                  colis.numeroSuivi,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 8),

              // Expéditeur - Format compact
              _buildCompactSection('EXPEDITEUR', [
                colis.expediteurNom,
                colis.expediteurTelephone,
                colis.expediteurAdresse,
              ]),

              pw.SizedBox(height: 6),

              // Destinataire - Format compact
              _buildCompactSection('DESTINATAIRE', [
                colis.destinataireNom,
                colis.destinataireTelephone,
                '${colis.destinataireVille}',
                colis.destinataireAdresse,
              ]),

              pw.SizedBox(height: 6),

              // Détails colis - Format compact
              _buildCompactSection('COLIS', [
                'Contenu: ${colis.contenu}',
                'Poids: ${colis.poids.toStringAsFixed(1)} kg',
                if (colis.dimensions != null) 'Dim: ${colis.dimensions}',
                if (colis.commentaire != null && colis.commentaire!.isNotEmpty) 'Note: ${colis.commentaire}',
              ]),

              pw.SizedBox(height: 6),

              // Total - Très visible
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${colis.montantTarif.toStringAsFixed(0)} FCFA',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (colis.tarifAgenceTransport != null && colis.tarifAgenceTransport! > 0) ...[
                      pw.SizedBox(height: 2),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Transport:', style: const pw.TextStyle(fontSize: 8)),
                          pw.Text('${colis.tarifAgenceTransport!.toStringAsFixed(0)} FCFA', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 6),

              // Statut paiement
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Paiement:', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          colis.isPaye ? 'PAYÉ' : 'NON PAYÉ',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (colis.isPaye && colis.datePaiement != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Le ${colis.datePaiement!.day}/${colis.datePaiement!.month}/${colis.datePaiement!.year}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              // Pied de page
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, style: pw.BorderStyle.dashed),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Merci de votre confiance',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'Gardez ce reçu pour le suivi',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'www.corex.com',
                      style: const pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Construit une section compacte du ticket (format 80mm)
  static pw.Widget _buildCompactSection(String title, List<String> items) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Container(
            height: 0.5,
            width: double.infinity,
            color: PdfColors.black,
            margin: const pw.EdgeInsets.symmetric(vertical: 3),
          ),
          ...items
              .map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      item,
                      style: const pw.TextStyle(fontSize: 8),
                      maxLines: 2,
                      overflow: pw.TextOverflow.clip,
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  /// Vérifie si l'impression est disponible sur la plateforme
  static Future<bool> isAvailable() async {
    try {
      await Printing.info();
      return true;
    } catch (e) {
      print('⚠️ [PRINT_SERVICE] Impression non disponible: $e');
      return false;
    }
  }

  /// Liste les imprimantes disponibles
  static Future<List<Printer>> getAvailablePrinters() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      print('⚠️ [PRINT_SERVICE] Erreur liste imprimantes: $e');
      return [];
    }
  }
}
