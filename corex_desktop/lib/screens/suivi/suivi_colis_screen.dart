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
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_off),
            onPressed: () => controller.resetFilters(),
            tooltip: 'Réinitialiser les filtres',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(controller),
          _buildFilters(controller),
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
          hintText: 'Rechercher par numéro, nom, téléphone...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildFilters(SuiviController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtres principaux
            Row(
              children: [
                _buildStatutFilter(controller),
                const SizedBox(width: 16),
                _buildRetoursSwitch(controller),
                const SizedBox(width: 16),
                _buildDateFilter(controller),
              ],
            ),
            const SizedBox(height: 8),
            // Filtres rapides de date
            Row(
              children: [
                _buildQuickDateFilter('Aujourd\'hui', 0, controller),
                const SizedBox(width: 8),
                _buildQuickDateFilter('Hier', -1, controller),
                const SizedBox(width: 8),
                _buildQuickDateFilter('Cette semaine', -7, controller),
                const SizedBox(width: 8),
                _buildQuickDateFilter('Ce mois', -30, controller),
                const SizedBox(width: 8),
                _buildQuickDateFilter('Cette année', -365, controller),
                const SizedBox(width: 8),
                _buildQuickDateFilter('Tous', null, controller),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetoursSwitch(SuiviController controller) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_return,
                size: 20,
                color: controller.afficherRetours.value ? const Color(0xFF2E7D32) : Colors.grey,
              ),
              const SizedBox(width: 8),
              const Text('Afficher les retours'),
              const SizedBox(width: 8),
              Switch(
                value: controller.afficherRetours.value,
                onChanged: (value) => controller.afficherRetours.value = value,
                activeColor: const Color(0xFF2E7D32),
              ),
            ],
          ),
        ));
  }

  Widget _buildStatutFilter(SuiviController controller) {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<String>(
            value: controller.selectedStatutFilter.value,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: 'tous', child: Text('Tous les statuts')),
              ...controller.statutsDisponibles.where((s) => s != 'tous').map((statut) => DropdownMenuItem(
                    value: statut,
                    child: Text(controller.getStatutLabel(statut)),
                  )),
            ],
            onChanged: (value) {
              if (value != null) {
                controller.selectedStatutFilter.value = value;
              }
            },
          ),
        ));
  }

  Widget _buildDateFilter(SuiviController controller) {
    return Row(
      children: [
        _buildDateButton(
          label: 'Date début',
          date: controller.dateDebutFilter.value,
          onPressed: () async {
            final date = await Get.dialog<DateTime>(
              _DatePickerDialog(initialDate: controller.dateDebutFilter.value),
            );
            if (date != null) {
              controller.dateDebutFilter.value = date;
            }
          },
        ),
        const SizedBox(width: 8),
        _buildDateButton(
          label: 'Date fin',
          date: controller.dateFinFilter.value,
          onPressed: () async {
            final date = await Get.dialog<DateTime>(
              _DatePickerDialog(initialDate: controller.dateFinFilter.value),
            );
            if (date != null) {
              controller.dateFinFilter.value = date;
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickDateFilter(String label, int? daysOffset, SuiviController controller) {
    return Obx(() {
      final now = DateTime.now();
      DateTime startOfPeriod;
      DateTime endOfPeriod;

      if (daysOffset == null) {
        // Tous les filtres
        startOfPeriod = DateTime(2020);
        endOfPeriod = DateTime(2030);
      } else if (daysOffset == 0) {
        // Aujourd'hui
        startOfPeriod = DateTime(now.year, now.month, now.day);
        endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (daysOffset == -1) {
        // Hier
        final yesterday = now.subtract(const Duration(days: 1));
        startOfPeriod = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endOfPeriod = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
      } else if (daysOffset == -7) {
        // Cette semaine
        final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startOfPeriod = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
        endOfPeriod = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (daysOffset == -30) {
        // Ce mois
        startOfPeriod = DateTime(now.year, now.month, 1);
        endOfPeriod = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else {
        // Cette année
        startOfPeriod = DateTime(now.year, 1, 1);
        endOfPeriod = DateTime(now.year, 12, 31, 23, 59, 59);
      }

      final isActive = controller.dateDebutFilter.value?.year == startOfPeriod.year &&
          controller.dateDebutFilter.value?.month == startOfPeriod.month &&
          controller.dateDebutFilter.value?.day == startOfPeriod.day &&
          controller.dateFinFilter.value?.year == endOfPeriod.year &&
          controller.dateFinFilter.value?.month == endOfPeriod.month &&
          controller.dateFinFilter.value?.day == endOfPeriod.day;

      return ElevatedButton(
        onPressed: () {
          controller.dateDebutFilter.value = startOfPeriod;
          controller.dateFinFilter.value = endOfPeriod;
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF2E7D32) : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.grey[800],
          side: BorderSide(
            color: isActive ? const Color(0xFF2E7D32) : Colors.grey[300]!,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: Text(label),
      );
    });
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : label),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
      ),
    );
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
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          colis.numeroSuivi,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Collecté le ${DateFormat('dd/MM/yyyy à HH:mm').format(colis.dateCollecte)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statutColor),
                    ),
                    child: Text(
                      controller.getStatutLabel(colis.statut),
                      style: TextStyle(
                        color: statutColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Contenu du colis
              if (colis.contenu.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contenu',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        colis.contenu,
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expéditeur',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(colis.expediteurNom),
                        Text(
                          colis.expediteurTelephone,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destinataire',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(colis.destinataireNom),
                        Text(
                          colis.destinataireTelephone,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    colis.destinataireVille,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.inventory_2, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${colis.poids} kg',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.payments, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${colis.montantTarif.toStringAsFixed(0)} FCFA',
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
        ),
      ),
    );
  }
}

class _DatePickerDialog extends StatelessWidget {
  final DateTime? initialDate;

  const _DatePickerDialog({this.initialDate});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CalendarDatePicker(
              initialDate: initialDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              onDateChanged: (date) => Get.back(result: date),
            ),
          ],
        ),
      ),
    );
  }
}
