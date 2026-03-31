import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/suivi_controller.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:corex_shared/models/agence_model.dart';
import 'package:corex_shared/models/transaction_model.dart';
import 'package:corex_shared/services/agence_service.dart';
import 'package:corex_shared/services/colis_service.dart';
import 'package:corex_shared/services/transaction_service.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/services/ticket_print_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class DetailsColisScreen extends StatelessWidget {
  const DetailsColisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SuiviController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Colis'),
        actions: [
          // Bouton imprimer le reçu
          Obx(() {
            final colis = controller.selectedColis.value;
            if (colis == null) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Imprimer le reçu',
              onPressed: () => _imprimerRecu(colis),
            );
          }),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showUpdateStatutDialog(context, controller),
            tooltip: 'Modifier le statut',
          ),
        ],
      ),
      body: Obx(() {
        final colis = controller.selectedColis.value;

        if (colis == null) {
          return const Center(child: Text('Aucun colis sélectionné'));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(colis, controller),
              _buildInfoSection(colis, context, controller),
              _buildHistorique(colis, controller),
              // Bouton Enregistrer visible uniquement si statut == collecte
              if (colis.statut == 'collecte')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading.value ? null : () => _showEnregistrerDialog(context, controller, colis),
                      icon: controller.isLoading.value
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: const Text('ENREGISTRER CE COLIS', style: TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(ColisModel colis, SuiviController controller) {
    final statutColor = Color(int.parse(controller.getStatutColor(colis.statut).replaceFirst('#', '0xFF')));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statutColor, statutColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            colis.numeroSuivi,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              controller.getStatutLabel(colis.statut),
              style: TextStyle(
                color: statutColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ColisModel colis, BuildContext context, SuiviController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Expéditeur',
            icon: Icons.person_outline,
            children: [
              _buildInfoRow('Nom', colis.expediteurNom),
              _buildInfoRow('Téléphone', colis.expediteurTelephone),
              _buildInfoRow('Adresse', colis.expediteurAdresse),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Destinataire',
            icon: Icons.person,
            children: [
              _buildInfoRow('Nom', colis.destinataireNom),
              _buildInfoRow('Téléphone', colis.destinataireTelephone),
              _buildInfoRow('Adresse', colis.destinataireAdresse),
              _buildInfoRow('Ville', colis.destinataireVille),
              if (colis.destinataireQuartier != null) _buildInfoRow('Quartier', colis.destinataireQuartier!),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Détails du Colis',
            icon: Icons.inventory_2,
            children: [
              _buildInfoRow('Contenu', colis.contenu),
              if (colis.poids != null) _buildInfoRow('Poids', '${colis.poids} kg'),
              if (colis.valeurDeclaree != null) _buildInfoRow('Valeur déclarée', '${colis.valeurDeclaree!.toStringAsFixed(0)} FCFA'),
              if (colis.dimensions != null) _buildInfoRow('Dimensions', colis.dimensions!),
              _buildInfoRow('Mode de livraison', colis.modeLivraison),
              if (colis.agenceTransportNom != null) _buildInfoRow('Agence transport', colis.agenceTransportNom!),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Informations Financières',
            icon: Icons.payments,
            titleAction: TextButton.icon(
              onPressed: () => _showModifierFraisDialog(colis, controller),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF4CAF50)),
            ),
            children: [
              if (colis.fraisLivraison > 0) _buildInfoRow('Frais de livraison', '${colis.fraisLivraison.toStringAsFixed(0)} FCFA'),
              if (colis.fraisCollecte > 0) _buildInfoRow('Frais de collecte', '${colis.fraisCollecte.toStringAsFixed(0)} FCFA'),
              if (colis.commissionVente > 0) _buildInfoRow('Commission vente', '${colis.commissionVente.toStringAsFixed(0)} FCFA'),
              _buildInfoRow('Total', '${colis.montantTarif.toStringAsFixed(0)} FCFA'),
              if (colis.montantDejaPaye > 0 && !colis.isPaye)
                _buildInfoRow('Déjà payé', '${colis.montantDejaPaye.toStringAsFixed(0)} FCFA', valueColor: Colors.green),
              if (!colis.isPaye && colis.resteAPayer > 0)
                _buildInfoRow('Reste à payer', '${colis.resteAPayer.toStringAsFixed(0)} FCFA', valueColor: Colors.red),
              _buildInfoRow(
                'Statut paiement',
                colis.isPaye ? 'Payé' : (colis.montantDejaPaye > 0 ? 'Partiellement payé' : 'Non payé'),
                valueColor: colis.isPaye ? Colors.green : Colors.red,
              ),
              if (colis.datePaiement != null)
                _buildInfoRow(
                  'Date de paiement',
                  DateFormat('dd/MM/yyyy à HH:mm').format(colis.datePaiement!),
                ),
              if (!colis.isPaye) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showPaymentDialog(context, colis, controller),
                    icon: const Icon(Icons.payment, color: Color(0xFF2E7D32)),
                    label: Text(
                      colis.montantDejaPaye > 0
                          ? 'Payer le reste (${colis.resteAPayer.toStringAsFixed(0)} FCFA)'
                          : 'Enregistrer le paiement',
                      style: const TextStyle(color: Color(0xFF2E7D32)),
                    ),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF2E7D32))),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Dates Importantes',
            icon: Icons.calendar_today,
            children: [
              _buildInfoRow(
                'Date de collecte',
                DateFormat('dd/MM/yyyy à HH:mm').format(colis.dateCollecte),
              ),
              if (colis.dateEnregistrement != null)
                _buildInfoRow(
                  'Date d\'enregistrement',
                  DateFormat('dd/MM/yyyy à HH:mm').format(colis.dateEnregistrement!),
                ),
              if (colis.dateLivraison != null)
                _buildInfoRow(
                  'Date de livraison',
                  DateFormat('dd/MM/yyyy à HH:mm').format(colis.dateLivraison!),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? titleAction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (titleAction != null) titleAction,
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorique(ColisModel colis, SuiviController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.history, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text(
                    'Historique des Statuts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (colis.historique.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Aucun historique disponible'),
                  ),
                )
              else
                ...colis.historique.asMap().entries.map((entry) {
                  final index = entry.key;
                  final historique = entry.value;
                  final isFirst = index == 0;
                  final isLast = index == colis.historique.length - 1;

                  return _buildTimelineItem(
                    historique: historique,
                    controller: controller,
                    isFirst: isFirst,
                    isLast: isLast,
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required HistoriqueStatut historique,
    required SuiviController controller,
    required bool isFirst,
    required bool isLast,
  }) {
    final statutColor = Color(int.parse(controller.getStatutColor(historique.statut).replaceFirst('#', '0xFF')));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: statutColor.withOpacity(0.3),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statutColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: statutColor.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.getStatutLabel(historique.statut),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statutColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy à HH:mm').format(historique.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (historique.commentaire != null && historique.commentaire!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      historique.commentaire!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showModifierFraisDialog(ColisModel colis, SuiviController controller) {
    final fraisLivraisonCtrl = TextEditingController(text: colis.fraisLivraison.toStringAsFixed(0));
    final fraisCollecteCtrl = TextEditingController(text: colis.fraisCollecte.toStringAsFixed(0));
    final commissionVenteCtrl = TextEditingController(text: colis.commissionVente.toStringAsFixed(0));

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
          Icon(Icons.edit, color: Color(0xFF4CAF50)),
          SizedBox(width: 8),
          Text('Modifier les frais'),
        ]),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (colis.isPaye)
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
                    Text('${calcTotal().toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4CAF50))),
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
                colis: colis,
                controller: controller,
                fraisLivraison: double.tryParse(fraisLivraisonCtrl.text) ?? 0,
                fraisCollecte: double.tryParse(fraisCollecteCtrl.text) ?? 0,
                commissionVente: double.tryParse(commissionVenteCtrl.text) ?? 0,
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Appliquer'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
          ),
        ],
      );
    }));
  }

  Future<void> _appliquerModificationFrais({
    required ColisModel colis,
    required SuiviController controller,
    required double fraisLivraison,
    required double fraisCollecte,
    required double commissionVente,
  }) async {
    try {
      if (!Get.isRegistered<ColisService>()) Get.put(ColisService(), permanent: true);
      final colisService = Get.find<ColisService>();
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value!;
      final nouveauTotal = fraisLivraison + fraisCollecte + commissionVente;

      await colisService.updateColis(colis.id, {
        'fraisLivraison': fraisLivraison,
        'fraisCollecte': fraisCollecte,
        'commissionVente': commissionVente,
        'montantTarif': nouveauTotal,
      });

      if (colis.isPaye) {
        final diff = nouveauTotal - colis.montantTarif;

        if (diff > 0) {
          // Montant augmenté → marquer comme non payé, conserver ce qui a déjà été payé
          await colisService.updateColis(colis.id, {
            'isPaye': false,
            'montantDejaPaye': colis.montantTarif, // l'ancien total était entièrement payé
          });
        } else if (diff < 0) {
          // Montant diminué → ajustement en caisse (remboursement de la partie COREX)
          final ancienCorex = colis.montantTarif - colis.fraisCollecte;
          final nouveauCorex = nouveauTotal - fraisCollecte;
          final diffCorex = nouveauCorex - ancienCorex;
          if (diffCorex < 0) {
            if (!Get.isRegistered<TransactionService>()) Get.put(TransactionService(), permanent: true);
            final transaction = TransactionModel(
              id: const Uuid().v4(),
              agenceId: user.agenceId ?? colis.agenceCorexId,
              type: 'depense',
              montant: diffCorex.abs(),
              date: DateTime.now(),
              categorieRecette: null,
              description: 'Ajustement frais colis ${colis.numeroSuivi} (${diffCorex.toStringAsFixed(0)} FCFA)',
              reference: colis.numeroSuivi,
              userId: user.id,
            );
            await Get.find<TransactionService>().createTransaction(transaction);
          }
        }
      }

      Get.snackbar('Succès', 'Frais mis à jour', backgroundColor: const Color(0xFF4CAF50), colorText: Colors.white);

      // Recharger et mettre à jour selectedColis pour rafraîchir l'affichage
      await controller.loadColis();
      final updated = controller.colisList.firstWhereOrNull((c) => c.id == colis.id);
      if (updated != null) controller.selectedColis.value = updated;
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de modifier les frais: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _imprimerRecu(ColisModel colis) async {
    try {
      final isAvailable = await TicketPrintService.isAvailable();
      if (!isAvailable) {
        Get.snackbar('Impression non disponible', 'L\'impression n\'est pas disponible sur cette plateforme', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      AgenceModel? agence;
      try {
        final authController = Get.find<AuthController>();
        final agenceId = authController.currentUser.value?.agenceId;
        if (agenceId != null) {
          if (!Get.isRegistered<AgenceService>()) Get.put(AgenceService(), permanent: true);
          agence = await Get.find<AgenceService>().getAgenceById(agenceId);
        }
      } catch (_) {}

      await TicketPrintService.printTicket(colis: colis, agence: agence);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'imprimer le reçu: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void _showEnregistrerDialog(BuildContext context, SuiviController controller, ColisModel colis) {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('Enregistrement du colis'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Colis: ${colis.numeroSuivi}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Que souhaitez-vous faire après l\'enregistrement ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Get.back();
              await controller.updateStatut(colis.id, 'enregistre', 'Colis enregistré');
              // Retour à la liste pour faire une nouvelle collecte
              Get.back();
            },
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Nouvelle collecte'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              await controller.updateStatut(colis.id, 'enregistre', 'Colis enregistré');
              // Rester sur la page détail (selectedColis sera mis à jour)
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, ColisModel colis, SuiviController controller) {
    final montantAPayer = colis.resteAPayer > 0 ? colis.resteAPayer : colis.montantTarif;
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payment, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Paiement du colis'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Numéro: ${colis.numeroSuivi}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Divider(),
            if (colis.fraisLivraison > 0) _buildPayRow('Frais de livraison', colis.fraisLivraison),
            if (colis.fraisCollecte > 0) _buildPayRow('Frais de collecte', colis.fraisCollecte),
            if (colis.commissionVente > 0) _buildPayRow('Commission vente', colis.commissionVente),
            const Divider(),
            _buildPayRow('Total', colis.montantTarif, bold: false),
            if (colis.montantDejaPaye > 0) ...[
              _buildPayRow('Déjà payé', colis.montantDejaPaye, color: Colors.green),
              _buildPayRow('Reste à payer', montantAPayer, bold: true, color: Colors.red),
            ] else
              _buildPayRow('Montant à encaisser', montantAPayer, bold: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton.icon(
            onPressed: () async {
              Get.back();
              await controller.payerColis(colis, montantOverride: montantAPayer);
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('Confirmer le paiement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayRow(String label, double montant, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: color)),
          Text('${montant.toStringAsFixed(0)} FCFA',
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color ?? (bold ? const Color(0xFF2E7D32) : null))),
        ],
      ),
    );
  }

  void _showUpdateStatutDialog(BuildContext context, SuiviController controller) {
    final colis = controller.selectedColis.value;
    if (colis == null) return;

    final commentaireController = TextEditingController();
    String? selectedStatut;

    // Obtenir les statuts valides pour la transition
    final validStatuts = _getValidStatuts(colis.statut);

    Get.dialog(
      AlertDialog(
        title: const Text('Modifier le Statut'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statut actuel: ${controller.getStatutLabel(colis.statut)}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Nouveau statut',
                  border: OutlineInputBorder(),
                ),
                items: validStatuts.map((statut) {
                  return DropdownMenuItem(
                    value: statut,
                    child: Text(controller.getStatutLabel(statut)),
                  );
                }).toList(),
                onChanged: (value) => selectedStatut = value,
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedStatut == null) {
                Get.snackbar('Erreur', 'Veuillez sélectionner un statut');
                return;
              }

              Get.back();
              await controller.updateStatut(
                colis.id,
                selectedStatut!,
                commentaireController.text.isEmpty ? null : commentaireController.text,
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  List<String> _getValidStatuts(String currentStatut) {
    final Map<String, List<String>> validTransitions = {
      'collecte': ['enregistre', 'annule'],
      'enregistre': ['enTransit', 'annule'],
      'enTransit': ['arriveDestination', 'retour'],
      'arriveDestination': ['enCoursLivraison', 'retire', 'retour'],
      'enCoursLivraison': ['livre', 'echec', 'retour'],
      'echec': ['enCoursLivraison', 'retour'],
      'livre': [],
      'retire': [],
      'retour': ['enTransit'],
      'annule': [],
    };

    return validTransitions[currentStatut] ?? [];
  }
}
