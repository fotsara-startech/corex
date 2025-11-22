import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String agenceId;
  final String type; // recette, depense
  final double montant;
  final DateTime date;
  final String? categorieRecette;
  final String? categorieDepense;
  final String description;
  final String? reference;
  final String userId;
  final String? justificatifUrl;

  TransactionModel({
    required this.id,
    required this.agenceId,
    required this.type,
    required this.montant,
    required this.date,
    this.categorieRecette,
    this.categorieDepense,
    required this.description,
    this.reference,
    required this.userId,
    this.justificatifUrl,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      agenceId: data['agenceId'] ?? '',
      type: data['type'] ?? '',
      montant: (data['montant'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      categorieRecette: data['categorieRecette'],
      categorieDepense: data['categorieDepense'],
      description: data['description'] ?? '',
      reference: data['reference'],
      userId: data['userId'] ?? '',
      justificatifUrl: data['justificatifUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'agenceId': agenceId,
      'type': type,
      'montant': montant,
      'date': Timestamp.fromDate(date),
      'categorieRecette': categorieRecette,
      'categorieDepense': categorieDepense,
      'description': description,
      'reference': reference,
      'userId': userId,
      'justificatifUrl': justificatifUrl,
    };
  }
}
