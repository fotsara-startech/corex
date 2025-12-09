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
  final String expediteurAdresse;
  final String destinataireNom;
  final String destinataireTelephone;
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
    required this.expediteurAdresse,
    required this.destinataireNom,
    required this.destinataireTelephone,
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
    this.isRetour = false,
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
      expediteurAdresse: data['expediteurAdresse'] ?? '',
      destinataireNom: data['destinataireNom'] ?? '',
      destinataireTelephone: data['destinataireTelephone'] ?? '',
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
      'expediteurAdresse': expediteurAdresse,
      'destinataireNom': destinataireNom,
      'destinataireTelephone': destinataireTelephone,
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
}
