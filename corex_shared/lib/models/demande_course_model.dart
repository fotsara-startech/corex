import 'package:cloud_firestore/cloud_firestore.dart';

class DemandeCoursModel {
  final String? id;
  final String clientId;
  final String clientNom;
  final String clientEmail;
  final String clientTelephone;
  final String lieu;
  final String tache;
  final String instructions;
  final double? budgetMax; // Budget maximum du client
  final String statut; // enAttenteValidation, validee, rejetee
  final DateTime dateCreation;
  final String? validateurId;
  final String? validateurNom;
  final DateTime? dateValidation;
  final double? tarifValide; // Tarif fixé par le gestionnaire
  final String? commentaireValidation;
  final String? commentaireRejet;
  final String? courseId; // ID de la course créée après validation

  DemandeCoursModel({
    this.id,
    required this.clientId,
    required this.clientNom,
    required this.clientEmail,
    required this.clientTelephone,
    required this.lieu,
    required this.tache,
    required this.instructions,
    this.budgetMax,
    this.statut = 'enAttenteValidation',
    DateTime? dateCreation,
    this.validateurId,
    this.validateurNom,
    this.dateValidation,
    this.tarifValide,
    this.commentaireValidation,
    this.commentaireRejet,
    this.courseId,
  }) : dateCreation = dateCreation ?? DateTime.now();

  factory DemandeCoursModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DemandeCoursModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientNom: data['clientNom'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      clientTelephone: data['clientTelephone'] ?? '',
      lieu: data['lieu'] ?? '',
      tache: data['tache'] ?? '',
      instructions: data['instructions'] ?? '',
      budgetMax: data['budgetMax']?.toDouble(),
      statut: data['statut'] ?? 'enAttenteValidation',
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validateurId: data['validateurId'],
      validateurNom: data['validateurNom'],
      dateValidation: (data['dateValidation'] as Timestamp?)?.toDate(),
      tarifValide: data['tarifValide']?.toDouble(),
      commentaireValidation: data['commentaireValidation'],
      commentaireRejet: data['commentaireRejet'],
      courseId: data['courseId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientNom': clientNom,
      'clientEmail': clientEmail,
      'clientTelephone': clientTelephone,
      'lieu': lieu,
      'tache': tache,
      'instructions': instructions,
      'budgetMax': budgetMax,
      'statut': statut,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'validateurId': validateurId,
      'validateurNom': validateurNom,
      'dateValidation': dateValidation != null ? Timestamp.fromDate(dateValidation!) : null,
      'tarifValide': tarifValide,
      'commentaireValidation': commentaireValidation,
      'commentaireRejet': commentaireRejet,
      'courseId': courseId,
    };
  }

  DemandeCoursModel copyWith({
    String? id,
    String? clientId,
    String? clientNom,
    String? clientEmail,
    String? clientTelephone,
    String? lieu,
    String? tache,
    String? instructions,
    double? budgetMax,
    String? statut,
    DateTime? dateCreation,
    String? validateurId,
    String? validateurNom,
    DateTime? dateValidation,
    double? tarifValide,
    String? commentaireValidation,
    String? commentaireRejet,
    String? courseId,
  }) {
    return DemandeCoursModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientNom: clientNom ?? this.clientNom,
      clientEmail: clientEmail ?? this.clientEmail,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      lieu: lieu ?? this.lieu,
      tache: tache ?? this.tache,
      instructions: instructions ?? this.instructions,
      budgetMax: budgetMax ?? this.budgetMax,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
      validateurId: validateurId ?? this.validateurId,
      validateurNom: validateurNom ?? this.validateurNom,
      dateValidation: dateValidation ?? this.dateValidation,
      tarifValide: tarifValide ?? this.tarifValide,
      commentaireValidation: commentaireValidation ?? this.commentaireValidation,
      commentaireRejet: commentaireRejet ?? this.commentaireRejet,
      courseId: courseId ?? this.courseId,
    );
  }

  @override
  String toString() {
    return 'DemandeCoursModel(id: $id, clientNom: $clientNom, lieu: $lieu, tache: $tache, statut: $statut)';
  }
}
