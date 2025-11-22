# COREX - Système de Gestion de Colis

## 📋 Description

COREX est un système complet de gestion de colis pour une entreprise d'intermédiation au **Cameroun**. Le système facilite la collecte, l'expédition, le suivi et la livraison de colis entre clients et agences de voyage partenaires.

## 🏗️ Architecture

### Applications
- **corex_desktop** : Application Windows pour agents, gestionnaires, commerciaux, coursiers
- **corex_mobile** : Application Android pour le PDG uniquement
- **corex_shared** : Package partagé contenant modèles, services et controllers

### Technologies
- **Frontend** : Flutter 3.24.0
- **Backend** : Firebase Firestore
- **State Management** : GetX 4.6.6
- **Authentification** : Firebase Auth

### Couleurs COREX
- Vert : #2E7D32
- Noir : #212121
- Blanc : #FFFFFF

## 🚀 Installation

### Prérequis
- Flutter 3.24.0 ou supérieur
- Dart 3.5.0
- Firebase CLI
- FlutterFire CLI

### Configuration

1. **Cloner le projet**
```bash
git clone <repository-url>
cd corex
```

2. **Installer les dépendances**
```bash
# Package partagé
cd corex_shared
flutter pub get

# Desktop
cd ../corex_desktop
flutter pub get

# Mobile
cd ../corex_mobile
flutter pub get
```

3. **Firebase est déjà configuré**
- Le projet Firebase `corex-a1c1e` est déjà configuré
- Les fichiers `firebase_options.dart` sont générés
- Le fichier `google-services.json` est en place

## 🎯 Lancer les applications

### Desktop (Windows)
```bash
cd corex_desktop
flutter run -d windows
```

### Mobile (Android)
```bash
cd corex_mobile
flutter run
```

## 📦 Structure du Projet

```
corex/
├── corex_desktop/          # Application Windows
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart
│   │   ├── theme/
│   │   │   └── corex_theme.dart
│   │   └── screens/
│   │       ├── auth/
│   │       │   └── login_screen.dart
│   │       └── home/
│   │           └── home_screen.dart
│   └── pubspec.yaml
│
├── corex_mobile/           # Application Android
│   ├── lib/
│   │   ├── main.dart
│   │   ├── firebase_options.dart
│   │   ├── theme/
│   │   │   └── corex_theme.dart
│   │   └── screens/
│   │       ├── auth/
│   │       │   └── login_screen.dart
│   │       └── home/
│   │           └── home_screen.dart
│   ├── android/
│   │   └── app/
│   │       └── google-services.json
│   └── pubspec.yaml
│
└── corex_shared/           # Package partagé
    ├── lib/
    │   ├── corex_shared.dart
    │   ├── models/
    │   │   ├── user_model.dart
    │   │   ├── agence_model.dart
    │   │   ├── colis_model.dart
    │   │   ├── livraison_model.dart
    │   │   ├── transaction_model.dart
    │   │   ├── zone_model.dart
    │   │   └── agence_transport_model.dart
    │   ├── services/
    │   │   ├── firebase_service.dart
    │   │   ├── auth_service.dart
    │   │   ├── colis_service.dart
    │   │   ├── livraison_service.dart
    │   │   └── transaction_service.dart
    │   ├── controllers/
    │   │   ├── auth_controller.dart
    │   │   ├── colis_controller.dart
    │   │   ├── livraison_controller.dart
    │   │   └── transaction_controller.dart
    │   ├── constants/
    │   │   ├── app_constants.dart
    │   │   └── statuts_colis.dart
    │   └── utils/
    │       ├── date_formatter.dart
    │       └── validators.dart
    └── pubspec.yaml
```

## ✅ Phase 0 - Complétée

### Ce qui a été fait
- ✅ Structure des 3 projets Flutter créée
- ✅ Configuration Firebase Firestore
- ✅ Modèles de données (User, Agence, Colis, Livraison, Transaction, Zone, AgenceTransport)
- ✅ Services Firebase (Auth, Colis, Livraison, Transaction)
- ✅ Controllers GetX (Auth, Colis, Livraison, Transaction)
- ✅ Thème COREX personnalisé
- ✅ Écrans de connexion (Desktop & Mobile)
- ✅ Écrans d'accueil de base
- ✅ Validation des formulaires
- ✅ Gestion des erreurs
- ✅ Mode hors ligne configuré

### Fonctionnalités disponibles
- Authentification Firebase
- Gestion des rôles (admin, gestionnaire, commercial, coursier, agent)
- Persistance hors ligne automatique
- Interface aux couleurs COREX
- Navigation avec GetX

## 📝 Prochaines Étapes

### Phase 1 - Authentification et Gestion des Utilisateurs
- Interface de gestion des utilisateurs (Admin)
- Système de rôles et permissions complet
- Réinitialisation de mot de passe

### Phase 2 - Gestion des Agences et Configuration
- Module de gestion des agences COREX
- Gestion des zones de livraison
- Gestion des agences de transport partenaires

### Phase 3 - Module Expédition de Colis
- Interface de collecte (Commercial)
- Calcul de tarif et modes de livraison
- Enregistrement du paiement
- Mode hors ligne complet

Voir `.kiro/specs/corex/tasks.md` pour le plan complet.

## 🔐 Sécurité

- Authentification Firebase obligatoire
- Règles de sécurité Firestore configurées
- Accès basé sur les rôles
- Traçabilité complète des actions

## 📞 Support

Pour toute question, consultez la documentation dans `.kiro/specs/corex/`

---

**Statut** : Phase 0 complétée ✅  
**Prêt pour** : Phase 1 - Authentification et Gestion des Utilisateurs  
**Date** : 22 Novembre 2025
