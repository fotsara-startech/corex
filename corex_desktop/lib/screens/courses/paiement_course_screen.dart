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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final montantFinal = widget.course.montantReel ?? widget.course.montantEstime;
    final commission = montantFinal * (widget.course.commissionPourcentage / 100);

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

              // Détails financiers
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
                      _buildFinanceRow(
                        'Commission COREX (${widget.course.commissionPourcentage}%)',
                        commission,
                        CorexTheme.primaryGreen,
                      ),
                      const Divider(),
                      _buildFinanceRow(
                        'MONTANT TOTAL',
                        montantFinal,
                        Colors.black,
                        isBold: true,
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
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
                      _buildCheckItem(
                          'Les justificatifs ont été validés (si présents)'),
                      _buildCheckItem(
                          'Une transaction financière sera créée automatiquement'),
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
                        onPressed: _courseController.isLoading.value
                            ? null
                            : _enregistrerPaiement,
                        icon: _courseController.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildFinanceRow(String label, double montant, Color color,
      {bool isBold = false}) {
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

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmer le paiement'),
        content: Text(
          'Voulez-vous enregistrer le paiement de ${(widget.course.montantReel ?? widget.course.montantEstime).toStringAsFixed(0)} FCFA ?\n\n'
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
        await _courseController.enregistrerPaiement(widget.course.id!);
        Get.back(); // Retour à l'écran précédent
      } catch (e) {
        // Erreur déjà gérée dans le controller
      }
    }
  }
}
