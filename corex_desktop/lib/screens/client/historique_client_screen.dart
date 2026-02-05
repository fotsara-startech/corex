import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoriqueClientScreen extends StatefulWidget {
  const HistoriqueClientScreen({super.key});

  @override
  State<HistoriqueClientScreen> createState() => _HistoriqueClientScreenState();
}

class _HistoriqueClientScreenState extends State<HistoriqueClientScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final AuthController _authController;

  final RxList<CourseModel> _coursesTerminees = <CourseModel>[].obs;
  final RxList<ColisModel> _colisTermines = <ColisModel>[].obs;
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

    _loadHistoriqueFromFirestore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoriqueFromFirestore() async {
    _isLoading.value = true;
    try {
      final user = _authController.currentUser.value!;

      // Charger les courses terminées du client
      final coursesQuery = await FirebaseFirestore.instance
          .collection('courses')
          .where('clientId', isEqualTo: user.id)
          .where('statut', whereIn: ['terminee', 'payee'])
          .orderBy('dateCreation', descending: true)
          .limit(50)
          .get();

      _coursesTerminees.value = coursesQuery.docs.map((doc) => CourseModel.fromFirestore(doc)).toList();

      // Charger les colis livrés du client
      final colisQuery = await FirebaseFirestore.instance
          .collection('colis')
          .where('expediteurEmail', isEqualTo: user.email)
          .where('statut', whereIn: ['livre', 'recupere'])
          .orderBy('dateCollecte', descending: true)
          .limit(50)
          .get();

      _colisTermines.value = colisQuery.docs.map((doc) => ColisModel.fromFirestore(doc)).toList();

      print('✅ [HISTORIQUE] Chargé ${_coursesTerminees.length} courses et ${_colisTermines.length} colis');
    } catch (e) {
      print('❌ [HISTORIQUE] Erreur chargement: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger votre historique: $e',
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
        title: const Text('Historique'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoriqueFromFirestore,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.directions_car),
              text: 'Courses (${_coursesTerminees.length})',
            ),
            Tab(
              icon: const Icon(Icons.local_shipping),
              text: 'Colis (${_colisTermines.length})',
            ),
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
    if (_coursesTerminees.isEmpty) {
      return _buildEmptyState(
        'Aucune course terminée',
        'Vous n\'avez pas encore de courses terminées dans votre historique.',
        Icons.directions_car,
        const Color(0xFF2E7D32),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _coursesTerminees.length,
      itemBuilder: (context, index) {
        final course = _coursesTerminees[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildColisTab() {
    if (_colisTermines.isEmpty) {
      return _buildEmptyState(
        'Aucun colis livré',
        'Vous n\'avez pas encore de colis livrés dans votre historique.',
        Icons.local_shipping,
        const Color(0xFF1976D2),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _colisTermines.length,
      itemBuilder: (context, index) {
        final colis = _colisTermines[index];
        return _buildColisCard(colis);
      },
    );
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

  Widget _buildCourseCard(CourseModel course) {
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
                        'Course Terminée',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(course.dateCreation),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatutChip(course.statut, true),
              ],
            ),
            const SizedBox(height: 16),

            // Détails
            _buildDetailRow('Lieu', course.lieu, Icons.location_on),
            const SizedBox(height: 8),
            _buildDetailRow('Tâche', course.tache, Icons.assignment),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Montant',
              '${course.montantEstime.toStringAsFixed(0)} FCFA',
              Icons.attach_money,
              color: Colors.green,
            ),
            if (course.coursierNom != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Coursier', course.coursierNom!, Icons.person),
            ],

            // Instructions si présentes
            if (course.instructions.isNotEmpty) ...[
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
                      course.instructions,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildColisCard(ColisModel colis) {
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
                        'Colis Livré',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(colis.dateCollecte),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatutChip(colis.statut, false),
              ],
            ),
            const SizedBox(height: 16),

            // Détails
            _buildDetailRow('N° Suivi', colis.numeroSuivi, Icons.qr_code),
            const SizedBox(height: 8),
            _buildDetailRow('Contenu', colis.contenu, Icons.description),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Destinataire',
              '${colis.destinataireNom} - ${colis.destinataireVille}',
              Icons.person_pin_circle_outlined,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              'Tarif',
              '${colis.montantTarif.toStringAsFixed(0)} FCFA',
              Icons.attach_money,
              color: Colors.green,
            ),
            if (colis.poids > 0) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Poids',
                '${colis.poids.toStringAsFixed(1)} kg',
                Icons.scale,
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

  Widget _buildStatutChip(String statut, bool isCourse) {
    Color color;
    String label;
    IconData icon;

    if (isCourse) {
      switch (statut) {
        case 'terminee':
          color = Colors.green;
          label = 'Terminée';
          icon = Icons.check_circle;
          break;
        case 'payee':
          color = Colors.blue;
          label = 'Payée';
          icon = Icons.payment;
          break;
        default:
          color = Colors.grey;
          label = statut;
          icon = Icons.help;
      }
    } else {
      switch (statut) {
        case 'livre':
          color = Colors.green;
          label = 'Livré';
          icon = Icons.check_circle;
          break;
        case 'recupere':
          color = Colors.blue;
          label = 'Récupéré';
          icon = Icons.done_all;
          break;
        default:
          color = Colors.grey;
          label = statut;
          icon = Icons.help;
      }
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
