import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/controllers/livraison_controller.dart';
import 'package:corex_shared/models/livraison_model.dart';
import 'package:corex_shared/models/colis_model.dart';
import 'package:corex_shared/models/user_model.dart';
import 'package:corex_shared/services/colis_service.dart';
import 'package:corex_shared/services/user_service.dart';
import 'package:corex_shared/services/livraison_service.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show AnchorElement, Blob, Url;

class SuiviLivraisonsScreen extends StatefulWidget {
  const SuiviLivraisonsScreen({super.key});

  @override
  State<SuiviLivraisonsScreen> createState() => _SuiviLivraisonsScreenState();
}

class _SuiviLivraisonsScreenState extends State<SuiviLivraisonsScreen> {
  // Services et controllers - récupérés de manière lazy
  LivraisonController get _livraisonController => Get.find<LivraisonController>();
  ColisService get _colisService => Get.find<ColisService>();
  UserService get _userService => Get.find<UserService>();
  AuthController get _authController => Get.find<AuthController>();

  final Map<String, ColisModel> _colisMap = {};
  final Map<String, UserModel> _coursiersMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ensureServicesAndLoadData();
  }

  Future<void> _ensureServicesAndLoadData() async {
    try {
      // Vérifier que les services essentiels sont disponibles
      if (!Get.isRegistered<ColisService>()) {
        Get.put(ColisService(), permanent: true);
      }
      if (!Get.isRegistered<UserService>()) {
        Get.put(UserService(), permanent: true);
      }
      if (!Get.isRegistered<LivraisonService>()) {
        Get.put(LivraisonService(), permanent: true);
      }
      if (!Get.isRegistered<LivraisonController>()) {
        Get.put(LivraisonController(), permanent: true);
      }

      // Attendre un peu pour s'assurer que tout est prêt
      await Future.delayed(const Duration(milliseconds: 100));

      await _loadData();
    } catch (e) {
      print('❌ [SUIVI_LIVRAISONS] Erreur initialisation: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Get.snackbar(
          'Erreur',
          'Impossible d\'initialiser les services: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _livraisonController.loadLivraisons();

      final user = _authController.currentUser.value;
      if (user == null || user.agenceId == null) return;

      // Charger les colis associés
      final colisIds = _livraisonController.livraisonsList.map((l) => l.colisId).toSet();

      for (var colisId in colisIds) {
        final colis = await _colisService.getColisById(colisId);
        if (colis != null) {
          _colisMap[colisId] = colis;
        }
      }

      // Charger les coursiers
      final coursiersIds = _livraisonController.livraisonsList.map((l) => l.coursierId).toSet();

      for (var coursierId in coursiersIds) {
        final coursier = await _userService.getUserById(coursierId);
        if (coursier != null) {
          _coursiersMap[coursierId] = coursier;
        }
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exporterExcel() async {
    final livraisons = _livraisonController.filteredLivraisons;

    if (livraisons.isEmpty) {
      Get.snackbar(
        'Aucune donnée',
        'Aucune livraison à exporter',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Livraisons'];

      // En-têtes
      final headers = [
        'Numéro de Suivi',
        'Date Création',
        'Expéditeur',
        'Destinataire',
        'Agence Voyage',
        'Destination',
        'Montant Versé',
        'Frais Expédition',
        'Frais Livraison',
        'Commission',
        'Coursier',
        'Zone',
        'Statut Livraison',
        'Date Départ',
        'Date Retour',
        'Motif Échec',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#4CAF50'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Données
      for (var rowIndex = 0; rowIndex < livraisons.length; rowIndex++) {
        final livraison = livraisons[rowIndex];
        final colis = _colisMap[livraison.colisId];
        final coursier = _coursiersMap[livraison.coursierId];
        final dataRowIndex = rowIndex + 1;

        final data = [
          colis?.numeroSuivi ?? 'Inconnu',
          DateFormat('dd/MM/yyyy HH:mm').format(livraison.dateCreation),
          colis?.expediteurNom ?? '-',
          colis?.destinataireNom ?? '-',
          colis?.agenceTransportNom ?? '-',
          colis?.destinataireVille ?? '-',
          colis?.montantDejaPaye.toStringAsFixed(0) ?? '0',
          colis != null ? (colis.fraisCollecte + colis.fraisLivraison + colis.commissionVente).toStringAsFixed(0) : '0',
          colis?.fraisLivraison.toStringAsFixed(0) ?? '0',
          colis?.commissionVente.toStringAsFixed(0) ?? '0',
          coursier?.nomComplet ?? 'Inconnu',
          livraison.zone,
          _getStatutLabel(livraison.statut),
          livraison.heureDepart != null ? DateFormat('dd/MM/yyyy HH:mm').format(livraison.heureDepart!) : '-',
          livraison.heureRetour != null ? DateFormat('dd/MM/yyyy HH:mm').format(livraison.heureRetour!) : '-',
          livraison.motifEchec ?? '-',
        ];

        for (var colIndex = 0; colIndex < data.length; colIndex++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: dataRowIndex));
          cell.value = TextCellValue(data[colIndex]);
        }
      }

      // Supprimer la feuille par défaut
      excel.delete('Sheet1');

      final bytes = excel.encode();
      if (bytes == null) return;

      final filename = 'Livraisons_${DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        // Sur Web, utiliser un téléchargement direct
        try {
          final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)..setAttribute('download', filename);
          anchor.click();
          html.Url.revokeObjectUrl(url);

          Get.snackbar(
            'Succès',
            'Export Excel téléchargé (${livraisons.length} livraisons)',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar('Erreur', 'Impossible d\'exporter Excel: $e', backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else {
        try {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/$filename');
          await file.writeAsBytes(bytes);
          await Share.shareXFiles([XFile(file.path)], subject: filename);

          Get.snackbar(
            'Succès',
            'Export Excel créé (${livraisons.length} livraisons)',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar('Erreur', 'Impossible d\'exporter Excel: $e', backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'export: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des Livraisons'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: _exporterExcel,
            tooltip: 'Exporter Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                _buildStatistics(),
                Expanded(child: _buildLivraisonsList()),
              ],
            ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Obx(() => Row(
            children: [
              const Text('Statut:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _livraisonController.filterStatut.value,
                items: const [
                  DropdownMenuItem(value: 'tous', child: Text('Tous')),
                  DropdownMenuItem(value: 'enAttente', child: Text('En attente')),
                  DropdownMenuItem(value: 'enCours', child: Text('En cours')),
                  DropdownMenuItem(value: 'livree', child: Text('Livrée')),
                  DropdownMenuItem(value: 'echec', child: Text('Échec')),
                ],
                onChanged: (value) {
                  _livraisonController.filterStatut.value = value ?? 'tous';
                },
              ),
              const SizedBox(width: 32),
              const Text('Coursier:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _livraisonController.filterCoursier.value,
                items: [
                  const DropdownMenuItem(value: 'tous', child: Text('Tous')),
                  ..._coursiersMap.values.map((coursier) {
                    return DropdownMenuItem(
                      value: coursier.id,
                      child: Text(coursier.nomComplet),
                    );
                  }),
                ],
                onChanged: (value) {
                  _livraisonController.filterCoursier.value = value ?? 'tous';
                },
              ),
            ],
          )),
    );
  }

  Widget _buildStatistics() {
    return Obx(() {
      final livraisons = _livraisonController.livraisonsList;
      final enAttente = livraisons.where((l) => l.statut == 'enAttente').length;
      final enCours = livraisons.where((l) => l.statut == 'enCours').length;
      final livrees = livraisons.where((l) => l.statut == 'livree').length;
      final echecs = livraisons.where((l) => l.statut == 'echec').length;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildStatCard('En attente', enAttente, Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('En cours', enCours, Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Livrées', livrees, Colors.green)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Échecs', echecs, Colors.red)),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivraisonsList() {
    return Obx(() {
      final livraisons = _livraisonController.filteredLivraisons;

      if (livraisons.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucune livraison', style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: livraisons.length,
        itemBuilder: (context, index) {
          final livraison = livraisons[index];
          final colis = _colisMap[livraison.colisId];
          final coursier = _coursiersMap[livraison.coursierId];
          return _buildLivraisonCard(livraison, colis, coursier);
        },
      );
    });
  }

  Widget _buildLivraisonCard(LivraisonModel livraison, ColisModel? colis, UserModel? coursier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: _buildStatutIcon(livraison.statut),
        title: Text(
          colis?.numeroSuivi ?? 'Colis inconnu',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Coursier: ${coursier?.nomComplet ?? "Inconnu"}'),
            Text('Zone: ${livraison.zone}'),
            Text('Créée le: ${DateFormat('dd/MM/yyyy HH:mm').format(livraison.dateCreation)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text('Détails du colis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (colis != null) ...[
                  _buildDetailRow('Destinataire', colis.destinataireNom),
                  _buildDetailRow('Téléphone', colis.destinataireTelephone),
                  _buildDetailRow('Adresse', colis.destinataireAdresse),
                  if (colis.destinataireQuartier != null) _buildDetailRow('Quartier', colis.destinataireQuartier!),
                  _buildDetailRow('Contenu', colis.poids != null ? '${colis.contenu} (${colis.poids} kg)' : colis.contenu),
                  if (colis.valeurDeclaree != null) _buildDetailRow('Valeur déclarée', '${colis.valeurDeclaree!.toStringAsFixed(0)} FCFA'),
                  _buildDetailRow('Tarif', '${colis.montantTarif} FCFA'),
                ],
                const SizedBox(height: 16),
                const Text('Détails de la livraison', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildDetailRow('Statut', _getStatutLabel(livraison.statut)),
                if (livraison.heureDepart != null) _buildDetailRow('Heure de départ', DateFormat('dd/MM/yyyy HH:mm').format(livraison.heureDepart!)),
                if (livraison.heureRetour != null) _buildDetailRow('Heure de retour', DateFormat('dd/MM/yyyy HH:mm').format(livraison.heureRetour!)),
                if (livraison.motifEchec != null) _buildDetailRow('Motif d\'échec', livraison.motifEchec!, isError: true),
                if (livraison.commentaire != null) _buildDetailRow('Commentaire', livraison.commentaire!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutIcon(String statut) {
    IconData icon;
    Color color;

    switch (statut) {
      case 'enAttente':
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case 'enCours':
        icon = Icons.local_shipping;
        color = Colors.blue;
        break;
      case 'livree':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'echec':
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 32);
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'enAttente':
        return 'En attente';
      case 'enCours':
        return 'En cours';
      case 'livree':
        return 'Livrée';
      case 'echec':
        return 'Échec';
      default:
        return statut;
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isError ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
