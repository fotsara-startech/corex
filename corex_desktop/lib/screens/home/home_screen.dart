import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import '../users/users_list_screen.dart';
import '../agences/agences_list_screen.dart';
import '../zones/zones_list_screen.dart';
import '../agences_transport/agences_transport_list_screen.dart';
import '../colis/colis_collecte_screen.dart';
import '../clients/clients_list_screen.dart';
import '../agent/enregistrement_colis_screen.dart';
import '../suivi/suivi_colis_screen.dart';
import '../livraisons/attribution_livraison_screen.dart';
import '../livraisons/suivi_livraisons_screen.dart';
import '../coursier/mes_livraisons_screen.dart';
import '../stockage/clients_stockeurs_screen.dart';
import '../stockage/factures_stockage_screen.dart';
import '../courses/courses_list_screen.dart';
import '../courses/suivi_courses_screen.dart';
import '../coursier/mes_courses_screen.dart';
import '../pdg/pdg_dashboard_screen.dart';
import '../../widgets/connection_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('COREX Desktop'),
        actions: [
          const ConnectionIndicator(),
          const SizedBox(width: 16),
          Obx(() {
            final user = authController.currentUser.value;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  user != null ? user.nomComplet : '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.signOut();
              Get.offAllNamed('/login');
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      drawer: _buildDrawer(authController),
      body: Obx(() {
        final user = authController.currentUser.value;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Interface spéciale pour les clients
        if (user.role == 'client') {
          return _buildClientInterface(user);
        }

        // Si l'utilisateur est PDG ou admin, afficher le dashboard PDG
        if (user.role == 'pdg' || user.role == 'admin') {
          return const PdgDashboardScreen(isEmbedded: true);
        }

        // Sinon, afficher l'interface standard pour les employés
        return _buildStandardHomeContent(authController);
      }),
    );
  }

  Widget _buildDrawer(AuthController authController) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Obx(() {
            final user = authController.currentUser.value;
            return UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
              ),
              accountName: Text(
                user?.nomComplet ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user != null && user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Tableau de bord'),
                  onTap: () {
                    Get.back();
                  },
                ),
                const Divider(),

                // Section Admin
                Obx(() {
                  final user = authController.currentUser.value;
                  print('🔍 [DRAWER] User: ${user?.email}, Role: ${user?.role}, IsAdmin: ${authController.isAdmin}');
                  if (authController.isAdmin) {
                    return Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'ADMINISTRATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        // Tableau de bord PDG - Accès spécial
                        if (user?.role == 'pdg' || user?.role == 'admin')
                          ListTile(
                            leading: const Icon(Icons.analytics, color: Color(0xFF6C5CE7)),
                            title: const Text(
                              'Tableau de Bord PDG',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C5CE7),
                              ),
                            ),
                            onTap: () {
                              Get.back();
                              Get.toNamed('/pdg/dashboard');
                            },
                          ),
                        // Validation des demandes clients - Nouveau
                        if (user?.role == 'gestionnaire' || user?.role == 'admin')
                          ListTile(
                            leading: const Icon(Icons.approval, color: Color(0xFF2E7D32)),
                            title: const Text(
                              'Demandes Clients',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            onTap: () {
                              Get.back();
                              Get.toNamed('/demandes');
                            },
                          ),
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('Gestion des utilisateurs'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const UsersListScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.business),
                          title: const Text('Gestion des agences'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const AgencesListScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.map),
                          title: const Text('Zones de livraison'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const ZonesListScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.local_shipping),
                          title: const Text('Agences de transport'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const AgencesTransportListScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.contacts),
                          title: const Text('Clients'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const ClientsListScreen());
                          },
                        ),
                        const Divider(),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Section Opérations
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'OPÉRATIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add_box),
                  title: const Text('Collecter un colis'),
                  onTap: () {
                    Get.back();
                    Get.to(() => const ColisCollecteScreen());
                  },
                ),
                Obx(() {
                  final user = authController.currentUser.value;
                  if (user?.role == 'agent' || user?.role == 'gestionnaire' || user?.role == 'admin') {
                    return ListTile(
                      leading: const Icon(Icons.app_registration),
                      title: const Text('Enregistrer des colis'),
                      onTap: () {
                        Get.back();
                        Get.to(() => const EnregistrementColisScreen());
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('Suivi des colis'),
                  onTap: () {
                    Get.back();
                    Get.to(() => const SuiviColisScreen());
                  },
                ),
                Obx(() {
                  final user = authController.currentUser.value;
                  if (user?.role == 'gestionnaire' || user?.role == 'admin') {
                    return ExpansionTile(
                      leading: const Icon(Icons.local_shipping),
                      title: const Text('Livraisons'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_add),
                          title: const Text('Attribution des livraisons'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const AttributionLivraisonScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.list_alt),
                          title: const Text('Suivi des livraisons'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const SuiviLivraisonsScreen());
                          },
                        ),
                      ],
                    );
                  } else if (user?.role == 'coursier') {
                    return ListTile(
                      leading: const Icon(Icons.delivery_dining),
                      title: const Text('Mes Livraisons'),
                      onTap: () {
                        Get.back();
                        Get.to(() => const MesLivraisonsScreen());
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
                Obx(() {
                  final user = authController.currentUser.value;
                  if (user?.role == 'gestionnaire' || user?.role == 'admin') {
                    return ListTile(
                      leading: const Icon(Icons.attach_money),
                      title: const Text('Caisse'),
                      onTap: () {
                        Get.back();
                        Get.toNamed('/caisse');
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Section Retours
                Obx(() {
                  final user = authController.currentUser.value;
                  if (user?.role == 'gestionnaire' || user?.role == 'admin' || user?.role == 'commercial') {
                    return ListTile(
                      leading: const Icon(Icons.keyboard_return),
                      title: const Text('Retours de Colis'),
                      onTap: () {
                        Get.back();
                        Get.toNamed('/retours');
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Section Stockage
                Obx(() {
                  final user = authController.currentUser.value;
                  if (user?.role == 'gestionnaire' || user?.role == 'admin') {
                    return ExpansionTile(
                      leading: const Icon(Icons.inventory_2),
                      title: const Text('Stockage'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('Clients stockeurs'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const ClientsStockeursScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: const Text('Factures de stockage'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const FacturesStockageScreen());
                          },
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Section Courses
                Obx(() {
                  final user = authController.currentUser.value;
                  if (user?.role == 'gestionnaire' || user?.role == 'admin') {
                    return ExpansionTile(
                      leading: const Icon(Icons.directions_run),
                      title: const Text('Service de Courses'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.add),
                          title: const Text('Créer une course'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const CoursesListScreen());
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.list_alt),
                          title: const Text('Suivi des courses'),
                          onTap: () {
                            Get.back();
                            Get.to(() => const SuiviCoursesScreen());
                          },
                        ),
                      ],
                    );
                  } else if (user?.role == 'commercial') {
                    return ListTile(
                      leading: const Icon(Icons.directions_run),
                      title: const Text('Service de Courses'),
                      onTap: () {
                        Get.back();
                        Get.to(() => const CoursesListScreen());
                      },
                    );
                  } else if (user?.role == 'coursier') {
                    return ListTile(
                      leading: const Icon(Icons.directions_run),
                      title: const Text('Mes Courses'),
                      onTap: () {
                        Get.back();
                        Get.to(() => const MesCoursesScreen());
                      },
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),

          // Footer
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authController.signOut();
              Get.offAllNamed('/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStandardHomeContent(AuthController authController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.dashboard,
            color: Color(0xFF2E7D32),
            size: 100,
          ),
          const SizedBox(height: 24),
          const Text(
            'Tableau de Bord COREX',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final user = authController.currentUser.value;
            return Text(
              'Connecté en tant que: ${_getRoleLabel(user?.role ?? "")}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            );
          }),
          const SizedBox(height: 48),
          const Text(
            'Phase 1 - Gestion des Utilisateurs ✅',
            style: TextStyle(fontSize: 14, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInterface(UserModel user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Déterminer le nombre de colonnes selon la largeur d'écran
        int crossAxisCount;
        double cardPadding;
        double mainPadding;

        if (constraints.maxWidth < 600) {
          // Mobile
          crossAxisCount = 1;
          cardPadding = 16.0;
          mainPadding = 16.0;
        } else if (constraints.maxWidth < 900) {
          // Tablette
          crossAxisCount = 2;
          cardPadding = 20.0;
          mainPadding = 24.0;
        } else {
          // Desktop
          crossAxisCount = 3;
          cardPadding = 24.0;
          mainPadding = 32.0;
        }

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF4CAF50),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(mainPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bienvenue - Responsive
                _buildWelcomeCard(user, constraints.maxWidth),
                const SizedBox(height: 24),

                // Titre Services
                Text(
                  'Services disponibles',
                  style: TextStyle(
                    fontSize: constraints.maxWidth < 600 ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Grid responsive des services
                _buildResponsiveServicesGrid(crossAxisCount, cardPadding),

                // Espacement en bas pour éviter le débordement
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(UserModel user, double screenWidth) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 600 ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre responsive
            Text(
              'Bienvenue, ${user.prenom} ${user.nom}',
              style: TextStyle(
                fontSize: screenWidth < 600 ? 20 : 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),

            // Informations utilisateur - Layout responsive
            if (screenWidth < 600) ...[
              // Mobile : Layout vertical
              _buildUserInfo('Email', user.email, Icons.email),
              const SizedBox(height: 8),
              _buildUserInfo('Téléphone', user.telephone, Icons.phone),
            ] else ...[
              // Desktop/Tablette : Layout horizontal
              Row(
                children: [
                  Expanded(
                    child: _buildUserInfo('Email', user.email, Icons.email),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildUserInfo('Téléphone', user.telephone, Icons.phone),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveServicesGrid(int crossAxisCount, double cardPadding) {
    final services = [
      {
        'title': 'Demande de Course',
        'description': 'Demander une course pour vos déplacements',
        'icon': Icons.directions_car,
        'color': const Color(0xFF2E7D32),
      },
      {
        'title': 'Demande de Colis',
        'description': 'Demander l\'envoi d\'un colis',
        'icon': Icons.local_shipping,
        'color': const Color(0xFF1976D2),
      },
      {
        'title': 'Mes Demandes',
        'description': 'Suivre l\'état de vos demandes',
        'icon': Icons.track_changes,
        'color': const Color(0xFFFF9800),
      },
      {
        'title': 'Historique',
        'description': 'Consulter l\'historique de vos services',
        'icon': Icons.history,
        'color': const Color(0xFF9C27B0),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: crossAxisCount == 1 ? 3.5 : 1.1, // Ratio adaptatif
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _buildResponsiveServiceCard(
          service['title'] as String,
          service['description'] as String,
          service['icon'] as IconData,
          service['color'] as Color,
          cardPadding,
          crossAxisCount == 1, // isMobile
          () {
            // Navigation selon le service
            switch (service['title']) {
              case 'Demande de Course':
                Get.toNamed('/client/demande-course');
                break;
              case 'Demande de Colis':
                Get.toNamed('/client/demande-colis');
                break;
              case 'Mes Demandes':
                Get.toNamed('/client/mes-demandes');
                break;
              case 'Historique':
                Get.toNamed('/client/historique');
                break;
              default:
                Get.snackbar(
                  'Bientôt disponible',
                  'Le service "${service['title']}" sera bientôt disponible',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF4CAF50),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
            }
          },
        );
      },
    );
  }

  Widget _buildResponsiveServiceCard(
    String title,
    String description,
    IconData icon,
    Color color,
    double padding,
    bool isMobile,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: isMobile ? _buildMobileServiceCardContent(title, description, icon, color) : _buildDesktopServiceCardContent(title, description, icon, color),
        ),
      ),
    );
  }

  Widget _buildMobileServiceCardContent(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 32,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildDesktopServiceCardContent(String title, String description, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 48,
            color: color,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'gestionnaire':
        return 'Gestionnaire';
      case 'commercial':
        return 'Commercial';
      case 'coursier':
        return 'Coursier';
      case 'agent':
        return 'Agent';
      case 'client':
        return 'Client';
      default:
        return role;
    }
  }
}
