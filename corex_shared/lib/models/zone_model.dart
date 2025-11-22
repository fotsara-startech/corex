import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  final String id;
  final String nom;
  final String ville;
  final List<String> quartiers;
  final String agenceId;
  final double tarifLivraison;

  ZoneModel({
    required this.id,
    required this.nom,
    required this.ville,
    required this.quartiers,
    required this.agenceId,
    required this.tarifLivraison,
  });

  factory ZoneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ZoneModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      ville: data['ville'] ?? '',
      quartiers: List<String>.from(data['quartiers'] ?? []),
      agenceId: data['agenceId'] ?? '',
      tarifLivraison: (data['tarifLivraison'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'ville': ville,
      'quartiers': quartiers,
      'agenceId': agenceId,
      'tarifLivraison': tarifLivraison,
    };
  }
}
