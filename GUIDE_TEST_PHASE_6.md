# Guide de Test - Phase 6: Module Livraison à Domicile

## Vue d'ensemble
Ce guide décrit les tests à effectuer pour valider le module de livraison à domicile (Phase 6).

## Prérequis
- Application COREX Desktop lancée
- Compte gestionnaire ou admin créé
- Au moins un coursier actif dans l'agence
- Des colis avec statut "arriveDestination"

## Tests à effectuer

### 1. Attribution des livraisons

#### Test 1.1: Accès à l'écran d'attribution
- Se connecter en tant que gestionnaire
- Ouvrir le menu latéral
- Cliquer sur "Livraisons" > "Attribution des livraisons"
- **Résultat attendu**: L'écran affiche la liste des colis avec statut "arriveDestination"

#### Test 1.2: Filtrage par zone
- Sur l'écran d'attribution, sélectionner une zone dans le filtre
- **Résultat attendu**: Seuls les colis de cette zone sont affichés

#### Test 1.3: Attribution d'une livraison
- Cliquer sur "Attribuer" pour un colis
- Sélectionner un coursier dans la liste déroulante
- Cliquer sur "Attribuer"
- **Résultat attendu**: 
  - Message de succès affiché
  - Le colis disparaît de la liste
  - Le statut du colis passe à "enCoursLivraison"
  - Une livraison est créée dans Firebase

#### Test 1.4: Validation coursier inactif
- Désactiver un coursier
- Essayer d'attribuer une livraison à ce coursier
- **Résultat attendu**: Message d'erreur "Le coursier sélectionné n'est pas actif"

### 2. Suivi des livraisons

#### Test 2.1: Accès à l'écran de suivi
- Ouvrir le menu latéral
- Cliquer sur "Livraisons" > "Suivi des livraisons"
- **Résultat attendu**: L'écran affiche toutes les livraisons de l'agence

#### Test 2.2: Statistiques
- Vérifier les cartes de statistiques en haut
- **Résultat attendu**: Les compteurs affichent le bon nombre de livraisons par statut

#### Test 2.3: Filtrage par statut
- Sélectionner "En attente" dans le filtre statut
- **Résultat attendu**: Seules les livraisons en attente sont affichées

#### Test 2.4: Filtrage par coursier
- Sélectionner un coursier dans le filtre
- **Résultat attendu**: Seules les livraisons de ce coursier sont affichées

#### Test 2.5: Détails d'une livraison
- Cliquer sur une livraison pour l'étendre
- **Résultat attendu**: 
  - Détails du colis affichés (destinataire, adresse, contenu)
  - Détails de la livraison affichés (statut, dates, commentaires)

#### Test 2.6: Rafraîchissement
- Cliquer sur l'icône de rafraîchissement
- **Résultat attendu**: Les données sont rechargées depuis Firebase

### 3. Tests d'intégration

#### Test 3.1: Workflow complet
1. Créer un colis en tant que commercial
2. L'enregistrer en tant qu'agent
3. Mettre son statut à "arriveDestination"
4. L'attribuer à un coursier en tant que gestionnaire
5. Vérifier dans le suivi des livraisons
- **Résultat attendu**: Le workflow complet fonctionne sans erreur

#### Test 3.2: Permissions
- Se connecter en tant que commercial
- Essayer d'accéder aux écrans de livraison
- **Résultat attendu**: Les menus de livraison ne sont pas visibles

### 4. Tests Firebase

#### Test 4.1: Vérification dans Firebase Console
- Ouvrir Firebase Console
- Aller dans Firestore
- Vérifier la collection "livraisons"
- **Résultat attendu**: Les livraisons créées sont présentes avec tous les champs

#### Test 4.2: Historique du colis
- Vérifier l'historique du colis après attribution
- **Résultat attendu**: Une entrée "enCoursLivraison" est ajoutée avec commentaire

## Problèmes connus
Aucun pour le moment.

## Prochaines étapes
Phase 7: Module Interface Coursier (confirmation de livraison, échecs, etc.)
