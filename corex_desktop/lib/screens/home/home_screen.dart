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

        // Si l'utilisateur est PDG ou admin, afficher le dashboard PDG
        if (user != null && (user.role == 'pdg' || user.role == 'admin')) {
          return const PdgDashboardScreen(isEmbedded: true);
        }

        // Sinon, afficher l'interface standard
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
      default:
        return role;
    }
  }
}
