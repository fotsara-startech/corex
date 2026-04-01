import 'dart:html' as html;
import 'dart:typed_data';
import '../models/colis_model.dart';
import '../models/client_model.dart';

class TicketServiceSimple {
  /// Génère et imprime un ticket de caisse pour un colis (version simple et fiable)
  static Future<void> generateAndPrintTicket({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
  }) async {
    try {
      print('🎫 [TICKET] Génération du ticket pour colis ${colis.numeroSuivi}');

      final ticketHtml = _generateCompleteTicketHtml(
        colis: colis,
        expediteur: expediteur,
        destinataire: destinataire,
      );

      // Ouvrir directement dans une nouvelle fenêtre avec bouton d'impression
      _openPrintWindow(ticketHtml);
      print('✅ [TICKET] Fenêtre d\'impression ouverte');
    } catch (e) {
      print('❌ [TICKET] Erreur génération ticket: $e');
      throw Exception('Erreur lors de la génération du ticket: $e');
    }
  }

  /// Ouvre une fenêtre avec le ticket et un bouton d'impression
  static void _openPrintWindow(String ticketHtml) {
    // Créer un blob avec le contenu HTML
    final blob = html.Blob([ticketHtml], 'text/html');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    // Ouvrir dans une nouvelle fenêtre
    final printWindow = html.window.open(blobUrl, '_blank', 'width=450,height=800,scrollbars=yes,resizable=yes,toolbar=yes,menubar=yes');

    if (printWindow != null) {
      // Nettoyer l'URL après un délai
      Future.delayed(const Duration(seconds: 10), () {
        html.Url.revokeObjectUrl(blobUrl);
      });
    } else {
      // Fallback: télécharger le fichier
      _downloadTicketAsHtml(ticketHtml);
    }
  }

  /// Génère le HTML complet du ticket avec interface d'impression
  static String _generateCompleteTicketHtml({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ticket COREX - ${colis.numeroSuivi}</title>
    <style>
        * {
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Courier New', monospace;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        
        .no-print {
            background: white;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .print-button {
            background: #2E7D32;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin: 0 10px;
        }
        
        .print-button:hover {
            background: #1B5E20;
        }
        
        .download-button {
            background: #1976D2;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin: 0 10px;
        }
        
        .download-button:hover {
            background: #1565C0;
        }
        
        .ticket {
            background: white;
            width: 80mm;
            margin: 0 auto;
            padding: 5mm;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
            border-radius: 8px;
        }
        
        .header {
            text-align: center;
            border-bottom: 2px solid #000;
            padding-bottom: 5px;
            margin-bottom: 10px;
        }
        
        .logo {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 2px;
        }
        
        .subtitle {
            font-size: 10px;
            margin-bottom: 5px;
        }
        
        .section {
            margin-bottom: 8px;
        }
        
        .section-title {
            font-weight: bold;
            font-size: 11px;
            border-bottom: 1px solid #000;
            margin-bottom: 3px;
        }
        
        .row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 2px;
        }
        
        .label {
            font-weight: bold;
        }
        
        .value {
            text-align: right;
        }
        
        .numero-suivi {
            text-align: center;
            font-size: 14px;
            font-weight: bold;
            border: 2px solid #000;
            padding: 5px;
            margin: 10px 0;
        }
        
        .total {
            border-top: 2px solid #000;
            border-bottom: 2px solid #000;
            padding: 5px 0;
            margin: 10px 0;
            font-weight: bold;
            font-size: 14px;
        }
        
        .footer {
            text-align: center;
            font-size: 10px;
            margin-top: 15px;
            border-top: 1px dashed #000;
            padding-top: 5px;
        }
        
        .qr-placeholder {
            text-align: center;
            border: 1px solid #000;
            padding: 10px;
            margin: 10px 0;
            font-size: 10px;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
            
            .no-print {
                display: none !important;
            }
            
            .ticket {
                box-shadow: none;
                border-radius: 0;
                width: 80mm;
                margin: 0;
                padding: 5mm;
            }
            
            @page {
                size: 80mm auto;
                margin: 0;
            }
        }
    </style>
</head>
<body>
    <div class="no-print">
        <h3>🎫 Ticket de Caisse COREX</h3>
        <p>Cliquez sur "Imprimer" pour imprimer le ticket, ou "Télécharger" pour le sauvegarder.</p>
        <button class="print-button" onclick="window.print()">
            🖨️ Imprimer
        </button>
        <button class="download-button" onclick="downloadTicket()">
            💾 Télécharger
        </button>
        <button class="print-button" onclick="window.close()" style="background: #666;">
            ❌ Fermer
        </button>
    </div>

    <div class="ticket">
        <!-- En-tête -->
        <div class="header">
            <div class="logo">COREX</div>
            <div class="subtitle">Système de Gestion de Colis</div>
            <div class="subtitle">$dateStr - $timeStr</div>
        </div>

        <!-- Numéro de suivi -->
        <div class="numero-suivi">
            ${colis.numeroSuivi}
        </div>

        <!-- Informations expéditeur -->
        <div class="section">
            <div class="section-title">EXPEDITEUR</div>
            <div>${expediteur?.nom ?? colis.expediteurNom}</div>
            <div>${expediteur?.telephone ?? colis.expediteurTelephone}</div>
            ${expediteur?.adresse != null && expediteur!.adresse!.isNotEmpty ? '<div>${expediteur.adresse}</div>' : ''}
        </div>

        <!-- Informations destinataire -->
        <div class="section">
            <div class="section-title">DESTINATAIRE</div>
            <div>${destinataire?.nom ?? colis.destinataireNom}</div>
            <div>${destinataire?.telephone ?? colis.destinataireTelephone}</div>
            <div>${colis.destinataireAdresse}</div>
            <div>${colis.destinataireVille}</div>
        </div>

        <!-- Détails du colis -->
        <div class="section">
            <div class="section-title">DETAILS COLIS</div>
            <div class="row">
                <span class="label">Contenu:</span>
                <span class="value">${colis.contenu}</span>
            </div>
            <div class="row">
                <span class="label">Poids:</span>
                <span class="value">${colis.poids != null ? colis.poids!.toStringAsFixed(1) : 'Non pesé'} ${colis.poids != null ? 'kg' : ''}</span>
            </div>
            ${colis.valeurDeclaree != null ? '<div class="row"><span class="label">Valeur déclarée:</span><span class="value">${colis.valeurDeclaree!.toStringAsFixed(0)} FCFA</span></div>' : ''}
            ${colis.dimensions != null ? '<div class="row"><span class="label">Dimensions:</span><span class="value">${colis.dimensions}</span></div>' : ''}
            ${colis.commentaire != null && colis.commentaire!.isNotEmpty ? '<div class="row"><span class="label">Commentaire:</span></div><div>${colis.commentaire}</div>' : ''}
        </div>

        <!-- Tarification -->
        <div class="section">
            <div class="section-title">TARIFICATION</div>
            <div class="row">
                <span class="label">Tarif base:</span>
                <span class="value">${colis.montantTarif.toStringAsFixed(0)} FCFA</span>
            </div>
            ${colis.tarifAgenceTransport != null && colis.tarifAgenceTransport! > 0 ? '<div class="row"><span class="label">Frais transport:</span><span class="value">${colis.tarifAgenceTransport!.toStringAsFixed(0)} FCFA</span></div>' : ''}
        </div>

        <!-- Total -->
        <div class="total">
            <div class="row">
                <span>TOTAL A PAYER:</span>
                <span>${colis.montantTarif.toStringAsFixed(0)} FCFA</span>
            </div>
        </div>

        <!-- Statut paiement -->
        <div class="section">
            <div class="row">
                <span class="label">Paiement:</span>
                <span class="value">${colis.isPaye ? 'PAYE' : 'NON PAYE'}</span>
            </div>
            ${colis.isPaye && colis.datePaiement != null ? '<div class="row"><span class="label">Date paiement:</span><span class="value">${colis.datePaiement!.day}/${colis.datePaiement!.month}/${colis.datePaiement!.year}</span></div>' : ''}
        </div>

        <!-- QR Code placeholder -->
        <div class="qr-placeholder">
            [QR CODE: ${colis.numeroSuivi}]<br>
            Scannez pour suivre votre colis
        </div>

        <!-- Pied de page -->
        <div class="footer">
            <div>Merci de votre confiance</div>
            <div>Gardez ce reçu pour le suivi</div>
            <div>www.corex.com</div>
            <div>Tel: +225 XX XX XX XX</div>
        </div>
    </div>

    <script>
        function downloadTicket() {
            // Créer une version simplifiée pour le téléchargement
            const ticketContent = document.querySelector('.ticket').outerHTML;
            const downloadHtml = `
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ticket COREX - ${colis.numeroSuivi}</title>
    <style>
        body { font-family: 'Courier New', monospace; margin: 20px; }
        .ticket { width: 80mm; margin: 0 auto; }
        .header { text-align: center; border-bottom: 2px solid #000; padding-bottom: 5px; margin-bottom: 10px; }
        .logo { font-size: 18px; font-weight: bold; margin-bottom: 2px; }
        .subtitle { font-size: 10px; margin-bottom: 5px; }
        .section { margin-bottom: 8px; }
        .section-title { font-weight: bold; font-size: 11px; border-bottom: 1px solid #000; margin-bottom: 3px; }
        .row { display: flex; justify-content: space-between; margin-bottom: 2px; }
        .label { font-weight: bold; }
        .value { text-align: right; }
        .numero-suivi { text-align: center; font-size: 14px; font-weight: bold; border: 2px solid #000; padding: 5px; margin: 10px 0; }
        .total { border-top: 2px solid #000; border-bottom: 2px solid #000; padding: 5px 0; margin: 10px 0; font-weight: bold; font-size: 14px; }
        .footer { text-align: center; font-size: 10px; margin-top: 15px; border-top: 1px dashed #000; padding-top: 5px; }
        .qr-placeholder { text-align: center; border: 1px solid #000; padding: 10px; margin: 10px 0; font-size: 10px; }
        @media print { @page { size: 80mm auto; margin: 0; } }
    </style>
</head>
<body>
    \${ticketContent}
</body>
</html>`;
            
            const blob = new Blob([downloadHtml], { type: 'text/html' });
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'ticket_corex_${colis.numeroSuivi}_${DateTime.now().millisecondsSinceEpoch}.html';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }
        
        // Auto-focus sur la fenêtre pour faciliter l'impression
        window.focus();
    </script>
</body>
</html>
    ''';
  }

  /// Télécharge le ticket en HTML (fallback)
  static void _downloadTicketAsHtml(String ticketHtml) {
    try {
      final bytes = Uint8List.fromList(ticketHtml.codeUnits);
      final blob = html.Blob([bytes], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute('download', 'ticket_corex_${DateTime.now().millisecondsSinceEpoch}.html')
        ..click();

      html.Url.revokeObjectUrl(url);

      print('✅ [TICKET] Ticket téléchargé en HTML');
    } catch (e) {
      print('❌ [TICKET] Erreur téléchargement: $e');
    }
  }

  /// Méthode simple pour téléchargement direct
  static Future<void> printTicketSimple({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
  }) async {
    try {
      print('🎫 [TICKET] Génération simple du ticket pour colis ${colis.numeroSuivi}');

      final ticketHtml = _generateCompleteTicketHtml(
        colis: colis,
        expediteur: expediteur,
        destinataire: destinataire,
      );

      // Télécharger directement le ticket
      _downloadTicketAsHtml(ticketHtml);

      print('✅ [TICKET] Ticket téléchargé pour impression');
    } catch (e) {
      print('❌ [TICKET] Erreur génération ticket simple: $e');
      throw Exception('Erreur lors de la génération du ticket: $e');
    }
  }
}
