// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:corex_shared/corex_shared.dart';
// import 'package:window_manager/window_manager.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Configuration de la fenêtre Windows
//   await windowManager.ensureInitialized();

//   WindowOptions windowOptions = const WindowOptions(
//     size: Size(1280, 720),
//     minimumSize: Size(800, 600),
//     center: true,
//     backgroundColor: Colors.transparent,
//     skipTaskbar: false,
//     titleBarStyle: TitleBarStyle.normal,
//   );

//   windowManager.waitUntilReadyToShow(windowOptions, () async {
//     await windowManager.show();
//     await windowManager.focus();
//   });

//   // Initialisation de Hive pour le stockage local
//   await Hive.initFlutter();

//   // Enregistrement des adapters Hive
//   if (!Hive.isAdapterRegistered(0)) {
//     Hive.registerAdapter(ColisModelAdapter());
//   }
//   // Supprimer les adapters non disponibles pour l'instant
//   // if (!Hive.isAdapterRegistered(1)) {
//   //   Hive.registerAdapter(UserModelAdapter());
//   // }
//   // if (!Hive.isAdapterRegistered(2)) {
//   //   Hive.registerAdapter(LivraisonModelAdapter());
//   // }

//   // Initialisation des services
//   await _initializeServices();

//   runApp(CorexDesktopApp());
// }

// Future<void> _initializeServices() async {
//   // Services de base (sans Firebase)
//   Get.put(EmailService(), permanent: true);
//   Get.put(NotificationService(), permanent: true);
//   Get.put(LocalColisRepository(), permanent: true);

//   // Test de la configuration email au démarrage
//   try {
//     final emailService = EmailService.instance;
//     print('🔄 Test de la configuration SMTP au démarrage...');
//     await emailService.testCurrentSmtpConfig();
//   } catch (e) {
//     print('⚠️ Erreur lors du test SMTP: $e');
//   }
// }

// class CorexDesktopApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'COREX Desktop (Test Email)',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//       home: EmailTestHomeScreen(),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }

// class EmailTestHomeScreen extends StatefulWidget {
//   @override
//   _EmailTestHomeScreenState createState() => _EmailTestHomeScreenState();
// }

// class _EmailTestHomeScreenState extends State<EmailTestHomeScreen> {
//   final EmailService emailService = EmailService.instance;
//   bool isLoading = false;
//   String logs = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('COREX Desktop - Test Configuration Email'),
//         backgroundColor: Colors.green[700],
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Row(
//           children: [
//             // Panel de gauche - Contrôles
//             Expanded(
//               flex: 1,
//               child: Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       Text(
//                         'Configuration SMTP',
//                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 16),
//                       _buildInfoCard(),
//                       SizedBox(height: 20),
//                       Text(
//                         'Tests Disponibles',
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 10),
//                       _buildTestButton(
//                         'Test Configuration Actuelle',
//                         _testCurrentConfig,
//                         Icons.settings,
//                       ),
//                       SizedBox(height: 8),
//                       _buildTestButton(
//                         'Test Toutes Configurations',
//                         _testAllConfigs,
//                         Icons.search,
//                       ),
//                       SizedBox(height: 8),
//                       _buildTestButton(
//                         'Envoyer Email Test',
//                         _sendTestEmail,
//                         Icons.email,
//                       ),
//                       SizedBox(height: 8),
//                       _buildTestButton(
//                         'Test Notification Colis',
//                         _testColisNotification,
//                         Icons.local_shipping,
//                       ),
//                       SizedBox(height: 20),
//                       ElevatedButton.icon(
//                         onPressed: _clearLogs,
//                         icon: Icon(Icons.clear),
//                         label: Text('Effacer Logs'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.grey[600],
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(width: 20),
//             // Panel de droite - Logs
//             Expanded(
//               flex: 2,
//               child: Card(
//                 child: Padding(
//                   padding: EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Logs des Tests',
//                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       SizedBox(height: 16),
//                       Expanded(
//                         child: Container(
//                           width: double.infinity,
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[100],
//                             border: Border.all(color: Colors.grey[300]!),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: SingleChildScrollView(
//                             child: Text(
//                               logs.isEmpty ? 'Aucun test effectué...' : logs,
//                               style: TextStyle(
//                                 fontFamily: 'monospace',
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard() {
//     return Container(
//       padding: EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         border: Border.all(color: Colors.blue[200]!),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Serveur: kastraeg.com:587', style: TextStyle(fontSize: 12)),
//           Text('Username: notification@kastraeg.com', style: TextStyle(fontSize: 12)),
//           Text('SSL: Désactivé', style: TextStyle(fontSize: 12)),
//           Text('Certificats: Ignorés', style: TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }

//   Widget _buildTestButton(String text, VoidCallback onPressed, IconData icon) {
//     return ElevatedButton.icon(
//       onPressed: isLoading ? null : onPressed,
//       icon: isLoading
//           ? SizedBox(
//               width: 16,
//               height: 16,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//           : Icon(icon),
//       label: Text(text),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.green[600],
//         foregroundColor: Colors.white,
//       ),
//     );
//   }

//   void _addLog(String message) {
//     setState(() {
//       logs += '[${DateTime.now().toString().substring(11, 19)}] $message\n';
//     });
//   }

//   Future<void> _testCurrentConfig() async {
//     setState(() {
//       isLoading = true;
//     });
//     _addLog('🔄 Test de la configuration SMTP actuelle...');

//     try {
//       final success = await emailService.testCurrentSmtpConfig();
//       _addLog(success ? '✅ Configuration actuelle fonctionne !' : '❌ Configuration actuelle échoue');
//     } catch (e) {
//       _addLog('❌ Erreur: $e');
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   Future<void> _testAllConfigs() async {
//     setState(() {
//       isLoading = true;
//     });
//     _addLog('🔄 Test de toutes les configurations SMTP...');

//     try {
//       await emailService.testMultipleSmtpConfigurations();
//       _addLog('✅ Tests terminés - Vérifiez les détails ci-dessus');
//     } catch (e) {
//       _addLog('❌ Erreur lors des tests: $e');
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   Future<void> _sendTestEmail() async {
//     setState(() {
//       isLoading = true;
//     });
//     _addLog('📧 Envoi d\'un email de test...');

//     try {
//       await emailService.sendCustomEmail(
//         to: 'manuel@kastraeg.com',
//         toName: 'Manuel Test',
//         subject: 'COREX Desktop - Test Email ${DateTime.now().toString().substring(0, 19)}',
//         body: '''
//         <h2>🎉 Test Email COREX Desktop</h2>
//         <p>Ceci est un email de test envoyé depuis l'application COREX Desktop.</p>
//         <div style="background-color: #f0f8ff; padding: 15px; border-radius: 5px; margin: 10px 0;">
//           <p><strong>📅 Date:</strong> ${DateTime.now()}</p>
//           <p><strong>🖥️ Application:</strong> COREX Desktop (Version Test)</p>
//           <p><strong>⚙️ Configuration:</strong> kastraeg.com:587</p>
//           <p><strong>✅ Status:</strong> Email envoyé avec succès !</p>
//         </div>
//         <p>Si vous recevez cet email, la configuration SMTP fonctionne parfaitement.</p>
//         ''',
//       );

//       _addLog('✅ Email de test ajouté à la file d\'attente');
//       _addLog('⏳ Vérifiez votre boîte email dans quelques secondes...');
//     } catch (e) {
//       _addLog('❌ Erreur lors de l\'envoi: $e');
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   Future<void> _testColisNotification() async {
//     setState(() {
//       isLoading = true;
//     });
//     _addLog('📦 Test de notification de changement de statut colis...');

//     try {
//       // Créer un colis de test
//       final testColis = ColisModel(
//         id: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
//         numeroSuivi: 'COL-TEST-${DateTime.now().millisecondsSinceEpoch}',
//         expediteurNom: 'Test Expéditeur',
//         expediteurEmail: 'expediteur@test.com',
//         destinataireNom: 'Manuel Test',
//         destinataireEmail: 'manuel@kastraeg.com',
//         destinataireAdresse: 'Adresse de test',
//         destinataireTelephone: '+33123456789',
//         contenu: 'Colis de test pour validation SMTP',
//         poids: 1.5,
//         // valeur: 100.0, // Supprimer si le champ n'existe pas
//         statut: 'enregistre',
//         modeLivraison: 'domicile',
//         dateCreation: DateTime.now(),
//         agenceOrigine: 'Test',
//         agenceDestination: 'Test',
//       );

//       await emailService.sendColisStatusChangeEmail(
//         colis: testColis,
//         newStatus: 'enTransit',
//         recipientEmail: 'manuel@kastraeg.com',
//         recipientName: 'Manuel Test',
//       );

//       _addLog('✅ Notification de colis ajoutée à la file d\'attente');
//       _addLog('📧 Email de changement de statut: enregistre → enTransit');
//     } catch (e) {
//       _addLog('❌ Erreur lors du test de notification: $e');
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   void _clearLogs() {
//     setState(() {
//       logs = '';
//     });
//   }
// }
