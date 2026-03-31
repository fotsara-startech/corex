import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MesDemandesScreen extends StatefulWidget {
  const MesDemandesScreen({super.key});

  @override
  State<MesDemandesScreen> createState() => _MesDemandesScreenState();
}

class _MesDemandesScreenState extends State<MesDemandesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AuthController _authController;

  final RxList<DemandeCoursModel> _demandesCourses = <DemandeCoursModel>[].obs;
  final RxList<DemandeColisModel> _demandesColis = <DemandeColisModel>[].obs;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    try {
      _authController = Get.find<AuthController>();
    } catch (e) {
      Get.back();
      Get.snackbar('Erreur', 'Accès non autorisé');
      return;
    }

    // Vérifier que l'utilisateur est un client
    final user = _authController.currentUser.value;
    if (user == null || user.role != 'client') {
      Get.back();
      Get.snackbar('Erreur', 'Accès non autorisé');
      return;
    }

    _loadMesDemandesFromFirestore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMesDemandesFromFirestore() async {
    _isLoading.value = true;
    try {
      final user = _authController.currentUser.value!;
      print('🔍 [MES_DEMANDES] Chargement pour client: ${user.id}');

      // Charger les demandes de courses du client
      final coursesQuery = await FirebaseFirestore.instance.collection('demandes_courses').where('clientId', isEqualTo: user.id).orderBy('dateCreation', descending: true).get();

      _demandesCourses.value = coursesQuery.docs.map((doc) => DemandeCoursModel.fromFirestore(doc)).toList();
      print('📋 [MES_DEMANDES] Courses chargées: ${_demandesCourses.length}');
      for (var course in _demandesCourses) {
        print('  - Course: ${course.tache} (${course.statut})');
      }

      // Charger les demandes de colis du client
      final colisQuery = await FirebaseFirestore.instance.collection('demandes_colis').where('clientId', isEqualTo: user.id).orderBy('dateCreation', descending: true).get();

      _demandesColis.value = colisQuery.docs.map((doc) => DemandeColisModel.fromFirestore(doc)).toList();
      print('📦 [MES_DEMANDES] Colis chargés: ${_demandesColis.length}');
      for (var colis in _demandesColis) {
        print('  - Colis: ${colis.description} (${colis.statut})');
      }

      print('✅ [MES_DEMANDES] Chargé ${_demandesCourses.length} courses et ${_demandesColis.length} colis');

      // Forcer la mise à jour de l'interface
      _demandesCourses.refresh();
      _demandesColis.refresh();
    } catch (e) {
      print('❌ [MES_DEMANDES] Erreur chargement: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger vos demandes: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Demandes'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMesDemandesFromFirestore,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Obx(() => Tab(
                  icon: const Icon(Icons.directions_car),
                  text: 'Courses (${_demandesCourses.length})',
                )),
            Obx(() => Tab(
                  icon: const Icon(Icons.local_shipping),
                  text: 'Colis (${_demandesColis.length})',
                )),
          ],
        ),
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildCoursesTab(),
            _buildColisTab(),
          ],
        );
      }),
    );
  }

  Widget _buildCoursesTab() {
    return Obx(() {
      if (_demandesCourses.isEmpty) {
        return _buildEmptyState(
          'Aucune demande de course',
          'Vous n\'avez pas encore fait de demande de course.',
          Icons.directions_car,
          const Color(0xFF2E7D32),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _demandesCourses.length,
        itemBuilder: (context, index) {
          final demande = _demandesCourses[index];
          return _buildCourseCard(demande);
        },
      );
    });
  }

  Widget _buildColisTab() {
    return Obx(() {
      if (_demandesColis.isEmpty) {
        return _buildEmptyState(
          'Aucune demande de colis',
          'Vous n\'avez pas encore fait de demande d\'expédition.',
          Icons.local_shipping,
          const Color(0xFF1976D2),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _demandesColis.length,
        itemBuilder: (context, index) {
          final demande = _demandesColis[index];
          return _buildColisCard(demande);
        },
      );
    });
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(DemandeCoursModel demande) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demande de Course',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(demande.dateCreation),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatutChip(demande.statut),
              ],
            ),
            const SizedBox(height: 16),

            // Détails
            _buildDetailRow('Lieu', demande.lieu, Icons.location_on),
            const SizedBox(height: 8),
            _buildDetailRow('Tâche', demande.tache, Icons.assignment),
            if (demande.budgetMax != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Budget max',
                '${demande.budgetMax!.toStringAsFixed(0)} FCFA',
                Icons.attach_money,
              ),
            ],
            if (demande.tarifValide != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Tarif validé',
                '${demande.tarifValide!.toStringAsFixed(0)} FCFA',
                Icons.check_circle,
                color: Colors.green,
              ),
            ],

            // Instructions si présentes
            if (demande.instructions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demande.instructions,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            // Commentaires de validation/rejet
            if (demande.commentaireValidation != null) ...[
              const SizedBox(height: 12),
              _buildCommentaireBox(
                'Commentaire de validation',
                demande.commentaireValidation!,
                Colors.green,
              ),
            ],
            if (demande.commentaireRejet != null) ...[
              const SizedBox(height: 12),
              _buildCommentaireBox(
                'Motif de rejet',
                demande.commentaireRejet!,
                Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColisCard(DemandeColisModel demande) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demande d\'Expédition',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(demande.dateCreation),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatutChip(demande.statut),
              ],
            ),
            const SizedBox(height: 16),

            // Détails
            _buildDetailRow('Description', demande.description, Icons.description),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Expéditeur',
              '${demande.expediteurNom} - ${demande.expediteurVille}',
              Icons.person_outline,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Destinataire',
              '${demande.destinataireNom} - ${demande.destinataireVille}',
              Icons.person_pin_circle_outlined,
            ),
            if (demande.poids != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Poids',
                '${demande.poids!.toStringAsFixed(1)} kg',
                Icons.scale,
              ),
            ],
            if (demande.tarifValide != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Tarif validé',
                '${demande.tarifValide!.toStringAsFixed(0)} FCFA',
                Icons.check_circle,
                color: Colors.green,
              ),
            ],

            // Instructions si présentes
            if (demande.instructions != null && demande.instructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions spéciales',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demande.instructions!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],

            // Commentaires de validation/rejet
            if (demande.commentaireValidation != null) ...[
              const SizedBox(height: 12),
              _buildCommentaireBox(
                'Commentaire de validation',
                demande.commentaireValidation!,
                Colors.green,
              ),
            ],
            if (demande.commentaireRejet != null) ...[
              const SizedBox(height: 12),
              _buildCommentaireBox(
                'Motif de rejet',
                demande.commentaireRejet!,
                Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black87,
              fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatutChip(String statut) {
    Color color;
    String label;
    IconData icon;

    switch (statut) {
      case 'enAttenteValidation':
        color = Colors.orange;
        label = 'En attente';
        icon = Icons.hourglass_empty;
        break;
      case 'validee':
        color = Colors.green;
        label = 'Validée';
        icon = Icons.check_circle;
        break;
      case 'rejetee':
        color = Colors.red;
        label = 'Rejetée';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = statut;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentaireBox(String title, String commentaire, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            commentaire,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
