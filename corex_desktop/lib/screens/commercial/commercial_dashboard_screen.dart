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

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _colisController = Get.find<ColisController>();
    _devisController = Get.find<DevisController>();
    _courseController = Get.find<CourseController>();
    _clientController = Get.find<ClientController>();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _colisController.loadColis(),
      _courseController.loadCourses(),
      _clientController.loadClients(),
    ]);
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

  Widget _buildKpiRow() {
    return Obx(() {
      final colis = _colisController.colisList;
      final devis = _devisController.devisList;
      final courses = _courseController.coursesList;
      final clients = _clientController.clientsList;

      final today = DateTime.now();
      final colisAujourd = colis.where((c) {
        final d = c.dateCollecte;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).length;

      final devisEnCours = devis.where((d) => d.statut == 'brouillon' || d.statut == 'envoye').length;
      final devisConverti = devis.where((d) => d.statut == 'valide' || d.statut == 'converti').length;
      final coursesActives = courses.where((c) => c.statut == 'enAttente' || c.statut == 'enCours').length;

      final kpis = [
        _KpiData('Colis auj.', colisAujourd.toString(), Icons.inventory_2, const Color(0xFF2E7D32)),
        _KpiData('Devis en cours', devisEnCours.toString(), Icons.description, const Color(0xFF1565C0)),
        _KpiData('Convertis', devisConverti.toString(), Icons.check_circle, const Color(0xFF00796B)),
        _KpiData('Courses act.', coursesActives.toString(), Icons.directions_bike, const Color(0xFFE65100)),
        _KpiData('Colis total', colis.length.toString(), Icons.all_inbox, const Color(0xFF6A1B9A)),
        _KpiData('Clients', clients.length.toString(), Icons.people, const Color(0xFF37474F)),
        _KpiData('Retours', colis.where((c) => c.isRetour).length.toString(), Icons.keyboard_return, const Color(0xFFC62828)),
        _KpiData('Terminées', _courseController.coursesTerminees.toString(), Icons.task_alt, const Color(0xFF2E7D32)),
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
      final devis = _devisController.devisList.take(6).toList();
      return _sectionCard(
        title: 'Devis récents',
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
      final colis = _colisController.colisList.take(6).toList();
      return _sectionCard(
        title: 'Colis récents',
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
      final courses = _courseController.coursesList.where((c) => c.statut == 'enAttente' || c.statut == 'enCours').take(5).toList();
      return _sectionCard(
        title: 'Courses en cours',
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
