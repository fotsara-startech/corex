import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/devis_controller.dart';
import 'package:corex_shared/models/devis_model.dart';
import 'package:intl/intl.dart';
import 'devis_form_screen.dart';

class DevisDetailScreen extends StatelessWidget {
  final DevisModel devisInitial;

  const DevisDetailScreen({super.key, required DevisModel devis}) : devisInitial = devis;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DevisController>() ? Get.find<DevisController>() : Get.put(DevisController(), permanent: true);

    // Initialiser selectedDevis avec le devis passé en paramètre
    if (controller.selectedDevis.value?.id != devisInitial.id) {
      controller.selectedDevis.value = devisInitial;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(devisInitial.numeroDevis),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => controller.imprimerDevis(controller.selectedDevis.value ?? devisInitial),
            tooltip: 'Imprimer',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => controller.exporterDevis(controller.selectedDevis.value ?? devisInitial),
            tooltip: 'Exporter PDF',
          ),
        ],
      ),
      body: Obx(() {
        final devis = controller.selectedDevis.value ?? devisInitial;
        final fmt = NumberFormat('#,###');
        final statutColor = _statutColor(devis.statut);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statut
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statutColor),
                ),
                child: Row(
                  children: [
                    Icon(_statutIcon(devis.statut), color: statutColor, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_statutLabel(devis.statut), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statutColor)),
                        Text(devis.numeroDevis, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Infos client
              _buildCard('Client', Icons.person, [
                _InfoRow('Nom', devis.clientNom),
                if (devis.clientTelephone.isNotEmpty) _InfoRow('Téléphone', devis.clientTelephone),
                _InfoRow('Créé le', DateFormat('dd/MM/yyyy à HH:mm').format(devis.dateCreation)),
                if (devis.dateValidation != null) _InfoRow('Validé le', DateFormat('dd/MM/yyyy à HH:mm').format(devis.dateValidation!)),
                if (devis.factureId != null) _InfoRow('Facture', devis.factureId!),
              ]),
              const SizedBox(height: 16),

              // Lignes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.list_alt, color: Color(0xFF2E7D32)),
                          SizedBox(width: 8),
                          Text('Lignes du devis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        color: Colors.grey.shade100,
                        child: const Row(
                          children: [
                            Expanded(flex: 4, child: Text('Désignation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            SizedBox(width: 8),
                            SizedBox(width: 60, child: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            SizedBox(width: 8),
                            SizedBox(width: 110, child: Text('Prix unit.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            SizedBox(width: 8),
                            SizedBox(width: 110, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                      ),
                      ...devis.lignes.map((l) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              children: [
                                Expanded(flex: 4, child: Text(l.designation)),
                                const SizedBox(width: 8),
                                SizedBox(width: 60, child: Text(l.quantite.toStringAsFixed(0))),
                                const SizedBox(width: 8),
                                SizedBox(width: 110, child: Text('${fmt.format(l.prixUnitaire)} FCFA')),
                                const SizedBox(width: 8),
                                SizedBox(width: 110, child: Text('${fmt.format(l.total)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                          )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('TOTAL : ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${fmt.format(devis.montantTotal)} FCFA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (devis.notes != null && devis.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildCard('Notes', Icons.notes, [_InfoRow('', devis.notes!)]),
              ],

              const SizedBox(height: 24),
              _buildActions(context, devis, controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActions(BuildContext context, DevisModel devis, DevisController controller) {
    return Column(
      children: [
        if (devis.canEdit) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.to(() => DevisFormScreen(devis: devis)),
              icon: const Icon(Icons.edit),
              label: const Text('MODIFIER'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (devis.canValider) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmerValidation(context, devis, controller),
              icon: const Icon(Icons.check_circle),
              label: const Text('VALIDER CE DEVIS'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (devis.canConvertir) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmerConversion(context, devis, controller),
              icon: const Icon(Icons.transform),
              label: const Text('CONVERTIR EN FACTURE'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (devis.canDelete) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmerSuppression(context, devis, controller),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('SUPPRIMER', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ],
    );
  }

  void _confirmerValidation(BuildContext context, DevisModel devis, DevisController controller) {
    Get.dialog(AlertDialog(
      title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Valider le devis')]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Devis: ${devis.numeroDevis}'),
          const SizedBox(height: 4),
          Text('Montant: ${NumberFormat('#,###').format(devis.montantTotal)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.green, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Une transaction sera créée en caisse.', style: TextStyle(fontSize: 12))),
            ]),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final ok = await controller.validerDevis(devis);
            if (ok) Get.back();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('Valider'),
        ),
      ],
    ));
  }

  void _confirmerConversion(BuildContext context, DevisModel devis, DevisController controller) {
    Get.dialog(AlertDialog(
      title: const Row(children: [Icon(Icons.transform, color: Colors.blue), SizedBox(width: 8), Text('Convertir en facture')]),
      content: Text('Convertir le devis ${devis.numeroDevis} en facture ?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final ok = await controller.convertirEnFacture(devis);
            if (ok) Get.back();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          child: const Text('Convertir'),
        ),
      ],
    ));
  }

  void _confirmerSuppression(BuildContext context, DevisModel devis, DevisController controller) {
    Get.dialog(AlertDialog(
      title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('Supprimer le devis')]),
      content: Text('Supprimer définitivement le devis ${devis.numeroDevis} ?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            final ok = await controller.deleteDevis(devis);
            if (ok) Get.back();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          child: const Text('Supprimer'),
        ),
      ],
    ));
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: const Color(0xFF2E7D32)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'valide':
        return Colors.green;
      case 'converti':
        return Colors.blue;
      case 'refuse':
        return Colors.red;
      case 'envoye':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _statutIcon(String statut) {
    switch (statut) {
      case 'valide':
        return Icons.check_circle;
      case 'converti':
        return Icons.transform;
      case 'refuse':
        return Icons.cancel;
      case 'envoye':
        return Icons.send;
      default:
        return Icons.edit_note;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'brouillon':
        return 'Brouillon';
      case 'envoye':
        return 'Envoyé';
      case 'valide':
        return 'Validé';
      case 'refuse':
        return 'Refusé';
      case 'converti':
        return 'Converti en facture';
      default:
        return statut;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500))),
          ],
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
