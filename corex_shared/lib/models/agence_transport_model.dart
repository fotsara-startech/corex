import 'package:cloud_firestore/cloud_firestore.dart';

class AgenceTransportModel {
  final String id;
  final String nom;
  final String contact;
  final String telephone;
  final List<String> villesDesservies;
  final Map<String, double> tarifs; // ville -> tarif
  final bool isActive;
  final DateTime createdAt;

  AgenceTransportModel({
    required this.id,
    required this.nom,
    required this.contact,
    required this.telephone,
    required this.villesDesservies,
    required this.tarifs,
    required this.isActive,
    required this.createdAt,
  });

  factory AgenceTransportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AgenceTransportModel(
      id: doc.id,
      nom: data['nom'] ?? '',
      contact: data['contact'] ?? '',
      telephone: data['telephone'] ?? '',
      villesDesservies: List<String>.from(data['villesDesservies'] ?? []),
      tarifs: Map<String, double>.from(
        (data['tarifs'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as num).toDouble()),
            ) ??
            {},
      ),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'contact': contact,
      'telephone': telephone,
      'villesDesservies': villesDesservies,
      'tarifs': tarifs,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
