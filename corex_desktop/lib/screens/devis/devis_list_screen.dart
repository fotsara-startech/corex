import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/devis_controller.dart';
import 'package:corex_shared/models/devis_model.dart';
import 'package:intl/intl.dart';
import 'devis_form_screen.dart';
import 'devis_detail_screen.dart';

class DevisListScreen extends StatelessWidget {
  const DevisListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<DevisController>() ? Get.find<DevisController>() : Get.put(DevisController(), permanent: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadDevis(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const DevisFormScreen()),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau devis'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: [
          // Filtres
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FiltreBtn(label: 'Tous', value: 'tous', selected: controller.selectedStatut.value, onTap: controller.setFiltreStatut),
                      const SizedBox(width: 8),
                      _FiltreBtn(label: 'Brouillon', value: 'brouillon', selected: controller.selectedStatut.value, onTap: controller.setFiltreStatut),
                      const SizedBox(width: 8),
                      _FiltreBtn(label: 'Envoye', value: 'envoye', selected: controller.selectedStatut.value, onTap: controller.setFiltreStatut),
                      const SizedBox(width: 8),
                      _FiltreBtn(label: 'Valide', value: 'valide', selected: controller.selectedStatut.value, onTap: controller.setFiltreStatut),
                      const SizedBox(width: 8),
                      _FiltreBtn(label: 'Refuse', value: 'refuse', selected: controller.selectedStatut.value, onTap: controller.setFiltreStatut),
                      const SizedBox(width: 8),
                      _FiltreBtn(label: 'Converti', value: 'converti', selected: controller.selectedStatut.value, onTap: controller.setFiltreStatut),
                    ],
                  ),
                ),
              )),

          // Liste
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.request_quote_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Aucun devis', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Get.to(() => const DevisFormScreen()),
                        icon: const Icon(Icons.add),
                        label: const Text('Créer un devis'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: controller.filteredList.length,
                itemBuilder: (context, index) {
                  final devis = controller.filteredList[index];
                  return _DevisCard(devis: devis, controller: controller);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _FiltreBtn extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final void Function(String) onTap;

  const _FiltreBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DevisCard extends StatelessWidget {
  final DevisModel devis;
  final DevisController controller;

  const _DevisCard({required this.devis, required this.controller});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final statutColor = _statutColor(devis.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          controller.selectedDevis.value = devis;
          Get.to(() => DevisDetailScreen(devis: devis));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(devis.numeroDevis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(devis.clientNom, style: TextStyle(color: Colors.grey[700])),
                        if (devis.clientTelephone.isNotEmpty) Text(devis.clientTelephone, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statutColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statutColor),
                        ),
                        child: Text(_statutLabel(devis.statut), style: TextStyle(color: statutColor, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      const SizedBox(height: 6),
                      Text('${fmt.format(devis.montantTotal)} FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Créé le ${DateFormat('dd/MM/yyyy').format(devis.dateCreation)} • ${devis.lignes.length} ligne(s)',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
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

  String _statutLabel(String statut) {
    switch (statut) {
      case 'brouillon':
        return 'Brouillon';
      case 'envoye':
        return 'Envoye';
      case 'valide':
        return 'Valide';
      case 'refuse':
        return 'Refuse';
      case 'converti':
        return 'Converti';
      default:
        return statut;
    }
  }
}
