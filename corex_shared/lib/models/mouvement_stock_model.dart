import 'package:cloud_firestore/cloud_firestore.dart';

class MouvementStockModel {
  final String id;
  final String depotId; // Référence au dépôt
  final String clientId; // Référence au client
  final String agenceId;
  final String type; // 'depot' ou 'retrait'
  final List<ProduitMouvement> produits; // Produits concernés par le mouvement
  final DateTime dateMouvement;
  final String userId; // Utilisateur qui a effectué le mouvement
  final String? notes;
  final DateTime createdAt;

  MouvementStockModel({
    required this.id,
    required this.depotId,
    required this.clientId,
    required this.agenceId,
    required this.type,
    required this.produits,
    required this.dateMouvement,
    required this.userId,
    this.notes,
    required this.createdAt,
  });

  factory MouvementStockModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MouvementStockModel(
      id: doc.id,
      depotId: data['depotId'] ?? '',
      clientId: data['clientId'] ?? '',
      agenceId: data['agenceId'] ?? '',
      type: data['type'] ?? 'depot',
      produits: (data['produits'] as List<dynamic>?)
              ?.map((p) => ProduitMouvement.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      dateMouvement: (data['dateMouvement'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'depotId': depotId,
      'clientId': clientId,
      'agenceId': agenceId,
      'type': type,
      'produits': produits.map((p) => p.toMap()).toList(),
      'dateMouvement': Timestamp.fromDate(dateMouvement),
      'userId': userId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ProduitMouvement {
  final String nom;
  final double quantite;
  final String unite;

  ProduitMouvement({
    required this.nom,
    required this.quantite,
    required this.unite,
  });

  factory ProduitMouvement.fromMap(Map<String, dynamic> map) {
    return ProduitMouvement(
      nom: map['nom'] ?? '',
      quantite: (map['quantite'] ?? 0).toDouble(),
      unite: map['unite'] ?? 'pieces',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'quantite': quantite,
      'unite': unite,
    };
  }
}
