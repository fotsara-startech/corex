import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:corex_shared/services/ticket_print_service.dart';
import 'enregistrement_colis_screen.dart';

class ColisDetailsScreen extends StatefulWidget {
  final ColisModel colis;

  const ColisDetailsScreen({super.key, required this.colis});

  @override
  State<ColisDetailsScreen> createState() => _ColisDetailsScreenState();
}

class _ColisDetailsScreenState extends State<ColisDetailsScreen> {
  final _isProcessing = false.obs;
  final _isPaye = false.obs;
  final _imprimerRecu = true.obs; // Option d'impression (activée par défaut)

  @override
  void initState() {
    super.initState();
    // Initialiser le statut de paiement avec la valeur actuelle du colis
    _isPaye.value = widget.colis.isPaye;
  }

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
                if (widget.colis.poids != null) _buildInfoRow('Poids', '${widget.colis.poids} kg'),
                if (widget.colis.valeurDeclaree != null) _buildInfoRow('Valeur déclarée', '${widget.colis.valeurDeclaree!.toStringAsFixed(0)} FCFA'),
                if (widget.colis.dimensions != null) _buildInfoRow('Dimensions', widget.colis.dimensions!),
                _buildInfoRow('Mode de livraison', _getModeLivraisonLabel()),
                if (widget.colis.agenceTransportNom != null) _buildInfoRow('Agence transport', widget.colis.agenceTransportNom!),
              ],
            ),
            const SizedBox(height: 16),

            // Informations financières avec option de paiement
            _buildPaymentSectionCard(),
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
            if (widget.colis.statut == 'collecte') _buildActionButtons(),
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

  Widget _buildPaymentSectionCard() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments, color: CorexTheme.primaryGreen),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Informations Financières',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showModifierFraisDialog(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: CorexTheme.primaryGreen),
                ),
              ],
            ),
            const Divider(height: 24),

            // Détail éclaté des frais
            if (widget.colis.fraisLivraison > 0) _buildFraisRow('Frais de livraison', widget.colis.fraisLivraison, Colors.green.shade700, isCorex: true),
            if (widget.colis.fraisCollecte > 0) _buildFraisRow('Montant collecté (vendeur)', widget.colis.fraisCollecte, Colors.orange.shade700, isCorex: false),
            if (widget.colis.commissionVente > 0) _buildFraisRow('Commission vente', widget.colis.commissionVente, Colors.purple.shade700, isCorex: true),
            const Divider(height: 16),
            _buildFraisRow('Total à encaisser', widget.colis.montantTarif, Colors.black87, bold: true),

            // Section paiement interactive pour les colis non payés
            if (widget.colis.statut == 'collecte') ...[
              const SizedBox(height: 16),
              Obx(() => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isPaye.value ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isPaye.value ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isPaye.value ? Icons.check_circle : Icons.payment,
                              color: _isPaye.value ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Paiement lors de l\'enregistrement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isPaye.value ? Colors.green.shade900 : Colors.orange.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _isPaye.value ? 'Colis payé' : 'Colis non payé',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            _isPaye.value ? 'Une transaction financière sera créée automatiquement' : 'Le paiement pourra être enregistré plus tard',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: _isPaye.value,
                          activeColor: Colors.green,
                          onChanged: (value) {
                            _isPaye.value = value;
                          },
                        ),
                        if (_isPaye.value) ...[
                          const Divider(),
                          if (widget.colis.fraisCollecte > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Le montant collecté (${widget.colis.fraisCollecte.toStringAsFixed(0)} FCFA) est à reverser au vendeur — il ne sera PAS enregistré en caisse COREX.',
                                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.store, size: 16, color: Colors.green.shade700),
                                    const SizedBox(width: 8),
                                    Text('Recette COREX:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                                  ],
                                ),
                                Text(
                                  '${(widget.colis.montantTarif - widget.colis.fraisCollecte).toStringAsFixed(0)} FCFA',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),
            ] else ...[
              _buildInfoRow('Statut paiement', widget.colis.isPaye ? 'Payé' : 'Non payé'),
              if (widget.colis.datePaiement != null) _buildInfoRow('Date paiement', dateFormat.format(widget.colis.datePaiement!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Checkbox pour l'impression du reçu
        Obx(() => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    Icon(
                      _imprimerRecu.value ? Icons.print : Icons.print_disabled,
                      color: _imprimerRecu.value ? CorexTheme.primaryGreen : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Imprimer le reçu après enregistrement',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  _imprimerRecu.value ? 'Le reçu sera imprimé automatiquement' : 'Vous pourrez imprimer le reçu plus tard',
                  style: const TextStyle(fontSize: 12),
                ),
                value: _imprimerRecu.value,
                activeColor: CorexTheme.primaryGreen,
                onChanged: (value) {
                  _imprimerRecu.value = value ?? true;
                },
              ),
            )),
        const SizedBox(height: 16),
        Obx(() => SizedBox(
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
                label: Text(
                  _isProcessing.value
                      ? 'ENREGISTREMENT...'
                      : _imprimerRecu.value
                          ? 'ENREGISTRER ET IMPRIMER LE REÇU'
                          : 'ENREGISTRER LE COLIS',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CorexTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            )),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('RETOUR'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: CorexTheme.primaryGreen),
            ),
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

  Widget _buildFraisRow(String label, double montant, Color color, {bool bold = false, bool isCorex = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
              if (!isCorex) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('à reverser', style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.w500)),
                ),
              ],
            ],
          ),
          Text('${montant.toStringAsFixed(0)} FCFA', style: TextStyle(fontSize: 13, color: color, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _enregistrerColis() async {
    _isProcessing.value = true;

    try {
      final colisService = Get.find<ColisService>();
      final authController = Get.find<AuthController>();

      // Initialiser ColisController s'il n'est pas encore enregistré
      if (!Get.isRegistered<ColisController>()) {
        Get.put(ColisController(), permanent: true);
      }
      final colisController = Get.find<ColisController>();

      // 1. Générer le numéro de suivi
      final numeroSuivi = await colisService.generateNumeroSuivi();

      // 2. Mettre à jour le statut du colis et le paiement
      await colisService.updateStatut(
        widget.colis.id,
        'enregistre',
        authController.currentUser.value!.id,
        'Colis enregistré avec le numéro $numeroSuivi',
      );

      // 3. Mettre à jour le numéro de suivi et le statut de paiement
      final updateData = {
        'numeroSuivi': numeroSuivi,
        'isPaye': _isPaye.value,
        'datePaiement': _isPaye.value ? Timestamp.fromDate(DateTime.now()) : null,
      };

      await colisService.updateColis(widget.colis.id, updateData);

      // 4. Créer la transaction financière si le colis est payé
      if (_isPaye.value) {
        print('💰 [ENREGISTREMENT] Création de la transaction financière');

        // Vérifier et initialiser le TransactionService si nécessaire
        if (!Get.isRegistered<TransactionService>()) {
          print('⚠️ [ENREGISTREMENT] TransactionService non trouvé, initialisation...');
          Get.put(TransactionService(), permanent: true);
        }

        final transactionService = Get.find<TransactionService>();
        final user = authController.currentUser.value!;

        final transaction = TransactionModel(
          id: const Uuid().v4(),
          agenceId: user.agenceId!,
          type: 'recette',
          montant: widget.colis.montantTarif - widget.colis.fraisCollecte,
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

      if (colisUpdated != null && _imprimerRecu.value) {
        // 7. Imprimer le ticket seulement si l'option est activée
        await _imprimerTicketAvecSelection(colisUpdated);
      }

      // 8. Afficher le message de succès
      String message;
      if (_isPaye.value && _imprimerRecu.value) {
        message = 'Colis enregistré et paiement encaissé\nNuméro de suivi: $numeroSuivi\nTicket prêt pour impression';
      } else if (_isPaye.value) {
        message = 'Colis enregistré et paiement encaissé\nNuméro de suivi: $numeroSuivi';
      } else if (_imprimerRecu.value) {
        message = 'Colis enregistré avec succès\nNuméro de suivi: $numeroSuivi\nTicket prêt pour impression';
      } else {
        message = 'Colis enregistré avec succès\nNuméro de suivi: $numeroSuivi';
      }

      Get.snackbar(
        'Succès',
        message,
        backgroundColor: CorexTheme.primaryGreen,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      // 9. Recharger la liste et retourner à l'écran d'enregistrement
      Get.off(() => const EnregistrementColisScreen());
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

  Future<void> _imprimerTicketAvecSelection(ColisModel colis) async {
    try {
      // Vérifier si l'impression est disponible
      final isAvailable = await TicketPrintService.isAvailable();
      if (!isAvailable) {
        Get.snackbar(
          'Impression non disponible',
          'L\'impression n\'est pas disponible sur cette plateforme',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          icon: const Icon(Icons.warning, color: Colors.white),
        );
        return;
      }

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

      // Ouvrir le dialogue d'impression avec sélection d'imprimante
      await TicketPrintService.printTicket(
        colis: colis,
        agence: agence,
      );

      print('✅ [TICKET] Dialogue d\'impression ouvert avec sélection d\'imprimante');
    } catch (e) {
      print('❌ [TICKET] Erreur impression avec sélection: $e');
      Get.snackbar(
        'Erreur d\'impression',
        'Impossible d\'ouvrir le dialogue d\'impression: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }

  void _showModifierFraisDialog() {
    final fraisLivraisonCtrl = TextEditingController(text: widget.colis.fraisLivraison.toStringAsFixed(0));
    final fraisCollecteCtrl = TextEditingController(text: widget.colis.fraisCollecte.toStringAsFixed(0));
    final commissionVenteCtrl = TextEditingController(text: widget.colis.commissionVente.toStringAsFixed(0));

    double calcTotal() => (double.tryParse(fraisLivraisonCtrl.text) ?? 0) + (double.tryParse(fraisCollecteCtrl.text) ?? 0) + (double.tryParse(commissionVenteCtrl.text) ?? 0);

    Get.dialog(StatefulBuilder(builder: (ctx, setDialogState) {
      void recalc() => setDialogState(() {});

      fraisLivraisonCtrl.removeListener(recalc);
      fraisCollecteCtrl.removeListener(recalc);
      commissionVenteCtrl.removeListener(recalc);
      fraisLivraisonCtrl.addListener(recalc);
      fraisCollecteCtrl.addListener(recalc);
      commissionVenteCtrl.addListener(recalc);

      return AlertDialog(
        title: const Row(children: [
          Icon(Icons.edit, color: CorexTheme.primaryGreen),
          SizedBox(width: 8),
          Text('Modifier les frais'),
        ]),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.colis.isPaye)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      'Colis déjà payé. Une transaction d\'ajustement sera créée en caisse.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    )),
                  ]),
                ),
              TextField(
                controller: fraisLivraisonCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Frais de livraison (FCFA)',
                  prefixIcon: const Icon(Icons.local_shipping),
                  labelStyle: TextStyle(color: Colors.green.shade700),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fraisCollecteCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant collecté vendeur (FCFA)',
                  prefixIcon: const Icon(Icons.swap_horiz),
                  labelStyle: TextStyle(color: Colors.orange.shade700),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commissionVenteCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Commission vente (FCFA)',
                  prefixIcon: const Icon(Icons.percent),
                  labelStyle: TextStyle(color: Colors.purple.shade700),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nouveau total:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${calcTotal().toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: CorexTheme.primaryGreen)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              await _appliquerModificationFrais(
                fraisLivraison: double.tryParse(fraisLivraisonCtrl.text) ?? 0,
                fraisCollecte: double.tryParse(fraisCollecteCtrl.text) ?? 0,
                commissionVente: double.tryParse(commissionVenteCtrl.text) ?? 0,
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Appliquer'),
            style: ElevatedButton.styleFrom(backgroundColor: CorexTheme.primaryGreen, foregroundColor: Colors.white),
          ),
        ],
      );
    }));
  }

  Future<void> _appliquerModificationFrais({
    required double fraisLivraison,
    required double fraisCollecte,
    required double commissionVente,
  }) async {
    _isProcessing.value = true;
    try {
      final colisService = Get.find<ColisService>();
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value!;
      final nouveauTotal = fraisLivraison + fraisCollecte + commissionVente;

      await colisService.updateColis(widget.colis.id, {
        'fraisLivraison': fraisLivraison,
        'fraisCollecte': fraisCollecte,
        'commissionVente': commissionVente,
        'montantTarif': nouveauTotal,
      });

      // Si déjà payé, gérer selon la direction du changement
      if (widget.colis.isPaye) {
        final diff = nouveauTotal - widget.colis.montantTarif;

        if (diff > 0) {
          // Montant augmenté → marquer comme non payé (reste à payer)
          await colisService.updateColis(widget.colis.id, {
            'isPaye': false,
            'datePaiement': null,
          });
        } else if (diff < 0) {
          // Montant diminué → ajustement en caisse (remboursement)
          final ancienCorex = widget.colis.montantTarif - widget.colis.fraisCollecte;
          final nouveauCorex = nouveauTotal - fraisCollecte;
          final diffCorex = nouveauCorex - ancienCorex;
          if (diffCorex < 0) {
            if (!Get.isRegistered<TransactionService>()) {
              Get.put(TransactionService(), permanent: true);
            }
            final transaction = TransactionModel(
              id: const Uuid().v4(),
              agenceId: user.agenceId!,
              type: 'depense',
              montant: diffCorex.abs(),
              date: DateTime.now(),
              categorieRecette: null,
              description: 'Ajustement frais colis ${widget.colis.numeroSuivi} (${diffCorex.toStringAsFixed(0)} FCFA)',
              reference: widget.colis.numeroSuivi,
              userId: user.id,
            );
            await Get.find<TransactionService>().createTransaction(transaction);
          }
        }
      }

      Get.snackbar('Succès', 'Frais mis à jour avec succès', backgroundColor: CorexTheme.primaryGreen, colorText: Colors.white);

      // Recharger le colis et rafraîchir l'écran
      if (Get.isRegistered<ColisController>()) {
        await Get.find<ColisController>().loadColis();
      }
      final colisUpdated = await colisService.getColisById(widget.colis.id);
      _isProcessing.value = false;
      if (colisUpdated != null) {
        Get.off(() => ColisDetailsScreen(colis: colisUpdated));
      } else {
        Get.back();
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de modifier les frais: $e', backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      _isProcessing.value = false;
    }
  }
}
