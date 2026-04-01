import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/livraison_controller.dart';
import 'package:corex_shared/controllers/course_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/models/livraison_model.dart';
import 'package:corex_shared/models/course_model.dart';
import 'package:intl/intl.dart';
import 'mes_livraisons_screen.dart';
import 'mes_courses_screen.dart';

class CoursierDashboardScreen extends StatefulWidget {
  const CoursierDashboardScreen({super.key});

  @override
  State<CoursierDashboardScreen> createState() => _CoursierDashboardScreenState();
}

class _CoursierDashboardScreenState extends State<CoursierDashboardScreen> {
  late final LivraisonController _livraisonCtrl;
  late final CourseController _courseCtrl;
  late final AuthController _authCtrl;

  @override
  void initState() {
    super.initState();
    _authCtrl = Get.find<AuthController>();
    _livraisonCtrl = Get.isRegistered<LivraisonController>() ? Get.find<LivraisonController>() : Get.put(LivraisonController());
    _courseCtrl = Get.isRegistered<CourseController>() ? Get.find<CourseController>() : Get.put(CourseController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _livraisonCtrl.loadLivraisons();
      _courseCtrl.loadCourses();
    });
  }

  String get _coursierId => _authCtrl.currentUser.value?.id ?? '';

  List<LivraisonModel> get _mesLivraisons => _livraisonCtrl.livraisonsList.where((l) => l.coursierId == _coursierId).toList();

  List<LivraisonModel> get _livraisonsAujourdhui {
    final today = DateTime.now();
    return _mesLivraisons.where((l) => l.dateCreation.year == today.year && l.dateCreation.month == today.month && l.dateCreation.day == today.day).toList();
  }

  List<CourseModel> get _mesCourses => _courseCtrl.coursesList.where((c) => c.coursierId == _coursierId).toList();

  List<CourseModel> get _coursesActives => _mesCourses.where((c) => c.statut == 'enCours' || c.statut == 'enAttente').toList();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final pad = isMobile ? 12.0 : 20.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Obx(() {
            final user = _authCtrl.currentUser.value;
            final livraisons = _mesLivraisons;
            final livraisonsAujourdhui = _livraisonsAujourdhui;
            final coursesActives = _coursesActives;
            final fmt = NumberFormat('#,###');

            final enAttente = livraisons.where((l) => l.statut == 'enAttente').length;
            final enCours = livraisons.where((l) => l.statut == 'enCours').length;
            final livrees = livraisons.where((l) => l.statut == 'livree').length;
            final echecs = livraisons.where((l) => l.statut == 'echec').length;
            final total = livrees + echecs;
            final tauxReussite = total > 0 ? (livrees / total * 100) : 0.0;
            final montantCollecte = livraisonsAujourdhui.where((l) => l.paiementCollecte).fold(0.0, (sum, l) => sum + (l.montantACollecte ?? 0));

            return RefreshIndicator(
              onRefresh: () async {
                await _livraisonCtrl.loadLivraisons();
                await _courseCtrl.loadCourses();
              },
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: isMobile ? 110 : 130,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF2E7D32),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(pad, 56, pad, 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 24 : 30,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                user?.prenom.isNotEmpty == true ? user!.prenom[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  fontSize: isMobile ? 20 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Bonjour, ${user?.prenom ?? 'Coursier'}',
                                    style: TextStyle(
                                      fontSize: isMobile ? 16 : 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(DateTime.now()),
                                    style: TextStyle(
                                      fontSize: isMobile ? 11 : 13,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: () {
                                _livraisonCtrl.loadLivraisons();
                                _courseCtrl.loadCourses();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.all(pad),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── KPIs Livraisons ──────────────────────
                        _SectionTitle(icon: Icons.local_shipping, label: 'Mes Livraisons', isMobile: isMobile),
                        SizedBox(height: isMobile ? 8 : 12),

                        // Sur mobile : 2 colonnes, sur tablet/desktop : 4 colonnes
                        if (isMobile) ...[
                          Row(children: [
                            Expanded(child: _KpiCard(label: 'En attente', value: enAttente.toString(), color: Colors.orange, icon: Icons.schedule, isMobile: true)),
                            const SizedBox(width: 10),
                            Expanded(child: _KpiCard(label: 'En cours', value: enCours.toString(), color: Colors.blue, icon: Icons.local_shipping, isMobile: true)),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: _KpiCard(label: 'Livrées', value: livrees.toString(), color: Colors.green, icon: Icons.check_circle, isMobile: true)),
                            const SizedBox(width: 10),
                            Expanded(child: _KpiCard(label: 'Échecs', value: echecs.toString(), color: Colors.red, icon: Icons.error, isMobile: true)),
                          ]),
                        ] else
                          Row(children: [
                            Expanded(child: _KpiCard(label: 'En attente', value: enAttente.toString(), color: Colors.orange, icon: Icons.schedule)),
                            const SizedBox(width: 12),
                            Expanded(child: _KpiCard(label: 'En cours', value: enCours.toString(), color: Colors.blue, icon: Icons.local_shipping)),
                            const SizedBox(width: 12),
                            Expanded(child: _KpiCard(label: 'Livrées', value: livrees.toString(), color: Colors.green, icon: Icons.check_circle)),
                            const SizedBox(width: 12),
                            Expanded(child: _KpiCard(label: 'Échecs', value: echecs.toString(), color: Colors.red, icon: Icons.error)),
                          ]),

                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: _KpiCard(
                            label: 'Taux de réussite',
                            value: '${tauxReussite.toStringAsFixed(0)}%',
                            color: tauxReussite >= 80
                                ? Colors.green
                                : tauxReussite >= 60
                                    ? Colors.orange
                                    : Colors.red,
                            icon: Icons.trending_up,
                            isMobile: isMobile,
                          )),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _KpiCard(
                            label: 'Collecté aujourd\'hui',
                            value: '${fmt.format(montantCollecte)} FCFA',
                            color: const Color(0xFF2E7D32),
                            icon: Icons.payments,
                            isMobile: isMobile,
                          )),
                        ]),
                        SizedBox(height: isMobile ? 20 : 28),

                        // ── Livraisons urgentes ──────────────────
                        if (enAttente > 0 || enCours > 0) ...[
                          _SectionTitle(icon: Icons.priority_high, label: 'À traiter maintenant', isMobile: isMobile),
                          const SizedBox(height: 8),
                          ...livraisons
                              .where((l) => l.statut == 'enAttente' || l.statut == 'enCours')
                              .take(3)
                              .map((l) => _LivraisonUrgenteTile(livraison: l, controller: _livraisonCtrl, isMobile: isMobile)),
                          if (enAttente + enCours > 3)
                            TextButton.icon(
                              onPressed: () => Get.to(() => const MesLivraisonsScreen()),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: Text('Voir toutes (${enAttente + enCours})', style: const TextStyle(fontSize: 13)),
                            ),
                          SizedBox(height: isMobile ? 20 : 28),
                        ],

                        // ── Courses ──────────────────────────────
                        _SectionTitle(icon: Icons.directions_run, label: 'Mes Courses', isMobile: isMobile),
                        const SizedBox(height: 8),

                        if (isMobile) ...[
                          Row(children: [
                            Expanded(
                                child: _KpiCard(
                                    label: 'En cours', value: _mesCourses.where((c) => c.statut == 'enCours').length.toString(), color: Colors.blue, icon: Icons.directions_run, isMobile: true)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _KpiCard(
                                    label: 'En attente',
                                    value: _mesCourses.where((c) => c.statut == 'enAttente').length.toString(),
                                    color: Colors.orange,
                                    icon: Icons.hourglass_empty,
                                    isMobile: true)),
                          ]),
                          const SizedBox(height: 10),
                          _KpiCard(
                              label: 'Terminées', value: _mesCourses.where((c) => c.statut == 'terminee').length.toString(), color: Colors.green, icon: Icons.check_circle_outline, isMobile: true),
                        ] else
                          Row(children: [
                            Expanded(child: _KpiCard(label: 'En cours', value: _mesCourses.where((c) => c.statut == 'enCours').length.toString(), color: Colors.blue, icon: Icons.directions_run)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _KpiCard(label: 'En attente', value: _mesCourses.where((c) => c.statut == 'enAttente').length.toString(), color: Colors.orange, icon: Icons.hourglass_empty)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _KpiCard(label: 'Terminées', value: _mesCourses.where((c) => c.statut == 'terminee').length.toString(), color: Colors.green, icon: Icons.check_circle_outline)),
                          ]),

                        const SizedBox(height: 10),
                        if (coursesActives.isNotEmpty) ...[
                          ...coursesActives.take(2).map((c) => _CourseTile(course: c, isMobile: isMobile)),
                          if (coursesActives.length > 2)
                            TextButton.icon(
                              onPressed: () => Get.to(() => const MesCoursesScreen()),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: Text('Voir toutes (${coursesActives.length})', style: const TextStyle(fontSize: 13)),
                            ),
                        ] else
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 20),
                                SizedBox(width: 10),
                                Expanded(child: Text('Aucune course active pour le moment', style: TextStyle(fontSize: 13))),
                              ],
                            ),
                          ),
                        SizedBox(height: isMobile ? 20 : 28),

                        // ── Accès rapide ─────────────────────────
                        _SectionTitle(icon: Icons.apps, label: 'Accès rapide', isMobile: isMobile),
                        const SizedBox(height: 10),
                        if (isMobile) ...[
                          _QuickActionCard(
                            icon: Icons.local_shipping,
                            label: 'Mes Livraisons',
                            color: const Color(0xFF2E7D32),
                            badge: enAttente + enCours > 0 ? '${enAttente + enCours}' : null,
                            onTap: () => Get.to(() => const MesLivraisonsScreen()),
                          ),
                          const SizedBox(height: 10),
                          _QuickActionCard(
                            icon: Icons.directions_run,
                            label: 'Mes Courses',
                            color: Colors.blue.shade700,
                            badge: coursesActives.isNotEmpty ? '${coursesActives.length}' : null,
                            onTap: () => Get.to(() => const MesCoursesScreen()),
                          ),
                        ] else
                          Row(children: [
                            Expanded(
                                child: _QuickActionCard(
                              icon: Icons.local_shipping,
                              label: 'Mes Livraisons',
                              color: const Color(0xFF2E7D32),
                              badge: enAttente + enCours > 0 ? '${enAttente + enCours}' : null,
                              onTap: () => Get.to(() => const MesLivraisonsScreen()),
                            )),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _QuickActionCard(
                              icon: Icons.directions_run,
                              label: 'Mes Courses',
                              color: Colors.blue.shade700,
                              badge: coursesActives.isNotEmpty ? '${coursesActives.length}' : null,
                              onTap: () => Get.to(() => const MesCoursesScreen()),
                            )),
                          ]),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// ── WIDGETS ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isMobile;
  const _SectionTitle({required this.icon, required this.label, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: isMobile ? 16 : 18, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isMobile;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: isMobile ? 18 : 20),
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: isMobile ? 11 : 12, color: Colors.grey.shade600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LivraisonUrgenteTile extends StatelessWidget {
  final LivraisonModel livraison;
  final LivraisonController controller;
  final bool isMobile;

  const _LivraisonUrgenteTile({required this.livraison, required this.controller, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final isEnAttente = livraison.statut == 'enAttente';
    final color = isEnAttente ? Colors.orange : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(isEnAttente ? Icons.schedule : Icons.local_shipping, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zone: ${livraison.zone}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        isEnAttente ? 'En attente de départ' : 'En cours de livraison',
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: isEnAttente
                  ? ElevatedButton.icon(
                      onPressed: () async => await controller.demarrerTournee(livraison.id),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Démarrer la tournée'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => Get.toNamed('/livraison/details', arguments: livraison),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Terminer la livraison'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final CourseModel course;
  final bool isMobile;
  const _CourseTile({required this.course, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final isEnCours = course.statut == 'enCours';
    final color = isEnCours ? Colors.blue : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(isEnCours ? Icons.directions_run : Icons.hourglass_empty, color: color, size: 18),
        ),
        title: Text(course.tache, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 13 : 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${course.lieu} • ${NumberFormat('#,###').format(course.montantEstime)} FCFA',
          style: TextStyle(fontSize: isMobile ? 11 : 12, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Text(isEnCours ? 'En cours' : 'En attente', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        onTap: () => Get.to(() => const MesCoursesScreen()),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
