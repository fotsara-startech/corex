import 'package:cloud_firestore/cloud_firestore.dart';

class AgenceModel {
  final String id;
  final String nom;
  final String adresse;
  final String ville;
  final String telephone;
  final String email;
  final bool isActive;
  final DateTime createdAt;

  AgenceModel({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.ville,
    required this.telephone,
    required this.email,
    required this.isActive,
    required this.createdAt,
  });

  factory AgenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgenceModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      adresse: data['adresse'] ?? '',
      ville: data['ville'] ?? '',
      telephone: data['telephone'] ?? '',
      email: data['email'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'telephone': telephone,
      'email': email,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AgenceModel copyWith({
    String? id,
    String? nom,
    String? adresse,
    String? ville,
    String? telephone,
    String? email,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AgenceModel(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
