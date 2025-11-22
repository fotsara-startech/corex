import 'package:get/get.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'auth_controller.dart';

class TransactionController extends GetxController {
  final TransactionService _transactionService = Get.find<TransactionService>();

  final RxList<TransactionModel> transactionsList = <TransactionModel>[].obs;
  final RxDouble soldeActuel = 0.0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final agenceId = authController.currentUser.value?.agenceId;

      if (agenceId == null) return;

      transactionsList.value = await _transactionService.getTransactionsByAgence(agenceId);
      _calculateSolde();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les transactions');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateSolde() {
    double recettes = transactionsList.where((t) => t.type == 'recette').fold(0, (sum, t) => sum + t.montant);

    double depenses = transactionsList.where((t) => t.type == 'depense').fold(0, (sum, t) => sum + t.montant);

    soldeActuel.value = recettes - depenses;
  }

  Future<void> createTransaction(TransactionModel transaction) async {
    try {
      await _transactionService.createTransaction(transaction);
      Get.snackbar('Succès', 'Transaction enregistrée');
      await loadTransactions();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'enregistrer la transaction');
    }
  }
}
