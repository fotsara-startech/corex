import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/colis_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/services/colis_service.dart';
import 'package:corex_shared/models/colis_model.dart';
import '../../theme/corex_theme.dart';
import 'package:intl/intl.dart';
import 'colis_details_screen.dart';
import 'nouvelle_collecte_screen.dart';

class EnregistrementColisScreen extends StatefulWidget {
  const EnregistrementColisScreen({super.key});

  @override
  State<EnregistrementColisScreen> createState() => _EnregistrementColisScreenState();
}

class _EnregistrementColisScreenState extends State<EnregistrementColisScreen> {
  DateTime? _dateDebut;
  DateTime? _dateFin;
  final _dateFormat = DateFormat('dd/MM/yyyy');
  late ColisController _colisController;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
    if (!Get.isRegistered<ColisService>()) {
      Get.put(ColisService(), permanent: true);
    }
    _colisController = Get.put(ColisController(), permanent: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharger à chaque fois que la page redevient active
    _colisController.loadColis();
  }

  @override
  Widget build(BuildContext context) {
    final colisController = _colisController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enregistrement des Colis'),
        backgroundColor: CorexTheme.primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => colisController.loadColis(),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Nouvelle collecte',
            onPressed: () {
              Get.to(() => const NouvelleCollecteScreen());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const NouvelleCollecteScreen());
        },
        backgroundColor: CorexTheme.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Collecte'),
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchBar(colisController),

          // Filtre par date
          _buildDateFilter(colisController),

          // Statistiques rapides
          _buildStats(colisController),

          // Liste des colis à enregistrer
          Expanded(
            child: Obx(() {
              if (colisController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var colisAEnregistrer = colisController.colisList.where((c) => c.statut == 'collecte').toList();

              // Appliquer le filtre par date
              colisAEnregistrer = _applyDateFilter(colisAEnregistrer);

              if (colisAEnregistrer.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: colisAEnregistrer.length,
                itemBuilder: (context, index) {
                  final colis = colisAEnregistrer[index];
                  return _buildColisCard(context, colis, colisController);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColisController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, téléphone...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) => controller.searchQuery.value = value,
      ),
    );
  }

  Widget _buildDateFilter(ColisController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickFilterChip('Aujourd\'hui', () {
                  setState(() {
                    final now = DateTime.now();
                    _dateDebut = DateTime(now.year, now.month, now.day, 0, 0, 0);
                    _dateFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickFilterChip('Cette semaine', () {
                  setState(() {
                    final now = DateTime.now();
                    final weekday = now.weekday;
                    _dateDebut = DateTime(now.year, now.month, now.day - weekday + 1, 0, 0, 0);
                    _dateFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickFilterChip('Ce mois', () {
                  setState(() {
                    final now = DateTime.now();
                    _dateDebut = DateTime(now.year, now.month, 1, 0, 0, 0);
                    _dateFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickFilterChip('7 derniers jours', () {
                  setState(() {
                    final now = DateTime.now();
                    _dateDebut = DateTime(now.year, now.month, now.day - 7, 0, 0, 0);
                    _dateFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
                  });
                }),
                const SizedBox(width: 8),
                _buildQuickFilterChip('30 derniers jours', () {
                  setState(() {
                    final now = DateTime.now();
                    _dateDebut = DateTime(now.year, now.month, now.day - 30, 0, 0, 0);
                    _dateFin = DateTime(now.year, now.month, now.day, 23, 59, 59);
                  });
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Sélection de dates personnalisées
          Row(
            children: [
              // Date de début
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateDebut(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: CorexTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateDebut != null ? _dateFormat.format(_dateDebut!) : 'Date début',
                            style: TextStyle(
                              fontSize: 14,
                              color: _dateDebut != null ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                        ),
                        if (_dateDebut != null)
                          InkWell(
                            onTap: () {
                              setState(() => _dateDebut = null);
                            },
                            child: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date de fin
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateFin(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: CorexTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateFin != null ? _dateFormat.format(_dateFin!) : 'Date fin',
                            style: TextStyle(
                              fontSize: 14,
                              color: _dateFin != null ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                        ),
                        if (_dateFin != null)
                          InkWell(
                            onTap: () {
                              setState(() => _dateFin = null);
                            },
                            child: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton réinitialiser
              if (_dateDebut != null || _dateFin != null)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _dateDebut = null;
                      _dateFin = null;
                    });
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Réinitialiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CorexTheme.primaryGreen),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 14, color: CorexTheme.primaryGreen),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: CorexTheme.primaryGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateDebut(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: CorexTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateDebut) {
      setState(() {
        _dateDebut = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        // Si date fin est avant date début, on la réinitialise
        if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) {
          _dateFin = null;
        }
      });
    }
  }

  Future<void> _selectDateFin(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? (_dateDebut ?? DateTime.now()),
      firstDate: _dateDebut ?? DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: CorexTheme.primaryGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateFin) {
      setState(() {
        _dateFin = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  List<ColisModel> _applyDateFilter(List<ColisModel> colisList) {
    if (_dateDebut == null && _dateFin == null) {
      return colisList;
    }

    return colisList.where((colis) {
      final dateCollecte = colis.dateCollecte;

      if (_dateDebut != null && dateCollecte.isBefore(_dateDebut!)) {
        return false;
      }

      if (_dateFin != null && dateCollecte.isAfter(_dateFin!)) {
        return false;
      }

      return true;
    }).toList();
  }

  Widget _buildStats(ColisController controller) {
    return Obx(() {
      var colisAEnregistrer = controller.colisList.where((c) => c.statut == 'collecte').toList();
      colisAEnregistrer = _applyDateFilter(colisAEnregistrer);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: CorexTheme.primaryGreen.withOpacity(0.1),
        child: Row(
          children: [
            // Statistique compacte
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CorexTheme.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending_actions, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${colisAEnregistrer.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'à enregistrer',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Indicateur de filtre
            if (_dateDebut != null || _dateFin != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_alt, size: 14, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _buildFilterText(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  String _buildFilterText() {
    if (_dateDebut != null && _dateFin != null) {
      return 'Du ${_dateFormat.format(_dateDebut!)} au ${_dateFormat.format(_dateFin!)}';
    } else if (_dateDebut != null) {
      return 'À partir du ${_dateFormat.format(_dateDebut!)}';
    } else if (_dateFin != null) {
      return 'Jusqu\'au ${_dateFormat.format(_dateFin!)}';
    }
    return '';
  }

  Widget _buildEmptyState() {
    final hasFilter = _dateDebut != null || _dateFin != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Aucun colis trouvé' : 'Aucun colis à enregistrer',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter ? 'Aucun colis collecté pour la période sélectionnée' : 'Tous les colis collectés ont été enregistrés',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilter) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _dateDebut = null;
                  _dateFin = null;
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer les filtres'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CorexTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColisCard(BuildContext context, ColisModel colis, ColisController controller) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Get.to(() => ColisDetailsScreen(colis: colis));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec date de collecte
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Collecté le ${dateFormat.format(colis.dateCollecte)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'À ENREGISTRER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Informations expéditeur
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Expéditeur',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          colis.expediteurNom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          colis.expediteurTelephone,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Informations destinataire
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Destinataire',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          colis.destinataireNom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${colis.destinataireVille} - ${colis.destinataireTelephone}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Détails du colis
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem('Contenu', colis.contenu),
                  _buildDetailItem('Poids', colis.poids != null ? '${colis.poids} kg' : 'Non pesé'),
                  _buildDetailItem('Tarif', '${colis.montantTarif} FCFA'),
                ],
              ),
              if (colis.valeurDeclaree != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Valeur déclarée: ${colis.valeurDeclaree!.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Bouton d'enregistrement
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => ColisDetailsScreen(colis: colis));
                  },
                  icon: const Icon(Icons.app_registration),
                  label: const Text('ENREGISTRER CE COLIS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CorexTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
