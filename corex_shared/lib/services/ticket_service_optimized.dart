import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import '../models/colis_model.dart';
import '../models/client_model.dart';
import '../models/agence_model.dart';

class TicketServiceOptimized {
  /// Génère et traite un ticket de caisse pour un colis (version optimisée)
  static Future<void> generateAndPrintTicket({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
    AgenceModel? agence,
  }) async {
    try {
      print('🎫 [TICKET] Génération optimisée du ticket pour colis ${colis.numeroSuivi}');

      // 1. Générer le QR code
      final qrCodeDataUrl = _generateQRCode(colis.numeroSuivi);

      // 2. Générer le HTML du ticket
      final ticketHtml = _generateOptimizedTicketHtml(
        colis: colis,
        expediteur: expediteur,
        destinataire: destinataire,
        agence: agence,
        qrCodeDataUrl: qrCodeDataUrl,
      );

      // 3. Télécharger automatiquement en PDF
      await _downloadAsPDF(ticketHtml, colis.numeroSuivi);

      // 4. Ouvrir directement l'interface d'impression
      await _openPrintDialog(ticketHtml);

      print('✅ [TICKET] Ticket généré, téléchargé et envoyé à l\'impression');
    } catch (e) {
      print('❌ [TICKET] Erreur génération ticket optimisé: $e');
      throw Exception('Erreur lors de la génération du ticket: $e');
    }
  }

  /// Génère un QR code en Data URL
  static String _generateQRCode(String data) {
    try {
      // Utiliser une API de génération de QR code en ligne
      final qrApiUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=${Uri.encodeComponent(data)}';
      return qrApiUrl;
    } catch (e) {
      print('⚠️ [TICKET] Erreur génération QR code: $e');
      // Fallback: retourner un placeholder
      return 'data:image/svg+xml;base64,${base64Encode(utf8.encode(_generateQRPlaceholder(data)))}';
    }
  }

  /// Génère un placeholder SVG pour le QR code
  static String _generateQRPlaceholder(String data) {
    return '''
<svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
  <rect width="100" height="100" fill="white" stroke="black" stroke-width="2"/>
  <text x="50" y="30" text-anchor="middle" font-family="Arial" font-size="8" fill="black">QR CODE</text>
  <text x="50" y="50" text-anchor="middle" font-family="Arial" font-size="6" fill="black">${data.length > 15 ? data.substring(0, 15) + '...' : data}</text>
  <text x="50" y="70" text-anchor="middle" font-family="Arial" font-size="6" fill="black">Scan pour suivi</text>
</svg>
    ''';
  }

  /// Télécharge le ticket en PDF
  static Future<void> _downloadAsPDF(String ticketHtml, String numeroSuivi) async {
    try {
      // Créer le HTML optimisé pour PDF
      final pdfHtml = _createPDFOptimizedHtml(ticketHtml);

      // Créer un blob et télécharger
      final bytes = Uint8List.fromList(pdfHtml.codeUnits);
      final blob = html.Blob([bytes], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'ticket_corex_${numeroSuivi}_${DateTime.now().millisecondsSinceEpoch}.html')
        ..style.display = 'none';

      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);

      print('✅ [TICKET] Ticket téléchargé automatiquement');
    } catch (e) {
      print('❌ [TICKET] Erreur téléchargement PDF: $e');
    }
  }

  /// Ouvre directement l'interface d'impression
  static Future<void> _openPrintDialog(String ticketHtml) async {
    try {
      // Créer le HTML optimisé pour impression
      final printHtml = _createPrintOptimizedHtml(ticketHtml);

      // Créer un blob
      final blob = html.Blob([printHtml], 'text/html');
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);

      final printWindow = html.window.open(blobUrl, '_blank', 'width=400,height=600,scrollbars=no,resizable=no,toolbar=no,menubar=no');

      if (printWindow != null) {
        print('✅ [TICKET] Interface d\'impression ouverte - impression automatique');

        // Nettoyer après un délai
        Future.delayed(const Duration(seconds: 5), () {
          html.Url.revokeObjectUrl(blobUrl);
        });
      } else {
        throw Exception('Impossible d\'ouvrir l\'interface d\'impression');
      }
    } catch (e) {
      print('❌ [TICKET] Erreur ouverture impression: $e');
    }
  }

  /// Crée un HTML optimisé pour PDF
  static String _createPDFOptimizedHtml(String ticketContent) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ticket COREX PDF</title>
    <style>
        @page { size: A4; margin: 20mm; }
        body { font-family: 'Courier New', monospace; margin: 0; padding: 20px; }
        .ticket { max-width: 80mm; margin: 0 auto; }
        .header { text-align: center; border-bottom: 2px solid #000; padding-bottom: 10px; margin-bottom: 15px; }
        .logo { font-size: 20px; font-weight: bold; margin-bottom: 5px; }
        .agence-info { font-size: 10px; margin-bottom: 3px; }
        .section { margin-bottom: 10px; }
        .section-title { font-weight: bold; font-size: 12px; border-bottom: 1px solid #000; margin-bottom: 5px; }
        .row { display: flex; justify-content: space-between; margin-bottom: 3px; }
        .numero-suivi { text-align: center; font-size: 16px; font-weight: bold; border: 2px solid #000; padding: 8px; margin: 15px 0; }
        .total { border-top: 2px solid #000; border-bottom: 2px solid #000; padding: 8px 0; margin: 15px 0; font-weight: bold; font-size: 16px; }
        .qr-code { text-align: center; margin: 15px 0; }
        .qr-code img { width: 80px; height: 80px; }
        .footer { text-align: center; font-size: 10px; margin-top: 20px; border-top: 1px dashed #000; padding-top: 10px; }
    </style>
</head>
<body>
    $ticketContent
</body>
</html>
    ''';
  }

  /// Crée un HTML optimisé pour impression directe
  static String _createPrintOptimizedHtml(String ticketContent) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Impression Ticket COREX</title>
    <style>
        @page { size: 80mm auto; margin: 0; }
        body { font-family: 'Courier New', monospace; margin: 0; padding: 5mm; width: 70mm; }
        .header { text-align: center; border-bottom: 2px solid #000; padding-bottom: 5px; margin-bottom: 10px; }
        .logo { font-size: 18px; font-weight: bold; margin-bottom: 2px; }
        .agence-info { font-size: 9px; margin-bottom: 2px; }
        .section { margin-bottom: 8px; }
        .section-title { font-weight: bold; font-size: 11px; border-bottom: 1px solid #000; margin-bottom: 3px; }
        .row { display: flex; justify-content: space-between; margin-bottom: 2px; font-size: 10px; }
        .numero-suivi { text-align: center; font-size: 14px; font-weight: bold; border: 2px solid #000; padding: 5px; margin: 10px 0; }
        .total { border-top: 2px solid #000; border-bottom: 2px solid #000; padding: 5px 0; margin: 10px 0; font-weight: bold; font-size: 14px; }
        .qr-code { text-align: center; margin: 10px 0; }
        .qr-code img { width: 60px; height: 60px; }
        .footer { text-align: center; font-size: 9px; margin-top: 15px; border-top: 1px dashed #000; padding-top: 5px; }
        @media print { body { -webkit-print-color-adjust: exact; print-color-adjust: exact; } }
    </style>
    <script>
        window.onload = function() {
            // Déclencher l'impression immédiatement après le chargement
            setTimeout(function() {
                window.print();
                // Fermer la fenêtre après impression ou annulation
                setTimeout(function() {
                    window.close();
                }, 2000);
            }, 100);
        };
        
        // Fermer la fenêtre après impression
        window.onafterprint = function() {
            setTimeout(function() {
                window.close();
            }, 500);
        };
        
        // Fermer aussi si l'utilisateur annule l'impression
        window.onbeforeunload = function() {
            return null;
        };
    </script>
</head>
<body>
    $ticketContent
</body>
</html>
    ''';
  }

  /// Génère le HTML optimisé du ticket
  static String _generateOptimizedTicketHtml({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
    AgenceModel? agence,
    required String qrCodeDataUrl,
  }) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Informations de l'agence
    final agenceNom = agence?.nom ?? 'COREX';
    final agenceAdresse = agence?.adresse ?? 'Adresse non spécifiée';
    final agenceTelephone = agence?.telephone ?? 'Tel: +225 XX XX XX XX';
    final agenceEmail = agence?.email ?? 'contact@corex.com';

    return '''
<div class="ticket">
    <!-- En-tête avec informations agence -->
    <div class="header">
        <div class="logo">$agenceNom</div>
        <div class="agence-info">$agenceAdresse</div>
        <div class="agence-info">$agenceTelephone</div>
        <div class="agence-info">$agenceEmail</div>
        <div class="agence-info">$dateStr - $timeStr</div>
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
        ${expediteur != null && expediteur.adresse != null && expediteur.adresse.isNotEmpty ? '<div>${expediteur.adresse}</div>' : ''}
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
            <span>Contenu:</span>
            <span>${colis.contenu}</span>
        </div>
        <div class="row">
            <span>Poids:</span>
            <span>${colis.poids.toStringAsFixed(1)} kg</span>
        </div>
        ${colis.dimensions != null ? '<div class="row"><span>Dimensions:</span><span>${colis.dimensions}</span></div>' : ''}
        ${colis.commentaire != null && colis.commentaire!.isNotEmpty ? '<div class="row"><span>Commentaire:</span></div><div style="font-size: 9px; margin-top: 3px;">${colis.commentaire}</div>' : ''}
    </div>

    <!-- Tarification -->
    <div class="section">
        <div class="section-title">TARIFICATION</div>
        <div class="row">
            <span>Tarif base:</span>
            <span>${colis.montantTarif.toStringAsFixed(0)} FCFA</span>
        </div>
        ${colis.tarifAgenceTransport != null && colis.tarifAgenceTransport! > 0 ? '<div class="row"><span>Frais transport:</span><span>${colis.tarifAgenceTransport!.toStringAsFixed(0)} FCFA</span></div>' : ''}
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
            <span>Paiement:</span>
            <span>${colis.isPaye ? 'PAYE' : 'NON PAYE'}</span>
        </div>
        ${colis.isPaye && colis.datePaiement != null ? '<div class="row"><span>Date paiement:</span><span>${colis.datePaiement!.day}/${colis.datePaiement!.month}/${colis.datePaiement!.year}</span></div>' : ''}
    </div>

    <!-- QR Code -->
    <div class="qr-code">
        <img src="$qrCodeDataUrl" alt="QR Code ${colis.numeroSuivi}" />
        <div style="font-size: 9px; margin-top: 3px;">Scannez pour suivre</div>
    </div>

    <!-- Pied de page -->
    <div class="footer">
        <div>Merci de votre confiance</div>
        <div>Gardez ce reçu pour le suivi</div>
        <div>www.corex.com</div>
    </div>
</div>
    ''';
  }

  /// Méthode simple pour téléchargement direct uniquement
  static Future<void> downloadTicketOnly({
    required ColisModel colis,
    ClientModel? expediteur,
    ClientModel? destinataire,
    AgenceModel? agence,
  }) async {
    try {
      print('💾 [TICKET] Téléchargement simple du ticket pour colis ${colis.numeroSuivi}');

      // Générer le QR code
      final qrCodeDataUrl = _generateQRCode(colis.numeroSuivi);

      // Générer le HTML du ticket
      final ticketHtml = _generateOptimizedTicketHtml(
        colis: colis,
        expediteur: expediteur,
        destinataire: destinataire,
        agence: agence,
        qrCodeDataUrl: qrCodeDataUrl,
      );

      // Télécharger uniquement
      await _downloadAsPDF(ticketHtml, colis.numeroSuivi);

      print('✅ [TICKET] Ticket téléchargé uniquement');
    } catch (e) {
      print('❌ [TICKET] Erreur téléchargement simple: $e');
      throw Exception('Erreur lors du téléchargement du ticket: $e');
    }
  }
}
