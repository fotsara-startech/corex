import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:intl/intl.dart';
import '../../theme/corex_theme.dart';
import 'course_details_screen.dart';

class SuiviCoursesScreen extends StatefulWidget {
  const SuiviCoursesScreen({super.key});

  @override
  State<SuiviCoursesScreen> createState() => _SuiviCoursesScreenState();
}

class _SuiviCoursesScreenState extends State<SuiviCoursesScreen> {
  CourseController? _courseController;
  UserController? _userController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    try {
      // Initialiser les contrôleurs de manière sécurisée
      if (Get.isRegistered<CourseController>()) {
        _courseController = Get.find<CourseController>();
      } else {
        _courseController = Get.put(CourseController());
      }

      if (Get.isRegistered<UserController>()) {
        _userController = Get.find<UserController>();
      } else {
        _userController = Get.put(UserController());
      }

      // Charger les données après l'initialisation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _courseController?.loadCourses();
        _userController?.loadUsers();
      });
    } catch (e) {
      print('⚠️ [SUIVI_COURSES] Erreur initialisation contrôleurs: $e');
      // Fallback: créer les contrôleurs directement
      _courseController = CourseController();
      _userController = UserController();
      Get.put(_courseController!, permanent: true);
      Get.put(_userController!, permanent: true);
    }
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

  List<UserModel> get _coursiers {
    return _userController?.usersList.where((user) => user.role == 'coursier').toList() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier que les contrôleurs sont initialisés
    if (_courseController == null || _userController == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Suivi des Tâches'),
          backgroundColor: CorexTheme.primaryGreen,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation en cours...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Tâches'),
        backgroundColor: CorexTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _courseController?.loadCourses(),
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
                      (_courseController?.totalCourses ?? 0).toString(),
                      Colors.blue,
                      Icons.list,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'En Attente',
                      (_courseController?.coursesEnAttente ?? 0).toString(),
                      Colors.orange,
                      Icons.pending,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'En Cours',
                      (_courseController?.coursesEnCours ?? 0).toString(),
                      Colors.blue,
                      Icons.assignment_ind,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      'Terminées',
                      (_courseController?.coursesTerminees ?? 0).toString(),
                      Colors.green,
                      Icons.check_circle,
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
                        value: _courseController?.filterStatut.value ?? 'tous',
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
                          if (value != null && _courseController != null) {
                            _courseController!.filterStatut.value = value;
                          }
                        },
                      )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: _courseController?.filterCoursier.value ?? 'tous',
                        decoration: const InputDecoration(
                          labelText: 'Filtrer par commissionnaire',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        items: [
                          const DropdownMenuItem(value: 'tous', child: Text('Tous')),
                          ..._coursiers.map((coursier) {
                            return DropdownMenuItem(
                              value: coursier.id,
                              child: Text(coursier.nomComplet),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          if (value != null && _courseController != null) {
                            _courseController!.filterCoursier.value = value;
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
              if (_courseController?.isLoading.value == true) {
                return const Center(child: CircularProgressIndicator());
              }

              final courses = _courseController?.filteredCourses ?? [];

              if (courses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune tâche',
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
              if (course.coursierNom != null) _buildInfoRow(Icons.person_pin, 'Commissionnaire', course.coursierNom!),
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
                      Icons.calendar_today,
                      'Créée le',
                      dateFormat.format(course.dateCreation),
                    ),
                  ),
                ],
              ),
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
