import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';
import '../../theme/corex_theme.dart';

class ValidationDemandeColisDialog extends StatefulWidget {
  final DemandeColisModel demande;
  final VoidCallback onValidated;

  const ValidationDemandeColisDialog({
    super.key,
    required this.demande,
    required this.onValidated,
  });

  @override
  State<ValidationDemandeColisDialog> createState() => _ValidationDemandeColisDialogState();
}

class _ValidationDemandeColisDialogState extends State<ValidationDemandeColisDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tarifController = TextEditingController();
  final _commentaireController = TextEditingController();
  final DemandeController _demandeController = Get.find<DemandeController>();

  @override
  void dispose() {
    _tarifController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête fixe
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: CorexTheme.primaryGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Validation Demande d\'Expédition',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Contenu scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations client
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations Client',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CorexTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Nom', widget.demande.clientNom),
                          _buildInfoRow('Téléphone', widget.demande.clientTelephone),
                          _buildInfoRow('Email', widget.demande.clientEmail),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informations expéditeur et destinataire
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expéditeur',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Nom', widget.demande.expediteurNom),
                                _buildInfoRow('Téléphone', widget.demande.expediteurTelephone),
                                _buildInfoRow('Ville', widget.demande.expediteurVille),
                                _buildInfoRow('Adresse', widget.demande.expediteurAdresse),
                                if (widget.demande.expediteurQuartier != null) _buildInfoRow('Quartier', widget.demande.expediteurQuartier!),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destinataire',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Nom', widget.demande.destinataireNom),
                                _buildInfoRow('Téléphone', widget.demande.destinataireTelephone),
                                _buildInfoRow('Ville', widget.demande.destinataireVille),
                                _buildInfoRow('Adresse', widget.demande.destinataireAdresse),
                                if (widget.demande.destinataireQuartier != null) _buildInfoRow('Quartier', widget.demande.destinataireQuartier!),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Détails du colis
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détails du Colis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Description', widget.demande.description),
                          if (widget.demande.poids != null) _buildInfoRow('Poids', '${widget.demande.poids!.toStringAsFixed(1)} kg'),
                          if (widget.demande.dimensions != null) _buildInfoRow('Dimensions', widget.demande.dimensions!),
                          if (widget.demande.valeurDeclaree != null)
                            _buildInfoRow(
                              'Valeur déclarée',
                              '${widget.demande.valeurDeclaree!.toStringAsFixed(0)} FCFA',
                            ),
                          if (widget.demande.instructions != null) _buildInfoRow('Instructions', widget.demande.instructions!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Formulaire de validation
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Validation et Tarification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CorexTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tarif
                          TextFormField(
                            controller: _tarifController,
                            decoration: const InputDecoration(
                              labelText: 'Tarif d\'expédition (FCFA)',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                              hintText: 'Ex: 3000',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Veuillez saisir le tarif';
                              }
                              final tarif = double.tryParse(value);
                              if (tarif == null || tarif <= 0) {
                                return 'Tarif invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Commentaire optionnel
                          TextFormField(
                            controller: _commentaireController,
                            decoration: const InputDecoration(
                              labelText: 'Commentaire (optionnel)',
                              prefixIcon: Icon(Icons.comment),
                              border: OutlineInputBorder(),
                              hintText: 'Informations supplémentaires pour le client...',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Boutons d'action fixes en bas
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton.icon(
                          onPressed: _demandeController.isProcessing.value ? null : _validerDemande,
                          icon: _demandeController.isProcessing.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label: const Text('Valider l\'Expédition'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CorexTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validerDemande() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final tarif = double.parse(_tarifController.text);
      final commentaire = _commentaireController.text.trim();

      await _demandeController.validerDemandeColis(
        demandeId: widget.demande.id!,
        tarifValide: tarif,
        commentaire: commentaire.isNotEmpty ? commentaire : null,
      );

      Navigator.of(context).pop();
      widget.onValidated();
    } catch (e) {
      // L'erreur est déjà gérée dans le contrôleur
    }
  }
}
