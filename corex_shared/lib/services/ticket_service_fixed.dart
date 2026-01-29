import 'dart:html' as html;
import 'dart:typed_data';
import '../models/colis_model.dart';
import '../models/client_model.dart';

class TicketServiceFixed {
  /// Génère et imprime un ticket de caisse pour un colis (version corrigée)
  static Future<void> generateAndPrintTicket({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
  }) async {
    try {
      print('🎫 [TICKET] Génération du ticket pour colis ${colis.numeroSuivi}');

      final ticketHtml = _generateTicketHtml(
        colis: colis,
        expediteur: expediteur,
        destinataire: destinataire,
      );

      // Utiliser la méthode la plus fiable
      await _printTicketReliable(ticketHtml);
      print('✅ [TICKET] Ticket envoyé à l\'imprimante');
    } catch (e) {
      print('❌ [TICKET] Erreur génération ticket: $e');
      throw Exception('Erreur lors de la génération du ticket: $e');
    }
  }

  /// Méthode d'impression fiable
  static Future<void> _printTicketReliable(String ticketHtml) async {
    try {
      // Créer le HTML avec script d'auto-impression
      final printableHtml = _createPrintableHtml(ticketHtml);

      // Encoder en base64 pour data URL
      final encodedHtml = html.window.btoa(printableHtml);
      final dataUrl = 'data:text/html;charset=utf-8;base64,$encodedHtml';

      // Ouvrir dans une nouvelle fenêtre
      final printWindow = html.window.open(dataUrl, '_blank', 'width=400,height=700,scrollbars=yes,resizable=yes');

      if (printWindow != null) {
        print('✅ [TICKET] Fenêtre d\'impression ouverte');

        // La fenêtre se fermera automatiquement après impression
        // grâce au script intégré
      } else {
        throw Exception('Impossible d\'ouvrir la fenêtre d\'impression');
      }
    } catch (e) {
      print('❌ [TICKET] Erreur impression: $e');
      // Fallback: télécharger le fichier
      _downloadTicketAsHtml(ticketHtml);
    }
  }

  /// Crée un HTML avec script d'auto-impression
  static String _createPrintableHtml(String ticketContent) {
    // Extraire le contenu du body du ticket
    final bodyStart = ticketContent.indexOf('<body>');
    final bodyEnd = ticketContent.indexOf('</body>') + 7;
    final bodyContent = bodyStart != -1 && bodyEnd != -1 ? ticketContent.substring(bodyStart + 6, bodyEnd - 7) : ticketContent;

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Impression Ticket COREX</title>
    <style>
        @page {
            size: 80mm auto;
            margin: 0;
        }
        
        body {
            font-family: 'Courier New', monospace;
            font-size: 12px;
            line-height: 1.2;
            margin: 0;
            padding: 5mm;
            width: 70mm;
            color: #000;
            background: #fff;
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
                -webkit-print-color-adjust: exact;
                print-color-adjust: exact;
            }
        }
    </style>
    <script>
        window.onload = function() {
            // Attendre un peu que le contenu soit rendu
            setTimeout(function() {
                // Déclencher l'impression
                window.print();
                
                // Fermer la fenêtre après impression (ou annulation)
                setTimeout(function() {
                    window.close();
                }, 2000);
            }, 1000);
        };
        
        // Gérer l'événement après impression
        window.onafterprint = function() {
            setTimeout(function() {
                window.close();
            }, 500);
        };
    </script>
</head>
<body>
$bodyContent
</body>
</html>
    ''';
  }

  /// Génère le HTML du ticket de caisse (80mm)
  static String _generateTicketHtml({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return '''
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
            <span class="value">${colis.poids.toStringAsFixed(1)} kg</span>
        </div>
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
        [QR CODE: ${colis.numeroSuivi}]
        Scannez pour suivre votre colis
    </div>

    <!-- Pied de page -->
    <div class="footer">
        <div>Merci de votre confiance</div>
        <div>Gardez ce reçu pour le suivi</div>
        <div>www.corex.com</div>
        <div>Tel: +225 XX XX XX XX</div>
    </div>
    ''';
  }

  /// Télécharge le ticket en HTML (fallback)
  static void _downloadTicketAsHtml(String ticketHtml) {
    try {
      final completeHtml = _createPrintableHtml(ticketHtml);
      final bytes = Uint8List.fromList(completeHtml.codeUnits);
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

      final ticketHtml = _generateTicketHtml(
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
