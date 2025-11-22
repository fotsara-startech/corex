# COREX - Vue d'ensemble du projet

## Introduction

COREX est un système de gestion de colis pour une entreprise d'intermédiation entre clients et agences de voyage. Le système couvre 5 services principaux : expédition, livraison à domicile, retours, courses et stockage.

## Technologies

- **Frontend**: Flutter 3.24.0 (Desktop Windows + Mobile Android)
- **Backend**: Firebase Firestore
- **State Management**: GetX 4.7.2
- **Authentification**: Firebase Auth (Email/Password)
- **Charte graphique**: Vert (#2E7D32), Noir (#212121), Blanc (#FFFFFF)
- **Localisation**: Cameroun

## Architecture

### Applications
1. **corex_desktop** - Application Windows pour agents, gestionnaires, commerciaux, coursiers
2. **corex_mobile** - Application Android pour le PDG uniquement
3. **corex_shared** - Package partagé (modèles, services, controllers)

### Rôles utilisateurs
- **Admin (PDG)**: Accès complet, vue globale toutes agences
- **Gestionnaire d'agence**: Gestion d'une agence spécifique
- **Commercial**: Collecte de colis en porte-à-porte
- **Coursier**: Livraison de colis à domicile
- **Agent d'enregistrement**: Enregistrement et suivi des colis

## Modules principaux

### 1. Expédition de colis
- Collecte en porte-à-porte par les commerciaux
- Tarification sur place
- Paiement cash à la collecte
- Choix du mode de réception (domicile, bureau COREX, agence transport)
- Génération automatique de numéro de suivi (COL-2025-XXXXXX)
- 9 statuts de suivi

### 2. Livraison à domicile
- Gestion des zones géographiques
- Attribution des coursiers par zone
- Fiches de livraison électroniques
- Enregistrement heures départ/retour
- Gestion des échecs de livraison

### 3. Gestion financière
- Caisse par agence (recettes/dépenses)
- Catégories de dépenses (transport, salaires, loyer, etc.)
- Rapports financiers (quotidien, mensuel, annuel)
- Tableaux de bord avec KPI

### 4. Stockage
- Gestion des clients stockeurs
- Inventaire détaillé par client
- Suivi des sorties de stock
- Facturation mensuelle automatique

### 5. Courses et retours
- Service de courses avec commission
- Retour de colis avec lien vers commande initiale
- Suivi complet des opérations

## Mode hors ligne

Le système utilise la persistance locale de Firebase Firestore :
- Cache automatique des données
- Synchronisation automatique lors de la reconnexion
- Priorité : collecte, enregistrement, livraison

## Prochaines étapes

Consultez les fichiers suivants pour plus de détails :
- **requirements.md** - Exigences détaillées avec user stories
- **design.md** - Architecture et conception technique
- **tasks.md** - Plan d'implémentation avec tâches

## Documentation

Voir le dossier racine du projet pour :
- START_HERE.md - Guide de démarrage
- FIREBASE_SETUP.md - Configuration Firebase
- GETX_GUIDE.md - Guide d'utilisation de GetX
- TODO.md - Liste des tâches
- NEXT_STEPS.md - Feuille de route détaillée
