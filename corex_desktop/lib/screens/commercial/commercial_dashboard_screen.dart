import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:corex_shared/corex_shared.dart';
import '../agent/nouvelle_collecte_screen.dart';
import '../courses/create_course_screen.dart';
import '../devis/devis_list_screen.dart';
import '../devis/devis_form_screen.dart';
import '../courses/courses_list_screen.dart';

class CommercialDashboardScreen extends StatefulWidget {
  const CommercialDashboardScreen({super.key});

  @override
  State<CommercialDashboardScreen> createState() => _CommercialDashboardScreenState();
}

class _CommercialDashboardScreenState extends State<CommercialDashboardScreen> {
  final _fmt = NumberFormat('#,###');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  late final ColisController _colisController;
  late final DevisController _devisController;
  late final CourseController _courseController;
  late final ClientController _clientController;
  late final AuthController _authController;
  late final TransactionController _transactionController;

  // CA du commercial
  final RxDouble _chiffreAffaires = 0.0.obs;
  final RxBool _loadingCA = false.obs;
  final RxString _periodeSelectionnee = 'Ce mois'.obs;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _colisController = Get.find<ColisController>();
    _devisController = Get.find<DevisController>();
    _courseController = Get.find<CourseController>();
    _clientController = Get.find<ClientController>();

    // Initialiser TransactionController de manière paresseuse
    if (!Get.isRegistered<TransactionController>()) {
      Get.put(TransactionController(), permanent: true);
    }
    _transactionController = Get.find<TransactionController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChiffreAffaires();
    });
  }

  Future<void> _loadChiffreAffaires() async {
    _loadingCA.value = true;
    try {
      final user = _authController.currentUser.value;
      if (user == null) return;

      // Calculer la plage de dates selon la période
      final plage = _getPlageDate(_periodeSelectionnee.value);

      // Calculer le CA à partir des transactions de type recette créées par ce commercial
      final transactions = _transactionController.transactionsList.where((t) {
        return t.type == 'recette' && t.userId == user.id && t.date.isAfter(plage.$1.subtract(const Duration(seconds: 1))) && t.date.isBefore(plage.$2.add(const Duration(seconds: 1)));
      }).toList();

      _chiffreAffaires.value = transactions.fold(0.0, (sum, t) => sum + t.montant);
    } catch (e) {
      print('Erreur chargement CA: $e');
    } finally {
      _loadingCA.value = false;
    }
  }

  (DateTime, DateTime) _getPlageDate(String periode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (periode) {
      case 'Aujourd\'hui':
        return (today, endOfToday);

      case 'Hier':
        final hier = today.subtract(const Duration(days: 1));
        return (hier, DateTime(hier.year, hier.month, hier.day, 23, 59, 59));

      case 'Cette semaine':
        final debutSemaine = today.subtract(Duration(days: now.weekday - 1));
        return (debutSemaine, endOfToday);

      case 'Semaine dernière':
        final debutSemaineDerniere = today.subtract(Duration(days: now.weekday + 6));
        final finSemaineDerniere = today.subtract(Duration(days: now.weekday));
        return (debutSemaineDerniere, DateTime(finSemaineDerniere.year, finSemaineDerniere.month, finSemaineDerniere.day, 23, 59, 59));

      case 'Ce mois':
        final debutMois = DateTime(now.year, now.month, 1);
        return (debutMois, endOfToday);

      case 'Mois dernier':
        final debutMoisDernier = DateTime(now.year, now.month - 1, 1);
        final finMoisDernier = DateTime(now.year, now.month, 1).subtract(const Duration(seconds: 1));
        return (debutMoisDernier, finMoisDernier);

      case 'Ce trimestre':
        final trimestreActuel = ((now.month - 1) ~/ 3) + 1;
        final debutTrimestre = DateTime(now.year, (trimestreActuel - 1) * 3 + 1, 1);
        return (debutTrimestre, endOfToday);

      case 'Trimestre dernier':
        final trimestreActuel = ((now.month - 1) ~/ 3) + 1;
        final trimestreDernier = trimestreActuel == 1 ? 4 : trimestreActuel - 1;
        final annee = trimestreActuel == 1 ? now.year - 1 : now.year;
        final debutTrimestreDernier = DateTime(annee, (trimestreDernier - 1) * 3 + 1, 1);
        final finTrimestreDernier = DateTime(annee, trimestreDernier * 3 + 1, 1).subtract(const Duration(seconds: 1));
        return (debutTrimestreDernier, finTrimestreDernier);

      case 'Cette année':
        final debutAnnee = DateTime(now.year, 1, 1);
        return (debutAnnee, endOfToday);

      case 'Année dernière':
        final debutAnneeDerniere = DateTime(now.year - 1, 1, 1);
        final finAnneeDerniere = DateTime(now.year, 1, 1).subtract(const Duration(seconds: 1));
        return (debutAnneeDerniere, finAnneeDerniere);

      default:
        return (DateTime(now.year, now.month, 1), endOfToday);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _colisController.loadColis(),
      _courseController.loadCourses(),
      _clientController.loadClients(),
      _transactionController.loadTransactions(),
    ]);
    await _loadChiffreAffaires();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildChiffreAffairesCard(),
            const SizedBox(height: 12),
            _buildKpiRow(),
            const SizedBox(height: 12),
            _buildQuickActions(),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    _buildRecentDevis(),
                    const SizedBox(height: 12),
                    _buildRecentColis(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRecentDevis()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRecentColis()),
                ],
              );
            }),
            const SizedBox(height: 16),
            _buildCoursesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final user = _authController.currentUser.value;
      return Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF2E7D32),
            child: Text(
              user != null && user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : 'C',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${user?.prenom ?? ''} 👋',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('EEE dd MMM yyyy', 'fr_FR').format(DateTime.now()),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Actu.', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
                side: const BorderSide(color: Color(0xFF2E7D32)),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildChiffreAffairesCard() {
    return Obx(() {
      final caFormatted = NumberFormat('#,###').format(_chiffreAffaires.value);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E7D32).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mon Chiffre d\'Affaires',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _loadingCA.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              '$caFormatted FCFA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadingCA.value ? null : _loadChiffreAffaires,
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _periodeSelectionnee.value,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF2E7D32),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                items: [
                  'Aujourd\'hui',
                  'Hier',
                  'Cette semaine',
                  'Semaine dernière',
                  'Ce mois',
                  'Mois dernier',
                  'Ce trimestre',
                  'Trimestre dernier',
                  'Cette année',
                  'Année dernière',
                ].map((periode) {
                  return DropdownMenuItem<String>(
                    value: periode,
                    child: Text(periode),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _periodeSelectionnee.value = value;
                    _loadChiffreAffaires();
                  }
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildKpiRow() {
    return Obx(() {
      final user = _authController.currentUser.value;
      final userId = user?.id ?? '';

      // Filtrer par commercial connecté
      final colis = _colisController.colisList.where((c) => c.commercialId == userId).toList();
      final devis = _devisController.devisList.where((d) => d.userId == userId).toList();
      final courses = _courseController.coursesList.where((c) => c.createdBy == userId).toList();
      final clients = _clientController.clientsList; // Les clients restent visibles pour tous

      final today = DateTime.now();
      final colisAujourd = colis.where((c) {
        final d = c.dateCollecte;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).length;

      final devisEnCours = devis.where((d) => d.statut == 'brouillon' || d.statut == 'envoye').length;
      final devisConverti = devis.where((d) => d.statut == 'valide' || d.statut == 'converti').length;
      final coursesActives = courses.where((c) => c.statut == 'enAttente' || c.statut == 'enCours').length;
      final coursesTerminees = courses.where((c) => c.statut == 'terminee').length;

      final kpis = [
        _KpiData('Colis auj.', colisAujourd.toString(), Icons.inventory_2, const Color(0xFF2E7D32)),
        _KpiData('Devis en cours', devisEnCours.toString(), Icons.description, const Color(0xFF1565C0)),
        _KpiData('Convertis', devisConverti.toString(), Icons.check_circle, const Color(0xFF00796B)),
        _KpiData('Courses act.', coursesActives.toString(), Icons.directions_bike, const Color(0xFFE65100)),
        _KpiData('Colis total', colis.length.toString(), Icons.all_inbox, const Color(0xFF6A1B9A)),
        _KpiData('Clients', clients.length.toString(), Icons.people, const Color(0xFF37474F)),
        _KpiData('Retours', colis.where((c) => c.isRetour).length.toString(), Icons.keyboard_return, const Color(0xFFC62828)),
        _KpiData('Terminées', coursesTerminees.toString(), Icons.task_alt, const Color(0xFF2E7D32)),
      ];

      return LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth > 500 ? 4 : 2;
        final ratio = constraints.maxWidth > 500 ? 3.2 : 2.8;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: ratio,
          ),
          itemCount: kpis.length,
          itemBuilder: (_, i) => _kpiCard(kpis[i]),
        );
      });
    });
  }

  Widget _kpiCard(_KpiData kpi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: kpi.color, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Icon(kpi.icon, color: kpi.color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(kpi.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kpi.color)),
                ),
                Text(kpi.label, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions rapides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionButton('Nouvelle collecte', Icons.add_box, const Color(0xFF2E7D32), () {
              Get.to(() => const NouvelleCollecteScreen());
            }),
            _actionButton('Nouveau devis', Icons.description, const Color(0xFF1565C0), () {
              Get.to(() => const DevisFormScreen());
            }),
            _actionButton('Nouvelle course', Icons.directions_bike, const Color(0xFFE65100), () {
              Get.to(() => const CreateCourseScreen());
            }),
            _actionButton('Voir devis', Icons.list_alt, const Color(0xFF00796B), () {
              Get.to(() => const DevisListScreen());
            }),
            _actionButton('Voir courses', Icons.route, const Color(0xFF6A1B9A), () {
              Get.to(() => const CoursesListScreen());
            }),
            _actionButton('Retours colis', Icons.keyboard_return, const Color(0xFFC62828), () {
              Get.toNamed('/retours');
            }),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDevis() {
    return Obx(() {
      final user = _authController.currentUser.value;
      final userId = user?.id ?? '';

      // Filtrer les devis du commercial connecté
      final devis = _devisController.devisList.where((d) => d.userId == userId).take(6).toList();

      return _sectionCard(
        title: 'Mes devis récents',
        icon: Icons.description,
        onMore: () => Get.to(() => const DevisListScreen()),
        child: devis.isEmpty
            ? const _EmptyState(message: 'Aucun devis')
            : Column(
                children: devis.map((d) => _devisRow(d)).toList(),
              ),
      );
    });
  }

  Widget _devisRow(DevisModel d) {
    final color = _devisColor(d.statut);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.numeroDevis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
                Text(d.clientNom, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_fmt.format(d.montantTotal)} F', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(_statutDevisLabel(d.statut), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentColis() {
    return Obx(() {
      final user = _authController.currentUser.value;
      final userId = user?.id ?? '';

      // Filtrer les colis du commercial connecté
      final colis = _colisController.colisList.where((c) => c.commercialId == userId).take(6).toList();

      return _sectionCard(
        title: 'Mes colis récents',
        icon: Icons.inventory_2,
        onMore: () {},
        child: colis.isEmpty
            ? const _EmptyState(message: 'Aucun colis')
            : Column(
                children: colis.map((c) => _colisRow(c)).toList(),
              ),
      );
    });
  }

  Widget _colisRow(ColisModel c) {
    final color = _colisColor(c.statut);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.numeroSuivi, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
                Text(c.destinataireNom, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_dateFmt.format(c.dateCollecte), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(_statutColisLabel(c.statut), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesSection() {
    return Obx(() {
      final user = _authController.currentUser.value;
      final userId = user?.id ?? '';

      // Filtrer les courses créées par le commercial connecté
      final courses = _courseController.coursesList.where((c) => c.createdBy == userId && (c.statut == 'enAttente' || c.statut == 'enCours')).take(5).toList();

      return _sectionCard(
        title: 'Mes courses en cours',
        icon: Icons.directions_bike,
        onMore: () => Get.to(() => const CoursesListScreen()),
        child: courses.isEmpty ? const _EmptyState(message: 'Aucune course active') : Column(children: courses.map((c) => _courseRow(c)).toList()),
      );
    });
  }

  Widget _courseRow(CourseModel c) {
    final isEnCours = c.statut == 'enCours';
    final color = isEnCours ? const Color(0xFF1565C0) : const Color(0xFFE65100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.clientNom, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis),
                Text(c.lieu, style: const TextStyle(color: Colors.grey, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_fmt.format(c.montantEstime)} F', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(isEnCours ? 'En cours' : 'Attente', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required VoidCallback onMore,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onMore,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Voir tout', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: child,
          ),
        ],
      ),
    );
  }

  Color _devisColor(String statut) {
    switch (statut) {
      case 'valide':
        return const Color(0xFF2E7D32);
      case 'converti':
        return const Color(0xFF1565C0);
      case 'refuse':
        return Colors.red;
      case 'envoye':
        return const Color(0xFFE65100);
      default:
        return Colors.grey;
    }
  }

  String _statutDevisLabel(String statut) {
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
        return 'Converti';
      default:
        return statut;
    }
  }

  Color _colisColor(String statut) {
    switch (statut) {
      case 'livre':
        return const Color(0xFF2E7D32);
      case 'en_transit':
        return const Color(0xFF1565C0);
      case 'en_attente':
        return const Color(0xFFE65100);
      case 'annule':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statutColisLabel(String statut) {
    switch (statut) {
      case 'collecte':
        return 'Collecté';
      case 'en_transit':
        return 'En transit';
      case 'livre':
        return 'Livré';
      case 'annule':
        return 'Annulé';
      case 'retour':
        return 'Retour';
      default:
        return statut;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiData(this.label, this.value, this.icon, this.color);
}
