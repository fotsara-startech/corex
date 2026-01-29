import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/colis_model.dart';
import '../models/client_model.dart';

class TicketService {
  /// Génère et imprime un ticket de caisse pour un colis
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

      if (kIsWeb) {
        await _printTicketWeb(ticketHtml);
      } else {
        // Pour desktop, on utilise aussi l'impression web
        await _printTicketWeb(ticketHtml);
      }

      print('✅ [TICKET] Ticket envoyé à l\'imprimante');
    } catch (e) {
      print('❌ [TICKET] Erreur génération ticket: $e');
      throw Exception('Erreur lors de la génération du ticket: $e');
    }
  }

  /// Méthode alternative avec data URL (plus compatible)
  static Future<void> generateAndPrintTicketDataUrl({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
  }) async {
    try {
      print('🎫 [TICKET] Génération du ticket (Data URL) pour colis ${colis.numeroSuivi}');

      final ticketHtml = _generateTicketHtml(
        colis: colis,
        expediteur: expediteur,
        destinataire: destinataire,
      );

      await _printViaDataUrl(ticketHtml);
      print('✅ [TICKET] Ticket envoyé à l\'imprimante via Data URL');
    } catch (e) {
      print('❌ [TICKET] Erreur génération ticket Data URL: $e');
      // Fallback vers téléchargement
      _downloadTicketAsHtml(_generateTicketHtml(
        colis: colis,
        expediteur: expediteur,
        destinataire: destinataire,
      ));
    }
  }

  /// Méthode alternative plus simple pour l'impression
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

      // Méthode simple: télécharger directement le ticket
      _downloadTicketAsHtml(ticketHtml);

      print('✅ [TICKET] Ticket téléchargé pour impression');
    } catch (e) {
      print('❌ [TICKET] Erreur génération ticket simple: $e');
      throw Exception('Erreur lors de la génération du ticket: $e');
    }
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
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Reçu COREX - ${colis.numeroSuivi}</title>
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
</head>
<body>
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
        ${expediteur?.adresse != null ? '<div>${expediteur!.adresse}</div>' : ''}
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
</body>
</html>
    ''';
  }

  /// Imprime le ticket via le navigateur web
  static Future<void> _printTicketWeb(String ticketHtml) async {
    try {
      // Méthode 1: Essayer avec Data URL (plus fiable)
      await _printViaDataUrl(ticketHtml);
    } catch (e) {
      print('❌ [TICKET] Erreur impression Data URL: $e');

      try {
        // Méthode 2: Essayer d'ouvrir dans une nouvelle fenêtre avec blob
        await _printViaNewWindow(ticketHtml);
      } catch (e2) {
        print('❌ [TICKET] Erreur impression nouvelle fenêtre: $e2');

        try {
          // Méthode 3: Essayer l'impression directe dans le document
          await _printViaDirectDocument(ticketHtml);
        } catch (e3) {
          print('❌ [TICKET] Erreur impression directe: $e3');

          // Fallback: télécharger le ticket en HTML
          print('🔄 [TICKET] Utilisation du fallback - téléchargement');
          _downloadTicketAsHtml(ticketHtml);
        }
      }
    }
  }

  /// Méthode d'impression via nouvelle fenêtre
  static Future<void> _printViaNewWindow(String ticketHtml) async {
    // Créer un blob avec le contenu HTML
    final blob = html.Blob([ticketHtml], 'text/html');
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    try {
      // Ouvrir dans une nouvelle fenêtre avec des dimensions adaptées au ticket
      final printWindow = html.window.open(blobUrl, '_blank', 'width=400,height=700,scrollbars=yes,resizable=yes');

      if (printWindow != null) {
        print('✅ [TICKET] Fenêtre d\'impression ouverte');
        // Note: L'utilisateur devra déclencher l'impression manuellement
        // ou utiliser TicketServiceFixed pour l'auto-impression
      } else {
        throw Exception('Impossible d\'ouvrir la fenêtre d\'impression');
      }
    } finally {
      // Nettoyer l'URL blob
      Future.delayed(const Duration(milliseconds: 5000), () {
        html.Url.revokeObjectUrl(blobUrl);
      });
    }
  }

  /// Méthode d'impression via document direct
  static Future<void> _printViaDirectDocument(String ticketHtml) async {
    // Sauvegarder le contenu actuel
    final originalContent = html.document.body!.innerHtml;
    final originalTitle = html.document.title;

    try {
      // Remplacer temporairement le contenu de la page
      html.document.title = 'Impression Ticket COREX';
      html.document.body!.innerHtml = ticketHtml;

      // Attendre un peu pour que le contenu soit rendu
      await Future.delayed(const Duration(milliseconds: 500));

      // Déclencher l'impression
      html.window.print();
      print('✅ [TICKET] Impression lancée via document direct');
    } finally {
      // Restaurer le contenu original après un délai
      Future.delayed(const Duration(milliseconds: 1000), () {
        html.document.body!.innerHtml = originalContent;
        html.document.title = originalTitle;
      });
    }
  }

  /// Méthode d'impression via Data URL
  static Future<void> _printViaDataUrl(String ticketHtml) async {
    try {
      // Encoder le HTML en base64 pour créer une data URL
      final encodedHtml = html.window.btoa(ticketHtml);
      final dataUrl = 'data:text/html;base64,$encodedHtml';

      // Ouvrir dans une nouvelle fenêtre
      final printWindow = html.window.open(dataUrl, '_blank', 'width=400,height=700,scrollbars=yes,resizable=yes');

      if (printWindow != null) {
        print('✅ [TICKET] Fenêtre d\'impression ouverte via Data URL');
        // Note: L'utilisateur devra déclencher l'impression manuellement
        // ou utiliser TicketServiceFixed pour l'auto-impression
      } else {
        throw Exception('Impossible d\'ouvrir la fenêtre d\'impression avec Data URL');
      }
    } catch (e) {
      print('❌ [TICKET] Erreur impression Data URL: $e');
      throw e;
    }
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

  /// Génère un ticket simple en texte brut (pour debug)
  static String generateTextTicket({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return '''
================================
           COREX
    Système de Gestion de Colis
        $dateStr
================================

NUMERO DE SUIVI: ${colis.numeroSuivi}

EXPEDITEUR:
${expediteur?.nom ?? colis.expediteurNom}
${expediteur?.telephone ?? colis.expediteurTelephone}

DESTINATAIRE:
${destinataire?.nom ?? colis.destinataireNom}
${destinataire?.telephone ?? colis.destinataireTelephone}
${colis.destinataireAdresse}
${colis.destinataireVille}

DETAILS COLIS:
Contenu: ${colis.contenu}
Poids: ${colis.poids.toStringAsFixed(1)} kg
${colis.dimensions != null ? 'Dimensions: ${colis.dimensions}' : ''}

TARIFICATION:
Tarif: ${colis.montantTarif.toStringAsFixed(0)} FCFA
${colis.tarifAgenceTransport != null && colis.tarifAgenceTransport! > 0 ? 'Frais transport: ${colis.tarifAgenceTransport!.toStringAsFixed(0)} FCFA' : ''}

TOTAL: ${colis.montantTarif.toStringAsFixed(0)} FCFA
Paiement: ${colis.isPaye ? 'PAYE' : 'NON PAYE'}

================================
    Merci de votre confiance
   Gardez ce reçu pour le suivi
================================
    ''';
  }
}
