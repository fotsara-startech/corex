import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/transaction_model.dart';
import 'firebase_service.dart';

class TransactionService extends GetxService {
  Future<void> createTransaction(TransactionModel transaction) async {
    await FirebaseService.transactions.doc(transaction.id).set(transaction.toFirestore());
  }

  Future<void> updateTransaction(String transactionId, Map<String, dynamic> data) async {
    await FirebaseService.transactions.doc(transactionId).update(data);
  }

  Future<TransactionModel?> getTransactionById(String transactionId) async {
    final doc = await FirebaseService.transactions.doc(transactionId).get();
    if (!doc.exists) return null;
    return TransactionModel.fromFirestore(doc);
  }

  Future<List<TransactionModel>> getTransactionsByAgence(String agenceId) async {
    final snapshot = await FirebaseService.transactions.where('agenceId', isEqualTo: agenceId).orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByPeriod(
    String agenceId,
    DateTime debut,
    DateTime fin,
  ) async {
    final snapshot = await FirebaseService.transactions
        .where('agenceId', isEqualTo: agenceId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(debut))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(fin))
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
  }

  Future<Map<String, double>> getBilanAgence(
    String agenceId,
    DateTime debut,
    DateTime fin,
  ) async {
    final transactions = await getTransactionsByPeriod(agenceId, debut, fin);

    double recettes = transactions.where((t) => t.type == 'recette').fold(0, (sum, t) => sum + t.montant);

    double depenses = transactions.where((t) => t.type == 'depense').fold(0, (sum, t) => sum + t.montant);

    return {
      'recettes': recettes,
      'depenses': depenses,
      'solde': recettes - depenses,
    };
  }

  Stream<List<TransactionModel>> watchTransactionsByAgence(String agenceId) {
    return FirebaseService.transactions
        .where('agenceId', isEqualTo: agenceId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList());
  }
}
