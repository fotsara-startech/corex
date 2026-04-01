# Refonte du Système de Livraison COREX

## Problématique

L'ancien système liait trop rigidement le statut du colis au type de livraison possible. Cela créait des limitations dans les cas réels où un colis peut nécessiter un livreur à n'importe quel moment de son cycle de vie.

### Exemple de cas bloquant
- Un colis "Enregistré" avec expéditeur et destinataire dans la même ville ne pouvait pas être attribué directement à un livreur pour livraison finale
- Le système forçait une hiérarchie de statuts qui ne correspondait pas à tous les scénarios métier

## Solution Implémentée

### 1. Ajout du champ `typeLivraison`

Le modèle `LivraisonModel` a été enrichi avec un nouveau champ obligatoire :

```dart
final String typeLivraison; // expedition, recuperation, livraison_finale
```

### 2. Trois types de livraison distincts

#### `livraison_finale` (par défaut)
- **Usage** : Livraison directe au destinataire final
- **Cas d'usage** : Expéditeur et destinataire dans la même ville
- **Icône** : 📦

#### `expedition`
- **Usage** : Transport du bureau vers une agence de transport
- **Cas d'usage** : Colis devant être transféré vers une autre ville
- **Icône** : 🚚

#### `recuperation`
- **Usage** : Récupération depuis une agence de transport vers le bureau/client
- **Cas d'usage** : Colis arrivant d'une autre ville
- **Icône** : 📥

### 3. Suppression de la hiérarchie rigide des statuts

**Avant** : Un colis devait avoir le statut "arriveDestination" pour être attribué à un livreur

**Après** : Un colis avec N'IMPORTE QUEL statut peut être attribué à un livreur selon le besoin métier

## Fichiers Modifiés

### 1. `corex_shared/lib/models/livraison_model.dart`
- Ajout du champ `typeLivraison` avec valeur par défaut `'livraison_finale'`
- Mise à jour de `fromFirestore()` pour lire le nouveau champ
- Mise à jour de `toFirestore()` pour sauvegarder le nouveau champ

### 2. `corex_shared/lib/controllers/livraison_controller.dart`
- Ajout du paramètre `required String typeLivraison` dans `attribuerLivraison()`
- Adaptation du message de confirmation selon le type de livraison
- Suppression des validations basées sur le statut du colis

### 3. `corex_desktop/lib/screens/livraisons/attribution_livraison_screen.dart`
- Suppression du filtre par statut "arriveDestination" - tous les colis sont maintenant affichés
- Ajout d'un dropdown pour sélectionner le type de livraison
- Affichage du statut actuel du colis dans le dialogue d'attribution
- Utilisation des constantes `TypesLivraison` pour les libellés et descriptions

### 4. `corex_shared/lib/constants/types_livraison.dart` (NOUVEAU)
- Classe utilitaire définissant les 3 types de livraison
- Méthodes helper pour obtenir libellés, descriptions et icônes
- Centralisation des constantes pour éviter les erreurs de typage

## Avantages de la Solution

### 1. Flexibilité maximale
- Un agent peut attribuer un livreur à n'importe quel moment du cycle de vie du colis
- Plus de blocage dû à un statut "incorrect"

### 2. Clarté métier
- Le type de livraison est explicite et documenté
- Les agents comprennent immédiatement le type de mission assignée au coursier

### 3. Traçabilité améliorée
- Chaque livraison indique clairement son objectif (expédition, récupération, livraison finale)
- Facilite les rapports et statistiques par type de livraison

### 4. Évolutivité
- Facile d'ajouter de nouveaux types de livraison si nécessaire
- Architecture découplée du statut du colis

## Migration des Données Existantes

Les livraisons existantes sans `typeLivraison` recevront automatiquement la valeur par défaut `'livraison_finale'` grâce au fallback dans `fromFirestore()` :

```dart
typeLivraison: data['typeLivraison'] ?? 'livraison_finale',
```

Aucune migration manuelle n'est nécessaire.

## Interface Utilisateur

### Dialogue d'Attribution

Le dialogue d'attribution affiche maintenant :

1. **Informations du colis** : Numéro de suivi, statut actuel, destinataire
2. **Type de livraison** : Dropdown avec 3 options (icône + libellé + description)
3. **Sélection du coursier** : Dropdown des coursiers actifs
4. **Paiement à la livraison** : Option COD avec montant à collecter

### Exemple d'affichage

```
Type de livraison:
┌─────────────────────────────────────────────────────┐
│ 📦 Livraison finale au destinataire                 │
│    Le coursier livre directement le colis au        │
│    destinataire final                               │
├─────────────────────────────────────────────────────┤
│ 🚚 Expédition vers agence de transport              │
│    Le coursier transporte le colis du bureau vers   │
│    l'agence de transport                            │
├─────────────────────────────────────────────────────┤
│ 📥 Récupération depuis agence de transport          │
│    Le coursier récupère le colis à l'agence de      │
│    transport pour le ramener au bureau              │
└─────────────────────────────────────────────────────┘
```

## Tests Recommandés

### Scénario 1 : Livraison locale directe
1. Créer un colis avec statut "enregistre"
2. Attribuer à un livreur avec type "livraison_finale"
3. Vérifier que le colis passe en "enCoursLivraison"
4. Confirmer la livraison

### Scénario 2 : Expédition inter-villes
1. Créer un colis avec statut "enregistre"
2. Attribuer à un livreur avec type "expedition"
3. Vérifier le message "Expédition vers agence de transport"
4. Confirmer la livraison à l'agence

### Scénario 3 : Récupération
1. Créer un colis avec statut "arriveDestination"
2. Attribuer à un livreur avec type "recuperation"
3. Vérifier le message "Récupération depuis agence de transport"
4. Confirmer la récupération

## Compatibilité

✅ **Rétrocompatible** : Les livraisons existantes continuent de fonctionner
✅ **Pas de migration requise** : Valeur par défaut automatique
✅ **Interface intuitive** : Dropdown avec descriptions claires

## Prochaines Étapes Possibles

1. **Statistiques par type** : Ajouter des rapports distinguant les 3 types de livraison
2. **Tarification différenciée** : Possibilité de tarifer différemment selon le type
3. **Optimisation des tournées** : Regrouper les livraisons par type pour optimiser les trajets
4. **Notifications spécifiques** : Adapter les notifications selon le type de livraison

---

**Date de mise en œuvre** : 24 février 2026
**Statut** : ✅ Implémenté et prêt pour tests
