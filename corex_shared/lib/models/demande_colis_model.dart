import 'package:cloud_firestore/cloud_firestore.dart';

class DemandeColisModel {
  final String? id;
  final String clientId;
  final String clientNom;
  final String clientEmail;
  final String clientTelephone;

  // Informations expéditeur
  final String expediteurNom;
  final String expediteurTelephone;
  final String expediteurAdresse;
  final String expediteurVille;
  final String? expediteurQuartier;

  // Informations destinataire
  final String destinataireNom;
  final String destinataireTelephone;
  final String destinataireAdresse;
  final String destinataireVille;
  final String? destinataireQuartier;

  // Informations colis
  final String description;
  final double? poids;
  final String? dimensions;
  final String? instructions;
  final double? valeurDeclaree;

  // Gestion de la demande
  final String statut; // enAttenteValidation, validee, rejetee
  final DateTime dateCreation;
  final String? validateurId;
  final String? validateurNom;
  final DateTime? dateValidation;
  final double? tarifValide; // Tarif fixé par le gestionnaire
  final String? commentaireValidation;
  final String? commentaireRejet;
  final String? colisId; // ID du colis créé après validation

  DemandeColisModel({
    this.id,
    required this.clientId,
    required this.clientNom,
    required this.clientEmail,
    required this.clientTelephone,
    required this.expediteurNom,
    required this.expediteurTelephone,
    required this.expediteurAdresse,
    required this.expediteurVille,
    this.expediteurQuartier,
    required this.destinataireNom,
    required this.destinataireTelephone,
    required this.destinataireAdresse,
    required this.destinataireVille,
    this.destinataireQuartier,
    required this.description,
    this.poids,
    this.dimensions,
    this.instructions,
    this.valeurDeclaree,
    this.statut = 'enAttenteValidation',
    DateTime? dateCreation,
    this.validateurId,
    this.validateurNom,
    this.dateValidation,
    this.tarifValide,
    this.commentaireValidation,
    this.commentaireRejet,
    this.colisId,
  }) : dateCreation = dateCreation ?? DateTime.now();

  factory DemandeColisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DemandeColisModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      clientNom: data['clientNom'] ?? '',
      clientEmail: data['clientEmail'] ?? '',
      clientTelephone: data['clientTelephone'] ?? '',
      expediteurNom: data['expediteurNom'] ?? '',
      expediteurTelephone: data['expediteurTelephone'] ?? '',
      expediteurAdresse: data['expediteurAdresse'] ?? '',
      expediteurVille: data['expediteurVille'] ?? '',
      expediteurQuartier: data['expediteurQuartier'],
      destinataireNom: data['destinataireNom'] ?? '',
      destinataireTelephone: data['destinataireTelephone'] ?? '',
      destinataireAdresse: data['destinataireAdresse'] ?? '',
      destinataireVille: data['destinataireVille'] ?? '',
      destinataireQuartier: data['destinataireQuartier'],
      description: data['description'] ?? '',
      poids: data['poids']?.toDouble(),
      dimensions: data['dimensions'],
      instructions: data['instructions'],
      valeurDeclaree: data['valeurDeclaree']?.toDouble(),
      statut: data['statut'] ?? 'enAttenteValidation',
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validateurId: data['validateurId'],
      validateurNom: data['validateurNom'],
      dateValidation: (data['dateValidation'] as Timestamp?)?.toDate(),
      tarifValide: data['tarifValide']?.toDouble(),
      commentaireValidation: data['commentaireValidation'],
      commentaireRejet: data['commentaireRejet'],
      colisId: data['colisId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientNom': clientNom,
      'clientEmail': clientEmail,
      'clientTelephone': clientTelephone,
      'expediteurNom': expediteurNom,
      'expediteurTelephone': expediteurTelephone,
      'expediteurAdresse': expediteurAdresse,
      'expediteurVille': expediteurVille,
      'expediteurQuartier': expediteurQuartier,
      'destinataireNom': destinataireNom,
      'destinataireTelephone': destinataireTelephone,
      'destinataireAdresse': destinataireAdresse,
      'destinataireVille': destinataireVille,
      'destinataireQuartier': destinataireQuartier,
      'description': description,
      'poids': poids,
      'dimensions': dimensions,
      'instructions': instructions,
      'valeurDeclaree': valeurDeclaree,
      'statut': statut,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'validateurId': validateurId,
      'validateurNom': validateurNom,
      'dateValidation': dateValidation != null ? Timestamp.fromDate(dateValidation!) : null,
      'tarifValide': tarifValide,
      'commentaireValidation': commentaireValidation,
      'commentaireRejet': commentaireRejet,
      'colisId': colisId,
    };
  }

  DemandeColisModel copyWith({
    String? id,
    String? clientId,
    String? clientNom,
    String? clientEmail,
    String? clientTelephone,
    String? expediteurNom,
    String? expediteurTelephone,
    String? expediteurAdresse,
    String? expediteurVille,
    String? expediteurQuartier,
    String? destinataireNom,
    String? destinataireTelephone,
    String? destinataireAdresse,
    String? destinataireVille,
    String? destinataireQuartier,
    String? description,
    double? poids,
    String? dimensions,
    String? instructions,
    double? valeurDeclaree,
    String? statut,
    DateTime? dateCreation,
    String? validateurId,
    String? validateurNom,
    DateTime? dateValidation,
    double? tarifValide,
    String? commentaireValidation,
    String? commentaireRejet,
    String? colisId,
  }) {
    return DemandeColisModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientNom: clientNom ?? this.clientNom,
      clientEmail: clientEmail ?? this.clientEmail,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      expediteurNom: expediteurNom ?? this.expediteurNom,
      expediteurTelephone: expediteurTelephone ?? this.expediteurTelephone,
      expediteurAdresse: expediteurAdresse ?? this.expediteurAdresse,
      expediteurVille: expediteurVille ?? this.expediteurVille,
      expediteurQuartier: expediteurQuartier ?? this.expediteurQuartier,
      destinataireNom: destinataireNom ?? this.destinataireNom,
      destinataireTelephone: destinataireTelephone ?? this.destinataireTelephone,
      destinataireAdresse: destinataireAdresse ?? this.destinataireAdresse,
      destinataireVille: destinataireVille ?? this.destinataireVille,
      destinataireQuartier: destinataireQuartier ?? this.destinataireQuartier,
      description: description ?? this.description,
      poids: poids ?? this.poids,
      dimensions: dimensions ?? this.dimensions,
      instructions: instructions ?? this.instructions,
      valeurDeclaree: valeurDeclaree ?? this.valeurDeclaree,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
      validateurId: validateurId ?? this.validateurId,
      validateurNom: validateurNom ?? this.validateurNom,
      dateValidation: dateValidation ?? this.dateValidation,
      tarifValide: tarifValide ?? this.tarifValide,
      commentaireValidation: commentaireValidation ?? this.commentaireValidation,
      commentaireRejet: commentaireRejet ?? this.commentaireRejet,
      colisId: colisId ?? this.colisId,
    );
  }

  @override
  String toString() {
    return 'DemandeColisModel(id: $id, clientNom: $clientNom, expediteur: $expediteurNom, destinataire: $destinataireNom, statut: $statut)';
  }
}
