import 'package:cloud_firestore/cloud_firestore.dart';

class LivraisonModel {
  final String id;
  final String colisId;
  final String coursierId;
  final String agenceId;
  final String zone;
  final DateTime dateCreation;
  final DateTime? heureDepart;
  final DateTime? heureRetour;
  final String statut; // enAttente, enCours, livree, echec
  final String? motifEchec;
  final String? commentaire;

  LivraisonModel({
    required this.id,
    required this.colisId,
    required this.coursierId,
    required this.agenceId,
    required this.zone,
    required this.dateCreation,
    this.heureDepart,
    this.heureRetour,
    required this.statut,
    this.motifEchec,
    this.commentaire,
  });

  factory LivraisonModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LivraisonModel(
      id: doc.id,
      colisId: data['colisId'] ?? '',
      coursierId: data['coursierId'] ?? '',
      agenceId: data['agenceId'] ?? '',
      zone: data['zone'] ?? '',
      dateCreation: (data['dateCreation'] as Timestamp).toDate(),
      heureDepart: data['heureDepart'] != null ? (data['heureDepart'] as Timestamp).toDate() : null,
      heureRetour: data['heureRetour'] != null ? (data['heureRetour'] as Timestamp).toDate() : null,
      statut: data['statut'] ?? 'enAttente',
      motifEchec: data['motifEchec'],
      commentaire: data['commentaire'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'colisId': colisId,
      'coursierId': coursierId,
      'agenceId': agenceId,
      'zone': zone,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'heureDepart': heureDepart != null ? Timestamp.fromDate(heureDepart!) : null,
      'heureRetour': heureRetour != null ? Timestamp.fromDate(heureRetour!) : null,
      'statut': statut,
      'motifEchec': motifEchec,
      'commentaire': commentaire,
    };
  }
}
