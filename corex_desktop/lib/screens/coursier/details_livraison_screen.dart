import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/livraison_controller.dart';
import 'package:corex_shared/controllers/colis_controller.dart';
import 'package:corex_shared/models/livraison_model.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
// import 'package:image_picker/image_picker.dart';

class DetailsLivraisonScreen extends StatefulWidget {
  const DetailsLivraisonScreen({super.key});

  @override
  State<DetailsLivraisonScreen> createState() => _DetailsLivraisonScreenState();
}

class _DetailsLivraisonScreenState extends State<DetailsLivraisonScreen> {
  final livraisonController = Get.find<LivraisonController>();
  final colisController = Get.find<ColisController>();
  final motifController = TextEditingController();
  final commentaireController = TextEditingController();
  String? selectedMotif;
  File? preuveImage;
  File? echecImage;

  final List<String> motifsEchec = [
    'Destinataire absent',
    'Adresse incorrecte',
    'Refus de réception',
    'Téléphone injoignable',
    'Autre',
  ];

  @override
  void dispose() {
    motifController.dispose();
    commentaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final livraison = Get.arguments as LivraisonModel?;

    if (livraison == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails de la livraison'),
        ),
        body: const Center(
          child: Text('Erreur: Livraison introuvable'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la livraison'),
      ),
      body: FutureBuilder<ColisModel?>(
        future: colisController.getColisById(livraison.colisId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Colis non trouvé'),
            );
          }

          final colis = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatutCard(livraison),
                const SizedBox(height: 16),
                _buildDestinataireCard(colis),
                const SizedBox(height: 16),
                _buildColisDetailsCard(colis),
                const SizedBox(height: 16),
                _buildTourneeCard(livraison),
                const SizedBox(height: 24),
                _buildActionButtons(livraison, colis),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatutCard(LivraisonModel livraison) {
    final statutColor = _getStatutColor(livraison.statut);
    final statutIcon = _getStatutIcon(livraison.statut);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statutIcon, color: statutColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatutLabel(livraison.statut),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statutColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Livraison #${livraison.id.substring(0, 8)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinataireCard(ColisModel colis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Text(
                  'Destinataire',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person_outline, 'Nom', colis.destinataireNom),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Téléphone', colis.destinataireTelephone),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.location_on,
              'Adresse',
              '${colis.destinataireAdresse}\n${colis.destinataireVille}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColisDetailsCard(ColisModel colis) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Text(
                  'Détails du colis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.qr_code, 'N° Suivi', colis.numeroSuivi),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.category, 'Contenu', colis.contenu),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.scale, 'Poids', '${colis.poids} kg'),
            if (colis.dimensions != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.straighten,
                'Dimensions',
                colis.dimensions!,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.attach_money,
              'Tarif',
              '${colis.montantTarif.toStringAsFixed(0)} FCFA',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourneeCard(LivraisonModel livraison) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                const Text(
                  'Informations de tournée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Date création',
              DateFormat('dd/MM/yyyy à HH:mm').format(livraison.dateCreation),
            ),
            if (livraison.paiementALaLivraison) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paiement à la livraison',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Montant à collecter: ${livraison.montantACollecte?.toStringAsFixed(0) ?? "0"} FCFA',
                          ),
                          if (livraison.paiementCollecte) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Collecté le ${DateFormat('dd/MM/yyyy à HH:mm').format(livraison.datePaiementCollecte!)}',
                                  style: const TextStyle(color: Colors.green, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (livraison.heureDepart != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.play_arrow,
                'Heure départ',
                DateFormat('HH:mm').format(livraison.heureDepart!),
              ),
            ],
            if (livraison.heureRetour != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.stop,
                'Heure retour',
                DateFormat('HH:mm').format(livraison.heureRetour!),
              ),
            ],
            if (livraison.motifEchec != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.error_outline,
                'Motif échec',
                livraison.motifEchec!,
              ),
            ],
            if (livraison.commentaire != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.comment,
                'Commentaire',
                livraison.commentaire!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(LivraisonModel livraison, ColisModel colis) {
    if (livraison.statut == 'enAttente') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _demarrerTournee(livraison),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Démarrer la tournée'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
      );
    } else if (livraison.statut == 'enCours') {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showConfirmerLivraisonDialog(livraison, colis),
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirmer la livraison'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showDeclarerEchecDialog(livraison, colis),
              icon: const Icon(Icons.error_outline),
              label: const Text('Déclarer un échec'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _demarrerTournee(LivraisonModel livraison) {
    Get.dialog(
      AlertDialog(
        title: const Text('Démarrer la tournée'),
        content: const Text(
          'Confirmez-vous le départ pour cette livraison ?\n\n'
          'L\'heure de départ sera enregistrée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await livraisonController.demarrerTournee(livraison.id);
              Get.back(); // Retour à la liste
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showConfirmerLivraisonDialog(LivraisonModel livraison, ColisModel colis) {
    final montantController = TextEditingController();
    bool paiementCollecte = false;

    // Pré-remplir le montant si c'est un paiement à la livraison
    if (livraison.paiementALaLivraison && livraison.montantACollecte != null) {
      montantController.text = livraison.montantACollecte!.toStringAsFixed(0);
      paiementCollecte = true;
    }

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Confirmer la livraison'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('La livraison a-t-elle été effectuée avec succès ?'),
                  const SizedBox(height: 16),

                  // Section paiement à la livraison
                  if (livraison.paiementALaLivraison) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.attach_money, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text(
                                'Paiement à la livraison',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            title: const Text('Paiement collecté'),
                            subtitle: Text(
                              'Montant: ${livraison.montantACollecte?.toStringAsFixed(0) ?? "0"} FCFA',
                            ),
                            value: paiementCollecte,
                            onChanged: (value) {
                              setState(() => paiementCollecte = value ?? false);
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (paiementCollecte) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: montantController,
                              decoration: const InputDecoration(
                                labelText: 'Montant collecté (FCFA)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (preuveImage != null) ...[
                    const Text(
                      'Preuve de livraison :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Image.file(
                      preuveImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton.icon(
                    onPressed: () async {
                      // await _pickPreuveImage();
                      setState(() {});
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(preuveImage == null ? 'Ajouter une photo/signature (optionnel)' : 'Changer la photo'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  this.setState(() => preuveImage = null);
                  montantController.dispose();
                  Get.back();
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validation du paiement si requis
                  if (livraison.paiementALaLivraison && paiementCollecte) {
                    final montant = double.tryParse(montantController.text);
                    if (montant == null || montant <= 0) {
                      Get.snackbar(
                        'Erreur',
                        'Veuillez saisir un montant valide',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }
                  }

                  Get.back();

                  // Confirmer la livraison avec paiement
                  await livraisonController.confirmerLivraison(
                    livraisonId: livraison.id,
                    colisId: colis.id,
                    preuveUrl: preuveImage?.path,
                    paiementCollecte: paiementCollecte,
                    montantCollecte: paiementCollecte ? double.tryParse(montantController.text) : null,
                  );

                  this.setState(() => preuveImage = null);
                  montantController.dispose();
                  Get.back(); // Retour à la liste
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeclarerEchecDialog(LivraisonModel livraison, ColisModel colis) {
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Déclarer un échec'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sélectionnez le motif de l\'échec :'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedMotif,
                    decoration: const InputDecoration(
                      labelText: 'Motif',
                      border: OutlineInputBorder(),
                    ),
                    items: motifsEchec.map((motif) {
                      return DropdownMenuItem(
                        value: motif,
                        child: Text(motif),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedMotif = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentaireController,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (echecImage != null) ...[
                    const Text(
                      'Photo justificative :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Image.file(
                      echecImage!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton.icon(
                    onPressed: () async {
                      // await _pickEchecImage();
                      setState(() {});
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(echecImage == null ? 'Ajouter une photo (optionnel)' : 'Changer la photo'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  selectedMotif = null;
                  commentaireController.clear();
                  this.setState(() => echecImage = null);
                  Get.back();
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: selectedMotif == null
                    ? null
                    : () async {
                        Get.back();
                        // TODO: Upload image to Firebase Storage if echecImage != null
                        await livraisonController.declarerEchec(
                          livraisonId: livraison.id,
                          colisId: colis.id,
                          motifEchec: selectedMotif!,
                          commentaire: commentaireController.text.isEmpty ? null : commentaireController.text,
                          photoUrl: echecImage?.path, // Temporary, should be Firebase URL
                        );
                        selectedMotif = null;
                        commentaireController.clear();
                        this.setState(() => echecImage = null);
                        Get.back(); // Retour à la liste
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Future<void> _pickPreuveImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.camera);

  //   if (image != null) {
  //     setState(() {
  //       preuveImage = File(image.path);
  //     });
  //   }
  // }

  // Future<void> _pickEchecImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.camera);

  //   if (image != null) {
  //     setState(() {
  //       echecImage = File(image.path);
  //     });
  //   }
  // }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'enAttente':
        return Colors.orange;
      case 'enCours':
        return Colors.blue;
      case 'livree':
        return Colors.green;
      case 'echec':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'enAttente':
        return Icons.schedule;
      case 'enCours':
        return Icons.local_shipping;
      case 'livree':
        return Icons.check_circle;
      case 'echec':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'enAttente':
        return 'En attente';
      case 'enCours':
        return 'En cours';
      case 'livree':
        return 'Livrée';
      case 'echec':
        return 'Échec';
      default:
        return statut;
    }
  }
}
