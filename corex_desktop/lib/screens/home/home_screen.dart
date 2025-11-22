import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import '../users/users_list_screen.dart';
import '../agences/agences_list_screen.dart';
import '../zones/zones_list_screen.dart';
import '../agences_transport/agences_transport_list_screen.dart';
import '../colis/colis_collecte_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('COREX Desktop'),
        actions: [
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
      body: Center(
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
      ),
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
                ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('Liste des colis'),
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Info',
                      'Fonctionnalité à venir (Phase 3.2)',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_shipping),
                  title: const Text('Livraisons'),
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Info',
                      'Fonctionnalité à venir (Phase 6)',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Caisse'),
                  onTap: () {
                    Get.back();
                    Get.snackbar(
                      'Info',
                      'Fonctionnalité à venir (Phase 8)',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
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
