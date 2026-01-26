import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import 'package:intl/intl.dart';
import '../../theme/corex_theme.dart';

class PaiementCourseScreen extends StatefulWidget {
  final CourseModel course;

  const PaiementCourseScreen({super.key, required this.course});

  @override
  State<PaiementCourseScreen> createState() => _PaiementCourseScreenState();
}

class _PaiementCourseScreenState extends State<PaiementCourseScreen> {
  final CourseController _courseController = Get.find<CourseController>();
  final _formKey = GlobalKey<FormState>();

  // Variables pour gérer le mode de commission
  late double _pourcentageCommission;
  late double _montantFixeCommission;
  bool _utiliserMontantFixe = false;

  final _pourcentageController = TextEditingController();
  final _montantFixeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser les valeurs de commission UNE SEULE FOIS
    final montantFinal = widget.course.montantReel ?? widget.course.montantEstime;
    _pourcentageCommission = widget.course.commissionPourcentage;
    _montantFixeCommission = montantFinal * (_pourcentageCommission / 100);
    _pourcentageController.text = _pourcentageCommission.toStringAsFixed(2);
    _montantFixeController.text = _montantFixeCommission.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _pourcentageController.dispose();
    _montantFixeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final montantFinal = widget.course.montantReel ?? widget.course.montantEstime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrer le Paiement'),
        backgroundColor: CorexTheme.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
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
                        'Détails de la Course',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      _buildInfoRow('Tâche', widget.course.tache),
                      _buildInfoRow('Lieu', widget.course.lieu),
                      _buildInfoRow('Client', widget.course.clientNom),
                      _buildInfoRow('Coursier', widget.course.coursierNom ?? 'N/A'),
                      if (widget.course.dateFin != null)
                        _buildInfoRow(
                          'Terminée le',
                          dateFormat.format(widget.course.dateFin!),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Détails financiers et Commission modifiable
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails Financiers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Divider(),
                      _buildFinanceRow(
                        'Montant estimé',
                        widget.course.montantEstime,
                        Colors.grey,
                      ),
                      if (widget.course.montantReel != null)
                        _buildFinanceRow(
                          'Montant réel',
                          widget.course.montantReel!,
                          Colors.blue,
                        ),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Section Commission
                      Text(
                        'Commission COREX',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: CorexTheme.primaryGreen,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Toggle: Pourcentage vs Montant Fixe
                      Row(
                        children: [
                          Expanded(
                            child: SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Pourcentage (%)'),
                                  icon: Icon(Icons.percent),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Montant Fixe'),
                                  icon: Icon(Icons.attach_money),
                                ),
                              ],
                              selected: {_utiliserMontantFixe},
                              onSelectionChanged: (Set<bool> newSelection) {
                                setState(() {
                                  _utiliserMontantFixe = newSelection.first;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Champ: Pourcentage ou Montant
                      if (!_utiliserMontantFixe)
                        TextFormField(
                          controller: _pourcentageController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Pourcentage (%)',
                            prefixIcon: const Icon(Icons.percent),
                            border: const OutlineInputBorder(),
                            helperText: 'Taux de commission à appliquer',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un pourcentage';
                            }
                            final pourcentage = double.tryParse(value);
                            if (pourcentage == null || pourcentage < 0 || pourcentage > 100) {
                              return 'Le pourcentage doit être entre 0 et 100';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              if (value.isNotEmpty) {
                                _pourcentageCommission = double.tryParse(value) ?? 0;
                                _montantFixeCommission = montantFinal * (_pourcentageCommission / 100);
                                _montantFixeController.text = _montantFixeCommission.toStringAsFixed(0);
                              }
                            });
                          },
                        )
                      else
                        TextFormField(
                          controller: _montantFixeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Montant Commission (FCFA)',
                            prefixIcon: const Icon(Icons.attach_money),
                            border: const OutlineInputBorder(),
                            helperText: 'Montant fixe à enregistrer en caisse',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un montant';
                            }
                            final montant = double.tryParse(value);
                            if (montant == null || montant < 0) {
                              return 'Le montant doit être positif';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              if (value.isNotEmpty) {
                                _montantFixeCommission = double.tryParse(value) ?? 0;
                                // Calculer le pourcentage équivalent pour affichage
                                if (montantFinal > 0) {
                                  _pourcentageCommission = (_montantFixeCommission / montantFinal) * 100;
                                }
                              }
                            });
                          },
                        ),
                      const SizedBox(height: 16),

                      // Affichage de la commission calculée
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CorexTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CorexTheme.primaryGreen),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Commission à enregistrer',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_montantFixeCommission.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    color: CorexTheme.primaryGreen,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!_utiliserMontantFixe)
                                  Text(
                                    '(${_pourcentageCommission.toStringAsFixed(2)}% de ${montantFinal.toStringAsFixed(0)} FCFA)',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            Icon(
                              Icons.check_circle,
                              color: CorexTheme.primaryGreen,
                              size: 40,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Justificatifs
              if (widget.course.justificatifs.isNotEmpty)
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
                        Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.course.justificatifs.length} fichier(s) uploadé(s)',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Validation du montant
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Validation du Paiement',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'En enregistrant ce paiement, vous confirmez que:',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      _buildCheckItem('Le montant a été vérifié'),
                      _buildCheckItem('Les justificatifs ont été validés (si présents)'),
                      _buildCheckItem('Une transaction financière sera créée automatiquement'),
                      _buildCheckItem('La course sera marquée comme payée'),
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
                        onPressed: _courseController.isLoading.value ? null : _enregistrerPaiement,
                        icon: _courseController.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Enregistrer le Paiement'),
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
        ),
      ),
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

  Widget _buildFinanceRow(String label, double montant, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            '${montant.toStringAsFixed(0)} FCFA',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enregistrerPaiement() async {
    if (!_formKey.currentState!.validate()) return;

    final montantFinal = widget.course.montantReel ?? widget.course.montantEstime;
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text(
          'Montant de la course: ${montantFinal.toStringAsFixed(0)} FCFA\n'
          'Commission à enregistrer: ${_montantFixeCommission.toStringAsFixed(0)} FCFA\n\n'
          'Voulez-vous continuer ?\n\n'
          'Une transaction financière sera créée automatiquement.',
        ),
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
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _courseController.enregistrerPaiement(
          widget.course.id!,
          montantCommission: _montantFixeCommission,
        );
        Get.back(); // Retour à l'écran précédent
      } catch (e) {
        // Erreur déjà gérée dans le controller
      }
    }
  }
}
