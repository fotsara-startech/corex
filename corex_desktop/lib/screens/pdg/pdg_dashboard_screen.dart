// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:corex_shared/controllers/pdg_dashboard_controller.dart';
// import 'package:corex_shared/controllers/auth_controller.dart';
// import '../../widgets/pdg/kpi_card.dart';
// import '../../widgets/pdg/evolution_chart.dart';
// import '../../widgets/pdg/performance_chart.dart';
// import '../../widgets/pdg/alert_card.dart';
// import '../../widgets/pdg/top_performers_card.dart';

// class PdgDashboardScreen extends StatelessWidget {
//   final bool isEmbedded;

//   const PdgDashboardScreen({Key? key, this.isEmbedded = false}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.put(PdgDashboardController());
//     final authController = Get.find<AuthController>();
//     final screenWidth = MediaQuery.of(context).size.width;
//     final isMobile = screenWidth < 768;
//     final isTablet = screenWidth >= 768 && screenWidth < 1024;

//     // Si c'est en mode embedded, retourner seulement le contenu
//     if (isEmbedded) {
//       return _buildDashboardContent(controller, authController, isMobile, isTablet);
//     }

//     // Sinon, retourner le Scaffold complet
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A1A0E), // Fond vert foncé
//       drawer: _buildDrawer(authController, isMobile), // Ajout du drawer
//       body: _buildDashboardContent(controller, authController, isMobile, isTablet),
//     );
//   }

//   Widget _buildDashboardContent(PdgDashboardController controller, AuthController authController, bool isMobile, bool isTablet) {
//     return Obx(() {
//       if (controller.isLoading.value) {
//         return const Center(
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)), // Vert principal
//           ),
//         );
//       }

//       return CustomScrollView(
//         slivers: [
//           // App Bar moderne avec glassmorphism - Responsive (seulement si pas embedded)
//           if (!isEmbedded)
//             SliverAppBar(
//               expandedHeight: isMobile ? 80 : 120,
//               floating: false,
//               pinned: true,
//               backgroundColor: Colors.transparent,
//               flexibleSpace: Container(
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                     colors: [
//                       const Color(0xFF2E7D32).withOpacity(0.8), // Vert principal
//                       const Color(0xFF4CAF50).withOpacity(0.6), // Vert clair
//                     ],
//                   ),
//                 ),
//                 child: FlexibleSpaceBar(
//                   title: isMobile
//                       ? Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Dashboard PDG',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 18,
//                               ),
//                             ),
//                             const SizedBox(height: 2),
//                             // Indicateur de source des données - Mobile
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                               decoration: BoxDecoration(
//                                 color: _hasRealData(controller) ? const Color(0xFF4CAF50).withOpacity(0.3) : const Color(0xFFFF9800).withOpacity(0.3),
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                   color: _hasRealData(controller) ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
//                                 ),
//                               ),
//                               child: Text(
//                                 _hasRealData(controller) ? 'RÉEL' : 'DÉMO',
//                                 style: TextStyle(
//                                   color: _hasRealData(controller) ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
//                                   fontSize: 8,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         )
//                       : Row(
//                           children: [
//                             const Text(
//                               'Tableau de Bord PDG',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 24,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             // Indicateur de source des données - Desktop
//                             Container(
//                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                               decoration: BoxDecoration(
//                                 color: _hasRealData(controller) ? const Color(0xFF4CAF50).withOpacity(0.3) : const Color(0xFFFF9800).withOpacity(0.3),
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: _hasRealData(controller) ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
//                                 ),
//                               ),
//                               child: Text(
//                                 _hasRealData(controller) ? 'DONNÉES RÉELLES' : 'MODE DÉMO',
//                                 style: TextStyle(
//                                   color: _hasRealData(controller) ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                   background: Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           const Color(0xFF2E7D32).withOpacity(0.3), // Vert principal
//                           const Color(0xFF4CAF50).withOpacity(0.2), // Vert clair
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               actions: [
//                 // Sélecteur de période - Responsive
//                 if (!isMobile) ...[
//                   Container(
//                     margin: const EdgeInsets.only(right: 16),
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.2),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.white.withOpacity(0.3)),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: controller.selectedPeriod.value,
//                         dropdownColor: const Color(0xFF1A1F2E),
//                         style: const TextStyle(color: Colors.white),
//                         icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
//                         items: const [
//                           DropdownMenuItem(value: 'today', child: Text('Aujourd\'hui')),
//                           DropdownMenuItem(value: 'week', child: Text('Cette semaine')),
//                           DropdownMenuItem(value: 'month', child: Text('Ce mois')),
//                           DropdownMenuItem(value: 'year', child: Text('Cette année')),
//                         ],
//                         onChanged: (value) {
//                           if (value != null) {
//                             controller.changePeriod(value);
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                 ],
//                 // Bouton refresh
//                 Container(
//                   margin: EdgeInsets.only(right: isMobile ? 8 : 16),
//                   child: IconButton(
//                     onPressed: controller.refreshData,
//                     icon: const Icon(Icons.refresh, color: Colors.white),
//                     tooltip: 'Actualiser',
//                   ),
//                 ),
//                 // Menu mobile pour sélecteur de période
//                 if (isMobile)
//                   PopupMenuButton<String>(
//                     icon: const Icon(Icons.more_vert, color: Colors.white),
//                     onSelected: (value) => controller.changePeriod(value),
//                     itemBuilder: (context) => [
//                       const PopupMenuItem(value: 'today', child: Text('Aujourd\'hui')),
//                       const PopupMenuItem(value: 'week', child: Text('Cette semaine')),
//                       const PopupMenuItem(value: 'month', child: Text('Ce mois')),
//                       const PopupMenuItem(value: 'year', child: Text('Cette année')),
//                     ],
//                   ),
//               ],
//             ),

//           // Contenu principal - Responsive
//           SliverPadding(
//             padding: EdgeInsets.all(isMobile ? 12 : 24),
//             sliver: SliverList(
//               delegate: SliverChildListDelegate([
//                 // Message d'information sur la source des données
//                 if (!_hasRealData(controller)) _buildDataSourceInfo(isMobile),
//                 if (!_hasRealData(controller)) SizedBox(height: isMobile ? 16 : 24),

//                 // Alertes critiques
//                 if (controller.alertesCritiques.isNotEmpty) ...[
//                   _buildAlertesCritiques(controller, isMobile),
//                   SizedBox(height: isMobile ? 16 : 24),
//                 ],

//                 // KPIs principaux
//                 _buildKPIsPrincipaux(controller, isMobile, isTablet),
//                 SizedBox(height: isMobile ? 24 : 32),

//                 // Graphiques d'évolution
//                 _buildGraphiquesEvolution(controller, isMobile, isTablet),
//                 SizedBox(height: isMobile ? 24 : 32),

//                 // Performance et analyses
//                 _buildPerformanceAnalyses(controller, isMobile, isTablet),
//                 SizedBox(height: isMobile ? 24 : 32),

//                 // Tableaux de bord détaillés
//                 _buildTableauxDetailles(controller, isMobile, isTablet),
//               ]),
//             ),
//           ),
//         ],
//       );
//     });
//   }

//   bool _hasRealData(PdgDashboardController controller) {
//     // Vérifier si nous avons des données réelles (non nulles et non par défaut)
//     return controller.caAujourdhui.value != 75000.0 || controller.colisAujourdhui.value != 45;
//   }

//   Widget _buildDataSourceInfo([bool isMobile = false]) {
//     return Container(
//       padding: EdgeInsets.all(isMobile ? 16 : 20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             const Color(0xFF4CAF50).withOpacity(0.1), // Vert clair
//             const Color(0xFF2E7D32).withOpacity(0.05), // Vert principal
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             Icons.info_outline,
//             color: const Color(0xFF4CAF50),
//             size: isMobile ? 20 : 24,
//           ),
//           SizedBox(width: isMobile ? 12 : 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Mode Démonstration Actif',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: isMobile ? 14 : 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: isMobile ? 2 : 4),
//                 Text(
//                   'Les données affichées sont des exemples. Ajoutez des colis, transactions et livraisons pour voir les vraies métriques.',
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.8),
//                     fontSize: isMobile ? 12 : 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAlertesCritiques(PdgDashboardController controller, [bool isMobile = false]) {
//     return Container(
//       padding: EdgeInsets.all(isMobile ? 16 : 20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             const Color(0xFFE17055).withOpacity(0.1),
//             const Color(0xFFD63031).withOpacity(0.05),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE17055).withOpacity(0.3)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.warning_amber_rounded,
//                 color: const Color(0xFFE17055),
//                 size: isMobile ? 20 : 24,
//               ),
//               SizedBox(width: isMobile ? 8 : 12),
//               Text(
//                 'Alertes Critiques',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: isMobile ? 16 : 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: isMobile ? 12 : 16),
//           ...controller.alertesCritiques
//               .map((alerte) => AlertCard(
//                     type: alerte['type'],
//                     titre: alerte['titre'],
//                     message: alerte['message'],
//                     action: alerte['action'],
//                   ))
//               .toList(),
//         ],
//       ),
//     );
//   }

//   Widget _buildKPIsPrincipaux(PdgDashboardController controller, bool isMobile, bool isTablet) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Indicateurs Clés de Performance',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: isMobile ? 18 : 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: isMobile ? 12 : 16),

//         // KPIs financiers - Layout responsive
//         if (isMobile)
//           // Mobile : 2 colonnes
//           Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: KpiCard(
//                       title: 'CA Aujourd\'huii',
//                       value: '${controller.caAujourdhui.value.toStringAsFixed(0)} FCFA',
//                       subtitle: 'Chiffre d\'affaires du jour',
//                       icon: Icons.today,
//                       color: const Color(0xFF1B5E20), // Vert très foncé
//                       trend: controller.croissanceCA.value,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: KpiCard(
//                       title: 'CA Mensuel',
//                       value: '${controller.caMois.value.toStringAsFixed(0)} FCFA',
//                       subtitle: 'Chiffre d\'affaires du mois',
//                       icon: Icons.calendar_month,
//                       color: const Color(0xFF0D47A1), // Bleu foncé
//                       trend: controller.croissanceCA.value,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: KpiCard(
//                       title: 'Marge Nette',
//                       value: '${controller.margeNette.value.toStringAsFixed(0)} FCFA',
//                       subtitle: 'Bénéfice après charges',
//                       icon: Icons.trending_up,
//                       color: const Color(0xFF004D40), // Teal foncé
//                       trend: (controller.margeNette.value / controller.caTotal.value) * 100,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: KpiCard(
//                       title: 'Créances',
//                       value: '${controller.creances.value.toStringAsFixed(0)} FCFA',
//                       subtitle: 'Montant à recouvrer',
//                       icon: Icons.account_balance_wallet,
//                       color: const Color(0xFFB71C1C), // Rouge foncé
//                       trend: -(controller.creances.value / controller.caTotal.value) * 100,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           )
//         else if (isTablet)
//           // Tablette : 3 colonnes
//           Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: KpiCard(
//                       title: 'CA Aujourd\'hui',
//                       value: '${controller.caAujourdhui.value.toStringAsFixed(0)} FCFA',
//                       subtitle: 'Chiffre d\'affaires du jour',
//                       icon: Icons.today,
//                       color: const Color(0xFF1B5E20), // Vert très foncé
//                       trend: controller.croissanceCA.value,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: KpiCard(
//                       title: 'CA Mensuel',
//                       value: '${controller.caMois.value.toStringAsFixed(0)} FCFA',
//                       subtitle: 'Chiffre d\'affaires du mois',
//                       icon: Icons.calendar_month,
//                       color: const Color(0xFF0D47A1), // Bleu foncé
//                       trend: controller.croissanceCA.value,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: KpiCard(
//                       title: 'Marge Nette',
//                       value: '${controller.margeNette.value.toStringAsFixed(0)} FCFA',
//                       subtitle: 'Bénéfice après charges',
//                       icon: Icons.trending_up,
//                       color: const Color(0xFF004D40), // Teal foncé
//                       trend: (controller.margeNette.value / controller.caTotal.value) * 100,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: KpiCard(
//                       title: 'Créances',
//                       value: '${controller.creances.value.toStringAsFixed(0)} FCFA',
//                       subtitle: 'Montant à recouvrer',
//                       icon: Icons.account_balance_wallet,
//                       color: const Color(0xFFB71C1C), // Rouge foncé
//                       trend: -(controller.creances.value / controller.caTotal.value) * 100,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(flex: 2, child: Container()), // Espace vide
//                 ],
//               ),
//             ],
//           )
//         else
//           // Desktop : 4 colonnes
//           Row(
//             children: [
//               Expanded(
//                 child: KpiCard(
//                   title: 'CA Aujourd\'hui',
//                   value: '${controller.caAujourdhui.value.toStringAsFixed(0)} FCFA',
//                   subtitle: 'Chiffre d\'affaires du jour',
//                   icon: Icons.today,
//                   color: const Color(0xFF1B5E20), // Vert très foncé
//                   trend: controller.croissanceCA.value,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: KpiCard(
//                   title: 'CA Mensuel',
//                   value: '${controller.caMois.value.toStringAsFixed(0)} FCFA',
//                   subtitle: 'Chiffre d\'affaires du mois',
//                   icon: Icons.calendar_month,
//                   color: const Color(0xFF0D47A1), // Bleu foncé
//                   trend: controller.croissanceCA.value,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: KpiCard(
//                   title: 'Marge Nette',
//                   value: '${controller.margeNette.value.toStringAsFixed(0)} FCFA',
//                   subtitle: 'Bénéfice après charges',
//                   icon: Icons.trending_up,
//                   color: const Color(0xFF004D40), // Teal foncé
//                   trend: (controller.margeNette.value / controller.caTotal.value) * 100,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: KpiCard(
//                   title: 'Créances',
//                   value: '${controller.creances.value.toStringAsFixed(0)} FCFA',
//                   subtitle: 'Montant à recouvrer',
//                   icon: Icons.account_balance_wallet,
//                   color: const Color(0xFFB71C1C), // Rouge foncé
//                   trend: -(controller.creances.value / controller.caTotal.value) * 100,
//                 ),
//               ),
//             ],
//           ),

//         SizedBox(height: isMobile ? 12 : 16),

//         // KPIs opérationnels - Layout responsive
//         if (isMobile)
//           // Mobile : 2 colonnes
//           Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: KpiCard(
//                       title: 'Colis Aujourd\'hui',
//                       value: '${controller.colisAujourdhui.value}',
//                       subtitle: 'Colis traités aujourd\'hui',
//                       icon: Icons.local_shipping,
//                       color: const Color(0xFF4A148C), // Violet foncé
//                       trend: controller.croissanceVolume.value,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: KpiCard(
//                       title: 'Taux de Livraison',
//                       value: '${controller.tauxLivraison.value.toStringAsFixed(1)}%',
//                       subtitle: 'Livraisons réussies',
//                       icon: Icons.check_circle,
//                       color: controller.tauxLivraison.value >= 90 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
//                       trend: controller.tauxLivraison.value - 90,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: KpiCard(
//                       title: 'Délai Moyen',
//                       value: '${controller.delaiMoyen.value.toStringAsFixed(1)}h',
//                       subtitle: 'Temps de livraison',
//                       icon: Icons.schedule,
//                       color: const Color(0xFFE65100), // Orange foncé
//                       trend: -(controller.delaiMoyen.value - 24),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: KpiCard(
//                       title: 'Clients Actifs',
//                       value: '${controller.clientsActifs.value}',
//                       subtitle: 'Clients ayant commandé',
//                       icon: Icons.people,
//                       color: const Color(0xFF1A237E), // Indigo foncé
//                       trend: 0,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           )
//         else
//           // Desktop et Tablette : 4 colonnes
//           Row(
//             children: [
//               Expanded(
//                 child: KpiCard(
//                   title: 'Colis Aujourd\'hui',
//                   value: '${controller.colisAujourdhui.value}',
//                   subtitle: 'Colis traités aujourd\'hui',
//                   icon: Icons.local_shipping,
//                   color: const Color(0xFF4A148C), // Violet foncé
//                   trend: controller.croissanceVolume.value,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: KpiCard(
//                   title: 'Taux de Livraison',
//                   value: '${controller.tauxLivraison.value.toStringAsFixed(1)}%',
//                   subtitle: 'Livraisons réussies',
//                   icon: Icons.check_circle,
//                   color: controller.tauxLivraison.value >= 90 ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
//                   trend: controller.tauxLivraison.value - 90,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: KpiCard(
//                   title: 'Délai Moyen',
//                   value: '${controller.delaiMoyen.value.toStringAsFixed(1)}h',
//                   subtitle: 'Temps de livraison',
//                   icon: Icons.schedule,
//                   color: const Color(0xFFE65100), // Orange foncé
//                   trend: -(controller.delaiMoyen.value - 24),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: KpiCard(
//                   title: 'Clients Actifs',
//                   value: '${controller.clientsActifs.value}',
//                   subtitle: 'Clients ayant commandé',
//                   icon: Icons.people,
//                   color: const Color(0xFF1A237E), // Indigo foncé
//                   trend: 0,
//                 ),
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   Widget _buildGraphiquesEvolution(PdgDashboardController controller, bool isMobile, bool isTablet) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Évolution des Performances',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: isMobile ? 18 : 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: isMobile ? 12 : 16),
//         if (isMobile)
//           // Mobile : Graphiques empilés verticalement
//           Column(
//             children: [
//               EvolutionChart(
//                 title: 'Évolution du Chiffre d\'Affaires',
//                 data: controller.evolutionCA,
//                 color: const Color(0xFF1B5E20), // Vert très foncé
//                 valueKey: 'ca',
//                 labelKey: 'label',
//               ),
//               const SizedBox(height: 16),
//               EvolutionChart(
//                 title: 'Évolution du Volume',
//                 data: controller.evolutionVolume,
//                 color: const Color(0xFF0D47A1), // Bleu foncé
//                 valueKey: 'volume',
//                 labelKey: 'label',
//               ),
//               const SizedBox(height: 16),
//               PerformanceChart(
//                 title: 'Statuts des Colis',
//                 data: controller.repartitionStatuts,
//                 type: ChartType.pie,
//               ),
//             ],
//           )
//         else if (isTablet)
//           // Tablette : 2 graphiques par ligne
//           Column(
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: EvolutionChart(
//                       title: 'Évolution du Chiffre d\'Affaires',
//                       data: controller.evolutionCA,
//                       color: const Color(0xFF1B5E20), // Vert très foncé
//                       valueKey: 'ca',
//                       labelKey: 'label',
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: EvolutionChart(
//                       title: 'Évolution du Volume',
//                       data: controller.evolutionVolume,
//                       color: const Color(0xFF0D47A1), // Bleu foncé
//                       valueKey: 'volume',
//                       labelKey: 'label',
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: PerformanceChart(
//                       title: 'Statuts des Colis',
//                       data: controller.repartitionStatuts,
//                       type: ChartType.pie,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(child: Container()), // Espace vide
//                 ],
//               ),
//             ],
//           )
//         else
//           // Desktop : 3 graphiques en ligne
//           Row(
//             children: [
//               // Évolution CA
//               Expanded(
//                 flex: 2,
//                 child: EvolutionChart(
//                   title: 'Évolution du Chiffre d\'Affaires',
//                   data: controller.evolutionCA,
//                   color: const Color(0xFF1B5E20), // Vert très foncé
//                   valueKey: 'ca',
//                   labelKey: 'label',
//                 ),
//               ),
//               const SizedBox(width: 16),

//               // Évolution Volume
//               Expanded(
//                 flex: 2,
//                 child: EvolutionChart(
//                   title: 'Évolution du Volume',
//                   data: controller.evolutionVolume,
//                   color: const Color(0xFF0D47A1), // Bleu foncé
//                   valueKey: 'volume',
//                   labelKey: 'label',
//                 ),
//               ),
//               const SizedBox(width: 16),

//               // Répartition statuts (Pie Chart)
//               Expanded(
//                 child: PerformanceChart(
//                   title: 'Statuts des Colis',
//                   data: controller.repartitionStatuts,
//                   type: ChartType.pie,
//                 ),
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   Widget _buildPerformanceAnalyses(PdgDashboardController controller, bool isMobile, bool isTablet) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Analyses de Performance',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: isMobile ? 18 : 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: isMobile ? 12 : 16),
//         if (isMobile)
//           // Mobile : Graphiques empilés verticalement
//           Column(
//             children: [
//               PerformanceChart(
//                 title: 'Performance par Agence',
//                 data: controller.performanceAgences,
//                 type: ChartType.bar,
//                 valueKey: 'ca',
//                 labelKey: 'agence',
//               ),
//               const SizedBox(height: 16),
//               PerformanceChart(
//                 title: 'Motifs d\'Échec',
//                 data: controller.motifsEchec,
//                 type: ChartType.horizontalBar,
//                 valueKey: 'count',
//                 labelKey: 'motif',
//               ),
//             ],
//           )
//         else
//           // Desktop et Tablette : 2 graphiques côte à côte
//           Row(
//             children: [
//               // Performance agences
//               Expanded(
//                 child: PerformanceChart(
//                   title: 'Performance par Agence',
//                   data: controller.performanceAgences,
//                   type: ChartType.bar,
//                   valueKey: 'ca',
//                   labelKey: 'agence',
//                 ),
//               ),
//               const SizedBox(width: 16),

//               // Motifs d'échec
//               Expanded(
//                 child: PerformanceChart(
//                   title: 'Motifs d\'Échec',
//                   data: controller.motifsEchec,
//                   type: ChartType.horizontalBar,
//                   valueKey: 'count',
//                   labelKey: 'motif',
//                 ),
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   Widget _buildTableauxDetailles(PdgDashboardController controller, bool isMobile, bool isTablet) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Tableaux de Bord Détaillés',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: isMobile ? 18 : 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         SizedBox(height: isMobile ? 12 : 16),
//         if (isMobile)
//           // Mobile : Tableaux empilés verticalement
//           Column(
//             children: [
//               TopPerformersCard(
//                 title: 'Top Coursiers',
//                 data: controller.topCoursiers,
//                 nameKey: 'nom',
//                 valueKey: 'livraisons',
//                 subtitleKey: 'tauxReussite',
//                 icon: Icons.delivery_dining,
//                 color: const Color(0xFF4CAF50),
//               ),
//               const SizedBox(height: 16),
//               TopPerformersCard(
//                 title: 'Performance Agences',
//                 data: controller.performanceAgences.take(5).toList(),
//                 nameKey: 'agence',
//                 valueKey: 'ca',
//                 subtitleKey: 'volume',
//                 icon: Icons.business,
//                 color: const Color(0xFF2E7D32),
//               ),
//             ],
//           )
//         else
//           // Desktop et Tablette : 2 tableaux côte à côte
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Top coursiers
//               Expanded(
//                 child: TopPerformersCard(
//                   title: 'Top Coursiers',
//                   data: controller.topCoursiers,
//                   nameKey: 'nom',
//                   valueKey: 'livraisons',
//                   subtitleKey: 'tauxReussite',
//                   icon: Icons.delivery_dining,
//                   color: const Color(0xFF4A148C), // Violet foncé
//                 ),
//               ),
//               const SizedBox(width: 16),

//               // Performance agences détaillée
//               Expanded(
//                 child: TopPerformersCard(
//                   title: 'Performance Agences',
//                   data: controller.performanceAgences.take(5).toList(),
//                   nameKey: 'agence',
//                   valueKey: 'ca',
//                   subtitleKey: 'volume',
//                   icon: Icons.business,
//                   color: const Color(0xFF1B5E20), // Vert très foncé // Vert principal
//                 ),
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   /// Construit le drawer avec le menu de navigation
//   Widget _buildDrawer(AuthController authController, bool isMobile) {
//     return Drawer(
//       backgroundColor: const Color(0xFF1A2E1A), // Fond vert foncé
//       child: Column(
//         children: [
//           // Header avec thème vert
//           Obx(() {
//             final user = authController.currentUser.value;
//             return UserAccountsDrawerHeader(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Color(0xFF2E7D32), // Vert principal
//                     Color(0xFF4CAF50), // Vert clair
//                   ],
//                 ),
//               ),
//               accountName: Text(
//                 user?.nomComplet ?? '',
//                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               accountEmail: Text(user?.email ?? ''),
//               currentAccountPicture: CircleAvatar(
//                 backgroundColor: Colors.white,
//                 child: Text(
//                   user != null && user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?',
//                   style: const TextStyle(
//                     fontSize: 32,
//                     color: Color(0xFF2E7D32),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             );
//           }),

//           // Menu items
//           Expanded(
//             child: ListView(
//               padding: EdgeInsets.zero,
//               children: [
//                 // Dashboard PDG - Item actuel
//                 Container(
//                   color: const Color(0xFF2E7D32).withOpacity(0.2),
//                   child: ListTile(
//                     leading: const Icon(Icons.analytics, color: Color(0xFF4CAF50)),
//                     title: const Text(
//                       'Tableau de Bord PDG',
//                       style: TextStyle(
//                         color: Color(0xFF4CAF50),
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     trailing: const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
//                     onTap: () {
//                       Get.back();
//                     },
//                   ),
//                 ),
//                 const Divider(color: Color(0xFF4CAF50)),

//                 // Navigation vers l'accueil
//                 ListTile(
//                   leading: const Icon(Icons.home, color: Colors.white70),
//                   title: const Text('Accueil', style: TextStyle(color: Colors.white70)),
//                   onTap: () {
//                     Get.back();
//                     Get.offAllNamed('/home');
//                   },
//                 ),

//                 // Section Administration
//                 const Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Text(
//                     'ADMINISTRATION',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF4CAF50),
//                     ),
//                   ),
//                 ),

//                 ListTile(
//                   leading: const Icon(Icons.people, color: Colors.white70),
//                   title: const Text('Gestion des utilisateurs', style: TextStyle(color: Colors.white70)),
//                   onTap: () {
//                     Get.back();
//                     Get.toNamed('/home'); // Retour à l'accueil pour accéder au menu complet
//                   },
//                 ),

//                 ListTile(
//                   leading: const Icon(Icons.business, color: Colors.white70),
//                   title: const Text('Gestion des agences', style: TextStyle(color: Colors.white70)),
//                   onTap: () {
//                     Get.back();
//                     Get.toNamed('/home');
//                   },
//                 ),

//                 // Section Opérations
//                 const Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Text(
//                     'OPÉRATIONS',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF4CAF50),
//                     ),
//                   ),
//                 ),

//                 ListTile(
//                   leading: const Icon(Icons.search, color: Colors.white70),
//                   title: const Text('Suivi des colis', style: TextStyle(color: Colors.white70)),
//                   onTap: () {
//                     Get.back();
//                     Get.toNamed('/home');
//                   },
//                 ),

//                 ListTile(
//                   leading: const Icon(Icons.attach_money, color: Colors.white70),
//                   title: const Text('Caisse', style: TextStyle(color: Colors.white70)),
//                   onTap: () {
//                     Get.back();
//                     Get.toNamed('/caisse');
//                   },
//                 ),

//                 // Section Rapports
//                 const Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Text(
//                     'RAPPORTS',
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF4CAF50),
//                     ),
//                   ),
//                 ),

//                 ListTile(
//                   leading: const Icon(Icons.notifications, color: Colors.white70),
//                   title: const Text('Notifications', style: TextStyle(color: Colors.white70)),
//                   onTap: () {
//                     Get.back();
//                     Get.toNamed('/notifications');
//                   },
//                 ),
//               ],
//             ),
//           ),

//           // Footer
//           const Divider(color: Color(0xFF4CAF50)),
//           ListTile(
//             leading: const Icon(Icons.logout, color: Colors.red),
//             title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
//             onTap: () async {
//               await authController.signOut();
//               Get.offAllNamed('/login');
//             },
//           ),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/pdg_dashboard_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import '../../widgets/pdg/kpi_card.dart';
import '../../widgets/pdg/evolution_chart.dart';
import '../../widgets/pdg/performance_chart.dart';
import '../../widgets/pdg/alert_card.dart';
import '../../widgets/pdg/top_performers_card.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
class _C {
  // Backgrounds
  static const bg = Color(0xFF060C07);
  static const surface = Color(0xFF0D1610);
  static const card = Color(0xFF111D12);
  static const cardHover = Color(0xFF162019);
  static const border = Color(0xFF1E2E1F);

  // Accent — vert forêt lumineux
  static const accent = Color(0xFF3DCC5A);
  static const accentDim = Color(0xFF1A7A30);
  static const accentBg = Color(0xFF0D2B14);

  // Sémantiques
  static const danger = Color(0xFFFF4444);
  static const warning = Color(0xFFFFAA00);
  static const info = Color(0xFF3B8BFF);
  static const muted = Color(0xFF3B7D3B); // vert désaturé

  // Texte
  static const textPrimary = Color(0xFFF0F5F1);
  static const textSecondary = Color(0xFF6B8C6C);
  static const textTertiary = Color(0xFF3A5C3A);

  // Dividers / Grids
  static const divider = Color(0xFF162019);
}

// ─────────────────────────────────────────────
//  TYPOGRAPHY HELPERS
// ─────────────────────────────────────────────
class _T {
  static const _base = TextStyle(fontFamily: 'DM Sans', color: _C.textPrimary);

  static TextStyle display = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle title = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static TextStyle subtitle = _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: _C.textSecondary, letterSpacing: 0.3);
  static TextStyle label = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: _C.textTertiary, letterSpacing: 1.2);
  static TextStyle body = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400, color: _C.textSecondary);
  static TextStyle mono = _base.copyWith(fontFamily: 'JetBrains Mono', fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle monoSm = _base.copyWith(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.w500);
}

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class PdgDashboardScreen extends StatelessWidget {
  final bool isEmbedded;
  const PdgDashboardScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PdgDashboardController());
    final authController = Get.find<AuthController>();
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 768;
    final isTablet = w >= 768 && w < 1200;

    if (isEmbedded) {
      return _body(controller, authController, isMobile, isTablet);
    }

    return Scaffold(
      backgroundColor: _C.bg,
      drawer: _Drawer(authController: authController),
      body: _body(controller, authController, isMobile, isTablet),
    );
  }

  Widget _body(PdgDashboardController ctrl, AuthController auth, bool isMobile, bool isTablet) {
    return Obx(() {
      if (ctrl.isLoading.value) {
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_C.accent),
            ),
          ),
        );
      }

      final pad = isMobile ? 16.0 : 28.0;

      return CustomScrollView(
        slivers: [
          if (!isEmbedded)
            _TopBar(
              controller: ctrl,
              authController: auth,
              isMobile: isMobile,
            ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Demo banner ──────────────────────────────────
                if (!_hasRealData(ctrl)) ...[
                  _DemoBanner(),
                  const SizedBox(height: 20),
                ],

                // ── Alertes ──────────────────────────────────────
                if (ctrl.alertesCritiques.isNotEmpty) ...[
                  _AlertsSection(controller: ctrl, isMobile: isMobile),
                  const SizedBox(height: 28),
                ],

                // ── KPIs ─────────────────────────────────────────
                _SectionHeader(label: 'PERFORMANCE', title: 'Indicateurs Clés'),
                const SizedBox(height: 16),
                _KpiGrid(ctrl: ctrl, isMobile: isMobile, isTablet: isTablet),
                const SizedBox(height: 36),

                // ── Graphiques ───────────────────────────────────
                _SectionHeader(label: 'TENDANCES', title: 'Évolution'),
                const SizedBox(height: 16),
                _ChartsSection(ctrl: ctrl, isMobile: isMobile, isTablet: isTablet),
                const SizedBox(height: 36),

                // ── Analyses ─────────────────────────────────────
                _SectionHeader(label: 'ANALYSES', title: 'Performance Opérationnelle'),
                const SizedBox(height: 16),
                _AnalyticsSection(ctrl: ctrl, isMobile: isMobile),
                const SizedBox(height: 36),

                // ── Tableaux ─────────────────────────────────────
                _SectionHeader(label: 'CLASSEMENT', title: 'Top Performers'),
                const SizedBox(height: 16),
                _LeaderboardSection(ctrl: ctrl, isMobile: isMobile),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      );
    });
  }

  bool _hasRealData(PdgDashboardController c) => c.caAujourdhui.value != 75000.0 || c.colisAujourdhui.value != 45;
}

// ─────────────────────────────────────────────
//  TOP APP BAR
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final PdgDashboardController controller;
  final AuthController authController;
  final bool isMobile;

  const _TopBar({required this.controller, required this.authController, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: isMobile ? 64 : 72,
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: _C.bg,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.border),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: _C.bg,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 28,
            vertical: 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo / branding mark
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _C.accentBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.accentDim.withOpacity(0.5)),
                ),
                child: const Icon(Icons.analytics_outlined, color: _C.accent, size: 16),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard PDG', style: _T.title.copyWith(fontSize: 15)),
                  Obx(() => _StatusPill(isReal: _hasRealData(controller))),
                ],
              ),
              const Spacer(),
              // Period selector
              if (!isMobile)
                Obx(() => _PeriodSelector(
                      value: controller.selectedPeriod.value,
                      onChanged: controller.changePeriod,
                    )),
              const SizedBox(width: 8),
              // Refresh
              _IconBtn(
                icon: Icons.refresh_rounded,
                onTap: controller.refreshData,
                tooltip: 'Actualiser',
              ),
              if (isMobile) ...[
                const SizedBox(width: 4),
                _MobilePeriodMenu(onSelected: controller.changePeriod),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasRealData(PdgDashboardController c) => c.caAujourdhui.value != 75000.0 || c.colisAujourdhui.value != 45;
}

// ─────────────────────────────────────────────
//  STATUS PILL
// ─────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final bool isReal;
  const _StatusPill({required this.isReal});

  @override
  Widget build(BuildContext context) {
    final color = isReal ? _C.accent : _C.warning;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          isReal ? 'Données réelles' : 'Mode démo',
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PERIOD SELECTOR
// ─────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _PeriodSelector({required this.value, required this.onChanged});

  static const _items = {
    'today': "Aujourd'hui",
    'week': 'Cette semaine',
    'month': 'Ce mois',
    'year': 'Cette année',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _C.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: _C.card,
          style: _T.body.copyWith(fontSize: 13, color: _C.textPrimary),
          icon: const Icon(Icons.unfold_more_rounded, color: _C.textSecondary, size: 16),
          items: _items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ICON BUTTON
// ─────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _IconBtn({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _C.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _C.border),
          ),
          child: Icon(icon, color: _C.textSecondary, size: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MOBILE PERIOD MENU
// ─────────────────────────────────────────────
class _MobilePeriodMenu extends StatelessWidget {
  final void Function(String) onSelected;
  const _MobilePeriodMenu({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: _C.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: _C.border),
      ),
      icon: Icon(Icons.more_horiz_rounded, color: _C.textSecondary, size: 20),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'today', child: Text("Aujourd'hui", style: TextStyle(color: _C.textPrimary, fontSize: 13))),
        PopupMenuItem(value: 'week', child: Text('Cette semaine', style: TextStyle(color: _C.textPrimary, fontSize: 13))),
        PopupMenuItem(value: 'month', child: Text('Ce mois', style: TextStyle(color: _C.textPrimary, fontSize: 13))),
        PopupMenuItem(value: 'year', child: Text('Cette année', style: TextStyle(color: _C.textPrimary, fontSize: 13))),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final String title;
  const _SectionHeader({required this.label, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(2),
            )),
        const SizedBox(width: 10),
        Text(label, style: _T.label),
        const SizedBox(width: 12),
        Container(height: 1, width: 20, color: _C.border),
        const SizedBox(width: 12),
        Text(title, style: _T.title.copyWith(fontSize: 16)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  DEMO BANNER
// ─────────────────────────────────────────────
class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _C.warning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _C.warning.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _C.warning, size: 17),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mode démonstration — Ajoutez des données réelles pour activer les métriques.',
              style: _T.body.copyWith(color: _C.warning.withOpacity(0.85), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ALERTS SECTION
// ─────────────────────────────────────────────
class _AlertsSection extends StatelessWidget {
  final PdgDashboardController controller;
  final bool isMobile;
  const _AlertsSection({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.danger.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.danger.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: _C.danger, size: 16),
            const SizedBox(width: 8),
            Text('Alertes Critiques', style: _T.subtitle.copyWith(color: _C.danger, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),
          ...controller.alertesCritiques.map((a) => AlertCard(
                type: a['type'],
                titre: a['titre'],
                message: a['message'],
                action: a['action'],
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  KPI GRID
// ─────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final PdgDashboardController ctrl;
  final bool isMobile, isTablet;
  const _KpiGrid({required this.ctrl, required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final financials = [
      _KpiData(
        label: "CA Aujourd'hui",
        value: '${ctrl.caAujourdhui.value.toStringAsFixed(0)} F',
        sub: 'Chiffre d\'affaires journalier',
        icon: Icons.bolt_rounded,
        accent: _C.accent,
        trend: ctrl.croissanceCA.value,
      ),
      _KpiData(
        label: 'CA Mensuel',
        value: '${ctrl.caMois.value.toStringAsFixed(0)} F',
        sub: 'Cumul du mois en cours',
        icon: Icons.calendar_today_rounded,
        accent: _C.info,
        trend: ctrl.croissanceCA.value,
      ),
      _KpiData(
        label: 'Marge Nette',
        value: '${ctrl.margeNette.value.toStringAsFixed(0)} F',
        sub: 'Bénéfice après charges',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF22D3A0),
        trend: (ctrl.margeNette.value / (ctrl.caTotal.value == 0 ? 1 : ctrl.caTotal.value)) * 100,
      ),
      _KpiData(
        label: 'Créances',
        value: '${ctrl.creances.value.toStringAsFixed(0)} F',
        sub: 'Montant à recouvrer',
        icon: Icons.account_balance_outlined,
        accent: _C.danger,
        trend: -(ctrl.creances.value / (ctrl.caTotal.value == 0 ? 1 : ctrl.caTotal.value)) * 100,
        negative: true,
      ),
    ];

    final operational = [
      _KpiData(
        label: 'Colis / Jour',
        value: '${ctrl.colisAujourdhui.value}',
        sub: 'Colis traités aujourd\'hui',
        icon: Icons.inventory_2_outlined,
        accent: const Color(0xFF9B7FFF),
        trend: ctrl.croissanceVolume.value,
      ),
      _KpiData(
        label: 'Taux de Livraison',
        value: '${ctrl.tauxLivraison.value.toStringAsFixed(1)}%',
        sub: 'Livraisons réussies',
        icon: Icons.check_circle_outline_rounded,
        accent: ctrl.tauxLivraison.value >= 90 ? _C.accent : _C.danger,
        trend: ctrl.tauxLivraison.value - 90,
      ),
      _KpiData(
        label: 'Délai Moyen',
        value: '${ctrl.delaiMoyen.value.toStringAsFixed(1)}h',
        sub: 'Temps de livraison',
        icon: Icons.timer_outlined,
        accent: _C.warning,
        trend: -(ctrl.delaiMoyen.value - 24),
      ),
      _KpiData(
        label: 'Clients Actifs',
        value: '${ctrl.clientsActifs.value}',
        sub: 'Clients ayant commandé',
        icon: Icons.people_outline_rounded,
        accent: const Color(0xFF38BDF8),
        trend: 0,
      ),
    ];

    if (isMobile) {
      return Column(children: [
        _grid2col(financials),
        const SizedBox(height: 12),
        _grid2col(operational),
      ]);
    }

    return Column(children: [
      _gridRow([...financials]),
      const SizedBox(height: 12),
      _gridRow([...operational]),
    ]);
  }

  Widget _gridRow(List<_KpiData> items) {
    return Row(
      children: items
          .asMap()
          .entries
          .map((e) {
            return [
              if (e.key > 0) const SizedBox(width: 12),
              Expanded(child: _KpiTile(data: e.value)),
            ];
          })
          .expand((w) => w)
          .toList(),
    );
  }

  Widget _grid2col(List<_KpiData> items) {
    return Column(children: [
      Row(children: [
        Expanded(child: _KpiTile(data: items[0])),
        const SizedBox(width: 10),
        Expanded(child: _KpiTile(data: items[1])),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _KpiTile(data: items[2])),
        const SizedBox(width: 10),
        Expanded(child: _KpiTile(data: items[3])),
      ]),
    ]);
  }
}

class _KpiData {
  final String label, value, sub;
  final IconData icon;
  final Color accent;
  final double trend;
  final bool negative;
  const _KpiData({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.accent,
    required this.trend,
    this.negative = false,
  });
}

// ─────────────────────────────────────────────
//  KPI TILE — card redesignée
// ─────────────────────────────────────────────
class _KpiTile extends StatelessWidget {
  final _KpiData data;
  const _KpiTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final up = data.trend > 0;
    final tColor = data.negative ? (up ? _C.danger : _C.accent) : (up ? _C.accent : _C.danger);
    final tIcon = up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: data.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(data.icon, color: data.accent, size: 15),
            ),
            const Spacer(),
            if (data.trend != 0)
              Row(children: [
                Icon(tIcon, color: tColor, size: 12),
                const SizedBox(width: 2),
                Text(
                  '${data.trend.abs().toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: tColor, fontWeight: FontWeight.w600),
                ),
              ]),
          ]),
          const SizedBox(height: 14),
          Text(data.value, style: _T.mono.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(data.label, style: _T.subtitle.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: _C.textPrimary.withOpacity(0.8))),
          const SizedBox(height: 3),
          Text(data.sub, style: _T.body.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CHARTS SECTION
// ─────────────────────────────────────────────
class _ChartsSection extends StatelessWidget {
  final PdgDashboardController ctrl;
  final bool isMobile, isTablet;
  const _ChartsSection({required this.ctrl, required this.isMobile, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    Widget caChart = _ChartCard(
      child: EvolutionChart(
        title: 'Chiffre d\'Affaires',
        data: ctrl.evolutionCA,
        color: _C.accent,
        valueKey: 'ca',
        labelKey: 'label',
      ),
    );
    Widget volChart = _ChartCard(
      child: EvolutionChart(
        title: 'Volume de Colis',
        data: ctrl.evolutionVolume,
        color: _C.info,
        valueKey: 'volume',
        labelKey: 'label',
      ),
    );
    Widget pieChart = _ChartCard(
      child: PerformanceChart(
        title: 'Statuts',
        data: ctrl.repartitionStatuts,
        type: ChartType.pie,
      ),
    );

    if (isMobile) {
      return Column(children: [
        caChart,
        const SizedBox(height: 12),
        volChart,
        const SizedBox(height: 12),
        pieChart,
      ]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 5, child: caChart),
      const SizedBox(width: 12),
      Expanded(flex: 5, child: volChart),
      const SizedBox(width: 12),
      Expanded(flex: 3, child: pieChart),
    ]);
  }
}

// ─────────────────────────────────────────────
//  ANALYTICS SECTION
// ─────────────────────────────────────────────
class _AnalyticsSection extends StatelessWidget {
  final PdgDashboardController ctrl;
  final bool isMobile;
  const _AnalyticsSection({required this.ctrl, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    Widget bar = _ChartCard(
      child: PerformanceChart(
        title: 'Performance par Agence',
        data: ctrl.performanceAgences,
        type: ChartType.bar,
        valueKey: 'ca',
        labelKey: 'agence',
      ),
    );
    Widget hBar = _ChartCard(
      child: PerformanceChart(
        title: 'Motifs d\'Échec',
        data: ctrl.motifsEchec,
        type: ChartType.horizontalBar,
        valueKey: 'count',
        labelKey: 'motif',
      ),
    );

    if (isMobile) {
      return Column(children: [bar, const SizedBox(height: 12), hBar]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: bar),
      const SizedBox(width: 12),
      Expanded(child: hBar),
    ]);
  }
}

// ─────────────────────────────────────────────
//  LEADERBOARD SECTION
// ─────────────────────────────────────────────
class _LeaderboardSection extends StatelessWidget {
  final PdgDashboardController ctrl;
  final bool isMobile;
  const _LeaderboardSection({required this.ctrl, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    Widget couriers = _ChartCard(
      child: TopPerformersCard(
        title: 'Top Coursiers',
        data: ctrl.topCoursiers,
        nameKey: 'nom',
        valueKey: 'livraisons',
        subtitleKey: 'tauxReussite',
        icon: Icons.delivery_dining_rounded,
        color: const Color(0xFF9B7FFF),
      ),
    );
    Widget agencies = _ChartCard(
      child: TopPerformersCard(
        title: 'Top Agences',
        data: ctrl.performanceAgences.take(5).toList(),
        nameKey: 'agence',
        valueKey: 'ca',
        subtitleKey: 'volume',
        icon: Icons.business_outlined,
        color: _C.accent,
      ),
    );

    if (isMobile) {
      return Column(children: [couriers, const SizedBox(height: 12), agencies]);
    }

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: couriers),
      const SizedBox(width: 12),
      Expanded(child: agencies),
    ]);
  }
}

// ─────────────────────────────────────────────
//  CHART CARD WRAPPER
// ─────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  DRAWER
// ─────────────────────────────────────────────
class _Drawer extends StatelessWidget {
  final AuthController authController;
  const _Drawer({required this.authController});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _C.surface,
      width: 260,
      child: Column(children: [
        // ── Header ──────────────────────────────
        Obx(() {
          final user = authController.currentUser.value;
          return Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _C.border)),
            ),
            child: Row(children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _C.accentBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.accentDim.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    user != null && user.prenom.isNotEmpty ? user.prenom[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      color: _C.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.nomComplet ?? '', style: _T.subtitle.copyWith(color: _C.textPrimary, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(user?.email ?? '', style: _T.body.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
            ]),
          );
        }),

        // ── Nav ─────────────────────────────────
        Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          _NavItem(icon: Icons.analytics_outlined, label: 'Dashboard PDG', active: true, onTap: () => Get.back()),
          _NavItem(
              icon: Icons.home_outlined,
              label: 'Accueil',
              onTap: () {
                Get.back();
                Get.offAllNamed('/home');
              }),
          _DrawerSection('Administration'),
          _NavItem(
              icon: Icons.people_outline,
              label: 'Utilisateurs',
              onTap: () {
                Get.back();
                Get.toNamed('/home');
              }),
          _NavItem(
              icon: Icons.business_outlined,
              label: 'Agences',
              onTap: () {
                Get.back();
                Get.toNamed('/home');
              }),
          _DrawerSection('Opérations'),
          _NavItem(
              icon: Icons.search_rounded,
              label: 'Suivi colis',
              onTap: () {
                Get.back();
                Get.toNamed('/home');
              }),
          _NavItem(
              icon: Icons.attach_money_rounded,
              label: 'Caisse',
              onTap: () {
                Get.back();
                Get.toNamed('/caisse');
              }),
          _DrawerSection('Rapports'),
          _NavItem(
              icon: Icons.notifications_none_rounded,
              label: 'Notifications',
              onTap: () {
                Get.back();
                Get.toNamed('/notifications');
              }),
        ])),

        // ── Footer ──────────────────────────────
        Container(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _C.border))),
          child: _NavItem(
            icon: Icons.logout_rounded,
            label: 'Déconnexion',
            danger: true,
            onTap: () async {
              await authController.signOut();
              Get.offAllNamed('/login');
            },
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(label.toUpperCase(), style: _T.label),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? _C.danger : (active ? _C.accent : _C.textSecondary);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _C.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 12),
          Text(label, style: _T.body.copyWith(color: color, fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          if (active) ...[
            const Spacer(),
            Container(width: 5, height: 5, decoration: BoxDecoration(color: _C.accent, shape: BoxShape.circle)),
          ],
        ]),
      ),
    );
  }
}
