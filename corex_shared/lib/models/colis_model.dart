import 'package:cloud_firestore/cloud_firestore.dart';

class HistoriqueStatut {
  final String statut;
  final DateTime date;
  final String userId;
  final String? commentaire;

  HistoriqueStatut({
    required this.statut,
    required this.date,
    required this.userId,
    this.commentaire,
  });

  factory HistoriqueStatut.fromMap(Map<String, dynamic> map) {
    return HistoriqueStatut(
      statut: map['statut'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
      commentaire: map['commentaire'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'statut': statut,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'commentaire': commentaire,
    };
  }
}

class ColisModel {
  final String id;
  final String numeroSuivi;
  final String expediteurNom;
  final String expediteurTelephone;
  final String? expediteurEmail;
  final String expediteurAdresse;
  final String destinataireNom;
  final String destinataireTelephone;
  final String? destinataireEmail;
  final String destinataireAdresse;
  final String destinataireVille;
  final String? destinataireQuartier;
  final String contenu;
  final double poids;
  final String? dimensions;
  final double montantTarif;
  final bool isPaye;
  final DateTime? datePaiement;
  final String modeLivraison;
  final String? zoneId;
  final String? agenceTransportId;
  final String? agenceTransportNom;
  final double? tarifAgenceTransport;
  final String statut;
  final String agenceCorexId;
  final String commercialId;
  final String? coursierId;
  final DateTime dateCollecte;
  final DateTime? dateEnregistrement;
  final DateTime? dateLivraison;
  final List<HistoriqueStatut> historique;
  final String? commentaire;
  final bool isRetour;
  final String? colisInitialId;
  final String? retourId;

  ColisModel({
    required this.id,
    required this.numeroSuivi,
    required this.expediteurNom,
    required this.expediteurTelephone,
    this.expediteurEmail,
    required this.expediteurAdresse,
    required this.destinataireNom,
    required this.destinataireTelephone,
    this.destinataireEmail,
    required this.destinataireAdresse,
    required this.destinataireVille,
    this.destinataireQuartier,
    required this.contenu,
    required this.poids,
    this.dimensions,
    required this.montantTarif,
    required this.isPaye,
    this.datePaiement,
    required this.modeLivraison,
    this.zoneId,
    this.agenceTransportId,
    this.agenceTransportNom,
    this.tarifAgenceTransport,
    required this.statut,
    required this.agenceCorexId,
    required this.commercialId,
    this.coursierId,
    required this.dateCollecte,
    this.dateEnregistrement,
    this.dateLivraison,
    required this.historique,
    this.commentaire,
    required this.isRetour,
    this.colisInitialId,
    this.retourId,
  });

  factory ColisModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ColisModel(
      id: doc.id,
      numeroSuivi: data['numeroSuivi'] ?? '',
      expediteurNom: data['expediteurNom'] ?? '',
      expediteurTelephone: data['expediteurTelephone'] ?? '',
      expediteurEmail: data['expediteurEmail'],
      expediteurAdresse: data['expediteurAdresse'] ?? '',
      destinataireNom: data['destinataireNom'] ?? '',
      destinataireTelephone: data['destinataireTelephone'] ?? '',
      destinataireEmail: data['destinataireEmail'],
      destinataireAdresse: data['destinataireAdresse'] ?? '',
      destinataireVille: data['destinataireVille'] ?? '',
      destinataireQuartier: data['destinataireQuartier'],
      contenu: data['contenu'] ?? '',
      poids: (data['poids'] ?? 0).toDouble(),
      dimensions: data['dimensions'],
      montantTarif: (data['montantTarif'] ?? 0).toDouble(),
      isPaye: data['isPaye'] ?? false,
      datePaiement: data['datePaiement'] != null ? (data['datePaiement'] as Timestamp).toDate() : null,
      modeLivraison: data['modeLivraison'] ?? '',
      zoneId: data['zoneId'],
      agenceTransportId: data['agenceTransportId'],
      agenceTransportNom: data['agenceTransportNom'],
      tarifAgenceTransport: data['tarifAgenceTransport']?.toDouble(),
      statut: data['statut'] ?? '',
      agenceCorexId: data['agenceCorexId'] ?? '',
      commercialId: data['commercialId'] ?? '',
      coursierId: data['coursierId'],
      dateCollecte: (data['dateCollecte'] as Timestamp).toDate(),
      dateEnregistrement: data['dateEnregistrement'] != null ? (data['dateEnregistrement'] as Timestamp).toDate() : null,
      dateLivraison: data['dateLivraison'] != null ? (data['dateLivraison'] as Timestamp).toDate() : null,
      historique: (data['historique'] as List<dynamic>?)?.map((h) => HistoriqueStatut.fromMap(h as Map<String, dynamic>)).toList() ?? [],
      commentaire: data['commentaire'],
      isRetour: data['isRetour'] ?? false,
      colisInitialId: data['colisInitialId'],
      retourId: data['retourId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'numeroSuivi': numeroSuivi,
      'expediteurNom': expediteurNom,
      'expediteurTelephone': expediteurTelephone,
      'expediteurEmail': expediteurEmail,
      'expediteurAdresse': expediteurAdresse,
      'destinataireNom': destinataireNom,
      'destinataireTelephone': destinataireTelephone,
      'destinataireEmail': destinataireEmail,
      'destinataireAdresse': destinataireAdresse,
      'destinataireVille': destinataireVille,
      'destinataireQuartier': destinataireQuartier,
      'contenu': contenu,
      'poids': poids,
      'dimensions': dimensions,
      'montantTarif': montantTarif,
      'isPaye': isPaye,
      'datePaiement': datePaiement != null ? Timestamp.fromDate(datePaiement!) : null,
      'modeLivraison': modeLivraison,
      'zoneId': zoneId,
      'agenceTransportId': agenceTransportId,
      'agenceTransportNom': agenceTransportNom,
      'tarifAgenceTransport': tarifAgenceTransport,
      'statut': statut,
      'agenceCorexId': agenceCorexId,
      'commercialId': commercialId,
      'coursierId': coursierId,
      'dateCollecte': Timestamp.fromDate(dateCollecte),
      'dateEnregistrement': dateEnregistrement != null ? Timestamp.fromDate(dateEnregistrement!) : null,
      'dateLivraison': dateLivraison != null ? Timestamp.fromDate(dateLivraison!) : null,
      'historique': historique.map((h) => h.toMap()).toList(),
      'commentaire': commentaire,
      'isRetour': isRetour,
      'colisInitialId': colisInitialId,
      'retourId': retourId,
    };
  }

  /// Crée une copie du colis avec les champs modifiés
  ColisModel copyWith({
    String? id,
    String? numeroSuivi,
    String? expediteurNom,
    String? expediteurTelephone,
    String? expediteurEmail,
    String? expediteurAdresse,
    String? destinataireNom,
    String? destinataireTelephone,
    String? destinataireEmail,
    String? destinataireAdresse,
    String? destinataireVille,
    String? destinataireQuartier,
    String? contenu,
    double? poids,
    String? dimensions,
    double? montantTarif,
    bool? isPaye,
    DateTime? datePaiement,
    String? modeLivraison,
    String? zoneId,
    String? agenceTransportId,
    String? agenceTransportNom,
    double? tarifAgenceTransport,
    String? statut,
    String? agenceCorexId,
    String? commercialId,
    String? coursierId,
    DateTime? dateCollecte,
    DateTime? dateEnregistrement,
    DateTime? dateLivraison,
    List<HistoriqueStatut>? historique,
    String? commentaire,
    bool? isRetour,
    String? colisInitialId,
    String? retourId,
  }) {
    return ColisModel(
      id: id ?? this.id,
      numeroSuivi: numeroSuivi ?? this.numeroSuivi,
      expediteurNom: expediteurNom ?? this.expediteurNom,
      expediteurTelephone: expediteurTelephone ?? this.expediteurTelephone,
      expediteurEmail: expediteurEmail ?? this.expediteurEmail,
      expediteurAdresse: expediteurAdresse ?? this.expediteurAdresse,
      destinataireNom: destinataireNom ?? this.destinataireNom,
      destinataireTelephone: destinataireTelephone ?? this.destinataireTelephone,
      destinataireEmail: destinataireEmail ?? this.destinataireEmail,
      destinataireAdresse: destinataireAdresse ?? this.destinataireAdresse,
      destinataireVille: destinataireVille ?? this.destinataireVille,
      destinataireQuartier: destinataireQuartier ?? this.destinataireQuartier,
      contenu: contenu ?? this.contenu,
      poids: poids ?? this.poids,
      dimensions: dimensions ?? this.dimensions,
      montantTarif: montantTarif ?? this.montantTarif,
      isPaye: isPaye ?? this.isPaye,
      datePaiement: datePaiement ?? this.datePaiement,
      modeLivraison: modeLivraison ?? this.modeLivraison,
      zoneId: zoneId ?? this.zoneId,
      agenceTransportId: agenceTransportId ?? this.agenceTransportId,
      agenceTransportNom: agenceTransportNom ?? this.agenceTransportNom,
      tarifAgenceTransport: tarifAgenceTransport ?? this.tarifAgenceTransport,
      statut: statut ?? this.statut,
      agenceCorexId: agenceCorexId ?? this.agenceCorexId,
      commercialId: commercialId ?? this.commercialId,
      coursierId: coursierId ?? this.coursierId,
      dateCollecte: dateCollecte ?? this.dateCollecte,
      dateEnregistrement: dateEnregistrement ?? this.dateEnregistrement,
      dateLivraison: dateLivraison ?? this.dateLivraison,
      historique: historique ?? this.historique,
      commentaire: commentaire ?? this.commentaire,
      isRetour: isRetour ?? this.isRetour,
      colisInitialId: colisInitialId ?? this.colisInitialId,
      retourId: retourId ?? this.retourId,
    );
  }
}
