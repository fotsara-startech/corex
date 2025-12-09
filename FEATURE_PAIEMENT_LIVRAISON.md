# Fonctionnalité : Paiement à la Livraison (COD - Cash On Delivery)

## 🎯 Objectif

Permettre la collecte des frais de livraison directement par le coursier lors de la livraison du colis, avec création automatique d'une transaction financière dans la caisse.

## 📦 Implémentation

### Modifications du Modèle de Données

#### LivraisonModel
Ajout de 4 nouveaux champs :

```dart
final bool paiementALaLivraison;      // Si le paiement doit être collecté
final double? montantACollecte;        // Montant à collecter
final bool paiementCollecte;           // Si le paiement a été collecté
final DateTime? datePaiementCollecte;  // Date de collecte
```

### Workflow Complet

#### 1. Attribution de Livraison (Gestionnaire)

**Écran** : `AttributionLivraisonScreen`

**Actions** :
1. Le gestionnaire sélectionne un colis à livrer (statut "arriveDestination")
2. Il sélectionne un coursier
3. **NOUVEAU** : Il coche "Paiement à la livraison (COD)"
4. **NOUVEAU** : Il saisit le montant à collecter (pré-rempli avec le tarif du colis)
5. Il confirme l'attribution

**Résultat** :
- Livraison créée avec `paiementALaLivraison = true` et `montantACollecte` défini
- Colis passe en statut "enCoursLivraison"
- Message de confirmation indique le montant à collecter

#### 2. Livraison (Coursier)

**Écran** : `DetailsLivraisonScreen`

**Affichage** :
- Si `paiementALaLivraison = true`, une section orange s'affiche :
  - Icône 💰
  - "Paiement à la livraison"
  - "Montant à collecter: X FCFA"
  - Si déjà collecté : ✅ "Collecté le DD/MM/YYYY à HH:MM"

**Actions lors de la confirmation** :
1. Le coursier clique sur "Confirmer la livraison"
2. **NOUVEAU** : Une section "Paiement à la livraison" apparaît dans la dialog
3. **NOUVEAU** : Case à cocher "Paiement collecté" (pré-cochée)
4. **NOUVEAU** : Champ "Montant collecté" (pré-rempli)
5. Le coursier peut modifier le montant si nécessaire
6. Il confirme la livraison

**Résultat** :
- Livraison mise à jour avec `paiementCollecte = true` et `datePaiementCollecte`
- Colis passe en statut "livre"
- **NOUVEAU** : Transaction automatique créée dans la caisse

#### 3. Transaction Automatique

**Service** : `LivraisonService.createTransactionForLivraison()`

**Conditions** :
- `paiementALaLivraison = true`
- `paiementCollecte = true`
- `montantACollecte != null`

**Transaction créée** :
```dart
TransactionModel(
  type: 'recette',
  categorieRecette: 'livraison',
  montant: montantACollecte,
  date: datePaiementCollecte,
  description: 'Paiement livraison colis COL-2025-XXXXXX',
  reference: numeroSuivi,
  agenceId: agenceId,
  userId: coursierId,
)
```

**Résultat** :
- Transaction visible dans le module Caisse
- Solde de la caisse mis à jour automatiquement
- Traçabilité complète (référence au colis, coursier, date)

## 🎨 Interface Utilisateur

### Écran d'Attribution (Gestionnaire)

```
┌─────────────────────────────────────┐
│ Attribuer une livraison             │
├─────────────────────────────────────┤
│ Colis: COL-2025-000001              │
│ Destinataire: Jean Dupont           │
│ Téléphone: +261 34 12 345 67        │
│ Adresse: 123 Rue Example            │
│                                      │
│ Sélectionner un coursier:           │
│ ┌─────────────────────────────────┐ │
│ │ Coursier ▼                      │ │
│ └─────────────────────────────────┘ │
│                                      │
│ ─────────────────────────────────── │
│                                      │
│ ☐ Paiement à la livraison (COD)    │
│   Le coursier collectera le         │
│   paiement lors de la livraison     │
│                                      │
│ ┌─────────────────────────────────┐ │
│ │ 💰 Montant à collecter (FCFA)  │ │
│ │ 25000                           │ │
│ └─────────────────────────────────┘ │
│                                      │
│         [Annuler]  [Attribuer]      │
└─────────────────────────────────────┘
```

### Écran de Confirmation (Coursier)

```
┌─────────────────────────────────────┐
│ Confirmer la livraison              │
├─────────────────────────────────────┤
│ La livraison a-t-elle été effectuée │
│ avec succès ?                        │
│                                      │
│ ┌─────────────────────────────────┐ │
│ │ 💰 Paiement à la livraison      │ │
│ │                                 │ │
│ │ ☑ Paiement collecté             │ │
│ │   Montant: 25000 FCFA           │ │
│ │                                 │ │
│ │ ┌─────────────────────────────┐ │ │
│ │ │ 💰 Montant collecté (FCFA)  │ │ │
│ │ │ 25000                       │ │ │
│ │ └─────────────────────────────┘ │ │
│ └─────────────────────────────────┘ │
│                                      │
│ 📷 Ajouter une photo/signature      │
│    (optionnel)                       │
│                                      │
│         [Annuler]  [Confirmer]      │
└─────────────────────────────────────┘
```

### Écran de Détails (Coursier)

```
┌─────────────────────────────────────┐
│ Informations de tournée             │
├─────────────────────────────────────┤
│ 📅 Date création                    │
│    04/12/2025 à 14:30               │
│                                      │
│ ┌─────────────────────────────────┐ │
│ │ 💰 Paiement à la livraison      │ │
│ │ Montant à collecter: 25000 FCFA │ │
│ │ ✅ Collecté le 04/12/2025 à     │ │
│ │    16:45                         │ │
│ └─────────────────────────────────┘ │
│                                      │
│ ▶ Heure départ: 15:00               │
│ ⏹ Heure retour: 16:50               │
└─────────────────────────────────────┘
```

## 📊 Cas d'Usage

### Cas 1 : Livraison avec Paiement COD

1. **Gestionnaire** : Attribue une livraison avec paiement COD de 25000 FCFA
2. **Coursier** : Voit le montant à collecter dans les détails
3. **Coursier** : Livre le colis et collecte 25000 FCFA
4. **Coursier** : Confirme la livraison avec paiement collecté
5. **Système** : Crée automatiquement une transaction de 25000 FCFA
6. **Caisse** : Le solde augmente de 25000 FCFA

### Cas 2 : Livraison sans Paiement COD

1. **Gestionnaire** : Attribue une livraison sans cocher COD
2. **Coursier** : Ne voit pas de section paiement
3. **Coursier** : Livre et confirme normalement
4. **Système** : Aucune transaction créée

### Cas 3 : Modification du Montant

1. **Gestionnaire** : Attribue avec 25000 FCFA
2. **Coursier** : Le destinataire paie 30000 FCFA (pourboire)
3. **Coursier** : Modifie le montant à 30000 FCFA dans la dialog
4. **Système** : Crée une transaction de 30000 FCFA

### Cas 4 : Paiement Non Collecté

1. **Gestionnaire** : Attribue avec paiement COD
2. **Coursier** : Le destinataire n'a pas l'argent
3. **Coursier** : Décoche "Paiement collecté" ou déclare un échec
4. **Système** : Aucune transaction créée

## 🔧 Fichiers Modifiés

### Modèles
- `corex_shared/lib/models/livraison_model.dart` - Ajout des champs de paiement

### Services
- `corex_shared/lib/services/livraison_service.dart` - Méthode `createTransactionForLivraison()`

### Controllers
- `corex_shared/lib/controllers/livraison_controller.dart` - Mise à jour de `attribuerLivraison()` et `confirmerLivraison()`

### Écrans
- `corex_desktop/lib/screens/livraisons/attribution_livraison_screen.dart` - Ajout de l'option COD
- `corex_desktop/lib/screens/coursier/details_livraison_screen.dart` - Affichage et collecte du paiement

## ✅ Tests Recommandés

### Test 1 : Attribution avec COD
1. Attribuer une livraison avec paiement COD de 10000 FCFA
2. Vérifier que la livraison est créée avec les bons champs
3. Vérifier le message de confirmation

### Test 2 : Affichage pour le Coursier
1. Se connecter en tant que coursier
2. Ouvrir une livraison avec COD
3. Vérifier l'affichage de la section orange
4. Vérifier le montant affiché

### Test 3 : Collecte du Paiement
1. Confirmer une livraison avec COD
2. Vérifier que la case est pré-cochée
3. Vérifier que le montant est pré-rempli
4. Confirmer la livraison
5. Vérifier le message de succès

### Test 4 : Transaction Automatique
1. Après la confirmation, aller dans "Caisse"
2. Vérifier qu'une transaction "livraison" est créée
3. Vérifier le montant, la description et la référence
4. Vérifier que le solde est mis à jour

### Test 5 : Modification du Montant
1. Attribuer avec 10000 FCFA
2. Lors de la confirmation, modifier à 15000 FCFA
3. Vérifier que la transaction est de 15000 FCFA

### Test 6 : Paiement Non Collecté
1. Attribuer avec COD
2. Lors de la confirmation, décocher "Paiement collecté"
3. Confirmer
4. Vérifier qu'aucune transaction n'est créée

### Test 7 : Livraison sans COD
1. Attribuer sans cocher COD
2. Vérifier que le coursier ne voit pas de section paiement
3. Confirmer normalement
4. Vérifier qu'aucune transaction n'est créée

## 📈 Statistiques et Rapports

### Dans le Module Caisse

Les transactions de paiement à la livraison apparaissent :
- **Type** : Recette
- **Catégorie** : Livraison
- **Description** : "Paiement livraison colis COL-2025-XXXXXX"
- **Référence** : Numéro de suivi du colis

Elles sont incluses dans :
- Le solde actuel
- Les recettes du jour
- L'historique des transactions
- Les filtres par catégorie "livraison"

### Traçabilité

Chaque transaction contient :
- Le numéro du colis (référence)
- Le coursier qui a collecté (userId)
- La date et l'heure exacte de collecte
- Le montant collecté

## 🚀 Améliorations Futures

### Priorité Haute
1. **Rapprochement de caisse coursier** : Vérifier que le coursier a bien remis l'argent
2. **Historique des paiements COD** : Vue dédiée pour les paiements collectés par coursier
3. **Notifications** : Alerter le gestionnaire quand un paiement COD est collecté

### Priorité Moyenne
4. **Statistiques COD** : Montant total collecté par coursier, par période
5. **Validation du montant** : Alerter si le montant collecté diffère du montant prévu
6. **Photo du reçu** : Permettre au coursier de photographier le reçu de paiement

### Priorité Basse
7. **Paiement partiel** : Permettre la collecte d'un montant partiel
8. **Devise** : Support de plusieurs devises
9. **Commission coursier** : Calculer automatiquement la commission du coursier

## 💡 Notes Importantes

### Sécurité
- Le montant peut être modifié par le coursier (flexibilité pour pourboires ou ajustements)
- Toutes les transactions sont tracées avec l'ID du coursier
- L'historique est immuable une fois créé

### Performance
- La création de transaction est asynchrone et n'affecte pas la confirmation de livraison
- En cas d'erreur de transaction, la livraison est quand même confirmée
- Les transactions sont synchronisées automatiquement en mode offline

### Compatibilité
- Compatible avec le mode offline existant
- Compatible avec les livraisons existantes (champs optionnels)
- Rétrocompatible : les anciennes livraisons fonctionnent toujours

---

**Date d'implémentation** : 4 décembre 2025
**Développeur** : Kiro AI Assistant
**Statut** : ✅ Implémenté et prêt pour les tests
