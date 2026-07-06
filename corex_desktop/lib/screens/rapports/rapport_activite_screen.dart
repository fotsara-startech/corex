import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:corex_shared/corex_shared.dart';

class RapportActiviteScreen extends StatefulWidget {
  const RapportActiviteScreen({super.key});

  @override
  State<RapportActiviteScreen> createState() => _RapportActiviteScreenState();
}

class _RapportActiviteScreenState extends State<RapportActiviteScreen> {
  DateTime _dateDebut = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dateFin = DateTime.now();
  String _periodeLabel = '30 derniers jours';
  bool _isLoading = false;

  _ColisStats? _colisStats;
  _CourseStats? _courseStats;
  _DevisStats? _devisStats;
  _CaisseStats? _caisseStats;

  final _fmt = NumberFormat('#,###');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _isLoading = true);
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      if (user == null) return;
      final agenceId = user.agenceId ?? '';
      final debut = DateTime(_dateDebut.year, _dateDebut.month, _dateDebut.day);
      final fin = DateTime(_dateFin.year, _dateFin.month, _dateFin.day, 23, 59, 59);

      final results = await Future.wait([
        _chargerColis(agenceId, debut, fin),
        _chargerCourses(agenceId, debut, fin),
        _chargerDevis(agenceId, debut, fin),
        _chargerCaisse(agenceId, debut, fin),
      ]);

      setState(() {
        _colisStats = results[0] as _ColisStats;
        _courseStats = results[1] as _CourseStats;
        _devisStats = results[2] as _DevisStats;
        _caisseStats = results[3] as _CaisseStats;
      });
    } catch (e) {
      debugPrint('Rapport erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<_ColisStats> _chargerColis(String agenceId, DateTime debut, DateTime fin) async {
    try {
      final service = Get.find<ColisService>();
      final tous = await service.getColisByAgence(agenceId);
      final filtres = tous.where((c) {
        final d = c.dateCollecte;
        return !d.isBefore(debut) && !d.isAfter(fin);
      }).toList();
      return _ColisStats(
        total: filtres.length,
        collectes: filtres.where((c) => c.statut == 'collecte').length,
        enregistres: filtres.where((c) => c.statut == 'enregistre').length,
        livres: filtres.where((c) => c.statut == 'livre').length,
        payes: filtres.where((c) => c.isPaye).length,
        montantTotal: filtres.fold(0.0, (s, c) => s + c.montantTarif),
        montantEncaisse: filtres.where((c) => c.isPaye).fold(0.0, (s, c) => s + c.montantTarif),
        montantEnAttente: filtres.where((c) => !c.isPaye).fold(0.0, (s, c) => s + c.resteAPayer),
      );
    } catch (_) {
      return _ColisStats.empty();
    }
  }

  Future<_CourseStats> _chargerCourses(String agenceId, DateTime debut, DateTime fin) async {
    try {
      final service = Get.find<CourseService>();
      final tous = await service.getCoursesByAgence(agenceId);
      final filtres = tous.where((c) {
        final d = c.dateCreation;
        return !d.isBefore(debut) && !d.isAfter(fin);
      }).toList();
      return _CourseStats(
        total: filtres.length,
        enAttente: filtres.where((c) => c.statut == 'enAttente').length,
        enCours: filtres.where((c) => c.statut == 'enCours').length,
        terminees: filtres.where((c) => c.statut == 'terminee').length,
        annulees: filtres.where((c) => c.statut == 'annulee').length,
        montantEstime: filtres.fold(0.0, (s, c) => s + c.montantEstime),
        montantReel: filtres.fold(0.0, (s, c) => s + (c.montantReel ?? c.montantEstime)),
        commissions: filtres.fold(0.0, (s, c) => s + c.commissionMontant),
      );
    } catch (_) {
      return _CourseStats.empty();
    }
  }

  Future<_DevisStats> _chargerDevis(String agenceId, DateTime debut, DateTime fin) async {
    try {
      final service = Get.find<DevisService>();
      final stream = service.getDevisByAgence(agenceId);
      final tous = await stream.first;
      final filtres = tous.where((d) {
        return !d.dateCreation.isBefore(debut) && !d.dateCreation.isAfter(fin);
      }).toList();
      return _DevisStats(
        total: filtres.length,
        brouillons: filtres.where((d) => d.statut == 'brouillon').length,
        envoyes: filtres.where((d) => d.statut == 'envoye').length,
        valides: filtres.where((d) => d.statut == 'valide').length,
        convertis: filtres.where((d) => d.statut == 'converti').length,
        refuses: filtres.where((d) => d.statut == 'refuse').length,
        montantTotal: filtres.fold(0.0, (s, d) => s + d.montantTotal),
        montantValide: filtres.where((d) => d.statut == 'valide' || d.statut == 'converti').fold(0.0, (s, d) => s + d.montantTotal),
      );
    } catch (_) {
      return _DevisStats.empty();
    }
  }

  Future<_CaisseStats> _chargerCaisse(String agenceId, DateTime debut, DateTime fin) async {
    try {
      final service = Get.find<TransactionService>();
      final transactions = await service.getTransactionsByPeriod(agenceId, debut, fin);
      final recettes = transactions.where((t) => t.type == 'recette').toList();
      final depenses = transactions.where((t) => t.type == 'depense').toList();
      final totalRecettes = recettes.fold(0.0, (s, t) => s + t.montant);
      final totalDepenses = depenses.fold(0.0, (s, t) => s + t.montant);

      // Regrouper par catégorie
      final Map<String, double> parCategorie = {};
      for (final t in recettes) {
        final cat = t.categorieRecette ?? 'Autre';
        parCategorie[cat] = (parCategorie[cat] ?? 0) + t.montant;
      }

      return _CaisseStats(
        totalRecettes: totalRecettes,
        totalDepenses: totalDepenses,
        solde: totalRecettes - totalDepenses,
        nbTransactions: transactions.length,
        parCategorie: parCategorie,
      );
    } catch (_) {
      return _CaisseStats.empty();
    }
  }

  // ─── Export PDF ──────────────────────────────────────────────────────────

  Future<void> _exporterPDF() async {
    final colis = _colisStats!;
    final courses = _courseStats!;
    final devis = _devisStats!;
    final caisse = _caisseStats!;

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // En-tête
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('COREX', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
            pw.Text('Résumé d\'activité', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Période: $_periodeLabel', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text('Du ${_dateFmt.format(_dateDebut)} au ${_dateFmt.format(_dateFin)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            pw.Text('Généré le ${_dateFmt.format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ]),
        ]),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, color: PdfColors.green800),
        pw.SizedBox(height: 16),

        // Synthèse globale
        _pdfSection('SYNTHÈSE GLOBALE', PdfColors.green800, [
          _pdfRow('Recettes caisse', '${_fmt.format(caisse.totalRecettes)} FCFA'),
          _pdfRow('Dépenses caisse', '${_fmt.format(caisse.totalDepenses)} FCFA'),
          _pdfRow('Solde net', '${_fmt.format(caisse.solde)} FCFA', bold: true),
          _pdfRow('Total colis', '${colis.total}'),
          _pdfRow('Total courses', '${courses.total}'),
          _pdfRow('Total devis', '${devis.total}'),
        ]),
        pw.SizedBox(height: 12),

        // Colis
        _pdfSection('COLIS', PdfColors.green700, [
          _pdfRow('Collectés (total période)', '${colis.total}'),
          _pdfRow('En attente enregistrement', '${colis.collectes}'),
          _pdfRow('Enregistrés', '${colis.enregistres}'),
          _pdfRow('Livrés', '${colis.livres}'),
          _pdfRow('Payés', '${colis.payes}'),
          _pdfRow('Montant total', '${_fmt.format(colis.montantTotal)} FCFA'),
          _pdfRow('Montant encaissé', '${_fmt.format(colis.montantEncaisse)} FCFA', bold: true),
          _pdfRow('Créances en attente', '${_fmt.format(colis.montantEnAttente)} FCFA'),
        ]),
        pw.SizedBox(height: 12),

        // Courses
        _pdfSection('COURSES', PdfColors.orange700, [
          _pdfRow('Total', '${courses.total}'),
          _pdfRow('En attente', '${courses.enAttente}'),
          _pdfRow('En cours', '${courses.enCours}'),
          _pdfRow('Terminées', '${courses.terminees}'),
          _pdfRow('Annulées', '${courses.annulees}'),
          _pdfRow('Montant estimé', '${_fmt.format(courses.montantEstime)} FCFA'),
          _pdfRow('Montant réel', '${_fmt.format(courses.montantReel)} FCFA', bold: true),
          _pdfRow('Commissions', '${_fmt.format(courses.commissions)} FCFA'),
        ]),
        pw.SizedBox(height: 12),

        // Devis
        _pdfSection('DEVIS', PdfColors.blue700, [
          _pdfRow('Total', '${devis.total}'),
          _pdfRow('Brouillons', '${devis.brouillons}'),
          _pdfRow('Envoyés', '${devis.envoyes}'),
          _pdfRow('Validés', '${devis.valides}'),
          _pdfRow('Convertis en facture', '${devis.convertis}'),
          _pdfRow('Refusés', '${devis.refuses}'),
          _pdfRow('Montant total', '${_fmt.format(devis.montantTotal)} FCFA'),
          _pdfRow('Montant validé', '${_fmt.format(devis.montantValide)} FCFA', bold: true),
        ]),
        pw.SizedBox(height: 12),

        // Caisse
        _pdfSection('CAISSE', PdfColors.teal700, [
          _pdfRow('Total recettes', '${_fmt.format(caisse.totalRecettes)} FCFA', bold: true),
          _pdfRow('Total dépenses', '${_fmt.format(caisse.totalDepenses)} FCFA'),
          _pdfRow('Solde net', '${_fmt.format(caisse.solde)} FCFA', bold: true),
          _pdfRow('Nombre de transactions', '${caisse.nbTransactions}'),
          if (caisse.parCategorie.isNotEmpty) ...caisse.parCategorie.entries.map((e) => _pdfRow('  ${e.key}', '${_fmt.format(e.value)} FCFA')),
        ]),
      ],
    ));

    final bytes = await pdf.save();
    final filename = 'Rapport_COREX_${_dateFmt.format(_dateDebut).replaceAll('/', '-')}_${_dateFmt.format(_dateFin).replaceAll('/', '-')}.pdf';

    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } else {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], subject: filename);
      } catch (_) {
        await Printing.sharePdf(bytes: bytes, filename: filename);
      }
    }
  }

  pw.Widget _pdfSection(String titre, PdfColor color, List<pw.Widget> rows) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: color,
          child: pw.Text(titre, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        ),
        pw.SizedBox(height: 6),
        ...rows,
      ]),
    );
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ]),
    );
  }

  // ─── Export Excel ─────────────────────────────────────────────────────────

  Future<void> _exporterExcel() async {
    final excel = Excel.createExcel();

    _remplirFeuilleColis(excel);
    _remplirFeuilleCourses(excel);
    _remplirFeuilleDevis(excel);
    _remplirFeuilleCaisse(excel);

    // Supprimer la feuille par défaut
    excel.delete('Sheet1');

    final bytes = excel.encode();
    if (bytes == null) return;

    final filename = 'Rapport_COREX_${_dateFmt.format(_dateDebut).replaceAll('/', '-')}_${_dateFmt.format(_dateFin).replaceAll('/', '-')}.xlsx';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(bytes), name: filename, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: filename,
      );
    } else {
      try {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], subject: filename);
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible d\'exporter Excel: $e', backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  void _remplirFeuilleColis(Excel excel) {
    final sheet = excel['Colis'];
    final s = _colisStats!;
    _xlHeader(sheet, 'RÉSUMÉ COLIS — $_periodeLabel');
    _xlRow(sheet, 'Total collectés', '${s.total}');
    _xlRow(sheet, 'En attente enregistrement', '${s.collectes}');
    _xlRow(sheet, 'Enregistrés', '${s.enregistres}');
    _xlRow(sheet, 'Livrés', '${s.livres}');
    _xlRow(sheet, 'Payés', '${s.payes}');
    _xlRow(sheet, 'Montant total (FCFA)', '${s.montantTotal.toStringAsFixed(0)}');
    _xlRow(sheet, 'Montant encaissé (FCFA)', '${s.montantEncaisse.toStringAsFixed(0)}');
    _xlRow(sheet, 'Créances en attente (FCFA)', '${s.montantEnAttente.toStringAsFixed(0)}');
  }

  void _remplirFeuilleCourses(Excel excel) {
    final sheet = excel['Courses'];
    final s = _courseStats!;
    _xlHeader(sheet, 'RÉSUMÉ COURSES — $_periodeLabel');
    _xlRow(sheet, 'Total', '${s.total}');
    _xlRow(sheet, 'En attente', '${s.enAttente}');
    _xlRow(sheet, 'En cours', '${s.enCours}');
    _xlRow(sheet, 'Terminées', '${s.terminees}');
    _xlRow(sheet, 'Annulées', '${s.annulees}');
    _xlRow(sheet, 'Montant estimé (FCFA)', '${s.montantEstime.toStringAsFixed(0)}');
    _xlRow(sheet, 'Montant réel (FCFA)', '${s.montantReel.toStringAsFixed(0)}');
    _xlRow(sheet, 'Commissions (FCFA)', '${s.commissions.toStringAsFixed(0)}');
  }

  void _remplirFeuilleDevis(Excel excel) {
    final sheet = excel['Devis'];
    final s = _devisStats!;
    _xlHeader(sheet, 'RÉSUMÉ DEVIS — $_periodeLabel');
    _xlRow(sheet, 'Total', '${s.total}');
    _xlRow(sheet, 'Brouillons', '${s.brouillons}');
    _xlRow(sheet, 'Envoyés', '${s.envoyes}');
    _xlRow(sheet, 'Validés', '${s.valides}');
    _xlRow(sheet, 'Convertis en facture', '${s.convertis}');
    _xlRow(sheet, 'Refusés', '${s.refuses}');
    _xlRow(sheet, 'Montant total (FCFA)', '${s.montantTotal.toStringAsFixed(0)}');
    _xlRow(sheet, 'Montant validé (FCFA)', '${s.montantValide.toStringAsFixed(0)}');
  }

  void _remplirFeuilleCaisse(Excel excel) {
    final sheet = excel['Caisse'];
    final s = _caisseStats!;
    _xlHeader(sheet, 'RÉSUMÉ CAISSE — $_periodeLabel');
    _xlRow(sheet, 'Total recettes (FCFA)', '${s.totalRecettes.toStringAsFixed(0)}');
    _xlRow(sheet, 'Total dépenses (FCFA)', '${s.totalDepenses.toStringAsFixed(0)}');
    _xlRow(sheet, 'Solde net (FCFA)', '${s.solde.toStringAsFixed(0)}');
    _xlRow(sheet, 'Nombre de transactions', '${s.nbTransactions}');
    if (s.parCategorie.isNotEmpty) {
      _xlRow(sheet, '', '');
      _xlRow(sheet, 'RECETTES PAR CATÉGORIE', '');
      for (final e in s.parCategorie.entries) {
        _xlRow(sheet, e.key, '${e.value.toStringAsFixed(0)}');
      }
    }
  }

  int _xlRowIndex = 0;

  void _xlHeader(Sheet sheet, String titre) {
    _xlRowIndex = 0;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: _xlRowIndex)).value = TextCellValue(titre);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: _xlRowIndex)).cellStyle = CellStyle(bold: true);
    _xlRowIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: _xlRowIndex)).value = TextCellValue('Indicateur');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: _xlRowIndex)).value = TextCellValue('Valeur');
    _xlRowIndex++;
  }

  void _xlRow(Sheet sheet, String label, String value) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: _xlRowIndex)).value = TextCellValue(label);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: _xlRowIndex)).value = TextCellValue(value);
    _xlRowIndex++;
  }

  void _selectionnerPeriode(String label, DateTime debut, DateTime fin) {
    setState(() {
      _periodeLabel = label;
      _dateDebut = debut;
      _dateFin = fin;
    });
    _chargerDonnees();
  }

  Future<void> _selectionnerDatePersonnalisee() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _dateDebut, end: _dateFin),
      locale: const Locale('fr', 'FR'),
    );
    if (range != null) {
      _selectionnerPeriode(
        '${_dateFmt.format(range.start)} - ${_dateFmt.format(range.end)}',
        range.start,
        range.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résumé d\'activité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: (_colisStats == null) ? null : _exporterPDF,
            tooltip: 'Exporter PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: (_colisStats == null) ? null : _exporterExcel,
            tooltip: 'Exporter Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerDonnees,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPeriodeSelector(),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildContenu(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodeSelector() {
    final periodes = [
      ("Aujourd'hui", DateTime.now(), DateTime.now()),
      ("7 jours", DateTime.now().subtract(const Duration(days: 6)), DateTime.now()),
      ("30 jours", DateTime.now().subtract(const Duration(days: 29)), DateTime.now()),
      ("Ce mois", DateTime(DateTime.now().year, DateTime.now().month, 1), DateTime.now()),
    ];

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Période : $_periodeLabel', style: const TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              TextButton.icon(
                onPressed: _selectionnerDatePersonnalisee,
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Personnalisée'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: periodes.map((p) {
                final isSelected = _periodeLabel == p.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p.$1),
                    selected: isSelected,
                    onSelected: (_) => _selectionnerPeriode(p.$1, p.$2, p.$3),
                    selectedColor: const Color(0xFF2E7D32),
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vue synthèse en haut
          _buildSyntheseGlobale(),
          const SizedBox(height: 20),
          // 4 sections détaillées
          _buildSectionColis(),
          const SizedBox(height: 16),
          _buildSectionCourses(),
          const SizedBox(height: 16),
          _buildSectionDevis(),
          const SizedBox(height: 16),
          _buildSectionCaisse(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSyntheseGlobale() {
    final caisse = _caisseStats;
    final colis = _colisStats;
    final courses = _courseStats;
    final devis = _devisStats;

    return Card(
      elevation: 2,
      color: const Color(0xFF2E7D32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Synthèse globale', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildKpi('Recettes', caisse != null ? '${_fmt.format(caisse.totalRecettes)} FCFA' : '-', Icons.trending_up, Colors.white),
                _buildKpi('Dépenses', caisse != null ? '${_fmt.format(caisse.totalDepenses)} FCFA' : '-', Icons.trending_down, Colors.orange.shade200),
                _buildKpi('Solde net', caisse != null ? '${_fmt.format(caisse.solde)} FCFA' : '-', Icons.account_balance_wallet, Colors.greenAccent),
                _buildKpi('Colis', colis != null ? '${colis.total}' : '-', Icons.inventory_2, Colors.white),
                _buildKpi('Courses', courses != null ? '${courses.total}' : '-', Icons.directions_run, Colors.white),
                _buildKpi('Devis', devis != null ? '${devis.total}' : '-', Icons.request_quote, Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpi(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSectionColis() {
    final s = _colisStats;
    return _buildSection(
      titre: 'Colis',
      icon: Icons.inventory_2,
      color: Colors.green.shade700,
      child: s == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  children: [
                    _buildStatCard('Total collectés', '${s.total}', Colors.blue.shade50, Colors.blue),
                    _buildStatCard('En attente', '${s.collectes}', Colors.orange.shade50, Colors.orange),
                    _buildStatCard('Enregistrés', '${s.enregistres}', Colors.purple.shade50, Colors.purple),
                    _buildStatCard('Livrés', '${s.livres}', Colors.green.shade50, Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Payés', '${s.payes}', Colors.green.shade50, Colors.green),
                    _buildStatCard('Montant total', '${_fmt.format(s.montantTotal)} FCFA', Colors.teal.shade50, Colors.teal),
                    _buildStatCard('Encaissé', '${_fmt.format(s.montantEncaisse)} FCFA', Colors.green.shade50, Colors.green.shade700),
                    _buildStatCard('En attente paiement', '${_fmt.format(s.montantEnAttente)} FCFA', Colors.red.shade50, Colors.red),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCourses() {
    final s = _courseStats;
    return _buildSection(
      titre: 'Courses',
      icon: Icons.directions_run,
      color: Colors.orange.shade700,
      child: s == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  children: [
                    _buildStatCard('Total', '${s.total}', Colors.blue.shade50, Colors.blue),
                    _buildStatCard('En attente', '${s.enAttente}', Colors.orange.shade50, Colors.orange),
                    _buildStatCard('En cours', '${s.enCours}', Colors.purple.shade50, Colors.purple),
                    _buildStatCard('Terminées', '${s.terminees}', Colors.green.shade50, Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Annulées', '${s.annulees}', Colors.red.shade50, Colors.red),
                    _buildStatCard('Montant estimé', '${_fmt.format(s.montantEstime)} FCFA', Colors.teal.shade50, Colors.teal),
                    _buildStatCard('Montant réel', '${_fmt.format(s.montantReel)} FCFA', Colors.green.shade50, Colors.green.shade700),
                    _buildStatCard('Commissions', '${_fmt.format(s.commissions)} FCFA', Colors.purple.shade50, Colors.purple),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSectionDevis() {
    final s = _devisStats;
    return _buildSection(
      titre: 'Devis',
      icon: Icons.request_quote,
      color: Colors.blue.shade700,
      child: s == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Row(
                  children: [
                    _buildStatCard('Total', '${s.total}', Colors.blue.shade50, Colors.blue),
                    _buildStatCard('Brouillons', '${s.brouillons}', Colors.grey.shade100, Colors.grey),
                    _buildStatCard('Envoyés', '${s.envoyes}', Colors.orange.shade50, Colors.orange),
                    _buildStatCard('Validés', '${s.valides}', Colors.green.shade50, Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Convertis en facture', '${s.convertis}', Colors.blue.shade50, Colors.blue.shade700),
                    _buildStatCard('Refusés', '${s.refuses}', Colors.red.shade50, Colors.red),
                    _buildStatCard('Montant total', '${_fmt.format(s.montantTotal)} FCFA', Colors.teal.shade50, Colors.teal),
                    _buildStatCard('Montant validé', '${_fmt.format(s.montantValide)} FCFA', Colors.green.shade50, Colors.green.shade700),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSectionCaisse() {
    final s = _caisseStats;
    return _buildSection(
      titre: 'Caisse',
      icon: Icons.account_balance_wallet,
      color: Colors.teal.shade700,
      child: s == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatCard('Recettes', '${_fmt.format(s.totalRecettes)} FCFA', Colors.green.shade50, Colors.green.shade700),
                    _buildStatCard('Dépenses', '${_fmt.format(s.totalDepenses)} FCFA', Colors.red.shade50, Colors.red),
                    _buildStatCard('Solde net', '${_fmt.format(s.solde)} FCFA', s.solde >= 0 ? Colors.teal.shade50 : Colors.red.shade50, s.solde >= 0 ? Colors.teal.shade700 : Colors.red),
                    _buildStatCard('Nb transactions', '${s.nbTransactions}', Colors.blue.shade50, Colors.blue),
                  ],
                ),
                if (s.parCategorie.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Recettes par catégorie', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: s.parCategorie.entries
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.teal.shade200)),
                              child: Text('${e.key}: ${_fmt.format(e.value)} FCFA', style: TextStyle(fontSize: 12, color: Colors.teal.shade800)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSection({required String titre, required IconData icon, required Color color, required Widget child}) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(titre, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.8)), textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

// ─── Modèles de stats internes ───────────────────────────────────────────────

class _ColisStats {
  final int total, collectes, enregistres, livres, payes;
  final double montantTotal, montantEncaisse, montantEnAttente;
  _ColisStats(
      {required this.total,
      required this.collectes,
      required this.enregistres,
      required this.livres,
      required this.payes,
      required this.montantTotal,
      required this.montantEncaisse,
      required this.montantEnAttente});
  factory _ColisStats.empty() => _ColisStats(total: 0, collectes: 0, enregistres: 0, livres: 0, payes: 0, montantTotal: 0, montantEncaisse: 0, montantEnAttente: 0);
}

class _CourseStats {
  final int total, enAttente, enCours, terminees, annulees;
  final double montantEstime, montantReel, commissions;
  _CourseStats(
      {required this.total,
      required this.enAttente,
      required this.enCours,
      required this.terminees,
      required this.annulees,
      required this.montantEstime,
      required this.montantReel,
      required this.commissions});
  factory _CourseStats.empty() => _CourseStats(total: 0, enAttente: 0, enCours: 0, terminees: 0, annulees: 0, montantEstime: 0, montantReel: 0, commissions: 0);
}

class _DevisStats {
  final int total, brouillons, envoyes, valides, convertis, refuses;
  final double montantTotal, montantValide;
  _DevisStats(
      {required this.total,
      required this.brouillons,
      required this.envoyes,
      required this.valides,
      required this.convertis,
      required this.refuses,
      required this.montantTotal,
      required this.montantValide});
  factory _DevisStats.empty() => _DevisStats(total: 0, brouillons: 0, envoyes: 0, valides: 0, convertis: 0, refuses: 0, montantTotal: 0, montantValide: 0);
}

class _CaisseStats {
  final double totalRecettes, totalDepenses, solde;
  final int nbTransactions;
  final Map<String, double> parCategorie;
  _CaisseStats({required this.totalRecettes, required this.totalDepenses, required this.solde, required this.nbTransactions, required this.parCategorie});
  factory _CaisseStats.empty() => _CaisseStats(totalRecettes: 0, totalDepenses: 0, solde: 0, nbTransactions: 0, parCategorie: {});
}
