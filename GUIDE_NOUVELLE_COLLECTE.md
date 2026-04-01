# Guide - Nouvelle Interface de Collecte de Colis

## Problème Résolu

L'interface de collecte des colis avait des erreurs GetX et ne permettait pas de créer des clients (expéditeur/destinataire) à la volée lors de la collecte.

## Solution Implémentée

### 1. Nouveau Formulaire de Collecte (`nouvelle_collecte_screen.dart`)

Un formulaire en 3 étapes qui permet:

#### Étape 1: Expéditeur
- **Recherche avancée**: Par nom, téléphone ou email
- **Sélection**: Si trouvé, les champs sont pré-remplis automatiquement
- **Création manuelle**: Si non trouvé, l'utilisateur remplit les champs manuellement
- **Champs**: Nom, Téléphone, Ville, Adresse, Email (optionnel)

#### Étape 2: Destinataire
- **Recherche avancée**: Par nom, téléphone ou email
- **Sélection**: Si trouvé, les champs sont pré-remplis automatiquement
- **Création manuelle**: Si non trouvé, l'utilisateur remplit les champs manuellement
- **Champs**: Nom, Téléphone, Ville, Adresse, Quartier (optionnel), Email (optionnel)

#### Étape 3: Détails du Colis
- Contenu
- Poids (kg)
- Dimensions (optionnel)
- Mode de livraison (domicile, bureau, agence de transport)
- Calcul automatique du tarif

### 2. Logique de Création Intelligente

Lors de la validation finale:

1. **Vérification de l'expéditeur**:
   - Si client existant trouvé → utilise son ID
   - Si nouveau client → crée le client en base de données et récupère l'ID

2. **Vérification du destinataire**:
   - Si client existant trouvé → utilise son ID
   - Si nouveau client → crée le client en base de données et récupère l'ID

3. **Création du colis**:
   - Utilise les IDs des clients (existants ou nouvellement créés)
   - Statut initial: "collecte"
   - Calcul automatique du tarif basé sur le poids

### 3. Corrections GetX

- Utilisation correcte de `Get.find<>()` pour les services
- Gestion des observables avec `.obs` et `Obx()`
- Pas d'erreur "SyncService not found"

### 4. Intégration

- Bouton "Nouvelle Collecte" ajouté dans l'AppBar
- FloatingActionButton pour un accès rapide
- Navigation fluide avec GetX

## Fonctionnalités Clés

### Recherche Multi-Critères
```dart
// Recherche par nom, téléphone ou email
final clients = await _clientService.searchClientsMultiCriteria(query, agenceId);
```

### Création Automatique de Clients
```dart
// Si le client n'existe pas, il est créé automatiquement
if (_expediteurExistant == null) {
  final expediteur = ClientModel(...);
  expediteurId = await _clientService.createClient(expediteur);
}
```

### Calcul de Tarif
```dart
// Tarif de base: 1000 FCFA + 500 FCFA par kg
double _calculerTarif() {
  final poids = double.tryParse(_poidsController.text.trim()) ?? 0;
  return 1000 + (poids * 500);
}
```

## Utilisation

1. **Accéder au formulaire**:
   - Cliquer sur le bouton "+" dans l'AppBar
   - Ou cliquer sur le FloatingActionButton "Nouvelle Collecte"

2. **Remplir l'expéditeur**:
   - Rechercher un client existant (optionnel)
   - Ou remplir manuellement les champs
   - Cliquer sur "Continuer"

3. **Remplir le destinataire**:
   - Rechercher un client existant (optionnel)
   - Ou remplir manuellement les champs
   - Cliquer sur "Continuer"

4. **Détails du colis**:
   - Remplir les informations du colis
   - Cliquer sur "Continuer" pour valider

5. **Validation**:
   - Le système crée automatiquement les clients s'ils n'existent pas
   - Le colis est créé avec le statut "collecte"
   - Retour à l'écran d'enregistrement

## Avantages

✅ **Pas de duplication**: Recherche avant création
✅ **Flexibilité**: Création manuelle si client non trouvé
✅ **Rapidité**: Pré-remplissage automatique si client trouvé
✅ **Validation**: Tous les champs requis sont validés
✅ **Traçabilité**: Liens entre colis et clients via IDs
✅ **UX améliorée**: Formulaire en étapes claires

## Fichiers Modifiés

1. **Nouveau**: `corex_desktop/lib/screens/agent/nouvelle_collecte_screen.dart`
2. **Modifié**: `corex_desktop/lib/screens/agent/enregistrement_colis_screen.dart`

## Tests Recommandés

1. ✅ Créer un colis avec expéditeur et destinataire existants
2. ✅ Créer un colis avec nouvel expéditeur et destinataire existant
3. ✅ Créer un colis avec expéditeur existant et nouveau destinataire
4. ✅ Créer un colis avec nouvel expéditeur et nouveau destinataire
5. ✅ Vérifier que les clients sont bien créés en base de données
6. ✅ Vérifier que le colis est bien créé avec les bons IDs
7. ✅ Tester la recherche multi-critères (nom, téléphone, email)
8. ✅ Vérifier le calcul automatique du tarif
