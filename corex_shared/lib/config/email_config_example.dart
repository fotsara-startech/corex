/// Exemple de configuration SMTP pour kastraeg.com
///
/// Utilisez ces paramètres basés sur les informations de configuration
/// de votre serveur mail kastraeg.com

import '../services/email_service.dart';

class EmailConfigExample {
  /// Configure le service email avec les paramètres kastraeg.com
  static void configureKastraegSmtp() {
    final emailService = EmailService.instance;

    emailService.configureSmtpServer(
      host: 'kastraeg.com',
      port: 465, // Port SMTP SSL selon votre configuration
      username: 'notification@kastraeg.com',
      password: 'VOTRE_MOT_DE_PASSE_EMAIL', // À remplacer par le vrai mot de passe
      fromEmail: 'notification@kastraeg.com',
      fromName: 'COREX - Système de Notifications',
      ssl: true, // SSL activé pour le port 465
      allowInsecure: false,
    );
  }

  /// Configuration alternative avec TLS (port 587)
  static void configureKastraegSmtpTLS() {
    final emailService = EmailService.instance;

    emailService.configureSmtpServer(
      host: 'kastraeg.com',
      port: 587, // Port SMTP TLS
      username: 'notification@kastraeg.com',
      password: 'VOTRE_MOT_DE_PASSE_EMAIL',
      fromEmail: 'notification@kastraeg.com',
      fromName: 'COREX - Système de Notifications',
      ssl: false, // TLS au lieu de SSL
      allowInsecure: false,
    );
  }

  /// Test de configuration email
  static Future<void> testEmailConfiguration() async {
    try {
      final emailService = EmailService.instance;

      await emailService.sendCustomEmail(
        to: 'test@example.com',
        toName: 'Test User',
        subject: 'Test de configuration SMTP COREX',
        body: '''
        <h2>Test de configuration</h2>
        <p>Si vous recevez cet email, la configuration SMTP fonctionne correctement.</p>
        <p>Serveur: kastraeg.com</p>
        <p>Date: ${DateTime.now()}</p>
        ''',
      );

      print('✅ Email de test envoyé avec succès');
    } catch (e) {
      print('❌ Erreur lors du test email: $e');
    }
  }
}
