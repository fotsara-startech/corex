import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

class DemandeColisForm extends StatefulWidget {
  const DemandeColisForm({super.key});

  @override
  State<DemandeColisForm> createState() => _DemandeColisFormState();
}

class _DemandeColisFormState extends State<DemandeColisForm> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour les champs expéditeur
  final _expediteurNom = TextEditingController();
  final _expediteurTelephone = TextEditingController();
  final _expediteurAdresse = TextEditingController();
  final _expediteurVille = TextEditingController();
  final _expediteurQuartier = TextEditingController();

  // Contrôleurs pour les champs destinataire
  final _destinataireNom = TextEditingController();
  final _destinataireTelephone = TextEditingController();
  final _destinataireAdresse = TextEditingController();
  final _destinataireVille = TextEditingController();
  final _destinataireQuartier = TextEditingController();

  // Contrôleurs pour les informations du colis
  final _description = TextEditingController();
  final _poids = TextEditingController();
  final _dimensions = TextEditingController();
  final _valeurDeclaree = TextEditingController();
  final _instructions = TextEditingController();

  late final DemandeController _demandeController;
  late final AuthController _authController;

  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();

    try {
      _demandeController = Get.find<DemandeController>();
      _authController = Get.find<AuthController>();
    } catch (e) {
      print('⚠️ [DEMANDE COLIS] Controllers non trouvés: $e');
      if (!Get.isRegistered<DemandeController>()) {
        Get.put(DemandeController());
        _demandeController = Get.find<DemandeController>();
      }
      if (!Get.isRegistered<AuthController>()) {
        Get.back();
        return;
      }
      _authController = Get.find<AuthController>();
    }

    // Vérifier que l'utilisateur est un client
    final user = _authController.currentUser.value;
    if (user == null || user.role != 'client') {
      Get.back();
      Get.snackbar('Erreur', 'Accès non autorisé');
      return;
    }

    // Pré-remplir les informations de l'expéditeur avec les données du client
    _expediteurNom.text = user.nomComplet;
    _expediteurTelephone.text = user.telephone;
  }

  @override
  void dispose() {
    _expediteurNom.dispose();
    _expediteurTelephone.dispose();
    _expediteurAdresse.dispose();
    _expediteurVille.dispose();
    _expediteurQuartier.dispose();
    _destinataireNom.dispose();
    _destinataireTelephone.dispose();
    _destinataireAdresse.dispose();
    _destinataireVille.dispose();
    _destinataireQuartier.dispose();
    _description.dispose();
    _poids.dispose();
    _dimensions.dispose();
    _valeurDeclaree.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _submitDemande() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;

    try {
      final user = _authController.currentUser.value!;

      final demande = DemandeColisModel(
        clientId: user.id,
        clientNom: user.nomComplet,
        clientEmail: user.email,
        clientTelephone: user.telephone,
        expediteurNom: _expediteurNom.text.trim(),
        expediteurTelephone: _expediteurTelephone.text.trim(),
        expediteurAdresse: _expediteurAdresse.text.trim(),
        expediteurVille: _expediteurVille.text.trim(),
        expediteurQuartier: _expediteurQuartier.text.trim().isEmpty ? null : _expediteurQuartier.text.trim(),
        destinataireNom: _destinataireNom.text.trim(),
        destinataireTelephone: _destinataireTelephone.text.trim(),
        destinataireAdresse: _destinataireAdresse.text.trim(),
        destinataireVille: _destinataireVille.text.trim(),
        destinataireQuartier: _destinataireQuartier.text.trim().isEmpty ? null : _destinataireQuartier.text.trim(),
        description: _description.text.trim(),
        poids: double.tryParse(_poids.text),
        dimensions: _dimensions.text.trim().isEmpty ? null : _dimensions.text.trim(),
        valeurDeclaree: double.tryParse(_valeurDeclaree.text),
        instructions: _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
        statut: 'enAttenteValidation',
      );

      await _demandeController.creerDemandeColis(demande);

      Get.back();
      Get.snackbar(
        'Demande envoyée',
        'Votre demande d\'expédition a été envoyée avec succès. Vous recevrez une confirmation par email.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4CAF50),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer la demande: $e',
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
        title: const Text('Demande d\'Expédition'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          double padding = isMobile ? 16.0 : 24.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 800,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1976D2).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_shipping,
                                  color: Color(0xFF1976D2),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nouvelle Demande d\'Expédition',
                                      style: TextStyle(
                                        fontSize: isMobile ? 18 : 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Remplissez les informations ci-dessous',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Expéditeur
                      _buildSectionCard(
                        'Informations Expéditeur',
                        Icons.person_outline,
                        const Color(0xFF4CAF50),
                        [
                          TextFormField(
                            controller: _expediteurNom,
                            decoration: const InputDecoration(
                              labelText: 'Nom complet de l\'expéditeur',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nom de l\'expéditeur requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _expediteurTelephone,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone de l\'expéditeur',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Téléphone de l\'expéditeur requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _expediteurAdresse,
                            decoration: const InputDecoration(
                              labelText: 'Adresse de l\'expéditeur',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Adresse de l\'expéditeur requise';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          if (isMobile) ...[
                            TextFormField(
                              controller: _expediteurVille,
                              decoration: const InputDecoration(
                                labelText: 'Ville de l\'expéditeur',
                                prefixIcon: Icon(Icons.location_city),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ville de l\'expéditeur requise';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _expediteurQuartier,
                              decoration: const InputDecoration(
                                labelText: 'Quartier (optionnel)',
                                prefixIcon: Icon(Icons.map),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _expediteurVille,
                                    decoration: const InputDecoration(
                                      labelText: 'Ville de l\'expéditeur',
                                      prefixIcon: Icon(Icons.location_city),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ville de l\'expéditeur requise';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _expediteurQuartier,
                                    decoration: const InputDecoration(
                                      labelText: 'Quartier (optionnel)',
                                      prefixIcon: Icon(Icons.map),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                        padding,
                      ),
                      const SizedBox(height: 24),

                      // Section Destinataire
                      _buildSectionCard(
                        'Informations Destinataire',
                        Icons.person_pin_circle_outlined,
                        const Color(0xFFFF9800),
                        [
                          TextFormField(
                            controller: _destinataireNom,
                            decoration: const InputDecoration(
                              labelText: 'Nom complet du destinataire',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nom du destinataire requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _destinataireTelephone,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone du destinataire',
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Téléphone du destinataire requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _destinataireAdresse,
                            decoration: const InputDecoration(
                              labelText: 'Adresse du destinataire',
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Adresse du destinataire requise';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          if (isMobile) ...[
                            TextFormField(
                              controller: _destinataireVille,
                              decoration: const InputDecoration(
                                labelText: 'Ville du destinataire',
                                prefixIcon: Icon(Icons.location_city),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ville du destinataire requise';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _destinataireQuartier,
                              decoration: const InputDecoration(
                                labelText: 'Quartier (optionnel)',
                                prefixIcon: Icon(Icons.map),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _destinataireVille,
                                    decoration: const InputDecoration(
                                      labelText: 'Ville du destinataire',
                                      prefixIcon: Icon(Icons.location_city),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ville du destinataire requise';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _destinataireQuartier,
                                    decoration: const InputDecoration(
                                      labelText: 'Quartier (optionnel)',
                                      prefixIcon: Icon(Icons.map),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                        padding,
                      ),
                      const SizedBox(height: 24),

                      // Section Colis
                      _buildSectionCard(
                        'Informations du Colis',
                        Icons.inventory_2_outlined,
                        const Color(0xFF9C27B0),
                        [
                          TextFormField(
                            controller: _description,
                            decoration: const InputDecoration(
                              labelText: 'Description du contenu',
                              prefixIcon: Icon(Icons.description),
                              hintText: 'Ex: Vêtements, documents, électronique...',
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Description du contenu requise';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          if (isMobile) ...[
                            TextFormField(
                              controller: _poids,
                              decoration: const InputDecoration(
                                labelText: 'Poids approximatif (kg)',
                                prefixIcon: Icon(Icons.scale),
                                hintText: 'Ex: 2.5',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _dimensions,
                              decoration: const InputDecoration(
                                labelText: 'Dimensions (optionnel)',
                                prefixIcon: Icon(Icons.straighten),
                                hintText: 'Ex: 30x20x10 cm',
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _poids,
                                    decoration: const InputDecoration(
                                      labelText: 'Poids approximatif (kg)',
                                      prefixIcon: Icon(Icons.scale),
                                      hintText: 'Ex: 2.5',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _dimensions,
                                    decoration: const InputDecoration(
                                      labelText: 'Dimensions (optionnel)',
                                      prefixIcon: Icon(Icons.straighten),
                                      hintText: 'Ex: 30x20x10 cm',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _valeurDeclaree,
                            decoration: const InputDecoration(
                              labelText: 'Valeur déclarée (FCFA) - optionnel',
                              prefixIcon: Icon(Icons.attach_money),
                              hintText: 'Pour l\'assurance',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _instructions,
                            decoration: const InputDecoration(
                              labelText: 'Instructions spéciales (optionnel)',
                              prefixIcon: Icon(Icons.comment),
                              hintText: 'Précautions particulières...',
                            ),
                            maxLines: 3,
                          ),
                        ],
                        padding,
                      ),
                      const SizedBox(height: 32),

                      // Bouton de soumission
                      Obx(() => SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading.value ? null : _submitDemande,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1976D2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading.value
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Envoyer la demande d\'expédition',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
    double padding,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
