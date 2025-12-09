import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/controllers/transaction_controller.dart';
import 'package:corex_shared/models/transaction_model.dart';
import 'package:intl/intl.dart';

class HistoriqueTransactionsScreen extends StatefulWidget {
  const HistoriqueTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<HistoriqueTransactionsScreen> createState() => _HistoriqueTransactionsScreenState();
}

class _HistoriqueTransactionsScreenState extends State<HistoriqueTransactionsScreen> {
  final transactionController = Get.find<TransactionController>();
  final currencyFormat = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _typeFiltre; // 'recette', 'depense', ou null pour tous
  String? _categorieFiltre;

  @override
  void initState() {
    super.initState();
    // Recharger les transactions à chaque fois qu'on arrive sur cet écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      transactionController.loadTransactions();
    });
  }

  List<TransactionModel> get _filteredTransactions {
    var transactions = transactionController.transactionsList.toList();

    // Filtre par date
    if (_dateDebut != null) {
      transactions = transactions.where((t) => t.date.isAfter(_dateDebut!)).toList();
    }
    if (_dateFin != null) {
      final finJournee = DateTime(_dateFin!.year, _dateFin!.month, _dateFin!.day, 23, 59, 59);
      transactions = transactions.where((t) => t.date.isBefore(finJournee)).toList();
    }

    // Filtre par type
    if (_typeFiltre != null) {
      transactions = transactions.where((t) => t.type == _typeFiltre).toList();
    }

    // Filtre par catégorie
    if (_categorieFiltre != null) {
      transactions = transactions.where((t) {
        if (t.type == 'recette') {
          return t.categorieRecette == _categorieFiltre;
        } else {
          return t.categorieDepense == _categorieFiltre;
        }
      }).toList();
    }

    return transactions;
  }

  double get _totalRecettes {
    return _filteredTransactions.where((t) => t.type == 'recette').fold(0.0, (sum, t) => sum + t.montant);
  }

  double get _totalDepenses {
    return _filteredTransactions.where((t) => t.type == 'depense').fold(0.0, (sum, t) => sum + t.montant);
  }

  double get _soldeFiltre {
    return _totalRecettes - _totalDepenses;
  }

  Future<void> _selectDateDebut() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateDebut ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dateDebut = date);
    }
  }

  Future<void> _selectDateFin() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dateFin = date);
    }
  }

  void _resetFilters() {
    setState(() {
      _dateDebut = null;
      _dateFin = null;
      _typeFiltre = null;
      _categorieFiltre = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Transactions'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Obx(() {
        if (transactionController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Filtres
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDateDebut,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _dateDebut == null ? 'Date début' : DateFormat('dd/MM/yyyy').format(_dateDebut!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDateFin,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _dateFin == null ? 'Date fin' : DateFormat('dd/MM/yyyy').format(_dateFin!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _typeFiltre,
                          decoration: const InputDecoration(
                            labelText: 'Type',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tous')),
                            DropdownMenuItem(value: 'recette', child: Text('Recettes')),
                            DropdownMenuItem(value: 'depense', child: Text('Dépenses')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _typeFiltre = value;
                              _categorieFiltre = null; // Reset catégorie
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.clear),
                          label: const Text('Réinitialiser'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Statistiques filtrées
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatChip('Recettes', _totalRecettes, Colors.green),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip('Dépenses', _totalDepenses, Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(
                      'Solde',
                      _soldeFiltre,
                      _soldeFiltre >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Liste des transactions
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? const Center(
                      child: Text('Aucune transaction trouvée'),
                    )
                  : ListView.separated(
                      itemCount: _filteredTransactions.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final transaction = _filteredTransactions[index];
                        return _buildTransactionTile(transaction);
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel transaction) {
    final isRecette = transaction.type == 'recette';
    final categorie = isRecette ? transaction.categorieRecette : transaction.categorieDepense;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isRecette ? Colors.green.shade100 : Colors.red.shade100,
        child: Icon(
          isRecette ? Icons.arrow_upward : Icons.arrow_downward,
          color: isRecette ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transaction.description,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd/MM/yyyy à HH:mm').format(transaction.date)),
          if (categorie != null)
            Text(
              _getCategorieLabel(categorie),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(transaction.montant),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRecette ? Colors.green : Colors.red,
              fontSize: 16,
            ),
          ),
          if (transaction.reference != null)
            Text(
              transaction.reference!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  String _getCategorieLabel(String categorie) {
    const labels = {
      // Recettes
      'expedition': 'Expédition',
      'livraison': 'Livraison',
      'retour': 'Retour',
      'courses': 'Courses',
      'stockage': 'Stockage',
      // Dépenses
      'transport': 'Transport',
      'salaires': 'Salaires',
      'loyer': 'Loyer',
      'carburant': 'Carburant',
      'internet': 'Internet',
      'electricite': 'Électricité',
      'autre': 'Autre',
    };
    return labels[categorie] ?? categorie;
  }
}
