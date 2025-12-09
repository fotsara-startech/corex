import 'package:cloud_firestore/cloud_firestore.dart';

class DepotModel {
  final String id;
  final String clientId; // Référence au client stockeur
  final String agenceId; // Agence où est stocké
  final List<ProduitStocke> produits; // Liste des produits déposés
  final String emplacement; // Zone, étagère, etc.
  final double tarifMensuel; // Tarif mensuel de stockage
  final String typeTarif; // 'global' ou 'par_produit'
  final DateTime dateDepot;
  final String userId; // Utilisateur qui a enregistré le dépôt
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DepotModel({
    required this.id,
    required this.clientId,
    required this.agenceId,
    required this.produits,
    required this.emplacement,
    required this.tarifMensuel,
    required this.typeTarif,
    required this.dateDepot,
    required this.userId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DepotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepotModel(
      id: doc.id,
      clientId: data['clientId'] ?? '',
      agenceId: data['agenceId'] ?? '',
      produits: (data['produits'] as List<dynamic>?)
              ?.map((p) => ProduitStocke.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      emplacement: data['emplacement'] ?? '',
      tarifMensuel: (data['tarifMensuel'] ?? 0).toDouble(),
      typeTarif: data['typeTarif'] ?? 'global',
      dateDepot: (data['dateDepot'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'agenceId': agenceId,
      'produits': produits.map((p) => p.toMap()).toList(),
      'emplacement': emplacement,
      'tarifMensuel': tarifMensuel,
      'typeTarif': typeTarif,
      'dateDepot': Timestamp.fromDate(dateDepot),
      'userId': userId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DepotModel copyWith({
    List<ProduitStocke>? produits,
    String? emplacement,
    double? tarifMensuel,
    String? notes,
    DateTime? updatedAt,
  }) {
    return DepotModel(
      id: id,
      clientId: clientId,
      agenceId: agenceId,
      produits: produits ?? this.produits,
      emplacement: emplacement ?? this.emplacement,
      tarifMensuel: tarifMensuel ?? this.tarifMensuel,
      typeTarif: typeTarif,
      dateDepot: dateDepot,
      userId: userId,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ProduitStocke {
  final String nom;
  final String description;
  final double quantite;
  final String unite; // 'kg', 'pieces', 'cartons', etc.
  final double? tarifUnitaire; // Si tarif par produit
  final String? photo; // URL de la photo du produit

  ProduitStocke({
    required this.nom,
    required this.description,
    required this.quantite,
    required this.unite,
    this.tarifUnitaire,
    this.photo,
  });

  factory ProduitStocke.fromMap(Map<String, dynamic> map) {
    return ProduitStocke(
      nom: map['nom'] ?? '',
      description: map['description'] ?? '',
      quantite: (map['quantite'] ?? 0).toDouble(),
      unite: map['unite'] ?? 'pieces',
      tarifUnitaire: map['tarifUnitaire']?.toDouble(),
      photo: map['photo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'quantite': quantite,
      'unite': unite,
      'tarifUnitaire': tarifUnitaire,
      'photo': photo,
    };
  }

  ProduitStocke copyWith({
    String? nom,
    String? description,
    double? quantite,
    String? unite,
    double? tarifUnitaire,
    String? photo,
  }) {
    return ProduitStocke(
      nom: nom ?? this.nom,
      description: description ?? this.description,
      quantite: quantite ?? this.quantite,
      unite: unite ?? this.unite,
      tarifUnitaire: tarifUnitaire ?? this.tarifUnitaire,
      photo: photo ?? this.photo,
    );
  }
}
