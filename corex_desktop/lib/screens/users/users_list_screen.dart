import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'user_form_dialog.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => userController.loadUsers(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(userController),

          // Liste des utilisateurs
          Expanded(
            child: Obx(() {
              if (userController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userController.usersList.isEmpty) {
                return const Center(
                  child: Text('Aucun utilisateur trouvé'),
                );
              }

              return _buildUsersList(userController);
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel utilisateur'),
      ),
    );
  }

  Widget _buildSearchAndFilters(UserController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom, email ou téléphone...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => controller.searchQuery.value = value,
          ),
          const SizedBox(height: 16),

          // Filtres
          Row(
            children: [
              // Filtre par rôle
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.filterRole.value,
                      decoration: const InputDecoration(
                        labelText: 'Rôle',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'tous', child: Text('Tous les rôles')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'gestionnaire', child: Text('Gestionnaire')),
                        DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                        DropdownMenuItem(value: 'coursier', child: Text('Coursier')),
                        DropdownMenuItem(value: 'agent', child: Text('Agent')),
                      ],
                      onChanged: (value) {
                        if (value != null) controller.filterRole.value = value;
                      },
                    )),
              ),
              const SizedBox(width: 16),

              // Filtre par statut
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.filterStatus.value,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'tous', child: Text('Tous')),
                        DropdownMenuItem(value: 'actif', child: Text('Actifs')),
                        DropdownMenuItem(value: 'inactif', child: Text('Inactifs')),
                      ],
                      onChanged: (value) {
                        if (value != null) controller.filterStatus.value = value;
                      },
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(UserController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.usersList.length,
      itemBuilder: (context, index) {
        final user = controller.usersList[index];
        return _buildUserCard(context, user, controller);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, UserController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive ? const Color(0xFF2E7D32) : Colors.grey,
          child: Text(
            user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          user.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('${user.telephone} • ${_getRoleLabel(user.role)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.isActive ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: user.isActive ? Colors.green.shade900 : Colors.red.shade900,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Menu actions
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(context, value, user, controller),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(user.isActive ? Icons.block : Icons.check_circle, size: 20),
                      const SizedBox(width: 8),
                      Text(user.isActive ? 'Désactiver' : 'Activer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
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

  void _handleAction(BuildContext context, String action, UserModel user, UserController controller) {
    switch (action) {
      case 'edit':
        _showUserDialog(context, user);
        break;
      case 'toggle':
        _confirmToggleStatus(context, user, controller);
        break;
      case 'delete':
        _confirmDelete(context, user, controller);
        break;
    }
  }

  void _showUserDialog(BuildContext context, UserModel? user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  void _confirmToggleStatus(BuildContext context, UserModel user, UserController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(user.isActive ? 'Désactiver l\'utilisateur' : 'Activer l\'utilisateur'),
        content: Text(
          user.isActive ? 'Êtes-vous sûr de vouloir désactiver ${user.nomComplet} ? Il ne pourra plus se connecter.' : 'Êtes-vous sûr de vouloir activer ${user.nomComplet} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.toggleUserStatus(user);
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user, UserController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${user.nomComplet} ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deleteUser(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
