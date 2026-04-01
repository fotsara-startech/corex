import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/devis_controller.dart';
import 'package:corex_shared/controllers/auth_controller.dart';
import 'package:corex_shared/models/devis_model.dart';
import 'package:corex_shared/models/client_model.dart';
import 'package:corex_shared/services/client_service.dart';
import 'package:intl/intl.dart';

class DevisFormScreen extends StatefulWidget {
  final DevisModel? devis; // null = création, non-null = édition

  const DevisFormScreen({super.key, this.devis});

  @override
  State<DevisFormScreen> createState() => _DevisFormScreenState();
}

class _DevisFormScreenState extends State<DevisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNomCtrl = TextEditingController();
  final _clientTelCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _fmt = NumberFormat('#,###');

  ClientModel? _clientSelectionne; // client existant sélectionné
  late List<_LigneForm> _lignes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.devis != null) {
      final d = widget.devis!;
      _clientNomCtrl.text = d.clientNom;
      _clientTelCtrl.text = d.clientTelephone;
      _notesCtrl.text = d.notes ?? '';
      _lignes = d.lignes.map((l) => _LigneForm.fromLigne(l)).toList();
    } else {
      _lignes = [_LigneForm()];
    }
  }

  @override
  void dispose() {
    _clientNomCtrl.dispose();
    _clientTelCtrl.dispose();
    _notesCtrl.dispose();
    for (final l in _lignes) l.dispose();
    super.dispose();
  }

  double get _montantTotal => _lignes.fold(0.0, (sum, l) => sum + l.total);

  void _ajouterLigne() => setState(() => _lignes.add(_LigneForm()));

  void _supprimerLigne(int index) {
    if (_lignes.length <= 1) {
      Get.snackbar('Info', 'Le devis doit avoir au moins une ligne');
      return;
    }
    setState(() {
      _lignes[index].dispose();
      _lignes.removeAt(index);
    });
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lignes.any((l) => l.designation.trim().isEmpty)) {
      Get.snackbar('Erreur', 'Toutes les lignes doivent avoir une désignation');
      return;
    }

    setState(() => _isLoading = true);

    final controller = Get.isRegistered<DevisController>() ? Get.find<DevisController>() : Get.put(DevisController(), permanent: true);

    // Créer le client s'il n'existe pas encore
    if (_clientSelectionne == null && _clientNomCtrl.text.trim().isNotEmpty) {
      try {
        final authController = Get.find<AuthController>();
        final agenceId = authController.currentUser.value?.agenceId ?? '';
        if (!Get.isRegistered<ClientService>()) Get.put(ClientService(), permanent: true);
        final clientService = Get.find<ClientService>();
        final now = DateTime.now();
        final newClient = ClientModel(
          id: '',
          nom: _clientNomCtrl.text.trim(),
          telephone: _clientTelCtrl.text.trim(),
          adresse: '',
          ville: '',
          type: 'les_deux',
          agenceId: agenceId,
          createdAt: now,
          updatedAt: now,
        );
        await clientService.createClient(newClient);
      } catch (e) {
        print('⚠️ [DEVIS_FORM] Erreur création client: $e');
        // On continue même si la création du client échoue
      }
    }

    final lignes = _lignes
        .map((l) => LigneDevis(
              designation: l.designation,
              quantite: l.quantite,
              prixUnitaire: l.prixUnitaire,
              total: l.total,
            ))
        .toList();

    bool ok;
    if (widget.devis == null) {
      // Création
      final newDevis = DevisModel(
        id: '',
        numeroDevis: '',
        clientNom: _clientNomCtrl.text.trim(),
        clientTelephone: _clientTelCtrl.text.trim(),
        agenceId: '',
        userId: '',
        lignes: lignes,
        montantTotal: _montantTotal,
        statut: 'brouillon',
        dateCreation: DateTime.now(),
        dateModification: DateTime.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      ok = await controller.createDevis(newDevis);
    } else {
      // Édition
      ok = await controller.updateDevis(
        widget.devis!.id,
        {
          'clientNom': _clientNomCtrl.text.trim(),
          'clientTelephone': _clientTelCtrl.text.trim(),
          'lignes': lignes.map((l) => l.toMap()).toList(),
          'montantTotal': _montantTotal,
          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        },
        currentStatut: widget.devis!.statut,
      );
    }

    setState(() => _isLoading = false);
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.devis == null ? 'Nouveau devis' : 'Modifier le devis'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Infos client
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Client', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Sélectionnez un client existant ou saisissez un nouveau nom.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    // Autocomplete sur le nom
                    Autocomplete<ClientModel>(
                      initialValue: TextEditingValue(text: _clientNomCtrl.text),
                      displayStringForOption: (c) => c.nom,
                      optionsBuilder: (textEditingValue) async {
                        _clientNomCtrl.text = textEditingValue.text;
                        if (textEditingValue.text.length < 2) return [];
                        try {
                          final authController = Get.find<AuthController>();
                          final agenceId = authController.currentUser.value?.agenceId ?? '';
                          if (!Get.isRegistered<ClientService>()) Get.put(ClientService(), permanent: true);
                          final clients = await Get.find<ClientService>().searchClientsMultiCriteria(textEditingValue.text, agenceId);
                          return clients;
                        } catch (_) {
                          return [];
                        }
                      },
                      onSelected: (client) {
                        setState(() {
                          _clientSelectionne = client;
                          _clientNomCtrl.text = client.nom;
                          _clientTelCtrl.text = client.telephone;
                        });
                      },
                      fieldViewBuilder: (context, ctrl, focusNode, onSubmitted) {
                        // Synchroniser avec notre controller
                        ctrl.text = _clientNomCtrl.text;
                        ctrl.addListener(() => _clientNomCtrl.text = ctrl.text);
                        return TextFormField(
                          controller: ctrl,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Nom du client *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.person),
                            suffixIcon: _clientSelectionne != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                          onChanged: (v) {
                            // Si l'user modifie manuellement, désélectionner le client
                            if (_clientSelectionne != null && v != _clientSelectionne!.nom) {
                              setState(() => _clientSelectionne = null);
                            }
                          },
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, i) {
                                  final c = options.elementAt(i);
                                  return ListTile(
                                    leading: const Icon(Icons.person),
                                    title: Text(c.nom),
                                    subtitle: Text(c.telephone),
                                    onTap: () => onSelected(c),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clientTelCtrl,
                      decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    if (_clientSelectionne == null && _clientNomCtrl.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                          child: const Row(children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.blue),
                            SizedBox(width: 6),
                            Expanded(child: Text('Nouveau client — sera créé automatiquement.', style: TextStyle(fontSize: 11, color: Colors.blue))),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lignes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lignes du devis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        TextButton.icon(
                          onPressed: _ajouterLigne,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const Divider(),
                    // En-têtes
                    const Row(
                      children: [
                        Expanded(flex: 4, child: Text('Désignation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                        SizedBox(width: 8),
                        SizedBox(width: 70, child: Text('Qté', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                        SizedBox(width: 8),
                        SizedBox(width: 100, child: Text('Prix unit.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                        SizedBox(width: 8),
                        SizedBox(width: 100, child: Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                        SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(
                        _lignes.length,
                        (i) => _LigneWidget(
                              key: ValueKey(i),
                              ligne: _lignes[i],
                              onChanged: () => setState(() {}),
                              onDelete: () => _supprimerLigne(i),
                            )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optionnel)', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${_fmt.format(_montantTotal)} FCFA', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Boutons
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _isLoading ? null : () => Get.back(), child: const Text('Annuler'))),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sauvegarder,
                    child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LigneForm {
  final TextEditingController designationCtrl;
  final TextEditingController quantiteCtrl;
  final TextEditingController prixCtrl;

  _LigneForm()
      : designationCtrl = TextEditingController(),
        quantiteCtrl = TextEditingController(text: '1'),
        prixCtrl = TextEditingController(text: '0');

  _LigneForm.fromLigne(LigneDevis l)
      : designationCtrl = TextEditingController(text: l.designation),
        quantiteCtrl = TextEditingController(text: l.quantite.toStringAsFixed(0)),
        prixCtrl = TextEditingController(text: l.prixUnitaire.toStringAsFixed(0));

  String get designation => designationCtrl.text.trim();
  double get quantite => double.tryParse(quantiteCtrl.text) ?? 0;
  double get prixUnitaire => double.tryParse(prixCtrl.text) ?? 0;
  double get total => quantite * prixUnitaire;

  void dispose() {
    designationCtrl.dispose();
    quantiteCtrl.dispose();
    prixCtrl.dispose();
  }
}

class _LigneWidget extends StatelessWidget {
  final _LigneForm ligne;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _LigneWidget({super.key, required this.ligne, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: TextField(
              controller: ligne.designationCtrl,
              decoration: const InputDecoration(hintText: 'Désignation', isDense: true, border: OutlineInputBorder()),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: TextField(
              controller: ligne.quantiteCtrl,
              decoration: const InputDecoration(hintText: 'Qté', isDense: true, border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextField(
              controller: ligne.prixCtrl,
              decoration: const InputDecoration(hintText: 'Prix', isDense: true, border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
              child: Text('${fmt.format(ligne.total)} FCFA', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: onDelete),
          ),
        ],
      ),
    );
  }
}
