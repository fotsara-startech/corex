import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/suivi_controller.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:intl/intl.dart';
import 'details_colis_screen.dart';

class SuiviColisScreen extends StatelessWidget {
  const SuiviColisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuiviController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Colis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadColis(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'reset') {
                controller.resetFilters();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Réinitialiser les filtres'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          _buildStatutChips(controller),
          Expanded(child: _buildColisList(controller)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(SuiviController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (value) => controller.searchQuery.value = value,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatutChips(SuiviController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() => ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatutChip(
                label: 'Tous',
                value: 'tous',
                controller: controller,
              ),
              ...controller.statutsDisponibles.where((s) => s != 'tous').map((statut) => _buildStatutChip(
                    label: controller.getStatutLabel(statut),
                    value: statut,
                    controller: controller,
                  )),
            ],
          )),
    );
  }

  Widget _buildStatutChip({
    required String label,
    required String value,
    required SuiviController controller,
  }) {
    return Obx(() {
      final isSelected = controller.selectedStatutFilter.value == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (selected) {
            controller.selectedStatutFilter.value = value;
          },
          backgroundColor: Colors.grey[200],
          selectedColor: const Color(0xFF4CAF50),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      );
    });
  }

  Widget _buildColisList(SuiviController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredColisList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun colis trouvé',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredColisList.length,
        itemBuilder: (context, index) {
          final colis = controller.filteredColisList[index];
          return _buildColisCard(colis, controller);
        },
      );
    });
  }

  Widget _buildColisCard(ColisModel colis, SuiviController controller) {
    final statutColor = Color(int.parse(controller.getStatutColor(colis.statut).replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          controller.selectColis(colis);
          Get.to(() => const DetailsColisScreen());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      colis.numeroSuivi,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statutColor),
                    ),
                    child: Text(
                      controller.getStatutLabel(colis.statut),
                      style: TextStyle(
                        color: statutColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd/MM/yyyy à HH:mm').format(colis.dateCollecte),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'De: ${colis.expediteurNom}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'À: ${colis.destinataireNom}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${colis.poids} kg',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${colis.montantTarif.toStringAsFixed(0)} F',
                        style: TextStyle(
                          color: colis.isPaye ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
