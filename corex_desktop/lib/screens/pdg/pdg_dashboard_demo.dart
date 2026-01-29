import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PdgDashboardDemo extends StatelessWidget {
  const PdgDashboardDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          // App Bar moderne avec glassmorphism
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6C5CE7).withOpacity(0.8),
                    const Color(0xFF74B9FF).withOpacity(0.6),
                  ],
                ),
              ),
              child: const FlexibleSpaceBar(
                title: Text(
                  'Tableau de Bord PDG - DEMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            actions: [
              // Sélecteur de période
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
                    value: 'today',
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
                      // Action de changement de période
                    },
                  ),
                ),
              ),
              // Bouton refresh
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: () {
                    Get.snackbar('Actualisation', 'Données mises à jour !');
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Actualiser',
                ),
              ),
            ],
          ),

          // Contenu principal
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPIs principaux
                _buildKPIsPrincipaux(),
                const SizedBox(height: 32),

                // Message de démonstration
                _buildDemoMessage(),
                const SizedBox(height: 32),

                // Graphiques de démonstration
                _buildGraphiquesDemo(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIsPrincipaux() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Indicateurs Clés de Performance - DEMO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Première ligne - KPIs financiers
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'CA Aujourd\'hui',
                value: '75 000 FCFA',
                subtitle: 'Chiffre d\'affaires du jour',
                icon: Icons.today,
                color: const Color(0xFF00B894),
                trend: 12.5,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                title: 'CA Mensuel',
                value: '850 000 FCFA',
                subtitle: 'Chiffre d\'affaires du mois',
                icon: Icons.calendar_month,
                color: const Color(0xFF6C5CE7),
                trend: 8.3,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                title: 'Marge Nette',
                value: '125 000 FCFA',
                subtitle: 'Bénéfice après charges',
                icon: Icons.trending_up,
                color: const Color(0xFF74B9FF),
                trend: 15.2,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                title: 'Créances',
                value: '45 000 FCFA',
                subtitle: 'Montant à recouvrer',
                icon: Icons.account_balance_wallet,
                color: const Color(0xFFE17055),
                trend: -5.1,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Deuxième ligne - KPIs opérationnels
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Colis Aujourd\'hui',
                value: '45',
                subtitle: 'Colis traités aujourd\'hui',
                icon: Icons.local_shipping,
                color: const Color(0xFF00CEC9),
                trend: 18.7,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                title: 'Taux de Livraison',
                value: '92.5%',
                subtitle: 'Livraisons réussies',
                icon: Icons.check_circle,
                color: const Color(0xFF00B894),
                trend: 2.3,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                title: 'Délai Moyen',
                value: '18.5h',
                subtitle: 'Temps de livraison',
                icon: Icons.schedule,
                color: const Color(0xFFFDAB3D),
                trend: -3.2,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                title: 'Clients Actifs',
                value: '245',
                subtitle: 'Clients ayant commandé',
                icon: Icons.people,
                color: const Color(0xFFA29BFE),
                trend: 12.8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec icône et trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              _buildTrendIndicator(trend, color),
            ],
          ),

          const SizedBox(height: 20),

          // Titre
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // Valeur principale
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Sous-titre
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(double trend, Color baseColor) {
    final isPositive = trend > 0;
    final isNeutral = trend == 0;

    Color trendColor;
    IconData trendIcon;

    if (isNeutral) {
      trendColor = Colors.grey;
      trendIcon = Icons.remove;
    } else if (isPositive) {
      trendColor = const Color(0xFF00B894);
      trendIcon = Icons.trending_up;
    } else {
      trendColor = const Color(0xFFE17055);
      trendIcon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trendIcon,
            color: trendColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${trend.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: trendColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.1),
            const Color(0xFF74B9FF).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF6C5CE7),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Mode Démonstration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ce tableau de bord fonctionne avec des données de démonstration.\n'
            'Les vrais KPIs seront disponibles une fois Firebase configuré et les données réelles ajoutées.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Get.snackbar(
                'Information',
                'Le tableau de bord PDG est opérationnel ! Ajoutez des données réelles pour voir les vrais KPIs.',
                backgroundColor: const Color(0xFF6C5CE7),
                colorText: Colors.white,
                duration: const Duration(seconds: 4),
              );
            },
            icon: const Icon(Icons.rocket_launch),
            label: const Text('Tableau de Bord Opérationnel !'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphiquesDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Graphiques de Performance - DEMO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDemoChart('Évolution CA', Icons.show_chart, const Color(0xFF6C5CE7)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDemoChart('Volume Colis', Icons.bar_chart, const Color(0xFF00B894)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDemoChart('Performance Agences', Icons.business, const Color(0xFF74B9FF)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoChart(String title, IconData icon, Color color) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F2E).withOpacity(0.8),
            const Color(0xFF2D3748).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: color.withOpacity(0.3),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Graphique de démonstration',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
