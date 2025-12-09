import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final _dateFormatShort = DateFormat('dd/MM/yyyy');

  // Couleurs COREX
  static final _greenColor = PdfColor.fromHex('#2E7D32');

  /// Génère le reçu de collecte
  Future<void> generateRecuCollecte(ColisModel colis) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo COREX
              _buildHeader('REÇU DE COLLECTE'),
              pw.SizedBox(height: 20),

              // Numéro de suivi
              _buildNumeroSuivi(colis.numeroSuivi),
              pw.SizedBox(height: 20),

              // Informations expéditeur
              _buildSection('EXPÉDITEUR', [
                _buildInfoLine('Nom', colis.expediteurNom),
                _buildInfoLine('Téléphone', colis.expediteurTelephone),
                _buildInfoLine('Adresse', colis.expediteurAdresse),
              ]),
              pw.SizedBox(height: 15),

              // Informations destinataire
              _buildSection('DESTINATAIRE', [
                _buildInfoLine('Nom', colis.destinataireNom),
                _buildInfoLine('Téléphone', colis.destinataireTelephone),
                _buildInfoLine('Ville', colis.destinataireVille),
                _buildInfoLine('Adresse', colis.destinataireAdresse),
                if (colis.destinataireQuartier != null) _buildInfoLine('Quartier', colis.destinataireQuartier!),
              ]),
              pw.SizedBox(height: 15),

              // Détails du colis
              _buildSection('DÉTAILS DU COLIS', [
                _buildInfoLine('Contenu', colis.contenu),
                _buildInfoLine('Poids', '${colis.poids} kg'),
                if (colis.dimensions != null) _buildInfoLine('Dimensions', colis.dimensions!),
                _buildInfoLine('Mode de livraison', _getModeLivraisonLabel(colis.modeLivraison)),
              ]),
              pw.SizedBox(height: 15),

              // Informations financières
              _buildSection('INFORMATIONS FINANCIÈRES', [
                _buildInfoLine('Tarif', '${colis.montantTarif} FCFA', bold: true),
                _buildInfoLine('Statut paiement', colis.isPaye ? 'PAYÉ' : 'NON PAYÉ'),
                if (colis.datePaiement != null) _buildInfoLine('Date paiement', _dateFormat.format(colis.datePaiement!)),
              ]),
              pw.SizedBox(height: 15),

              // Dates
              _buildInfoLine('Date de collecte', _dateFormat.format(colis.dateCollecte)),
              if (colis.dateEnregistrement != null) _buildInfoLine('Date d\'enregistrement', _dateFormat.format(colis.dateEnregistrement!)),

              pw.Spacer(),

              // Pied de page
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await _savePdf(pdf, 'Recu_Collecte_${colis.numeroSuivi}.pdf');
  }

  /// Génère le bordereau d'expédition
  Future<void> generateBordereauExpedition(ColisModel colis) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              _buildHeader('BORDEREAU D\'EXPÉDITION'),
              pw.SizedBox(height: 20),

              // Numéro de suivi (grand format)
              _buildNumeroSuiviBig(colis.numeroSuivi),
              pw.SizedBox(height: 30),

              // Informations en deux colonnes
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Colonne gauche - Expéditeur
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSection('DE', [
                          pw.Text(
                            colis.expediteurNom,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(colis.expediteurTelephone, style: const pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(height: 5),
                          pw.Text(colis.expediteurAdresse, style: const pw.TextStyle(fontSize: 10)),
                        ]),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),

                  // Colonne droite - Destinataire
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildSection('À', [
                          pw.Text(
                            colis.destinataireNom,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(colis.destinataireTelephone, style: const pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            '${colis.destinataireVille}${colis.destinataireQuartier != null ? ' - ${colis.destinataireQuartier}' : ''}',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(colis.destinataireAdresse, style: const pw.TextStyle(fontSize: 10)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Détails du colis
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _greenColor, width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DÉTAILS DU COLIS',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _greenColor,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDetailBox('Contenu', colis.contenu),
                        _buildDetailBox('Poids', '${colis.poids} kg'),
                        _buildDetailBox('Tarif', '${colis.montantTarif} FCFA'),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Mode de livraison
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'MODE DE LIVRAISON: ',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _getModeLivraisonLabel(colis.modeLivraison).toUpperCase(),
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatureBox('Signature Expéditeur'),
                  _buildSignatureBox('Signature Destinataire'),
                ],
              ),
              pw.SizedBox(height: 10),

              // Pied de page
              _buildFooter(),
            ],
          );
        },
      ),
    );

    await _savePdf(pdf, 'Bordereau_${colis.numeroSuivi}.pdf');
  }

  // Widgets de construction PDF

  pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'COREX',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: _greenColor,
                  ),
                ),
                pw.Text(
                  'Service de Livraison Express',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  _dateFormatShort.format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          height: 3,
          color: _greenColor,
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildNumeroSuivi(String numero) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'N° de suivi: ',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            numero,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: _greenColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNumeroSuiviBig(String numero) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: _greenColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Center(
        child: pw.Text(
          numero,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _greenColor,
          ),
        ),
        pw.SizedBox(height: 8),
        ...children,
      ],
    );
  }

  pw.Widget _buildInfoLine(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailBox(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignatureBox(String label) {
    return pw.Container(
      width: 200,
      height: 80,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          height: 1,
          color: PdfColors.grey,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'COREX - Service de Livraison Express | Tél: +237 XXX XXX XXX | Email: contact@corex.cm',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  String _getModeLivraisonLabel(String mode) {
    switch (mode) {
      case 'domicile':
        return 'Livraison à domicile';
      case 'bureau':
        return 'Retrait au bureau';
      case 'agence_transport':
        return 'Agence de transport';
      default:
        return mode;
    }
  }

  Future<void> _savePdf(pw.Document pdf, String filename) async {
    try {
      // Obtenir le répertoire des documents
      final directory = await getApplicationDocumentsDirectory();
      final corexDir = Directory('${directory.path}/COREX/Documents');

      // Créer le dossier s'il n'existe pas
      if (!await corexDir.exists()) {
        await corexDir.create(recursive: true);
      }

      // Sauvegarder le fichier
      final file = File('${corexDir.path}/$filename');
      await file.writeAsBytes(await pdf.save());

      print('✅ PDF sauvegardé: ${file.path}');

      // Ouvrir le fichier automatiquement
      await OpenFile.open(file.path);
    } catch (e) {
      print('❌ Erreur sauvegarde PDF: $e');
      rethrow;
    }
  }
}
