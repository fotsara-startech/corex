import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications et Alertes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshAlerts(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistiques des alertes
              _buildAlertsStats(controller),
              const SizedBox(height: 24),

              // Alertes critiques
              if (controller.hasCriticalAlerts) ...[
                _buildCriticalAlertsSection(controller),
                const SizedBox(height: 24),
              ],

              // Toutes les alertes
              _buildAllAlertsSection(controller),
              const SizedBox(height: 24),

              // Préférences de notification
              _buildNotificationPreferences(controller),
              const SizedBox(height: 24),

              // Actions admin
              if (['admin', 'pdg'].contains(Get.find<AuthController>().currentUser.value?.role)) ...[
                _buildAdminActions(controller),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAlertsStats(NotificationController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques des Alertes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    controller.activeAlerts.length.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Non lues',
                    controller.unreadAlertsCount.toString(),
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Critiques',
                    controller.getCriticalAlerts().length.toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertsSection(NotificationController controller) {
    final criticalAlerts = controller.getCriticalAlerts();

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Alertes Critiques (${criticalAlerts.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...criticalAlerts.map((alert) => _buildAlertTile(alert, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAlertsSection(NotificationController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toutes les Alertes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (controller.activeAlerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucune alerte active',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ...controller.activeAlerts.map((alert) => _buildAlertTile(alert, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTile(AlertModel alert, NotificationController controller) {
    final severityColor = Color(int.parse(controller.getSeverityColor(alert.severity).substring(1), radix: 16) + 0xFF000000);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: severityColor, width: 4)),
        color: Colors.grey.shade50,
      ),
      child: ListTile(
        title: Text(
          alert.title,
          style: TextStyle(
            fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.message),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    controller.getSeverityText(alert.severity),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: severityColor.withOpacity(0.2),
                ),
                const SizedBox(width: 8),
                Text(
                  alert.createdAt.toString().split(' ')[0],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!alert.isRead)
              IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => controller.markAlertAsRead(alert.id),
                tooltip: 'Marquer comme lu',
              ),
            if (!alert.isResolved)
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _showResolveDialog(alert, controller),
                tooltip: 'Résoudre',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPreferences(NotificationController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Préférences de Notification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final prefs = controller.preferences;
              return Column(
                children: [
                  SwitchListTile(
                    title: const Text('Changements de statut des colis'),
                    value: prefs.colisStatusUpdates,
                    onChanged: (value) => _updatePreference(controller, 'colisStatusUpdates', value),
                  ),
                  SwitchListTile(
                    title: const Text('Arrivée des colis à destination'),
                    value: prefs.colisArrival,
                    onChanged: (value) => _updatePreference(controller, 'colisArrival', value),
                  ),
                  SwitchListTile(
                    title: const Text('Attribution de livraisons'),
                    value: prefs.livraisonAttribution,
                    onChanged: (value) => _updatePreference(controller, 'livraisonAttribution', value),
                  ),
                  SwitchListTile(
                    title: const Text('Livraisons réussies'),
                    value: prefs.livraisonSuccess,
                    onChanged: (value) => _updatePreference(controller, 'livraisonSuccess', value),
                  ),
                  SwitchListTile(
                    title: const Text('Échecs de livraison'),
                    value: prefs.livraisonEchec,
                    onChanged: (value) => _updatePreference(controller, 'livraisonEchec', value),
                  ),
                  SwitchListTile(
                    title: const Text('Factures de stockage'),
                    value: prefs.factureStockage,
                    onChanged: (value) => _updatePreference(controller, 'factureStockage', value),
                  ),
                  SwitchListTile(
                    title: const Text('Attribution de courses'),
                    value: prefs.courseAttribution,
                    onChanged: (value) => _updatePreference(controller, 'courseAttribution', value),
                  ),
                  SwitchListTile(
                    title: const Text('Alertes système'),
                    value: prefs.alertes,
                    onChanged: (value) => _updatePreference(controller, 'alertes', value),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions(NotificationController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions Administrateur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateAlertDialog(controller),
              icon: const Icon(Icons.add_alert),
              label: const Text('Créer une alerte manuelle'),
            ),
          ],
        ),
      ),
    );
  }

  void _updatePreference(NotificationController controller, String key, bool value) {
    final currentPrefs = controller.preferences;
    NotificationPreferences newPrefs;

    switch (key) {
      case 'colisStatusUpdates':
        newPrefs = NotificationPreferences(
          colisStatusUpdates: value,
          colisArrival: currentPrefs.colisArrival,
          livraisonAttribution: currentPrefs.livraisonAttribution,
          livraisonSuccess: currentPrefs.livraisonSuccess,
          livraisonEchec: currentPrefs.livraisonEchec,
          factureStockage: currentPrefs.factureStockage,
          courseAttribution: currentPrefs.courseAttribution,
          alertes: currentPrefs.alertes,
        );
        break;
      case 'colisArrival':
        newPrefs = NotificationPreferences(
          colisStatusUpdates: currentPrefs.colisStatusUpdates,
          colisArrival: value,
          livraisonAttribution: currentPrefs.livraisonAttribution,
          livraisonSuccess: currentPrefs.livraisonSuccess,
          livraisonEchec: currentPrefs.livraisonEchec,
          factureStockage: currentPrefs.factureStockage,
          courseAttribution: currentPrefs.courseAttribution,
          alertes: currentPrefs.alertes,
        );
        break;
      // Ajouter les autres cas selon les besoins
      default:
        return;
    }

    controller.updateNotificationPreferences(newPrefs);
  }

  void _showResolveDialog(AlertModel alert, NotificationController controller) {
    final resolutionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Résoudre l\'alerte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alerte: ${alert.title}'),
            const SizedBox(height: 16),
            TextField(
              controller: resolutionController,
              decoration: const InputDecoration(
                labelText: 'Description de la résolution',
                hintText: 'Décrivez comment l\'alerte a été résolue...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.resolveAlert(alert.id, resolutionController.text);
              Get.back();
            },
            child: const Text('Résoudre'),
          ),
        ],
      ),
    );
  }

  void _showCreateAlertDialog(NotificationController controller) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    AlertSeverity selectedSeverity = AlertSeverity.medium;

    Get.dialog(
      AlertDialog(
        title: const Text('Créer une alerte'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre de l\'alerte',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AlertSeverity>(
                  value: selectedSeverity,
                  decoration: const InputDecoration(
                    labelText: 'Sévérité',
                  ),
                  items: AlertSeverity.values.map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Text(controller.getSeverityText(severity)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedSeverity = value;
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.createManualAlert(
                title: titleController.text,
                message: messageController.text,
                severity: selectedSeverity,
              );
              Get.back();
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
