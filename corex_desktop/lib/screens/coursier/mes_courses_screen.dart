import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:intl/intl.dart';
import '../../theme/corex_theme.dart';

class MesCoursesScreen extends StatefulWidget {
  const MesCoursesScreen({super.key});

  @override
  State<MesCoursesScreen> createState() => _MesCoursesScreenState();
}

class _MesCoursesScreenState extends State<MesCoursesScreen> {
  final CourseController _courseController = Get.find<CourseController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _courseController.loadCourses();
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

  Future<void> _demarrerCourse(CourseModel course) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Démarrer la course'),
        content: Text('Voulez-vous démarrer la course "${course.tache}" ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CorexTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _courseController.demarrerCourse(course.id!);
    }
  }

  Future<void> _terminerCourse(CourseModel course) async {
    final montantController = TextEditingController(
      text: course.montantEstime.toStringAsFixed(0),
    );

    final result = await Get.dialog<Map<String, dynamic>>(
      AlertDialog(
        title: const Text('Terminer la course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Course: ${course.tache}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: montantController,
              decoration: const InputDecoration(
                labelText: 'Montant réel (FCFA)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: L\'upload des justificatifs sera disponible prochainement',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
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
              final montant = double.tryParse(montantController.text);
              if (montant == null || montant <= 0) {
                Get.snackbar('Erreur', 'Montant invalide');
                return;
              }
              Get.back(result: {
                'montant': montant,
                'justificatifs': <String>[], // Vide pour l'instant
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CorexTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _courseController.terminerCourse(
        courseId: course.id!,
        montantReel: result['montant'],
        justificatifs: result['justificatifs'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Courses'),
        backgroundColor: CorexTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _courseController.loadCourses(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques
          Obx(() => Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    _buildStatCard(
                      'Total',
                      _courseController.totalCourses.toString(),
                      Colors.blue,
                      Icons.list,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'En Cours',
                      _courseController.coursesEnCours.toString(),
                      Colors.blue,
                      Icons.directions_run,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Terminées',
                      _courseController.coursesTerminees.toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ],
                ),
              )),

          // Filtre par statut
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => DropdownButtonFormField<String>(
                  value: _courseController.filterStatut.value,
                  decoration: const InputDecoration(
                    labelText: 'Filtrer par statut',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tous', child: Text('Tous')),
                    DropdownMenuItem(value: 'enCours', child: Text('En Cours')),
                    DropdownMenuItem(
                        value: 'terminee', child: Text('Terminées')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _courseController.filterStatut.value = value;
                    }
                  },
                )),
          ),

          // Liste des courses
          Expanded(
            child: Obx(() {
              if (_courseController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = _courseController.filteredCourses;

              if (courses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_run,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune course assignée',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return _buildCourseCard(course);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.tache,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.lieu,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatutColor(course.statut).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatutLabel(course.statut),
                    style: TextStyle(
                      color: _getStatutColor(course.statut),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, 'Client', course.clientNom),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, 'Téléphone', course.clientTelephone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.description, 'Instructions', course.instructions),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.attach_money,
              'Montant estimé',
              '${course.montantEstime.toStringAsFixed(0)} FCFA',
            ),
            if (course.dateAttribution != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.calendar_today,
                'Attribuée le',
                dateFormat.format(course.dateAttribution!),
              ),
            ],
            if (course.dateDebut != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.play_arrow,
                'Démarrée le',
                dateFormat.format(course.dateDebut!),
              ),
            ],
            if (course.dateFin != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.check,
                'Terminée le',
                dateFormat.format(course.dateFin!),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.money,
                'Montant réel',
                '${course.montantReel?.toStringAsFixed(0) ?? "0"} FCFA',
              ),
            ],
            const SizedBox(height: 12),
            // Boutons d'action
            if (course.statut == 'enCours' && course.dateDebut == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _demarrerCourse(course),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer la course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CorexTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            if (course.statut == 'enCours' && course.dateDebut != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _terminerCourse(course),
                  icon: const Icon(Icons.check),
                  label: const Text('Terminer la course'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
