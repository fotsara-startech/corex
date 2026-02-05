import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import '../../theme/corex_theme.dart';
import 'validation_demande_course_dialog.dart';
import 'validation_demande_colis_dialog.dart';

class DemandesDashboardScreen extends StatefulWidget {
  const DemandesDashboardScreen({super.key});

  @override
  State<DemandesDashboardScreen> createState() => _DemandesDashboardScreenState();
}

class _DemandesDashboardScreenState extends State<DemandesDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DemandeController _demandeController = Get.put(DemandeController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Recharger les données périodiquement
    _setupAutoRefresh();
  }

  void _setupAutoRefresh() {
    // Recharger toutes les 30 secondes
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      if (mounted) {
        _demandeController.loadDemandesEnAttente();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Demandes Clients'),
        backgroundColor: CorexTheme.primaryGreen,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Obx(() => Tab(
                  text: 'Courses (${_demandeController.totalDemandesCourses})',
                  icon: const Icon(Icons.directions_run),
                )),
            Obx(() => Tab(
                  text: 'Colis (${_demandeController.totalDemandesColis})',
                  icon: const Icon(Icons.local_shipping),
                )),
          ],
        ),
        actions: [
          Obx(() => _demandeController.totalDemandesEnAttente > 0
              ? Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_demandeController.totalDemandesEnAttente} en attente',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              : const SizedBox.shrink()),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _demandeController.loadDemandesEnAttente(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCoursesTab(),
          _buildColisTab(),
        ],
      ),
    );
  }

  Widget _buildCoursesTab() {
    return Obx(() {
      if (_demandeController.isLoadingCourses.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_demandeController.demandesCoursesEnAttente.isEmpty) {
        return _buildEmptyState(
          icon: Icons.directions_run,
          title: 'Aucune demande de course',
          subtitle: 'Les nouvelles demandes de courses apparaîtront ici',
        );
      }

      return RefreshIndicator(
        onRefresh: () => _demandeController.loadDemandesCoursesEnAttente(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _demandeController.demandesCoursesEnAttente.length,
          itemBuilder: (context, index) {
            final demande = _demandeController.demandesCoursesEnAttente[index];
            return _buildDemandeCoursCard(demande);
          },
        ),
      );
    });
  }

  Widget _buildColisTab() {
    return Obx(() {
      if (_demandeController.isLoadingColis.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_demandeController.demandesColisEnAttente.isEmpty) {
        return _buildEmptyState(
          icon: Icons.local_shipping,
          title: 'Aucune demande de colis',
          subtitle: 'Les nouvelles demandes d\'expédition apparaîtront ici',
        );
      }

      return RefreshIndicator(
        onRefresh: () => _demandeController.loadDemandesColisEnAttente(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _demandeController.demandesColisEnAttente.length,
          itemBuilder: (context, index) {
            final demande = _demandeController.demandesColisEnAttente[index];
            return _buildDemandeColisCard(demande);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDemandeCoursCard(DemandeCoursModel demande) {
    final timeAgo = _getTimeAgo(demande.dateCreation);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec client et temps
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: CorexTheme.primaryGreen,
                  child: Text(
                    demande.clientNom.isNotEmpty ? demande.clientNom[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demande.clientNom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        demande.clientTelephone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Détails de la course
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.location_on, 'Lieu', demande.lieu),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.task, 'Tâche', demande.tache),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.description, 'Instructions', demande.instructions),
                  if (demande.budgetMax != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.attach_money,
                      'Budget max',
                      '${demande.budgetMax!.toStringAsFixed(0)} FCFA',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejeterDemandeCourse(demande),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _validerDemandeCourse(demande),
                    icon: const Icon(Icons.check),
                    label: const Text('Valider & Tarifer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CorexTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandeColisCard(DemandeColisModel demande) {
    final timeAgo = _getTimeAgo(demande.dateCreation);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec client et temps
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: CorexTheme.primaryGreen,
                  child: Text(
                    demande.clientNom.isNotEmpty ? demande.clientNom[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demande.clientNom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        demande.clientTelephone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Détails du colis
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.inventory, 'Description', demande.description),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          Icons.person_outline,
                          'Expéditeur',
                          '${demande.expediteurNom} - ${demande.expediteurVille}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          Icons.person,
                          'Destinataire',
                          '${demande.destinataireNom} - ${demande.destinataireVille}',
                        ),
                      ),
                    ],
                  ),
                  if (demande.poids != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.scale,
                      'Poids',
                      '${demande.poids!.toStringAsFixed(1)} kg',
                    ),
                  ],
                  if (demande.dimensions != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.straighten, 'Dimensions', demande.dimensions!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejeterDemandeColis(demande),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _validerDemandeColis(demande),
                    icon: const Icon(Icons.check),
                    label: const Text('Valider & Tarifer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CorexTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }

  void _validerDemandeCourse(DemandeCoursModel demande) {
    showDialog(
      context: context,
      builder: (context) => ValidationDemandeCoursDialog(
        demande: demande,
        onValidated: () => _demandeController.loadDemandesCoursesEnAttente(),
      ),
    );
  }

  void _rejeterDemandeCourse(DemandeCoursModel demande) {
    _showRejetDialog(
      title: 'Rejeter la demande de course',
      content: 'Êtes-vous sûr de vouloir rejeter cette demande de course de ${demande.clientNom} ?',
      onConfirm: (motif) => _demandeController.rejeterDemandeCourse(
        demandeId: demande.id!,
        motifRejet: motif,
      ),
    );
  }

  void _validerDemandeColis(DemandeColisModel demande) {
    showDialog(
      context: context,
      builder: (context) => ValidationDemandeColisDialog(
        demande: demande,
        onValidated: () => _demandeController.loadDemandesColisEnAttente(),
      ),
    );
  }

  void _rejeterDemandeColis(DemandeColisModel demande) {
    _showRejetDialog(
      title: 'Rejeter la demande de colis',
      content: 'Êtes-vous sûr de vouloir rejeter cette demande d\'expédition de ${demande.clientNom} ?',
      onConfirm: (motif) => _demandeController.rejeterDemandeColis(
        demandeId: demande.id!,
        motifRejet: motif,
      ),
    );
  }

  void _showRejetDialog({
    required String title,
    required String content,
    required Function(String) onConfirm,
  }) {
    final motifController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            const SizedBox(height: 16),
            TextField(
              controller: motifController,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet',
                hintText: 'Expliquez pourquoi cette demande est rejetée...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motifController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                onConfirm(motifController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
