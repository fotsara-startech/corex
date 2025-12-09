import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/suivi_controller.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';

class DetailsColisScreen extends StatelessWidget {
  const DetailsColisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SuiviController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Colis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showUpdateStatutDialog(context, controller),
            tooltip: 'Modifier le statut',
          ),
        ],
      ),
      body: Obx(() {
        final colis = controller.selectedColis.value;

        if (colis == null) {
          return const Center(child: Text('Aucun colis sélectionné'));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(colis, controller),
              _buildInfoSection(colis),
              _buildHistorique(colis, controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(ColisModel colis, SuiviController controller) {
    final statutColor = Color(int.parse(controller.getStatutColor(colis.statut).replaceFirst('#', '0xFF')));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statutColor, statutColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            colis.numeroSuivi,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              controller.getStatutLabel(colis.statut),
              style: TextStyle(
                color: statutColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ColisModel colis) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Expéditeur',
            icon: Icons.person_outline,
            children: [
              _buildInfoRow('Nom', colis.expediteurNom),
              _buildInfoRow('Téléphone', colis.expediteurTelephone),
              _buildInfoRow('Adresse', colis.expediteurAdresse),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Destinataire',
            icon: Icons.person,
            children: [
              _buildInfoRow('Nom', colis.destinataireNom),
              _buildInfoRow('Téléphone', colis.destinataireTelephone),
              _buildInfoRow('Adresse', colis.destinataireAdresse),
              _buildInfoRow('Ville', colis.destinataireVille),
              if (colis.destinataireQuartier != null) _buildInfoRow('Quartier', colis.destinataireQuartier!),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Détails du Colis',
            icon: Icons.inventory_2,
            children: [
              _buildInfoRow('Contenu', colis.contenu),
              _buildInfoRow('Poids', '${colis.poids} kg'),
              if (colis.dimensions != null) _buildInfoRow('Dimensions', colis.dimensions!),
              _buildInfoRow('Mode de livraison', colis.modeLivraison),
              if (colis.agenceTransportNom != null) _buildInfoRow('Agence transport', colis.agenceTransportNom!),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Informations Financières',
            icon: Icons.payments,
            children: [
              _buildInfoRow('Montant', '${colis.montantTarif.toStringAsFixed(0)} FCFA'),
              _buildInfoRow(
                'Statut paiement',
                colis.isPaye ? 'Payé' : 'Non payé',
                valueColor: colis.isPaye ? Colors.green : Colors.red,
              ),
              if (colis.datePaiement != null)
                _buildInfoRow(
                  'Date de paiement',
                  DateFormat('dd/MM/yyyy à HH:mm').format(colis.datePaiement!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Dates Importantes',
            icon: Icons.calendar_today,
            children: [
              _buildInfoRow(
                'Date de collecte',
                DateFormat('dd/MM/yyyy à HH:mm').format(colis.dateCollecte),
              ),
              if (colis.dateEnregistrement != null)
                _buildInfoRow(
                  'Date d\'enregistrement',
                  DateFormat('dd/MM/yyyy à HH:mm').format(colis.dateEnregistrement!),
                ),
              if (colis.dateLivraison != null)
                _buildInfoRow(
                  'Date de livraison',
                  DateFormat('dd/MM/yyyy à HH:mm').format(colis.dateLivraison!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorique(ColisModel colis, SuiviController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text(
                    'Historique des Statuts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (colis.historique.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Aucun historique disponible'),
                  ),
                )
              else
                ...colis.historique.asMap().entries.map((entry) {
                  final index = entry.key;
                  final historique = entry.value;
                  final isFirst = index == 0;
                  final isLast = index == colis.historique.length - 1;

                  return _buildTimelineItem(
                    historique: historique,
                    controller: controller,
                    isFirst: isFirst,
                    isLast: isLast,
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required HistoriqueStatut historique,
    required SuiviController controller,
    required bool isFirst,
    required bool isLast,
  }) {
    final statutColor = Color(int.parse(controller.getStatutColor(historique.statut).replaceFirst('#', '0xFF')));

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(color: statutColor.withOpacity(0.3)),
      indicatorStyle: IndicatorStyle(
        width: 40,
        color: statutColor,
        iconStyle: IconStyle(
          iconData: Icons.check,
          color: Colors.white,
        ),
      ),
      endChild: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.getStatutLabel(historique.statut),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: statutColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy à HH:mm').format(historique.date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (historique.commentaire != null && historique.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  historique.commentaire!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUpdateStatutDialog(BuildContext context, SuiviController controller) {
    final colis = controller.selectedColis.value;
    if (colis == null) return;

    final commentaireController = TextEditingController();
    String? selectedStatut;

    // Obtenir les statuts valides pour la transition
    final validStatuts = _getValidStatuts(colis.statut);

    Get.dialog(
      AlertDialog(
        title: const Text('Modifier le Statut'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statut actuel: ${controller.getStatutLabel(colis.statut)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Nouveau statut',
                  border: OutlineInputBorder(),
                ),
                items: validStatuts.map((statut) {
                  return DropdownMenuItem(
                    value: statut,
                    child: Text(controller.getStatutLabel(statut)),
                  );
                }).toList(),
                onChanged: (value) => selectedStatut = value,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentaireController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedStatut == null) {
                Get.snackbar('Erreur', 'Veuillez sélectionner un statut');
                return;
              }

              Get.back();
              await controller.updateStatut(
                colis.id,
                selectedStatut!,
                commentaireController.text.isEmpty ? null : commentaireController.text,
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  List<String> _getValidStatuts(String currentStatut) {
    final Map<String, List<String>> validTransitions = {
      'collecte': ['enregistre', 'annule'],
      'enregistre': ['enTransit', 'annule'],
      'enTransit': ['arriveDestination', 'retour'],
      'arriveDestination': ['enCoursLivraison', 'retire', 'retour'],
      'enCoursLivraison': ['livre', 'echec', 'retour'],
      'echec': ['enCoursLivraison', 'retour'],
      'livre': [],
      'retire': [],
      'retour': ['enTransit'],
      'annule': [],
    };

    return validTransitions[currentStatut] ?? [];
  }
}
