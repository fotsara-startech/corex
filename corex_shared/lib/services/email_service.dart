import 'dart:async';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:get/get.dart';
import '../models/colis_model.dart';
import '../models/user_model.dart';
import '../models/livraison_model.dart';

class EmailService extends GetxService {
  static EmailService get instance => Get.find<EmailService>();

  // Configuration SMTP
  late SmtpServer _smtpServer;
  late String _fromEmail;
  late String _fromName;

  // File d'attente des emails
  final List<EmailTask> _emailQueue = [];
  bool _isProcessing = false;

  @override
  void onInit() {
    super.onInit();
    _initializeEmailConfig();
    _startEmailProcessor();
  }

  /// Configure le serveur SMTP avec des paramètres personnalisés
  void configureSmtpServer({
    required String host,
    required int port,
    required String username,
    required String password,
    required String fromEmail,
    required String fromName,
    bool ssl = true,
    bool allowInsecure = false,
    bool ignoreBadCertificate = false,
  }) {
    _smtpServer = SmtpServer(
      host,
      port: port,
      username: username,
      password: password,
      ssl: ssl,
      allowInsecure: allowInsecure,
      ignoreBadCertificate: ignoreBadCertificate,
    );

    _fromEmail = fromEmail;
    _fromName = fromName;

    print('✅ Configuration SMTP mise à jour: $host:$port');
  }

  void _initializeEmailConfig() {
    // Configuration SMTP pour kastraeg.com avec gestion du certificat expiré
    _smtpServer = SmtpServer(
      'kastraeg.com',
      port: 587, // Port TLS standard
      username: 'notification@kastraeg.com',
      password: 'l[bNMaG%MZTL',
      ssl: false, // Pas de SSL direct
      allowInsecure: true, // Permettre les connexions non sécurisées
      ignoreBadCertificate: true, // Ignorer les certificats invalides
    );

    _fromEmail = 'notification@kastraeg.com';
    _fromName = 'COREX - Système de Notifications';
  }

  /// Démarre le processeur de file d'attente d'emails
  void _startEmailProcessor() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_isProcessing && _emailQueue.isNotEmpty) {
        _processEmailQueue();
      }
    });
  }

  /// Traite la file d'attente des emails
  Future<void> _processEmailQueue() async {
    if (_emailQueue.isEmpty) return;

    _isProcessing = true;

    while (_emailQueue.isNotEmpty) {
      final emailTask = _emailQueue.removeAt(0);

      try {
        await _sendEmailInternal(emailTask);
        _logEmailSuccess(emailTask);
      } catch (e) {
        _logEmailError(emailTask, e.toString());

        // Retry logic - remettre en queue si moins de 3 tentatives
        if (emailTask.retryCount < 3) {
          emailTask.retryCount++;
          _emailQueue.add(emailTask);
        }
      }

      // Délai entre les envois pour éviter le spam
      await Future.delayed(const Duration(seconds: 2));
    }

    _isProcessing = false;
  }

  /// Envoie un email de changement de statut de colis
  Future<void> sendColisStatusChangeEmail({
    required ColisModel colis,
    required String newStatus,
    required String recipientEmail,
    required String recipientName,
  }) async {
    final subject = 'COREX - Mise à jour de votre colis ${colis.numeroSuivi}';
    final body = _buildColisStatusEmailBody(colis, newStatus, recipientName);

    final emailTask = EmailTask(
      to: recipientEmail,
      toName: recipientName,
      subject: subject,
      body: body,
      type: EmailType.colisStatus,
      relatedId: colis.id,
    );

    _emailQueue.add(emailTask);
  }

  /// Envoie un email d'arrivée à destination
  Future<void> sendColisArrivalEmail({
    required ColisModel colis,
    required String destinataireEmail,
    required String destinataireName,
  }) async {
    final subject = 'COREX - Votre colis ${colis.numeroSuivi} est arrivé à destination';
    final body = _buildColisArrivalEmailBody(colis, destinataireName);

    final emailTask = EmailTask(
      to: destinataireEmail,
      toName: destinataireName,
      subject: subject,
      body: body,
      type: EmailType.colisArrival,
      relatedId: colis.id,
    );

    _emailQueue.add(emailTask);
  }

  /// Envoie un email d'attribution de livraison au coursier
  Future<void> sendLivraisonAttributionEmail({
    required LivraisonModel livraison,
    required ColisModel colis,
    required UserModel coursier,
  }) async {
    final subject = 'COREX - Nouvelle livraison attribuée';
    final body = _buildLivraisonAttributionEmailBody(livraison, colis, coursier);

    final emailTask = EmailTask(
      to: coursier.email,
      toName: coursier.nom,
      subject: subject,
      body: body,
      type: EmailType.livraisonAttribution,
      relatedId: livraison.id,
    );

    _emailQueue.add(emailTask);
  }

  /// Envoie un email de facturation
  Future<void> sendFactureEmail({
    required String clientEmail,
    required String clientName,
    required String factureId,
    required double montant,
    required String periode,
    String? pdfPath,
  }) async {
    final subject = 'COREX - Facture de stockage $periode';
    final body = _buildFactureEmailBody(clientName, factureId, montant, periode);

    final emailTask = EmailTask(
      to: clientEmail,
      toName: clientName,
      subject: subject,
      body: body,
      type: EmailType.facture,
      relatedId: factureId,
      attachmentPath: pdfPath,
    );

    _emailQueue.add(emailTask);
  }

  /// Envoie un email personnalisé
  Future<void> sendCustomEmail({
    required String to,
    required String toName,
    required String subject,
    required String body,
    String? attachmentPath,
  }) async {
    final emailTask = EmailTask(
      to: to,
      toName: toName,
      subject: subject,
      body: body,
      type: EmailType.custom,
      attachmentPath: attachmentPath,
    );

    _emailQueue.add(emailTask);
  }

  /// Envoie effectivement l'email
  Future<void> _sendEmailInternal(EmailTask emailTask) async {
    final message = Message()
      ..from = Address(_fromEmail, _fromName)
      ..recipients.add(Address(emailTask.to, emailTask.toName))
      ..subject = emailTask.subject
      ..html = emailTask.body;

    // Ajouter une pièce jointe si spécifiée
    if (emailTask.attachmentPath != null && emailTask.attachmentPath!.isNotEmpty) {
      final file = File(emailTask.attachmentPath!);
      if (await file.exists()) {
        message.attachments.add(FileAttachment(file));
      }
    }

    await send(message, _smtpServer);
  }

  /// Construit le corps de l'email pour changement de statut
  String _buildColisStatusEmailBody(ColisModel colis, String newStatus, String recipientName) {
    final statusText = _getStatusDisplayText(newStatus);

    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; margin-bottom: 30px; }
            .logo { color: #2E7D32; font-size: 24px; font-weight: bold; }
            .status { background-color: #E8F5E8; padding: 15px; border-radius: 5px; margin: 20px 0; text-align: center; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">COREX</div>
                <h2>Mise à jour de votre colis</h2>
            </div>
            <p>Bonjour $recipientName,</p>
            <div class="status">
                <h3>Nouveau statut : $statusText</h3>
            </div>
            <p><strong>Numéro de suivi :</strong> ${colis.numeroSuivi}</p>
        </div>
    </body>
    </html>
    ''';
  }

  /// Construit le corps de l'email d'arrivée à destination
  String _buildColisArrivalEmailBody(ColisModel colis, String destinataireName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; margin-bottom: 30px; }
            .logo { color: #2E7D32; font-size: 24px; font-weight: bold; }
            .arrival { background-color: #E8F5E8; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">COREX</div>
                <h2>Votre colis est arrivé !</h2>
            </div>
            <p>Bonjour $destinataireName,</p>
            <div class="arrival">
                <h3>🎉 Bonne nouvelle !</h3>
                <p>Votre colis est arrivé à destination et sera bientôt livré.</p>
            </div>
            <p><strong>Numéro de suivi :</strong> ${colis.numeroSuivi}</p>
            <p><strong>Expéditeur :</strong> ${colis.expediteurNom}</p>
        </div>
    </body>
    </html>
    ''';
  }

  /// Construit le corps de l'email d'attribution de livraison
  String _buildLivraisonAttributionEmailBody(LivraisonModel livraison, ColisModel colis, UserModel coursier) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; margin-bottom: 30px; }
            .logo { color: #2E7D32; font-size: 24px; font-weight: bold; }
            .assignment { background-color: #E3F2FD; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">COREX</div>
                <h2>Nouvelle livraison attribuée</h2>
            </div>
            <p>Bonjour ${coursier.nom},</p>
            <div class="assignment">
                <h3>📦 Nouvelle mission de livraison</h3>
                <p>Une nouvelle livraison vous a été attribuée.</p>
            </div>
            <p><strong>Numéro de suivi :</strong> ${colis.numeroSuivi}</p>
            <p><strong>Destinataire :</strong> ${colis.destinataireNom}</p>
            <p><strong>Adresse :</strong> ${colis.destinataireAdresse}</p>
        </div>
    </body>
    </html>
    ''';
  }

  /// Construit le corps de l'email de facturation
  String _buildFactureEmailBody(String clientName, String factureId, double montant, String periode) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
            .container { max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; }
            .header { text-align: center; margin-bottom: 30px; }
            .logo { color: #2E7D32; font-size: 24px; font-weight: bold; }
            .invoice { background-color: #FFF3E0; padding: 20px; border-radius: 5px; margin: 20px 0; text-align: center; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="logo">COREX</div>
                <h2>Facture de stockage</h2>
            </div>
            <p>Bonjour $clientName,</p>
            <div class="invoice">
                <h3>📄 Nouvelle facture disponible</h3>
                <p>Votre facture de stockage pour la période $periode est disponible.</p>
            </div>
            <p><strong>Numéro de facture :</strong> $factureId</p>
            <p><strong>Montant :</strong> ${montant.toStringAsFixed(0)} FCFA</p>
        </div>
    </body>
    </html>
    ''';
  }

  /// Convertit le statut en texte lisible
  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'collecte':
        return 'Collecté';
      case 'enregistre':
        return 'Enregistré';
      case 'enTransit':
        return 'En transit';
      case 'arriveDestination':
        return 'Arrivé à destination';
      case 'enCoursLivraison':
        return 'En cours de livraison';
      case 'livre':
        return 'Livré';
      case 'retourne':
        return 'Retourné';
      default:
        return status;
    }
  }

  /// Log des succès d'envoi
  void _logEmailSuccess(EmailTask emailTask) {
    print('✅ Email envoyé avec succès: ${emailTask.type.name} -> ${emailTask.to}');
  }

  /// Log des erreurs d'envoi
  void _logEmailError(EmailTask emailTask, String error) {
    print('❌ Erreur envoi email: ${emailTask.type.name} -> ${emailTask.to} | Erreur: $error');
  }

  /// Teste différentes configurations SMTP pour kastraeg.com
  Future<void> testMultipleSmtpConfigurations() async {
    final configs = [
      {
        'name': 'Port 587 TLS',
        'host': 'kastraeg.com',
        'port': 587,
        'ssl': false,
        'allowInsecure': true,
        'ignoreBadCertificate': true,
      },
      {
        'name': 'Port 25 Plain',
        'host': 'kastraeg.com',
        'port': 25,
        'ssl': false,
        'allowInsecure': true,
        'ignoreBadCertificate': true,
      },
      {
        'name': 'Port 2079 Custom',
        'host': 'kastraeg.com',
        'port': 2079,
        'ssl': false,
        'allowInsecure': true,
        'ignoreBadCertificate': true,
      },
    ];

    for (final config in configs) {
      print('🔄 Test configuration: ${config['name']}');

      try {
        final testServer = SmtpServer(
          config['host'] as String,
          port: config['port'] as int,
          username: 'notification@kastraeg.com',
          password: 'l[bNMaG%MZTL',
          ssl: config['ssl'] as bool,
          allowInsecure: config['allowInsecure'] as bool,
          ignoreBadCertificate: config['ignoreBadCertificate'] as bool,
        );

        final message = Message()
          ..from = Address('notification@kastraeg.com', 'COREX Test')
          ..recipients.add(Address('manuel@kastraeg.com', 'Test'))
          ..subject = 'Test ${config['name']}'
          ..text = 'Test de configuration ${config['name']} - ${DateTime.now()}';

        await send(message, testServer);
        print('✅ ${config['name']} - SUCCÈS !');

        // Si cette config fonctionne, l'utiliser
        _smtpServer = testServer;
        break;
      } catch (e) {
        print('❌ ${config['name']} - Échec: $e');
      }
    }
  }

  /// Test simple de configuration SMTP
  Future<bool> testCurrentSmtpConfig() async {
    try {
      final message = Message()
        ..from = Address(_fromEmail, _fromName)
        ..recipients.add(Address('manuel@kastraeg.com', 'Test'))
        ..subject = 'COREX - Test SMTP ${DateTime.now()}'
        ..text = 'Test de la configuration SMTP actuelle';

      await send(message, _smtpServer);
      print('✅ Configuration SMTP actuelle fonctionne');
      return true;
    } catch (e) {
      print('❌ Configuration SMTP actuelle échoue: $e');
      return false;
    }
  }
}

/// Classe représentant une tâche d'email
class EmailTask {
  final String to;
  final String toName;
  final String subject;
  final String body;
  final EmailType type;
  final String? relatedId;
  final String? attachmentPath;
  int retryCount;

  EmailTask({
    required this.to,
    required this.toName,
    required this.subject,
    required this.body,
    required this.type,
    this.relatedId,
    this.attachmentPath,
    this.retryCount = 0,
  });
}

/// Types d'emails
enum EmailType {
  colisStatus,
  colisArrival,
  livraisonAttribution,
  facture,
  custom,
}
