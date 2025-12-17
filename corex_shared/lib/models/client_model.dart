import 'package:cloud_firestore/cloud_firestore.dart';

class ClientModel {
  final String id;
  final String nom;
  final String telephone;
  final String? email; // Champ email optionnel pour les notifications
  final String adresse;
  final String ville;
  final String? quartier;
  final String type; // 'expediteur', 'destinataire', 'les_deux'
  final String agenceId; // Agence qui a créé ce client
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientModel({
    required this.id,
    required this.nom,
    required this.telephone,
    this.email,
    required this.adresse,
    required this.ville,
    this.quartier,
    required this.type,
    required this.agenceId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClientModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'], // Peut être null
      adresse: data['adresse'] ?? '',
      ville: data['ville'] ?? '',
      quartier: data['quartier'],
      type: data['type'] ?? 'les_deux',
      agenceId: data['agenceId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'telephone': telephone,
      'email': email, // Inclure l'email dans Firestore
      'adresse': adresse,
      'ville': ville,
      'quartier': quartier,
      'type': type,
      'agenceId': agenceId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ClientModel copyWith({
    String? nom,
    String? telephone,
    String? email,
    String? adresse,
    String? ville,
    String? quartier,
    String? type,
    DateTime? updatedAt,
  }) {
    return ClientModel(
      id: id,
      nom: nom ?? this.nom,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      type: type ?? this.type,
      agenceId: agenceId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
