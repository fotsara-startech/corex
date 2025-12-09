# Guide de Test - Phase 8 : Module Gestion Financière (Caisse)

## Vue d'Ensemble

Ce guide vous permet de tester toutes les fonctionnalités du module de gestion financière (caisse) implémenté dans la Phase 8.

## Prérequis

1. Application COREX Desktop lancée
2. Utilisateur connecté (n'importe quel rôle peut accéder à la caisse)
3. Firebase Firestore accessible
4. Au moins une agence configurée

## Accès au Module Caisse

### Étape 1 : Navigation
1. Depuis l'écran d'accueil, cliquer sur le menu (☰)
2. Dans la section "OPÉRATIONS", cliquer sur "Caisse"
3. Le tableau de bord de la caisse s'affiche

**Résultat attendu** :
- Écran "Gestion de Caisse" affiché
- Nom de l'agence visible en haut
- 3 cartes de statistiques : Solde Actuel, Recettes du Jour, Dépenses du Jour
- 2 boutons : "Enregistrer une Recette" (vert) et "Enregistrer une Dépense" (rouge)
- Bouton "Voir l'Historique et Rapprochement"
- Section "Dernières Transactions" (vide si aucune transaction)

## Test 1 : Enregistrement d'une Recette

### Scénario : Enregistrer une recette manuelle

1. Cliquer sur "Enregistrer une Recette" (bouton vert)
2. Remplir le formulaire :
   - **Montant** : 50000
   - **Catégorie** : Sélectionner "Expédition"
   - **Description** : "Test recette manuelle"
3. Cliquer sur "Enregistrer"

**Résultats attendus** :
- Message de succès affiché : "Transaction enregistrée avec succès"
- Nouveau solde affiché dans le message
- Retour automatique au tableau de bord
- Solde actuel mis à jour (+50000 FCFA)
- Recettes du jour mis à jour (+50000 FCFA)
- Transaction visible dans "Dernières Transactions"

### Variations à Tester

#### Test 1.1 : Validation du montant
1. Essayer d'enregistrer avec un montant vide
   - **Attendu** : Message d'erreur "Veuillez saisir le montant"
2. Essayer d'enregistrer avec un montant négatif (-1000)
   - **Attendu** : Message d'erreur "Le montant doit être positif"
3. Essayer d'enregistrer avec un montant invalide (abc)
   - **Attendu** : Message d'erreur "Montant invalide"

#### Test 1.2 : Validation de la catégorie
1. Essayer d'enregistrer sans sélectionner de catégorie
   - **Attendu** : Message d'erreur "Veuillez sélectionner une catégorie"

#### Test 1.3 : Validation de la description
1. Essayer d'enregistrer sans description
   - **Attendu** : Message d'erreur "Veuillez saisir une description"

#### Test 1.4 : Toutes les catégories de recettes
Tester l'enregistrement avec chaque catégorie :
- Expédition
- Livraison
- Retour
- Courses
- Stockage
- Autre

## Test 2 : Enregistrement d'une Dépense

### Scénario : Enregistrer une dépense manuelle

1. Depuis le tableau de bord, cliquer sur "Enregistrer une Dépense" (bouton rouge)
2. Remplir le formulaire :
   - **Montant** : 15000
   - **Catégorie** : Sélectionner "Carburant"
   - **Description** : "Carburant pour livraisons"
3. Cliquer sur "Enregistrer"

**Résultats attendus** :
- Message de succès affiché
- Nouveau solde affiché (50000 - 15000 = 35000 FCFA)
- Retour automatique au tableau de bord
- Solde actuel mis à jour (35000 FCFA)
- Dépenses du jour mis à jour (+15000 FCFA)
- Transaction visible dans "Dernières Transactions"

### Variations à Tester

#### Test 2.1 : Toutes les catégories de dépenses
Tester l'enregistrement avec chaque catégorie :
- Transport
- Salaires
- Loyer
- Carburant
- Internet
- Électricité
- Autre

#### Test 2.2 : Validations
Tester les mêmes validations que pour les recettes (montant, catégorie, description)

## Test 3 : Historique des Transactions

### Scénario : Consulter l'historique complet

1. Depuis le tableau de bord, cliquer sur "Voir l'Historique et Rapprochement"
2. Observer la liste des transactions

**Résultats attendus** :
- Écran "Historique des Transactions" affiché
- Section de filtres en haut (Date début, Date fin, Type)
- 3 cartes de statistiques : Recettes, Dépenses, Solde
- Liste des transactions avec :
  - Icône (↑ vert pour recette, ↓ rouge pour dépense)
  - Description
  - Date et heure
  - Catégorie
  - Montant (vert pour recette, rouge pour dépense)

### Test 3.1 : Filtrage par Date

1. Cliquer sur "Date début"
2. Sélectionner la date d'aujourd'hui
3. Observer les résultats

**Résultat attendu** :
- Seules les transactions d'aujourd'hui sont affichées
- Statistiques mises à jour

4. Cliquer sur "Date fin"
5. Sélectionner la date d'aujourd'hui
6. Observer les résultats

**Résultat attendu** :
- Seules les transactions d'aujourd'hui sont affichées

### Test 3.2 : Filtrage par Type

1. Dans le filtre "Type", sélectionner "Recettes"
2. Observer les résultats

**Résultat attendu** :
- Seules les recettes sont affichées
- Statistiques "Dépenses" = 0
- Statistiques "Solde" = Total des recettes

3. Sélectionner "Dépenses"
4. Observer les résultats

**Résultat attendu** :
- Seules les dépenses sont affichées
- Statistiques "Recettes" = 0
- Statistiques "Solde" = -Total des dépenses

5. Sélectionner "Tous"
6. Observer les résultats

**Résultat attendu** :
- Toutes les transactions sont affichées
- Statistiques complètes

### Test 3.3 : Réinitialisation des Filtres

1. Appliquer plusieurs filtres (date + type)
2. Cliquer sur "Réinitialiser"

**Résultat attendu** :
- Tous les filtres sont effacés
- Toutes les transactions sont affichées
- Statistiques complètes

## Test 4 : Création Automatique de Transaction

### Scénario : Vérifier la création automatique lors du paiement d'un colis

1. Aller dans "Collecter un colis"
2. Créer un nouveau colis avec toutes les informations
3. Dans la section paiement :
   - Cocher "Paiement effectué"
   - Saisir un montant (ex: 25000)
4. Enregistrer le colis
5. Retourner dans "Caisse" → "Historique"

**Résultats attendus** :
- Une nouvelle transaction de type "Recette" est créée automatiquement
- Catégorie : "Expédition"
- Description : "Paiement colis COL-2025-XXXXXX" (avec le numéro du colis)
- Montant : 25000 FCFA
- Référence : Numéro de suivi du colis
- Le solde est mis à jour automatiquement

### Test 4.1 : Colis non payé

1. Créer un colis sans cocher "Paiement effectué"
2. Vérifier l'historique des transactions

**Résultat attendu** :
- Aucune transaction n'est créée pour ce colis

## Test 5 : Calcul du Solde

### Scénario : Vérifier la cohérence du solde

1. Noter le solde actuel affiché
2. Calculer manuellement : Σ(recettes) - Σ(dépenses)
3. Comparer avec le solde affiché

**Résultat attendu** :
- Le solde affiché correspond exactement au calcul manuel

### Test 5.1 : Statistiques du Jour

1. Noter les recettes du jour
2. Noter les dépenses du jour
3. Vérifier que seules les transactions d'aujourd'hui sont comptées

**Résultat attendu** :
- Les statistiques du jour sont correctes
- Les transactions des jours précédents ne sont pas comptées

## Test 6 : Isolation par Agence

### Scénario : Vérifier que chaque agence voit uniquement ses transactions

**Prérequis** : Avoir 2 utilisateurs de 2 agences différentes

1. Se connecter avec l'utilisateur de l'agence A
2. Enregistrer une recette de 10000 FCFA
3. Noter le solde
4. Se déconnecter
5. Se connecter avec l'utilisateur de l'agence B
6. Aller dans "Caisse"

**Résultats attendus** :
- L'agence B ne voit pas la transaction de l'agence A
- Le solde de l'agence B est indépendant
- Chaque agence a son propre historique

## Test 7 : Mode Hors Ligne

### Scénario : Enregistrer une transaction hors ligne

1. Désactiver la connexion internet (ou déconnecter Firebase)
2. Enregistrer une recette de 5000 FCFA
3. Observer le comportement

**Résultats attendus** :
- La transaction est enregistrée localement
- Message de succès affiché
- Solde mis à jour localement

4. Réactiver la connexion internet
5. Attendre quelques secondes
6. Vérifier dans Firebase Console

**Résultat attendu** :
- La transaction est synchronisée automatiquement dans Firebase

## Test 8 : Interface Utilisateur

### Test 8.1 : Responsive Design

1. Redimensionner la fenêtre de l'application
2. Observer l'adaptation de l'interface

**Résultat attendu** :
- Les cartes de statistiques s'adaptent
- Les formulaires restent lisibles
- Pas de débordement de texte

### Test 8.2 : Feedback Utilisateur

1. Enregistrer une transaction
2. Observer les indicateurs de chargement

**Résultat attendu** :
- Indicateur de chargement pendant l'enregistrement
- Message de succès clair
- Retour automatique au tableau de bord

### Test 8.3 : Bouton Annuler

1. Ouvrir le formulaire de recette
2. Remplir partiellement
3. Cliquer sur "Annuler"

**Résultat attendu** :
- Retour au tableau de bord sans enregistrer
- Aucune transaction créée

## Test 9 : Performance

### Scénario : Tester avec un grand nombre de transactions

1. Créer 50+ transactions (recettes et dépenses)
2. Aller dans l'historique
3. Observer le temps de chargement

**Résultat attendu** :
- Chargement rapide (< 2 secondes)
- Liste fluide
- Filtres réactifs

## Test 10 : Gestion des Erreurs

### Test 10.1 : Erreur de connexion

1. Désactiver Firebase (ou simuler une erreur)
2. Essayer d'enregistrer une transaction

**Résultat attendu** :
- Message d'erreur clair
- L'application ne plante pas
- Possibilité de réessayer

### Test 10.2 : Données invalides

1. Essayer d'enregistrer avec des données extrêmes (montant très élevé)
2. Observer le comportement

**Résultat attendu** :
- L'application gère correctement
- Pas de crash

## Checklist de Test Complète

### Fonctionnalités de Base
- [ ] Accès au module caisse depuis le menu
- [ ] Affichage du tableau de bord avec statistiques
- [ ] Enregistrement d'une recette
- [ ] Enregistrement d'une dépense
- [ ] Consultation de l'historique

### Validations
- [ ] Validation du montant (vide, négatif, invalide)
- [ ] Validation de la catégorie (obligatoire)
- [ ] Validation de la description (obligatoire)

### Filtres
- [ ] Filtrage par date début
- [ ] Filtrage par date fin
- [ ] Filtrage par type (recette/dépense/tous)
- [ ] Réinitialisation des filtres

### Intégration
- [ ] Création automatique de transaction lors du paiement d'un colis
- [ ] Référence au numéro de suivi dans la transaction
- [ ] Pas de transaction si colis non payé

### Calculs
- [ ] Solde actuel correct
- [ ] Recettes du jour correctes
- [ ] Dépenses du jour correctes
- [ ] Statistiques filtrées correctes

### Sécurité
- [ ] Isolation des données par agence
- [ ] Utilisateur enregistré dans la transaction

### Mode Hors Ligne
- [ ] Enregistrement hors ligne
- [ ] Synchronisation automatique au retour de connexion

### Interface
- [ ] Responsive design
- [ ] Indicateurs de chargement
- [ ] Messages de succès/erreur clairs
- [ ] Bouton annuler fonctionnel

## Bugs Connus et Limitations

### À Implémenter
1. **Upload de justificatifs** : L'upload de photos/PDF pour les dépenses n'est pas encore implémenté
2. **Rapprochement de caisse** : L'interface de rapprochement (solde théorique vs réel) n'est pas encore implémentée
3. **Export** : L'export PDF/Excel de l'historique n'est pas encore implémenté
4. **Graphiques** : Les graphiques d'évolution ne sont pas encore implémentés

### Limitations
- Pas de pagination pour l'historique (peut être lent avec beaucoup de transactions)
- Pas de recherche textuelle dans l'historique
- Pas de tri personnalisé des colonnes

## Rapport de Test

Après avoir effectué tous les tests, remplir ce rapport :

**Date du test** : ___________
**Testeur** : ___________
**Version** : Phase 8

### Résultats
- Tests réussis : ___ / ___
- Tests échoués : ___ / ___
- Bugs trouvés : ___

### Bugs Identifiés
1. ___________
2. ___________
3. ___________

### Commentaires
___________
___________
___________

---

**Bon test ! 🧪**
