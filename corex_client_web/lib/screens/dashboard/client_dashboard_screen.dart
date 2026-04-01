import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/client_login_screen.dart';
import '../../controllers/client_auth_controller.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  late final ClientAuthController _authController;

  @override
  void initState() {
    super.initState();

    // Initialiser le controller de manière sécurisée
    try {
      _authController = Get.find<ClientAuthController>();
    } catch (e) {
      print('⚠️ [CLIENT DASHBOARD] ClientAuthController non trouvé, création: $e');
      _authController = Get.put(ClientAuthController());
    }

    // Vérifier l'authentification
    if (!_authController.isAuthenticated.value) {
      Get.offAllNamed('/login');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser.value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('COREX Client'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _authController.signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenue
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue, ${user.nom} ${user.prenom}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: ${user.email}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Téléphone: ${user.telephone}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Services disponibles
            Text(
              'Services disponibles',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Demande de course
                  _buildServiceCard(
                    context,
                    'Demande de Course',
                    'Demander une course pour vos déplacements',
                    Icons.directions_car,
                    const Color(0xFF2E7D32),
                    () {
                      // TODO: Navigation vers formulaire de demande de course
                      Get.snackbar(
                        'Bientôt disponible',
                        'Le formulaire de demande de course sera bientôt disponible',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                  // Demande de colis
                  _buildServiceCard(
                    context,
                    'Demande de Colis',
                    'Demander l\'envoi d\'un colis',
                    Icons.local_shipping,
                    const Color(0xFF1976D2),
                    () {
                      // TODO: Navigation vers formulaire de demande de colis
                      Get.snackbar(
                        'Bientôt disponible',
                        'Le formulaire de demande de colis sera bientôt disponible',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                  // Suivi des demandes
                  _buildServiceCard(
                    context,
                    'Mes Demandes',
                    'Suivre l\'état de vos demandes',
                    Icons.track_changes,
                    const Color(0xFFFF9800),
                    () {
                      // TODO: Navigation vers suivi des demandes
                      Get.snackbar(
                        'Bientôt disponible',
                        'Le suivi des demandes sera bientôt disponible',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),

                  // Historique
                  _buildServiceCard(
                    context,
                    'Historique',
                    'Consulter l\'historique de vos services',
                    Icons.history,
                    const Color(0xFF9C27B0),
                    () {
                      // TODO: Navigation vers historique
                      Get.snackbar(
                        'Bientôt disponible',
                        'L\'historique sera bientôt disponible',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
