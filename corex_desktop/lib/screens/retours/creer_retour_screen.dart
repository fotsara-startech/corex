import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/retour_controller.dart';
import 'package:corex_shared/models/colis_model.dart';

class CreerRetourScreen extends StatefulWidget {
  const CreerRetourScreen({Key? key}) : super(key: key);

  @override
  State<CreerRetourScreen> createState() => _CreerRetourScreenState();
}

class _CreerRetourScreenState extends State<CreerRetourScreen> {
  final RetourController _retourController = Get.put(RetourController());
  final TextEditingController _numeroSuiviController = TextEditingController();
  final TextEditingController _commentaireController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _numeroSuiviController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _rechercherColis() async {
    if (_numeroSuiviController.text.trim().isEmpty) {
      Get.snackbar('Erreur', 'Veuillez saisir un numéro de suivi');
      return;
    }

    await _retourController.rechercherColisParNumero(_numeroSuiviController.text.trim());
  }

  Future<void> _creerRetour() async {
    if (_retourController.selectedColis.value == null) {
      Get.snackbar('Erreur', 'Veuillez d\'abord rechercher un colis');
      return;
    }

    if (_formKey.currentState!.validate()) {
      final success = await _retourController.creerRetour(
        _retourController.selectedColis.value!,
        commentaire: _commentaireController.text.trim().isEmpty 
            ? null 
            : _commentaireController.text.trim(),
      );

      if (success) {
        _numeroSuiviController.clear();
        _commentaireController.clear();
        _retourController.selectedColis.value = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un Retour'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Obx(() {
        if (_retourController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section de recherche
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rechercher le colis initial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _numeroSuiviController,
                                decoration: const InputDecoration(
                                  labelText: 'Numéro de suivi',
                                  hintText: 'COL-2025-XXXXXX',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.search),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez saisir un numéro de suivi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _rechercherColis,
                              icon: const Icon(Icons.search),
                              label: const Text('Rechercher'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Détails du colis trouvé
                if (_retourController.selectedColis.value != null)
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Colis trouvé',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildColisDetails(_retourController.selectedColis.value!),
                          const SizedBox(height: 24),
                          
                          // Commentaire optionnel
                          TextFormField(
                            controller: _commentaireController,
                            decoration: const InputDecoration(
                              labelText: 'Commentaire (optionnel)',
                              hintText: 'Raison du retour...',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.comment),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          
                          // Bouton de création
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _creerRetour,
                              icon: const Icon(Icons.add_circle),
                              label: const Text('Créer le Retour'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildColisDetails(ColisModel colis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Numéro de suivi', colis.numeroSuivi),
        _buildDetailRow('Statut', colis.statut),
        const SizedBox(height: 16),
        const Text(
          'Expéditeur (deviendra destinataire du retour)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Nom', colis.expediteurNom),
        _buildDetailRow('Téléphone', colis.expediteurTelephone),
        _buildDetailRow('Adresse', colis.expediteurAdresse),
        const SizedBox(height: 16),
        const Text(
          'Destinataire (deviendra expéditeur du retour)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Nom', colis.destinataireNom),
        _buildDetailRow('Téléphone', colis.destinataireTelephone),
        _buildDetailRow('Adresse', colis.destinataireAdresse),
        const SizedBox(height: 16),
        const Text(
          'Détails du colis',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Contenu', colis.contenu),
        _buildDetailRow('Poids', '${colis.poids} kg'),
        _buildDetailRow('Tarif', '${colis.montantTarif} FCFA'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
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
