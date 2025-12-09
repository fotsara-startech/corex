import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:intl/intl.dart';
import '../../theme/corex_theme.dart';
import 'create_course_screen.dart';
import 'course_details_screen.dart';
import 'attribuer_course_screen.dart';
import 'suivi_courses_screen.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  final CourseController _courseController = Get.find<CourseController>();
  final AuthController _authController = Get.find<AuthController>();

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

  @override
  Widget build(BuildContext context) {
    final user = _authController.currentUser.value;
    final canCreate = user?.role == 'commercial' || user?.role == 'gestionnaire' || user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service de Courses'),
        backgroundColor: CorexTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => Get.to(() => const SuiviCoursesScreen()),
            tooltip: 'Suivi des courses',
          ),
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
                      'En Attente',
                      _courseController.coursesEnAttente.toString(),
                      Colors.orange,
                      Icons.pending,
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
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Commission',
                      '${_courseController.totalCommissions.toStringAsFixed(0)} FCFA',
                      CorexTheme.primaryGreen,
                      Icons.attach_money,
                    ),
                  ],
                ),
              )),

          // Filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: _courseController.filterStatut.value,
                        decoration: const InputDecoration(
                          labelText: 'Filtrer par statut',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'tous', child: Text('Tous')),
                          DropdownMenuItem(value: 'enAttente', child: Text('En Attente')),
                          DropdownMenuItem(value: 'enCours', child: Text('En Cours')),
                          DropdownMenuItem(value: 'terminee', child: Text('Terminées')),
                          DropdownMenuItem(value: 'annulee', child: Text('Annulées')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _courseController.filterStatut.value = value;
                          }
                        },
                      )),
                ),
              ],
            ),
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
                      Icon(Icons.directions_run, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune course',
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
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => Get.to(() => const CreateCourseScreen()),
              backgroundColor: CorexTheme.primaryGreen,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle Course'),
            )
          : null,
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
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
      child: InkWell(
        onTap: () => Get.to(() => CourseDetailsScreen(courseId: course.id!)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(Icons.person, 'Client', course.clientNom),
                  ),
                  Expanded(
                    child: _buildInfoRow(Icons.phone, 'Téléphone', course.clientTelephone),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(
                      Icons.attach_money,
                      'Montant',
                      '${course.montantEstime.toStringAsFixed(0)} FCFA',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoRow(
                      Icons.percent,
                      'Commission',
                      '${course.commissionMontant.toStringAsFixed(0)} FCFA',
                    ),
                  ),
                ],
              ),
              if (course.coursierNom != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(Icons.delivery_dining, 'Coursier', course.coursierNom!),
              ],
              const SizedBox(height: 8),
              _buildInfoRow(Icons.calendar_today, 'Créée le', dateFormat.format(course.dateCreation)),
              if (course.paye) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Paiement enregistré',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              if (course.statut == 'enAttente') ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => AttribuerCourseScreen(course: course)),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Attribuer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CorexTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
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
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
