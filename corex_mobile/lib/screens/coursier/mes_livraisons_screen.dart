import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/livraison_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/models/livraison_model.dart';
import 'package:intl/intl.dart';

class MesLivraisonsScreen extends StatelessWidget {
  const MesLivraisonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LivraisonController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context, controller),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filtrer par coursier connecté et par statut sélectionné
        var livraisons = controller.livraisonsList
            .where((l) => l.coursierId == authController.currentUser.value?.id)
            .toList();

        if (controller.selectedStatutFilter.value != 'tous') {
          livraisons = livraisons
              .where((l) => l.statut == controller.selectedStatutFilter.value)
              .toList();
        }

        if (livraisons.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadLivraisons(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: livraisons.length,
            itemBuilder: (context, index) {
              final livraison = livraisons[index];
              return _buildLivraisonCard(livraison, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune livraison assignée',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivraisonCard(LivraisonModel livraison, LivraisonController controller) {
    final statutColor = _getStatutColor(livraison.statut);
    final statutIcon = _getStatutIcon(livraison.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.toNamed('/coursier/livraison/details', arguments: livraison),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statutIcon, color: statutColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Livraison #${livraison.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatutLabel(livraison.statut),
                          style: TextStyle(
                            color: statutColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow(Icons.location_on, 'Zone', livraison.zone),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.calendar_today,
                'Créée le',
                DateFormat('dd/MM/yyyy à HH:mm').format(livraison.dateCreation),
              ),
              if (livraison.heureDepart != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.access_time,
                  'Départ',
                  DateFormat('HH:mm').format(livraison.heureDepart!),
                ),
              ],
              if (livraison.statut == 'enAttente' || livraison.statut == 'enCours') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(livraison, controller),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(LivraisonModel livraison, LivraisonController controller) {
    if (livraison.statut == 'enAttente') {
      return ElevatedButton.icon(
        onPressed: () => _demarrerTournee(livraison, controller),
        icon: const Icon(Icons.play_arrow, size: 18),
        label: const Text('Démarrer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      );
    } else if (livraison.statut == 'enCours') {
      return ElevatedButton.icon(
        onPressed: () => Get.toNamed('/coursier/livraison/details', arguments: livraison),
        icon: const Icon(Icons.check, size: 18),
        label: const Text('Terminer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _demarrerTournee(LivraisonModel livraison, LivraisonController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Démarrer la tournée'),
        content: const Text('Confirmez-vous le départ pour cette livraison ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.demarrerTournee(livraison.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, LivraisonController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrer par statut',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterOption(controller, 'tous', 'Toutes'),
            _buildFilterOption(controller, 'enAttente', 'En attente'),
            _buildFilterOption(controller, 'enCours', 'En cours'),
            _buildFilterOption(controller, 'livree', 'Livrées'),
            _buildFilterOption(controller, 'echec', 'Échec'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(LivraisonController controller, String value, String label) {
    return Obx(() => RadioListTile<String>(
          title: Text(label),
          value: value,
          groupValue: controller.selectedStatutFilter.value,
          onChanged: (newValue) {
            controller.selectedStatutFilter.value = newValue!;
            Get.back();
          },
        ));
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'enAttente':
        return Colors.orange;
      case 'enCours':
        return Colors.blue;
      case 'livree':
        return Colors.green;
      case 'echec':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'enAttente':
        return Icons.schedule;
      case 'enCours':
        return Icons.local_shipping;
      case 'livree':
        return Icons.check_circle;
      case 'echec':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'enAttente':
        return 'En attente';
      case 'enCours':
        return 'En cours';
      case 'livree':
        return 'Livrée';
      case 'echec':
        return 'Échec';
      default:
        return statut;
    }
  }
}
