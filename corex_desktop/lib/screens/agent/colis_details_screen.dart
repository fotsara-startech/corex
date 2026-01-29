import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/colis_controller.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:corex_shared/models/agence_model.dart';
import 'package:corex_shared/models/transaction_model.dart';
import 'package:corex_shared/services/agence_service.dart';
import 'package:corex_shared/services/transaction_service.dart';
import 'package:uuid/uuid.dart';
import '../../theme/corex_theme.dart';
import 'package:corex_shared/services/colis_service.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:intl/intl.dart';
import 'package:corex_shared/services/ticket_service_optimized.dart';

class ColisDetailsScreen extends StatefulWidget {
  final ColisModel colis;

  const ColisDetailsScreen({super.key, required this.colis});

  @override
  State<ColisDetailsScreen> createState() => _ColisDetailsScreenState();
}

class _ColisDetailsScreenState extends State<ColisDetailsScreen> {
  final _isProcessing = false.obs;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Colis'),
        backgroundColor: CorexTheme.primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statut actuel
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Informations expéditeur
            _buildSectionCard(
              'Expéditeur',
              Icons.person,
              [
                _buildInfoRow('Nom', widget.colis.expediteurNom),
                _buildInfoRow('Téléphone', widget.colis.expediteurTelephone),
                _buildInfoRow('Adresse', widget.colis.expediteurAdresse),
              ],
            ),
            const SizedBox(height: 16),

            // Informations destinataire
            _buildSectionCard(
              'Destinataire',
              Icons.location_on,
              [
                _buildInfoRow('Nom', widget.colis.destinataireNom),
                _buildInfoRow('Téléphone', widget.colis.destinataireTelephone),
                _buildInfoRow('Ville', widget.colis.destinataireVille),
                _buildInfoRow('Adresse', widget.colis.destinataireAdresse),
                if (widget.colis.destinataireQuartier != null) _buildInfoRow('Quartier', widget.colis.destinataireQuartier!),
              ],
            ),
            const SizedBox(height: 16),

            // Détails du colis
            _buildSectionCard(
              'Détails du Colis',
              Icons.inventory_2,
              [
                _buildInfoRow('Contenu', widget.colis.contenu),
                _buildInfoRow('Poids', '${widget.colis.poids} kg'),
                if (widget.colis.dimensions != null) _buildInfoRow('Dimensions', widget.colis.dimensions!),
                _buildInfoRow('Mode de livraison', _getModeLivraisonLabel()),
                if (widget.colis.agenceTransportNom != null) _buildInfoRow('Agence transport', widget.colis.agenceTransportNom!),
              ],
            ),
            const SizedBox(height: 16),

            // Informations financières
            _buildSectionCard(
              'Informations Financières',
              Icons.payments,
              [
                _buildInfoRow('Tarif', '${widget.colis.montantTarif} FCFA', bold: true),
                _buildInfoRow('Statut paiement', widget.colis.isPaye ? 'Payé' : 'Non payé'),
                if (widget.colis.datePaiement != null) _buildInfoRow('Date paiement', dateFormat.format(widget.colis.datePaiement!)),
              ],
            ),
            const SizedBox(height: 16),

            // Dates importantes
            _buildSectionCard(
              'Dates',
              Icons.calendar_today,
              [
                _buildInfoRow('Date de collecte', dateFormat.format(widget.colis.dateCollecte)),
                if (widget.colis.dateEnregistrement != null) _buildInfoRow('Date d\'enregistrement', dateFormat.format(widget.colis.dateEnregistrement!)),
              ],
            ),
            const SizedBox(height: 24),

            // Boutons d'action
            if (widget.colis.statut == 'collecte') Obx(() => _buildActionButtons()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusLabel;

    switch (widget.colis.statut) {
      case 'collecte':
        statusColor = Colors.orange;
        statusLabel = 'EN ATTENTE D\'ENREGISTREMENT';
        break;
      case 'enregistre':
        statusColor = CorexTheme.primaryGreen;
        statusLabel = 'ENREGISTRÉ';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = widget.colis.statut.toUpperCase();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Column(
        children: [
          Icon(
            widget.colis.statut == 'collecte' ? Icons.pending_actions : Icons.check_circle,
            color: statusColor,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (widget.colis.numeroSuivi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'N° ${widget.colis.numeroSuivi}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: CorexTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing.value ? null : _enregistrerColis,
            icon: _isProcessing.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.app_registration),
            label: Text(_isProcessing.value ? 'ENREGISTREMENT...' : 'ENREGISTRER ET IMPRIMER LE REÇU'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CorexTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('RETOUR'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: CorexTheme.primaryGreen),
          ),
        ),
      ],
    );
  }

  String _getModeLivraisonLabel() {
    switch (widget.colis.modeLivraison) {
      case 'domicile':
        return 'Livraison à domicile';
      case 'bureau':
        return 'Retrait au bureau';
      case 'agence_transport':
        return 'Agence de transport';
      default:
        return widget.colis.modeLivraison;
    }
  }

  Future<void> _enregistrerColis() async {
    _isProcessing.value = true;

    try {
      final colisService = Get.find<ColisService>();
      final authController = Get.find<AuthController>();
      final colisController = Get.find<ColisController>();

      // 1. Générer le numéro de suivi
      final numeroSuivi = await colisService.generateNumeroSuivi();

      // 2. Mettre à jour le statut du colis
      await colisService.updateStatut(
        widget.colis.id,
        'enregistre',
        authController.currentUser.value!.id,
        'Colis enregistré avec le numéro $numeroSuivi',
      );

      // 3. Mettre à jour le numéro de suivi
      await colisService.updateColis(widget.colis.id, {
        'numeroSuivi': numeroSuivi,
      });

      // 4. Créer la transaction financière si le colis est payé
      if (widget.colis.isPaye) {
        print('💰 [ENREGISTREMENT] Création de la transaction financière');
        final transactionService = Get.find<TransactionService>();
        final user = authController.currentUser.value!;

        final transaction = TransactionModel(
          id: const Uuid().v4(),
          agenceId: user.agenceId!,
          type: 'recette',
          montant: widget.colis.montantTarif,
          date: DateTime.now(),
          categorieRecette: 'expedition',
          description: 'Enregistrement colis $numeroSuivi - ${widget.colis.destinataireNom}',
          reference: numeroSuivi,
          userId: user.id,
        );

        try {
          await transactionService.createTransaction(transaction);
          print('✅ [ENREGISTREMENT] Transaction créée avec succès');
        } catch (e) {
          print('❌ [ENREGISTREMENT] Erreur création transaction: $e');
          // On continue même si la transaction échoue
        }
      }

      // 5. Recharger les données
      await colisController.loadColis();

      // 6. Récupérer le colis mis à jour
      final colisUpdated = await colisService.getColisById(widget.colis.id);

      if (colisUpdated != null) {
        // 7. Proposer l'impression du ticket
        await _proposerImpressionTicket(colisUpdated);
      }

      // 8. Afficher le message de succès
      Get.snackbar(
        'Succès',
        'Colis enregistré avec succès\nNuméro de suivi: $numeroSuivi',
        backgroundColor: CorexTheme.primaryGreen,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      // 9. Retourner à l'écran précédent
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'enregistrer le colis: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> _proposerImpressionTicket(ColisModel colis) async {
    // Afficher une boîte de dialogue pour proposer l'impression
    final result = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Impression du reçu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: CorexTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Comment souhaitez-vous obtenir le reçu du colis ?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'N° ${colis.numeroSuivi}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: CorexTheme.primaryGreen,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: 'skip'),
            child: const Text('Plus tard'),
          ),
          ElevatedButton.icon(
            onPressed: () => Get.back(result: 'download'),
            icon: const Icon(Icons.download),
            label: const Text('Télécharger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Get.back(result: 'print'),
            icon: const Icon(Icons.print),
            label: const Text('Imprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CorexTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result == 'print') {
      try {
        // Récupérer les informations de l'agence actuelle
        final authController = Get.find<AuthController>();
        final agenceId = authController.currentUser.value?.agenceId;

        AgenceModel? agence;
        if (agenceId != null) {
          try {
            final agenceService = Get.find<AgenceService>();
            agence = await agenceService.getAgenceById(agenceId);
          } catch (e) {
            print('⚠️ [TICKET] Impossible de récupérer l\'agence: $e');
          }
        }

        // Générer et imprimer le ticket optimisé
        await TicketServiceOptimized.generateAndPrintTicket(
          colis: colis,
          agence: agence,
        );

        Get.snackbar(
          'Ticket généré',
          'Ticket téléchargé et envoyé à l\'impression',
          backgroundColor: CorexTheme.primaryGreen,
          colorText: Colors.white,
          icon: const Icon(Icons.print, color: Colors.white),
        );
      } catch (e) {
        Get.snackbar(
          'Erreur génération ticket',
          'Erreur: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    } else if (result == 'download') {
      try {
        // Récupérer les informations de l'agence actuelle
        final authController = Get.find<AuthController>();
        final agenceId = authController.currentUser.value?.agenceId;

        AgenceModel? agence;
        if (agenceId != null) {
          try {
            final agenceService = Get.find<AgenceService>();
            agence = await agenceService.getAgenceById(agenceId);
          } catch (e) {
            print('⚠️ [TICKET] Impossible de récupérer l\'agence: $e');
          }
        }

        // Télécharger uniquement le ticket
        await TicketServiceOptimized.downloadTicketOnly(
          colis: colis,
          agence: agence,
        );

        Get.snackbar(
          'Téléchargement lancé',
          'Le reçu a été téléchargé',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          icon: const Icon(Icons.download, color: Colors.white),
        );
      } catch (e) {
        Get.snackbar(
          'Erreur de téléchargement',
          'Impossible de télécharger le reçu: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.error, color: Colors.white),
        );
      }
    }
  }
}
