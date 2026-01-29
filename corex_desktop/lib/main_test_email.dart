import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser seulement les services nécessaires pour les emails
  Get.put(EmailService());
  Get.put(NotificationService());

  runApp(EmailTestApp());
}

class EmailTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'COREX Email Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: EmailTestScreen(),
    );
  }
}

class EmailTestScreen extends StatefulWidget {
  @override
  _EmailTestScreenState createState() => _EmailTestScreenState();
}

class _EmailTestScreenState extends State<EmailTestScreen> {
  final EmailService emailService = EmailService.instance;
  bool isLoading = false;
  String result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Configuration SMTP COREX'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration SMTP Actuelle',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('Serveur: kastraeg.com:587'),
                    Text('Username: notification@kastraeg.com'),
                    Text('SSL: Désactivé (certificat expiré)'),
                    Text('Sécurité: allowInsecure + ignoreBadCertificate'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _testCurrentConfig,
              child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Tester Configuration Actuelle'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : _testMultipleConfigs,
              child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Tester Toutes les Configurations'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: isLoading ? null : _sendTestEmail,
              child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Envoyer Email de Test'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Résultats des Tests',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            result.isEmpty ? 'Aucun test effectué' : result,
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testCurrentConfig() async {
    setState(() {
      isLoading = true;
      result = 'Test de la configuration actuelle...\n';
    });

    try {
      final success = await emailService.testCurrentSmtpConfig();
      setState(() {
        result += success ? '✅ Configuration actuelle fonctionne !\n' : '❌ Configuration actuelle échoue\n';
      });
    } catch (e) {
      setState(() {
        result += '❌ Erreur: $e\n';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _testMultipleConfigs() async {
    setState(() {
      isLoading = true;
      result = 'Test de toutes les configurations...\n';
    });

    try {
      await emailService.testMultipleSmtpConfigurations();
      setState(() {
        result += '✅ Tests terminés - Vérifiez la console pour les détails\n';
      });
    } catch (e) {
      setState(() {
        result += '❌ Erreur lors des tests: $e\n';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _sendTestEmail() async {
    setState(() {
      isLoading = true;
      result = 'Envoi d\'un email de test...\n';
    });

    try {
      await emailService.sendCustomEmail(
        to: 'manuel@kastraeg.com',
        toName: 'Manuel Test',
        subject: 'COREX - Test Email ${DateTime.now()}',
        body: '''
        <h2>Test Email COREX</h2>
        <p>Ceci est un email de test envoyé depuis l'application COREX Desktop.</p>
        <p><strong>Date:</strong> ${DateTime.now()}</p>
        <p><strong>Configuration:</strong> kastraeg.com:587</p>
        <p><strong>Status:</strong> Email envoyé avec succès !</p>
        ''',
      );

      setState(() {
        result += '✅ Email de test ajouté à la file d\'attente\n';
        result += 'Vérifiez la console pour le statut d\'envoi\n';
      });
    } catch (e) {
      setState(() {
        result += '❌ Erreur lors de l\'envoi: $e\n';
      });
    }

    setState(() {
      isLoading = false;
    });
  }
}
