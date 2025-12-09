import 'package:cloud_firestore/cloud_firestore.dart';

class FactureStockageModel {
  final String id;
  final String numeroFacture; // Format: FACT-YYYY-MM-XXXXXX
  final String clientId; // Référence au client stockeur
  final String agenceId;
  final List<String> depotIds; // Liste des dépôts facturés
  final DateTime periodeDebut;
  final DateTime periodeFin;
  final double montantTotal;
  final String statut; // 'impayee', 'payee', 'annulee'
  final DateTime? datePaiement;
  final String? transactionId; // Référence à la transaction de paiement
  final DateTime dateEmission;
  final String userId; // Utilisateur qui a généré la facture
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FactureStockageModel({
    required this.id,
    required this.numeroFacture,
    required this.clientId,
    required this.agenceId,
    required this.depotIds,
    required this.periodeDebut,
    required this.periodeFin,
    required this.montantTotal,
    required this.statut,
    this.datePaiement,
    this.transactionId,
    required this.dateEmission,
    required this.userId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FactureStockageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FactureStockageModel(
      id: doc.id,
      numeroFacture: data['numeroFacture'] ?? '',
      clientId: data['clientId'] ?? '',
      agenceId: data['agenceId'] ?? '',
      depotIds: List<String>.from(data['depotIds'] ?? []),
      periodeDebut: (data['periodeDebut'] as Timestamp).toDate(),
      periodeFin: (data['periodeFin'] as Timestamp).toDate(),
      montantTotal: (data['montantTotal'] ?? 0).toDouble(),
      statut: data['statut'] ?? 'impayee',
      datePaiement: data['datePaiement'] != null
          ? (data['datePaiement'] as Timestamp).toDate()
          : null,
      transactionId: data['transactionId'],
      dateEmission: (data['dateEmission'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'numeroFacture': numeroFacture,
      'clientId': clientId,
      'agenceId': agenceId,
      'depotIds': depotIds,
      'periodeDebut': Timestamp.fromDate(periodeDebut),
      'periodeFin': Timestamp.fromDate(periodeFin),
      'montantTotal': montantTotal,
      'statut': statut,
      'datePaiement': datePaiement != null ? Timestamp.fromDate(datePaiement!) : null,
      'transactionId': transactionId,
      'dateEmission': Timestamp.fromDate(dateEmission),
      'userId': userId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FactureStockageModel copyWith({
    String? statut,
    DateTime? datePaiement,
    String? transactionId,
    String? notes,
    DateTime? updatedAt,
  }) {
    return FactureStockageModel(
      id: id,
      numeroFacture: numeroFacture,
      clientId: clientId,
      agenceId: agenceId,
      depotIds: depotIds,
      periodeDebut: periodeDebut,
      periodeFin: periodeFin,
      montantTotal: montantTotal,
      statut: statut ?? this.statut,
      datePaiement: datePaiement ?? this.datePaiement,
      transactionId: transactionId ?? this.transactionId,
      dateEmission: dateEmission,
      userId: userId,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
