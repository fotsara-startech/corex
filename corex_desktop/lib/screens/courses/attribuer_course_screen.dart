import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import '../../theme/corex_theme.dart';

class AttribuerCourseScreen extends StatefulWidget {
  final CourseModel course;

  const AttribuerCourseScreen({super.key, required this.course});

  @override
  State<AttribuerCourseScreen> createState() => _AttribuerCourseScreenState();
}

class _AttribuerCourseScreenState extends State<AttribuerCourseScreen> {
  final CourseController _courseController = Get.find<CourseController>();
  final UserController _userController = Get.find<UserController>();

  UserModel? _selectedCoursier;

  @override
  void initState() {
    super.initState();
    _userController.loadUsers();
  }

  List<UserModel> get _coursiers {
    return _userController.usersList.where((user) => user.role == 'coursier' && user.isActive).toList();
  }

  Future<void> _attribuer() async {
    if (_selectedCoursier == null) {
      Get.snackbar('Erreur', 'Veuillez sélectionner un coursier');
      return;
    }

    try {
      await _courseController.attribuerCourse(
        courseId: widget.course.id!,
        coursier: _selectedCoursier!,
      );
      Get.back();
    } catch (e) {
      // Erreur déjà gérée dans le controller
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attribuer la Tâche'),
        backgroundColor: CorexTheme.primaryGreen,
      ),
      body: Obx(() {
        if (_userController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations de la course
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails de la Tâche',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      _buildInfoRow('Tâche', widget.course.tache),
                      _buildInfoRow('Lieu', widget.course.lieu),
                      _buildInfoRow('Client', widget.course.clientNom),
                      _buildInfoRow(
                        'Montant',
                        '${widget.course.montantEstime.toStringAsFixed(0)} FCFA',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sélection du coursier
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sélectionner un Commissionnaire',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      if (_coursiers.isEmpty)
                        const Text(
                          'Aucun commissionnaire actif disponible',
                          style: TextStyle(color: Colors.red),
                        )
                      else
                        DropdownButtonFormField<UserModel>(
                          value: _selectedCoursier,
                          decoration: const InputDecoration(
                            labelText: 'Commissionnaire',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_pin),
                          ),
                          items: _coursiers.map((coursier) {
                            return DropdownMenuItem(
                              value: coursier,
                              child: Text(
                                '${coursier.nomComplet} - ${coursier.telephone}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCoursier = value;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Boutons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  Obx(() => ElevatedButton.icon(
                        onPressed: _courseController.isLoading.value || _coursiers.isEmpty ? null : _attribuer,
                        icon: _courseController.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Attribuer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CorexTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      )),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
