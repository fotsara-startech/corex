import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/colis_controller.dart';
import 'package:corex_shared/models/colis_model.dart';
import '../../theme/corex_theme.dart';
import 'package:intl/intl.dart';
import 'colis_details_screen.dart';

class EnregistrementColisScreen extends StatelessWidget {
  const EnregistrementColisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colisController = Get.put(ColisController()); //Get.find<ColisController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrement des Colis'),
        backgroundColor: CorexTheme.primaryGreen,
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchBar(colisController),

          // Statistiques rapides
          _buildStats(colisController),

          // Liste des colis à enregistrer
          Expanded(
            child: Obx(() {
              if (colisController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final colisAEnregistrer = colisController.colisList.where((c) => c.statut == 'collecte').toList();

              if (colisAEnregistrer.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: colisAEnregistrer.length,
                itemBuilder: (context, index) {
                  final colis = colisAEnregistrer[index];
                  return _buildColisCard(context, colis, colisController);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColisController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, téléphone...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) => controller.searchQuery.value = value,
      ),
    );
  }

  Widget _buildStats(ColisController controller) {
    return Obx(() {
      final colisAEnregistrer = controller.colisList.where((c) => c.statut == 'collecte').length;

      return Container(
        padding: const EdgeInsets.all(16),
        color: CorexTheme.primaryGreen.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              Icons.pending_actions,
              'À enregistrer',
              colisAEnregistrer.toString(),
              CorexTheme.primaryGreen,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun colis à enregistrer',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les colis collectés ont été enregistrés',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColisCard(BuildContext context, ColisModel colis, ColisController controller) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Get.to(() => ColisDetailsScreen(colis: colis));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec date de collecte
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Collecté le ${dateFormat.format(colis.dateCollecte)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'À ENREGISTRER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations expéditeur
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expéditeur',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          colis.expediteurNom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          colis.expediteurTelephone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Informations destinataire
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Destinataire',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          colis.destinataireNom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${colis.destinataireVille} - ${colis.destinataireTelephone}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Détails du colis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem('Contenu', colis.contenu),
                  _buildDetailItem('Poids', '${colis.poids} kg'),
                  _buildDetailItem('Tarif', '${colis.montantTarif} FCFA'),
                ],
              ),
              const SizedBox(height: 16),

              // Bouton d'enregistrement
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => ColisDetailsScreen(colis: colis));
                  },
                  icon: const Icon(Icons.app_registration),
                  label: const Text('ENREGISTRER CE COLIS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CorexTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
