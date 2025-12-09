import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:intl/intl.dart';
import '../../theme/corex_theme.dart';
import 'paiement_course_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final CourseService _courseService = Get.find<CourseService>();
  CourseModel? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() => _isLoading = true);
    final course = await _courseService.getCourseById(widget.courseId);
    setState(() {
      _course = course;
      _isLoading = false;
    });
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'enAttente':
        return Colors.orange;
      case 'enCours':
        return Colors.blue;
      case 'terminee':
        return Colors.green;
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'enAttente':
        return 'En Attente';
      case 'enCours':
        return 'En Cours';
      case 'terminee':
        return 'Terminée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails de la Course'),
          backgroundColor: CorexTheme.primaryGreen,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails de la Course'),
          backgroundColor: CorexTheme.primaryGreen,
        ),
        body: const Center(child: Text('Course introuvable')),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Course'),
        backgroundColor: CorexTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourse,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _getStatutColor(_course!.statut).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatutLabel(_course!.statut),
                  style: TextStyle(
                    color: _getStatutColor(_course!.statut),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Informations client
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    _buildDetailRow(Icons.person, 'Nom', _course!.clientNom),
                    _buildDetailRow(Icons.phone, 'Téléphone', _course!.clientTelephone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Détails de la course
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails de la Course',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    _buildDetailRow(Icons.location_on, 'Lieu', _course!.lieu),
                    _buildDetailRow(Icons.task, 'Tâche', _course!.tache),
                    _buildDetailRow(Icons.description, 'Instructions', _course!.instructions),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarification
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarification',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.attach_money,
                      'Montant estimé',
                      '${_course!.montantEstime.toStringAsFixed(0)} FCFA',
                    ),
                    _buildDetailRow(
                      Icons.percent,
                      'Commission (${_course!.commissionPourcentage}%)',
                      '${_course!.commissionMontant.toStringAsFixed(0)} FCFA',
                    ),
                    if (_course!.montantReel != null)
                      _buildDetailRow(
                        Icons.money,
                        'Montant réel',
                        '${_course!.montantReel!.toStringAsFixed(0)} FCFA',
                      ),
                    if (_course!.paye) ...[
                      const Divider(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Paiement enregistré',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  if (_course!.datePaiement != null)
                                    Text(
                                      'Le ${DateFormat('dd/MM/yyyy à HH:mm').format(_course!.datePaiement!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Coursier
            if (_course!.coursierNom != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coursier',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      _buildDetailRow(Icons.delivery_dining, 'Nom', _course!.coursierNom!),
                      if (_course!.dateAttribution != null)
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Attribué le',
                          dateFormat.format(_course!.dateAttribution!),
                        ),
                      if (_course!.dateDebut != null)
                        _buildDetailRow(
                          Icons.play_arrow,
                          'Démarré le',
                          dateFormat.format(_course!.dateDebut!),
                        ),
                      if (_course!.dateFin != null)
                        _buildDetailRow(
                          Icons.check,
                          'Terminé le',
                          dateFormat.format(_course!.dateFin!),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dates',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Créée le',
                      dateFormat.format(_course!.dateCreation),
                    ),
                  ],
                ),
              ),
            ),

            // Justificatifs
            if (_course!.justificatifs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Justificatifs',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      Text('${_course!.justificatifs.length} fichier(s) uploadé(s)'),
                    ],
                  ),
                ),
              ),
            ],

            // Bouton de paiement
            if (_course!.statut == 'terminee' && !_course!.paye) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Get.to(() => PaiementCourseScreen(course: _course!));
                    _loadCourse(); // Recharger après paiement
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Enregistrer le Paiement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CorexTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
