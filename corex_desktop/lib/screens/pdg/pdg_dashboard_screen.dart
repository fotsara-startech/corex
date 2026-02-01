import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/pdg_dashboard_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import '../../widgets/pdg/kpi_card.dart';
import '../../widgets/pdg/evolution_chart.dart';
import '../../widgets/pdg/performance_chart.dart';
import '../../widgets/pdg/alert_card.dart';
import '../../widgets/pdg/top_performers_card.dart';

class PdgDashboardScreen extends StatelessWidget {
  final bool isEmbedded;

  const PdgDashboardScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PdgDashboardController());
    final authController = Get.find<AuthController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    // Si c'est en mode embedded, retourner seulement le contenu
    if (isEmbedded) {
      return _buildDashboardContent(controller, authController, isMobile, isTablet);
    }

    // Sinon, retourner le Scaffold complet
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0E), // Fond vert foncé
      drawer: _buildDrawer(authController, isMobile), // Ajout du drawer
      body: _buildDashboardContent(controller, authController, isMobile, isTablet),
    );
  }

  Widget _buildDashboardContent(PdgDashboardController controller, AuthController authController, bool isMobile, bool isTablet) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)), // Vert principal
          ),
        );
      }

      return CustomScrollView(
        slivers: [
          // App Bar moderne avec glassmorphism - Responsive (seulement si pas embedded)
          if (!isEmbedded)
            SliverAppBar(
              expandedHeight: isMobile ? 80 : 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E7D32).withOpacity(0.8), // Vert principal
                      const Color(0xFF4CAF50).withOpacity(0.6), // Vert clair
                    ],
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: isMobile
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard PDG',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Indicateur de source des données - Mobile
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _hasRealData(controller) ? const Color(0xFF4CAF50).withOpacity(0.3) : const Color(0xFFFF9800).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _hasRealData(controller) ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                ),
                              ),
                              child: Text(
                                _hasRealData(controller) ? 'RÉEL' : 'DÉMO',
                                style: TextStyle(
                                  color: _hasRealData(controller) ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Text(
                              'Tableau de Bord PDG',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Indicateur de source des données - Desktop
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _hasRealData(controller) ? const Color(0xFF4CAF50).withOpacity(0.3) : const Color(0xFFFF9800).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasRealData(controller) ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                ),
                              ),
                              child: Text(
                                _hasRealData(controller) ? 'DONNÉES RÉELLES' : 'MODE DÉMO',
                                style: TextStyle(
                                  color: _hasRealData(controller) ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2E7D32).withOpacity(0.3), // Vert principal
                          const Color(0xFF4CAF50).withOpacity(0.2), // Vert clair
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // Sélecteur de période - Responsive
                if (!isMobile) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: controller.selectedPeriod.value,
                        dropdownColor: const Color(0xFF1A1F2E),
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'today', child: Text('Aujourd\'hui')),
                          DropdownMenuItem(value: 'week', child: Text('Cette semaine')),
                          DropdownMenuItem(value: 'month', child: Text('Ce mois')),
                          DropdownMenuItem(value: 'year', child: Text('Cette année')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            controller.changePeriod(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
                // Bouton refresh
                Container(
                  margin: EdgeInsets.only(right: isMobile ? 8 : 16),
                  child: IconButton(
                    onPressed: controller.refreshData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'Actualiser',
                  ),
                ),
                // Menu mobile pour sélecteur de période
                if (isMobile)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) => controller.changePeriod(value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'today', child: Text('Aujourd\'hui')),
                      const PopupMenuItem(value: 'week', child: Text('Cette semaine')),
                      const PopupMenuItem(value: 'month', child: Text('Ce mois')),
                      const PopupMenuItem(value: 'year', child: Text('Cette année')),
                    ],
                  ),
              ],
            ),

          // Contenu principal - Responsive
          SliverPadding(
            padding: EdgeInsets.all(isMobile ? 12 : 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Message d'information sur la source des données
                if (!_hasRealData(controller)) _buildDataSourceInfo(isMobile),
                if (!_hasRealData(controller)) SizedBox(height: isMobile ? 16 : 24),

                // Alertes critiques
                if (controller.alertesCritiques.isNotEmpty) ...[
                  _buildAlertesCritiques(controller, isMobile),
                  SizedBox(height: isMobile ? 16 : 24),
                ],

                // KPIs principaux
                _buildKPIsPrincipaux(controller, isMobile, isTablet),
                SizedBox(height: isMobile ? 24 : 32),

                // Graphiques d'évolution
                _buildGraphiquesEvolution(controller, isMobile, isTablet),
                SizedBox(height: isMobile ? 24 : 32),

                // Performance et analyses
                _buildPerformanceAnalyses(controller, isMobile, isTablet),
                SizedBox(height: isMobile ? 24 : 32),

                // Tableaux de bord détaillés
                _buildTableauxDetailles(controller, isMobile, isTablet),
              ]),
            ),
          ),
        ],
      );
    });
  }

  bool _hasRealData(PdgDashboardController controller) {
    // Vérifier si nous avons des données réelles (non nulles et non par défaut)
    return controller.caAujourdhui.value != 75000.0 || controller.colisAujourdhui.value != 45;
  }

  Widget _buildDataSourceInfo([bool isMobile = false]) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withOpacity(0.1), // Vert clair
            const Color(0xFF2E7D32).withOpacity(0.05), // Vert principal
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF4CAF50),
            size: isMobile ? 20 : 24,
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Démonstration Actif',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                Text(
                  'Les données affichées sont des exemples. Ajoutez des colis, transactions et livraisons pour voir les vraies métriques.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isMobile ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertesCritiques(PdgDashboardController controller, [bool isMobile = false]) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE17055).withOpacity(0.1),
            const Color(0xFFD63031).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE17055).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFE17055),
                size: isMobile ? 20 : 24,
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'Alertes Critiques',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          ...controller.alertesCritiques
              .map((alerte) => AlertCard(
                    type: alerte['type'],
                    titre: alerte['titre'],
                    message: alerte['message'],
                    action: alerte['action'],
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildKPIsPrincipaux(PdgDashboardController controller, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs Clés de Performance',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),

        // KPIs financiers - Layout responsive
        if (isMobile)
          // Mobile : 2 colonnes
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'CA Aujourd\'huii',
                      value: '${controller.caAujourdhui.value.toStringAsFixed(0)} FCFA',
                      subtitle: 'Chiffre d\'affaires du jour',
                      icon: Icons.today,
                      color: const Color(0xFF1B5E20), // Vert très foncé
                      trend: controller.croissanceCA.value,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'CA Mensuel',
                      value: '${controller.caMois.value.toStringAsFixed(0)} FCFA',
                      subtitle: 'Chiffre d\'affaires du mois',
                      icon: Icons.calendar_month,
                      color: const Color(0xFF0D47A1), // Bleu foncé
                      trend: controller.croissanceCA.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'Marge Nette',
                      value: '${controller.margeNette.value.toStringAsFixed(0)} FCFA',
                      subtitle: 'Bénéfice après charges',
                      icon: Icons.trending_up,
                      color: const Color(0xFF004D40), // Teal foncé
                      trend: (controller.margeNette.value / controller.caTotal.value) * 100,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'Créances',
                      value: '${controller.creances.value.toStringAsFixed(0)} FCFA',
                      subtitle: 'Montant à recouvrer',
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFFB71C1C), // Rouge foncé
                      trend: -(controller.creances.value / controller.caTotal.value) * 100,
                    ),
                  ),
                ],
              ),
            ],
          )
        else if (isTablet)
          // Tablette : 3 colonnes
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'CA Aujourd\'hui',
                      value: '${controller.caAujourdhui.value.toStringAsFixed(0)} FCFA',
                      subtitle: 'Chiffre d\'affaires du jour',
                      icon: Icons.today,
                      color: const Color(0xFF1B5E20), // Vert très foncé
                      trend: controller.croissanceCA.value,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiCard(
                      title: 'CA Mensuel',
                      value: '${controller.caMois.value.toStringAsFixed(0)} FCFA',
                      subtitle: 'Chiffre d\'affaires du mois',
                      icon: Icons.calendar_month,
                      color: const Color(0xFF0D47A1), // Bleu foncé
                      trend: controller.croissanceCA.value,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KpiCard(
                      title: 'Marge Nette',
                      value: '${controller.margeNette.value.toStringAsFixed(0)} FCFA',
                      subtitle: 'Bénéfice après charges',
                      icon: Icons.trending_up,
                      color: const Color(0xFF004D40), // Teal foncé
                      trend: (controller.margeNette.value / controller.caTotal.value) * 100,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'Créances',
                      value: '${controller.creances.value.toStringAsFixed(0)} FCFA',
                      subtitle: 'Montant à recouvrer',
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFFB71C1C), // Rouge foncé
                      trend: -(controller.creances.value / controller.caTotal.value) * 100,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: Container()), // Espace vide
                ],
              ),
            ],
          )
        else
          // Desktop : 4 colonnes
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: 'CA Aujourd\'hui',
                  value: '${controller.caAujourdhui.value.toStringAsFixed(0)} FCFA',
                  subtitle: 'Chiffre d\'affaires du jour',
                  icon: Icons.today,
                  color: const Color(0xFF1B5E20), // Vert très foncé
                  trend: controller.croissanceCA.value,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'CA Mensuel',
                  value: '${controller.caMois.value.toStringAsFixed(0)} FCFA',
                  subtitle: 'Chiffre d\'affaires du mois',
                  icon: Icons.calendar_month,
                  color: const Color(0xFF0D47A1), // Bleu foncé
                  trend: controller.croissanceCA.value,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'Marge Nette',
                  value: '${controller.margeNette.value.toStringAsFixed(0)} FCFA',
                  subtitle: 'Bénéfice après charges',
                  icon: Icons.trending_up,
                  color: const Color(0xFF004D40), // Teal foncé
                  trend: (controller.margeNette.value / controller.caTotal.value) * 100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'Créances',
                  value: '${controller.creances.value.toStringAsFixed(0)} FCFA',
                  subtitle: 'Montant à recouvrer',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFFB71C1C), // Rouge foncé
                  trend: -(controller.creances.value / controller.caTotal.value) * 100,
                ),
              ),
            ],
          ),

        SizedBox(height: isMobile ? 12 : 16),

        // KPIs opérationnels - Layout responsive
        if (isMobile)
          // Mobile : 2 colonnes
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'Colis Aujourd\'hui',
                      value: '${controller.colisAujourdhui.value}',
                      subtitle: 'Colis traités aujourd\'hui',
                      icon: Icons.local_shipping,
                      color: const Color(0xFF4A148C), // Violet foncé
                      trend: controller.croissanceVolume.value,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'Taux de Livraison',
                      value: '${controller.tauxLivraison.value.toStringAsFixed(1)}%',
                      subtitle: 'Livraisons réussies',
                      icon: Icons.check_circle,
                      color: controller.tauxLivraison.value >= 90 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                      trend: controller.tauxLivraison.value - 90,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KpiCard(
                      title: 'Délai Moyen',
                      value: '${controller.delaiMoyen.value.toStringAsFixed(1)}h',
                      subtitle: 'Temps de livraison',
                      icon: Icons.schedule,
                      color: const Color(0xFFE65100), // Orange foncé
                      trend: -(controller.delaiMoyen.value - 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: KpiCard(
                      title: 'Clients Actifs',
                      value: '${controller.clientsActifs.value}',
                      subtitle: 'Clients ayant commandé',
                      icon: Icons.people,
                      color: const Color(0xFF1A237E), // Indigo foncé
                      trend: 0,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          // Desktop et Tablette : 4 colonnes
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: 'Colis Aujourd\'hui',
                  value: '${controller.colisAujourdhui.value}',
                  subtitle: 'Colis traités aujourd\'hui',
                  icon: Icons.local_shipping,
                  color: const Color(0xFF4A148C), // Violet foncé
                  trend: controller.croissanceVolume.value,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'Taux de Livraison',
                  value: '${controller.tauxLivraison.value.toStringAsFixed(1)}%',
                  subtitle: 'Livraisons réussies',
                  icon: Icons.check_circle,
                  color: controller.tauxLivraison.value >= 90 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                  trend: controller.tauxLivraison.value - 90,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'Délai Moyen',
                  value: '${controller.delaiMoyen.value.toStringAsFixed(1)}h',
                  subtitle: 'Temps de livraison',
                  icon: Icons.schedule,
                  color: const Color(0xFFE65100), // Orange foncé
                  trend: -(controller.delaiMoyen.value - 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'Clients Actifs',
                  value: '${controller.clientsActifs.value}',
                  subtitle: 'Clients ayant commandé',
                  icon: Icons.people,
                  color: const Color(0xFF1A237E), // Indigo foncé
                  trend: 0,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildGraphiquesEvolution(PdgDashboardController controller, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Évolution des Performances',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        if (isMobile)
          // Mobile : Graphiques empilés verticalement
          Column(
            children: [
              EvolutionChart(
                title: 'Évolution du Chiffre d\'Affaires',
                data: controller.evolutionCA,
                color: const Color(0xFF1B5E20), // Vert très foncé
                valueKey: 'ca',
                labelKey: 'label',
              ),
              const SizedBox(height: 16),
              EvolutionChart(
                title: 'Évolution du Volume',
                data: controller.evolutionVolume,
                color: const Color(0xFF0D47A1), // Bleu foncé
                valueKey: 'volume',
                labelKey: 'label',
              ),
              const SizedBox(height: 16),
              PerformanceChart(
                title: 'Statuts des Colis',
                data: controller.repartitionStatuts,
                type: ChartType.pie,
              ),
            ],
          )
        else if (isTablet)
          // Tablette : 2 graphiques par ligne
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: EvolutionChart(
                      title: 'Évolution du Chiffre d\'Affaires',
                      data: controller.evolutionCA,
                      color: const Color(0xFF1B5E20), // Vert très foncé
                      valueKey: 'ca',
                      labelKey: 'label',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: EvolutionChart(
                      title: 'Évolution du Volume',
                      data: controller.evolutionVolume,
                      color: const Color(0xFF0D47A1), // Bleu foncé
                      valueKey: 'volume',
                      labelKey: 'label',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PerformanceChart(
                      title: 'Statuts des Colis',
                      data: controller.repartitionStatuts,
                      type: ChartType.pie,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Container()), // Espace vide
                ],
              ),
            ],
          )
        else
          // Desktop : 3 graphiques en ligne
          Row(
            children: [
              // Évolution CA
              Expanded(
                flex: 2,
                child: EvolutionChart(
                  title: 'Évolution du Chiffre d\'Affaires',
                  data: controller.evolutionCA,
                  color: const Color(0xFF1B5E20), // Vert très foncé
                  valueKey: 'ca',
                  labelKey: 'label',
                ),
              ),
              const SizedBox(width: 16),

              // Évolution Volume
              Expanded(
                flex: 2,
                child: EvolutionChart(
                  title: 'Évolution du Volume',
                  data: controller.evolutionVolume,
                  color: const Color(0xFF0D47A1), // Bleu foncé
                  valueKey: 'volume',
                  labelKey: 'label',
                ),
              ),
              const SizedBox(width: 16),

              // Répartition statuts (Pie Chart)
              Expanded(
                child: PerformanceChart(
                  title: 'Statuts des Colis',
                  data: controller.repartitionStatuts,
                  type: ChartType.pie,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPerformanceAnalyses(PdgDashboardController controller, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyses de Performance',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        if (isMobile)
          // Mobile : Graphiques empilés verticalement
          Column(
            children: [
              PerformanceChart(
                title: 'Performance par Agence',
                data: controller.performanceAgences,
                type: ChartType.bar,
                valueKey: 'ca',
                labelKey: 'agence',
              ),
              const SizedBox(height: 16),
              PerformanceChart(
                title: 'Motifs d\'Échec',
                data: controller.motifsEchec,
                type: ChartType.horizontalBar,
                valueKey: 'count',
                labelKey: 'motif',
              ),
            ],
          )
        else
          // Desktop et Tablette : 2 graphiques côte à côte
          Row(
            children: [
              // Performance agences
              Expanded(
                child: PerformanceChart(
                  title: 'Performance par Agence',
                  data: controller.performanceAgences,
                  type: ChartType.bar,
                  valueKey: 'ca',
                  labelKey: 'agence',
                ),
              ),
              const SizedBox(width: 16),

              // Motifs d'échec
              Expanded(
                child: PerformanceChart(
                  title: 'Motifs d\'Échec',
                  data: controller.motifsEchec,
                  type: ChartType.horizontalBar,
                  valueKey: 'count',
                  labelKey: 'motif',
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTableauxDetailles(PdgDashboardController controller, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tableaux de Bord Détaillés',
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        if (isMobile)
          // Mobile : Tableaux empilés verticalement
          Column(
            children: [
              TopPerformersCard(
                title: 'Top Coursiers',
                data: controller.topCoursiers,
                nameKey: 'nom',
                valueKey: 'livraisons',
                subtitleKey: 'tauxReussite',
                icon: Icons.delivery_dining,
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 16),
              TopPerformersCard(
                title: 'Performance Agences',
                data: controller.performanceAgences.take(5).toList(),
                nameKey: 'agence',
                valueKey: 'ca',
                subtitleKey: 'volume',
                icon: Icons.business,
                color: const Color(0xFF2E7D32),
              ),
            ],
          )
        else
          // Desktop et Tablette : 2 tableaux côte à côte
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top coursiers
              Expanded(
                child: TopPerformersCard(
                  title: 'Top Coursiers',
                  data: controller.topCoursiers,
                  nameKey: 'nom',
                  valueKey: 'livraisons',
                  subtitleKey: 'tauxReussite',
                  icon: Icons.delivery_dining,
                  color: const Color(0xFF4A148C), // Violet foncé
                ),
              ),
              const SizedBox(width: 16),

              // Performance agences détaillée
              Expanded(
                child: TopPerformersCard(
                  title: 'Performance Agences',
                  data: controller.performanceAgences.take(5).toList(),
                  nameKey: 'agence',
                  valueKey: 'ca',
                  subtitleKey: 'volume',
                  icon: Icons.business,
                  color: const Color(0xFF1B5E20), // Vert très foncé // Vert principal
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Construit le drawer avec le menu de navigation
  Widget _buildDrawer(AuthController authController, bool isMobile) {
    return Drawer(
      backgroundColor: const Color(0xFF1A2E1A), // Fond vert foncé
      child: Column(
        children: [
          // Header avec thème vert
          Obx(() {
            final user = authController.currentUser.value;
            return UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E7D32), // Vert principal
                    Color(0xFF4CAF50), // Vert clair
                  ],
                ),
              ),
              accountName: Text(
                user?.nomComplet ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user != null && user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Dashboard PDG - Item actuel
                Container(
                  color: const Color(0xFF2E7D32).withOpacity(0.2),
                  child: ListTile(
                    leading: const Icon(Icons.analytics, color: Color(0xFF4CAF50)),
                    title: const Text(
                      'Tableau de Bord PDG',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                    onTap: () {
                      Get.back();
                    },
                  ),
                ),
                const Divider(color: Color(0xFF4CAF50)),

                // Navigation vers l'accueil
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white70),
                  title: const Text('Accueil', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Get.back();
                    Get.offAllNamed('/home');
                  },
                ),

                // Section Administration
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'ADMINISTRATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.people, color: Colors.white70),
                  title: const Text('Gestion des utilisateurs', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/home'); // Retour à l'accueil pour accéder au menu complet
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.business, color: Colors.white70),
                  title: const Text('Gestion des agences', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/home');
                  },
                ),

                // Section Opérations
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'OPÉRATIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.search, color: Colors.white70),
                  title: const Text('Suivi des colis', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/home');
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.white70),
                  title: const Text('Caisse', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/caisse');
                  },
                ),

                // Section Rapports
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'RAPPORTS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.white70),
                  title: const Text('Notifications', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Get.back();
                    Get.toNamed('/notifications');
                  },
                ),
              ],
            ),
          ),

          // Footer
          const Divider(color: Color(0xFF4CAF50)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authController.signOut();
              Get.offAllNamed('/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
