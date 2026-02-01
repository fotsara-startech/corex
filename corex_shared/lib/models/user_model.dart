import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String role;
  final String? agenceId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.role,
    this.agenceId,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Gérer isActive qui peut être bool ou string
    bool isActiveValue = true;
    if (data['isActive'] != null) {
      if (data['isActive'] is bool) {
        isActiveValue = data['isActive'] as bool;
      } else if (data['isActive'] is String) {
        isActiveValue = data['isActive'].toString().toLowerCase() == 'true';
      }
    }

    // Gérer createdAt qui peut être null
    DateTime createdAtValue = DateTime.now();
    if (data['createdAt'] != null) {
      createdAtValue = (data['createdAt'] as Timestamp).toDate();
    }

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      telephone: data['telephone'] ?? '',
      role: data['role'] ?? '',
      agenceId: data['agenceId'],
      isActive: isActiveValue,
      createdAt: createdAtValue,
      lastLogin: data['lastLogin'] != null ? (data['lastLogin'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'role': role,
      'agenceId': agenceId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  // Méthodes pour la sérialisation JSON (stockage local)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] ?? '',
      agenceId: json['agenceId'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'role': role,
      'agenceId': agenceId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  String get nomComplet => '$prenom $nom';

  UserModel copyWith({
    String? id,
    String? email,
    String? nom,
    String? prenom,
    String? telephone,
    String? role,
    String? agenceId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      agenceId: agenceId ?? this.agenceId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
