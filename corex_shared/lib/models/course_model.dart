import 'package:cloud_firestore/cloud_firestore.dart';

class CourseModel {
  final String? id;
  final String clientId;
  final String clientNom;
  final String clientTelephone;
  final String instructions;
  final String lieu;
  final String tache;
  final double montantEstime;
  final double commissionPourcentage;
  final double commissionMontant;
  final String statut; // enAttente, enCours, terminee, annulee
  final String? coursierId;
  final String? coursierNom;
  final double? montantReel;
  final List<String> justificatifs; // URLs des photos de reçus
  final DateTime dateCreation;
  final DateTime? dateAttribution;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final String? commentaire;
  final String agenceId;
  final String createdBy;
  final String? modifiedBy;
  final DateTime? modifiedAt;
  final bool paye;
  final DateTime? datePaiement;

  CourseModel({
    this.id,
    required this.clientId,
    required this.clientNom,
    required this.clientTelephone,
    required this.instructions,
    required this.lieu,
    required this.tache,
    required this.montantEstime,
    this.commissionPourcentage = 10.0, // 10% par défaut
    double? commissionMontant,
    this.statut = 'enAttente',
    this.coursierId,
    this.coursierNom,
    this.montantReel,
    this.justificatifs = const [],
    DateTime? dateCreation,
    this.dateAttribution,
    this.dateDebut,
    this.dateFin,
    this.commentaire,
    required this.agenceId,
    required this.createdBy,
    this.modifiedBy,
    this.modifiedAt,
    this.paye = false,
    this.datePaiement,
  })  : dateCreation = dateCreation ?? DateTime.now(),
        commissionMontant = commissionMontant ?? (montantEstime * (commissionPourcentage / 100));

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientNom: data['clientNom'] ?? '',
      clientTelephone: data['clientTelephone'] ?? '',
      instructions: data['instructions'] ?? '',
      lieu: data['lieu'] ?? '',
      tache: data['tache'] ?? '',
      montantEstime: (data['montantEstime'] ?? 0).toDouble(),
      commissionPourcentage: (data['commissionPourcentage'] ?? 10.0).toDouble(),
      commissionMontant: (data['commissionMontant'] ?? 0).toDouble(),
      statut: data['statut'] ?? 'enAttente',
      coursierId: data['coursierId'],
      coursierNom: data['coursierNom'],
      montantReel: data['montantReel']?.toDouble(),
      justificatifs: List<String>.from(data['justificatifs'] ?? []),
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dateAttribution: (data['dateAttribution'] as Timestamp?)?.toDate(),
      dateDebut: (data['dateDebut'] as Timestamp?)?.toDate(),
      dateFin: (data['dateFin'] as Timestamp?)?.toDate(),
      commentaire: data['commentaire'],
      agenceId: data['agenceId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      modifiedBy: data['modifiedBy'],
      modifiedAt: (data['modifiedAt'] as Timestamp?)?.toDate(),
      paye: data['paye'] ?? false,
      datePaiement: (data['datePaiement'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientNom': clientNom,
      'clientTelephone': clientTelephone,
      'instructions': instructions,
      'lieu': lieu,
      'tache': tache,
      'montantEstime': montantEstime,
      'commissionPourcentage': commissionPourcentage,
      'commissionMontant': commissionMontant,
      'statut': statut,
      'coursierId': coursierId,
      'coursierNom': coursierNom,
      'montantReel': montantReel,
      'justificatifs': justificatifs,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateAttribution': dateAttribution != null ? Timestamp.fromDate(dateAttribution!) : null,
      'dateDebut': dateDebut != null ? Timestamp.fromDate(dateDebut!) : null,
      'dateFin': dateFin != null ? Timestamp.fromDate(dateFin!) : null,
      'commentaire': commentaire,
      'agenceId': agenceId,
      'createdBy': createdBy,
      'modifiedBy': modifiedBy,
      'modifiedAt': modifiedAt != null ? Timestamp.fromDate(modifiedAt!) : null,
      'paye': paye,
      'datePaiement': datePaiement != null ? Timestamp.fromDate(datePaiement!) : null,
    };
  }

  CourseModel copyWith({
    String? id,
    String? clientId,
    String? clientNom,
    String? clientTelephone,
    String? instructions,
    String? lieu,
    String? tache,
    double? montantEstime,
    double? commissionPourcentage,
    double? commissionMontant,
    String? statut,
    String? coursierId,
    String? coursierNom,
    double? montantReel,
    List<String>? justificatifs,
    DateTime? dateCreation,
    DateTime? dateAttribution,
    DateTime? dateDebut,
    DateTime? dateFin,
    String? commentaire,
    String? agenceId,
    String? createdBy,
    String? modifiedBy,
    DateTime? modifiedAt,
    bool? paye,
    DateTime? datePaiement,
  }) {
    return CourseModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientNom: clientNom ?? this.clientNom,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      instructions: instructions ?? this.instructions,
      lieu: lieu ?? this.lieu,
      tache: tache ?? this.tache,
      montantEstime: montantEstime ?? this.montantEstime,
      commissionPourcentage: commissionPourcentage ?? this.commissionPourcentage,
      commissionMontant: commissionMontant ?? this.commissionMontant,
      statut: statut ?? this.statut,
      coursierId: coursierId ?? this.coursierId,
      coursierNom: coursierNom ?? this.coursierNom,
      montantReel: montantReel ?? this.montantReel,
      justificatifs: justificatifs ?? this.justificatifs,
      dateCreation: dateCreation ?? this.dateCreation,
      dateAttribution: dateAttribution ?? this.dateAttribution,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      commentaire: commentaire ?? this.commentaire,
      agenceId: agenceId ?? this.agenceId,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      paye: paye ?? this.paye,
      datePaiement: datePaiement ?? this.datePaiement,
    );
  }

  @override
  String toString() {
    return 'CourseModel(id: $id, clientNom: $clientNom, lieu: $lieu, tache: $tache, montantEstime: $montantEstime, statut: $statut)';
  }
}
