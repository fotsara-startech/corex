import 'package:cloud_firestore/cloud_firestore.dart';

class LigneDevis {
  final String designation;
  final double quantite;
  final double prixUnitaire;
  final double total; // quantite × prixUnitaire

  LigneDevis({
    required this.designation,
    required this.quantite,
    required this.prixUnitaire,
    required this.total,
  });

  factory LigneDevis.fromMap(Map<String, dynamic> map) {
    return LigneDevis(
      designation: map['designation'] ?? '',
      quantite: (map['quantite'] ?? 0).toDouble(),
      prixUnitaire: (map['prixUnitaire'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'designation': designation,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
      'total': total,
    };
  }

  LigneDevis copyWith({String? designation, double? quantite, double? prixUnitaire}) {
    final q = quantite ?? this.quantite;
    final p = prixUnitaire ?? this.prixUnitaire;
    return LigneDevis(
      designation: designation ?? this.designation,
      quantite: q,
      prixUnitaire: p,
      total: q * p,
    );
  }
}

class DevisModel {
  final String id;
  final String numeroDevis;
  final String clientNom;
  final String clientTelephone;
  final String agenceId;
  final String userId;
  final List<LigneDevis> lignes;
  final double montantTotal;
  final String statut; // brouillon | envoye | valide | refuse | converti
  final DateTime dateCreation;
  final DateTime dateModification;
  final DateTime? dateValidation;
  final String? transactionId;
  final String? factureId;
  final String? notes;

  DevisModel({
    required this.id,
    required this.numeroDevis,
    required this.clientNom,
    required this.clientTelephone,
    required this.agenceId,
    required this.userId,
    required this.lignes,
    required this.montantTotal,
    required this.statut,
    required this.dateCreation,
    required this.dateModification,
    this.dateValidation,
    this.transactionId,
    this.factureId,
    this.notes,
  });

  bool get canEdit => statut == 'brouillon' || statut == 'envoye';
  bool get canDelete => statut == 'brouillon' || statut == 'envoye';
  bool get canValider => statut == 'brouillon' || statut == 'envoye';
  bool get canConvertir => statut == 'valide';

  factory DevisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DevisModel(
      id: doc.id,
      numeroDevis: data['numeroDevis'] ?? '',
      clientNom: data['clientNom'] ?? '',
      clientTelephone: data['clientTelephone'] ?? '',
      agenceId: data['agenceId'] ?? '',
      userId: data['userId'] ?? '',
      lignes: (data['lignes'] as List<dynamic>?)?.map((l) => LigneDevis.fromMap(l as Map<String, dynamic>)).toList() ?? [],
      montantTotal: (data['montantTotal'] ?? 0).toDouble(),
      statut: data['statut'] ?? 'brouillon',
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      dateModification: (data['dateModification'] as Timestamp).toDate(),
      dateValidation: data['dateValidation'] != null ? (data['dateValidation'] as Timestamp).toDate() : null,
      transactionId: data['transactionId'],
      factureId: data['factureId'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'numeroDevis': numeroDevis,
      'clientNom': clientNom,
      'clientTelephone': clientTelephone,
      'agenceId': agenceId,
      'userId': userId,
      'lignes': lignes.map((l) => l.toMap()).toList(),
      'montantTotal': montantTotal,
      'statut': statut,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': Timestamp.fromDate(dateModification),
      'dateValidation': dateValidation != null ? Timestamp.fromDate(dateValidation!) : null,
      'transactionId': transactionId,
      'factureId': factureId,
      'notes': notes,
    };
  }

  DevisModel copyWith({
    String? numeroDevis,
    String? clientNom,
    String? clientTelephone,
    List<LigneDevis>? lignes,
    double? montantTotal,
    String? statut,
    DateTime? dateModification,
    DateTime? dateValidation,
    String? transactionId,
    String? factureId,
    String? notes,
  }) {
    return DevisModel(
      id: id,
      numeroDevis: numeroDevis ?? this.numeroDevis,
      clientNom: clientNom ?? this.clientNom,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      agenceId: agenceId,
      userId: userId,
      lignes: lignes ?? this.lignes,
      montantTotal: montantTotal ?? this.montantTotal,
      statut: statut ?? this.statut,
      dateCreation: dateCreation,
      dateModification: dateModification ?? this.dateModification,
      dateValidation: dateValidation ?? this.dateValidation,
      transactionId: transactionId ?? this.transactionId,
      factureId: factureId ?? this.factureId,
      notes: notes ?? this.notes,
    );
  }
}
