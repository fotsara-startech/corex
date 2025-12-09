# Guide de Test - Phase 7 : Module Interface Coursier

## Vue d'Ensemble

La Phase 7 implémente l'interface complète pour les coursiers, leur permettant de gérer leurs livraisons depuis la collecte jusqu'à la confirmation de livraison ou la déclaration d'échec.

## Fonctionnalités Implémentées

### 7.1 Interface coursier pour les livraisons ✅
- ✅ Écran de liste des livraisons assignées au coursier connecté
- ✅ Filtrage par statut (enAttente, enCours, livree, echec)
- ✅ Écran de détails de la livraison avec toutes les informations
- ✅ Affichage des informations du destinataire (nom, téléphone, adresse complète)
- ✅ Affichage des détails du colis (contenu, poids, tarif)

### 7.2 Enregistrement de la tournée ✅
- ✅ Interface d'enregistrement de l'heure de départ de tournée
- ✅ Interface de confirmation de livraison réussie
- ✅ Capture de signature ou photo de preuve (optionnel)
- ✅ Enregistrement de l'heure de retour de tournée
- ✅ Mise à jour du statut de la livraison et du colis

### 7.3 Gestion des échecs de livraison ✅
- ✅ Interface de déclaration d'échec de livraison
- ✅ Saisie du motif d'échec (liste prédéfinie + autre)
- ✅ Capture de photo justificative optionnelle
- ✅ Mise à jour du statut de livraison en "echec"
- ✅ Permet la réattribution de la livraison par le gestionnaire

### 7.4 Mode hors ligne pour coursiers ✅
- ✅ Persistance Firebase déjà configurée pour les livraisons
- ✅ Synchronisation automatique des confirmations de livraison
- ✅ Gestion des conflits de données (priorité serveur)
- ✅ Indicateurs visuels du mode offline (via ConnectionIndicator existant)

## Architecture

### Fichiers Créés/Modifiés

#### Desktop (corex_desktop)
- ✅ `lib/screens/coursier/details_livraison_screen.dart` - Écran de détails (créé)
- ✅ `lib/screens/coursier/mes_livraisons_screen.dart` - Liste des livraisons (amélioré)
- ✅ `lib/main.dart` - Routes ajoutées

#### Mobile (corex_mobile)
- ✅ `lib/screens/coursier/mes_livraisons_screen.dart` - Liste des livraisons (créé)
- ✅ `lib/screens/coursier/details_livraison_screen.dart` - Écran de détails (créé)
- ✅ `lib/main.dart` - Routes et controllers ajoutés

#### Shared (corex_shared)
- ✅ `lib/controllers/colis_controller.dart` - Méthode `getColisById()` ajoutée
- ✅ `lib/controllers/livraison_controller.dart` - Méthodes déjà existantes:
  - `demarrerTournee()`
  - `confirmerLivraison()`
  - `declarerEchec()`
  - `terminerTournee()`

#### Dépendances
- ✅ `image_picker: ^1.1.2` ajouté aux deux pubspec.yaml

## ⚠️ Correction Importante

**Problème résolu** : Les coursiers ne pouvaient pas accéder à leurs livraisons car l'entrée de menu était manquante dans le HomeScreen.

**Solution appliquée** : Ajout de l'option "Mes Livraisons" dans le menu pour le rôle "coursier".

Voir `PHASE_7_FIX_NAVIGATION.md` pour les détails.

## Prérequis pour les Tests

### 1. Installation des Dépendances

```bash
# Desktop
cd corex_desktop
flutter pub get

# Mobile
cd ../corex_mobile
flutter pub get
```

### 2. Données de Test Requises

Vous aurez besoin de :
- ✅ Un utilisateur avec le rôle "coursier"
- ✅ Des livraisons assignées à ce coursier
- ✅ Des colis avec le statut "arriveDestination" ou "enCoursLivraison"

### 3. Créer un Utilisateur Coursier

Dans Firebase Console > Firestore > users :

```json
{
  "email": "coursier@corex.com",
  "nom": "Diallo",
  "prenom": "Mamadou",
  "telephone": "+221771234567",
  "role": "coursier",
  "agenceId": "agence_dakar_001",
  "isActive": true,
  "createdAt": "2025-01-15T10:00:00Z"
}
```

Créer le compte dans Firebase Authentication avec le même email.

## Scénarios de Test

### Test 1 : Connexion et Affichage des Livraisons

**Objectif** : Vérifier que le coursier peut voir ses livraisons assignées

**Étapes** :
1. Lancer l'application (Desktop ou Mobile)
2. Se connecter avec le compte coursier
3. Naviguer vers "Mes Livraisons"

**Résultats Attendus** :
- ✅ Liste des livraisons assignées au coursier
- ✅ Affichage du statut de chaque livraison (badge coloré)
- ✅ Informations de base : zone, date de création
- ✅ Bouton "Démarrer" pour les livraisons en attente
- ✅ Bouton "Terminer" pour les livraisons en cours

### Test 2 : Filtrage par Statut

**Objectif** : Vérifier le filtrage des livraisons

**Étapes** :
1. Dans "Mes Livraisons", cliquer sur l'icône de filtre
2. Sélectionner "En attente"
3. Vérifier que seules les livraisons en attente s'affichent
4. Répéter pour les autres statuts

**Résultats Attendus** :
- ✅ Filtrage correct par statut
- ✅ Interface de filtre claire (dialog desktop, bottom sheet mobile)
- ✅ Mise à jour immédiate de la liste

### Test 3 : Démarrage de Tournée

**Objectif** : Vérifier l'enregistrement de l'heure de départ

**Étapes** :
1. Sélectionner une livraison en statut "enAttente"
2. Cliquer sur "Démarrer la tournée"
3. Confirmer dans le dialog

**Résultats Attendus** :
- ✅ Dialog de confirmation affiché
- ✅ Statut de la livraison passe à "enCours"
- ✅ Heure de départ enregistrée
- ✅ Message de succès affiché
- ✅ Bouton change en "Terminer"

**Vérification Firebase** :
```
livraisons/{livraisonId}:
  statut: "enCours"
  heureDepart: Timestamp(...)
```

### Test 4 : Consultation des Détails

**Objectif** : Vérifier l'affichage complet des informations

**Étapes** :
1. Cliquer sur une livraison dans la liste
2. Consulter l'écran de détails

**Résultats Attendus** :
- ✅ Statut de la livraison avec icône et couleur
- ✅ Informations du destinataire :
  - Nom complet
  - Téléphone (cliquable pour appeler)
  - Adresse complète avec ville
- ✅ Détails du colis :
  - Numéro de suivi
  - Contenu
  - Poids
  - Dimensions
  - Tarif
- ✅ Informations de tournée :
  - Date de création
  - Heure de départ (si démarrée)
  - Heure de retour (si terminée)

### Test 5 : Confirmation de Livraison Réussie

**Objectif** : Vérifier le workflow de confirmation

**Étapes** :
1. Ouvrir les détails d'une livraison "enCours"
2. Cliquer sur "Confirmer la livraison"
3. (Optionnel) Ajouter une photo de preuve
4. Confirmer

**Résultats Attendus** :
- ✅ Dialog/Bottom sheet de confirmation affiché
- ✅ Option d'ajouter une photo (caméra)
- ✅ Aperçu de la photo si ajoutée
- ✅ Statut de la livraison passe à "livree"
- ✅ Statut du colis passe à "livre"
- ✅ Heure de retour enregistrée
- ✅ Message de succès
- ✅ Retour automatique à la liste

**Vérification Firebase** :
```
livraisons/{livraisonId}:
  statut: "livree"
  heureRetour: Timestamp(...)
  preuveUrl: "path/to/image" (si photo ajoutée)

colis/{colisId}:
  statut: "livre"
  historique: [
    ...
    {
      statut: "livre",
      date: Timestamp(...),
      userId: "coursier_id",
      commentaire: "Colis livré avec succès"
    }
  ]
```

### Test 6 : Déclaration d'Échec de Livraison

**Objectif** : Vérifier le workflow d'échec

**Étapes** :
1. Ouvrir les détails d'une livraison "enCours"
2. Cliquer sur "Déclarer un échec"
3. Sélectionner un motif (ex: "Destinataire absent")
4. Ajouter un commentaire (optionnel)
5. Ajouter une photo justificative (optionnel)
6. Confirmer

**Résultats Attendus** :
- ✅ Dialog/Bottom sheet d'échec affiché
- ✅ Liste déroulante des motifs :
  - Destinataire absent
  - Adresse incorrecte
  - Refus de réception
  - Téléphone injoignable
  - Autre
- ✅ Champ commentaire optionnel
- ✅ Option d'ajouter une photo
- ✅ Bouton "Confirmer" désactivé si aucun motif sélectionné
- ✅ Statut de la livraison passe à "echec"
- ✅ Statut du colis passe à "echecLivraison"
- ✅ Motif et commentaire enregistrés
- ✅ Message de succès
- ✅ Retour automatique à la liste

**Vérification Firebase** :
```
livraisons/{livraisonId}:
  statut: "echec"
  heureRetour: Timestamp(...)
  motifEchec: "Destinataire absent"
  commentaire: "Personne ne répond"
  photoUrl: "path/to/image" (si photo ajoutée)

colis/{colisId}:
  statut: "echecLivraison"
  historique: [
    ...
    {
      statut: "echecLivraison",
      date: Timestamp(...),
      userId: "coursier_id",
      commentaire: "Échec de livraison: Destinataire absent - Personne ne répond"
    }
  ]
```

### Test 7 : Mode Hors Ligne

**Objectif** : Vérifier le fonctionnement sans connexion

**Étapes** :
1. Se connecter et charger les livraisons
2. Désactiver le réseau (mode avion ou WiFi)
3. Démarrer une tournée
4. Confirmer une livraison
5. Réactiver le réseau

**Résultats Attendus** :
- ✅ Indicateur "Hors ligne" visible
- ✅ Les livraisons déjà chargées restent visibles
- ✅ Possibilité de démarrer une tournée
- ✅ Possibilité de confirmer une livraison
- ✅ Actions enregistrées localement
- ✅ Synchronisation automatique au retour de connexion
- ✅ Indicateur "Synchronisation..." visible
- ✅ Données mises à jour dans Firebase

**Note** : La persistance Firebase gère automatiquement la synchronisation.

### Test 8 : Capture de Photos

**Objectif** : Vérifier la fonctionnalité de capture d'images

**Étapes** :
1. Lors de la confirmation ou de l'échec
2. Cliquer sur "Ajouter une photo"
3. Autoriser l'accès à la caméra si demandé
4. Prendre une photo
5. Vérifier l'aperçu

**Résultats Attendus** :
- ✅ Demande de permission caméra (première fois)
- ✅ Ouverture de la caméra
- ✅ Photo capturée
- ✅ Aperçu de la photo dans le dialog
- ✅ Option de changer la photo
- ✅ Photo enregistrée avec la livraison

**Note** : Pour l'instant, le chemin local est enregistré. L'upload vers Firebase Storage sera implémenté dans une phase ultérieure.

### Test 9 : Rafraîchissement de la Liste

**Objectif** : Vérifier le pull-to-refresh

**Étapes** :
1. Dans la liste des livraisons
2. Tirer vers le bas (pull-to-refresh)

**Résultats Attendus** :
- ✅ Indicateur de chargement affiché
- ✅ Liste rechargée depuis Firebase
- ✅ Nouvelles livraisons affichées
- ✅ Statuts mis à jour

### Test 10 : Navigation et Retour

**Objectif** : Vérifier la navigation entre les écrans

**Étapes** :
1. Naviguer de la liste vers les détails
2. Utiliser le bouton retour
3. Confirmer une livraison et vérifier le retour automatique

**Résultats Attendus** :
- ✅ Navigation fluide
- ✅ Bouton retour fonctionnel
- ✅ Retour automatique après confirmation/échec
- ✅ Liste mise à jour après retour

## Tests d'Intégration

### Test I1 : Workflow Complet de Livraison Réussie

**Scénario** : Du départ à la confirmation

**Étapes** :
1. Coursier se connecte
2. Consulte ses livraisons en attente
3. Démarre une tournée
4. Consulte les détails du destinataire
5. Confirme la livraison avec photo
6. Vérifie que la livraison disparaît des "En cours"

**Résultats Attendus** :
- ✅ Workflow complet sans erreur
- ✅ Toutes les données enregistrées correctement
- ✅ Historique complet dans le colis

### Test I2 : Workflow Complet d'Échec de Livraison

**Scénario** : Du départ à l'échec

**Étapes** :
1. Coursier démarre une tournée
2. Tente de livrer
3. Déclare un échec avec motif et photo
4. Gestionnaire voit l'échec
5. Gestionnaire réattribue la livraison

**Résultats Attendus** :
- ✅ Échec enregistré correctement
- ✅ Gestionnaire peut voir le motif et la photo
- ✅ Possibilité de réattribuer

### Test I3 : Multiples Livraisons en Parallèle

**Scénario** : Gérer plusieurs livraisons

**Étapes** :
1. Coursier a 5 livraisons assignées
2. Démarre toutes les tournées
3. Confirme 3 livraisons
4. Déclare 2 échecs
5. Vérifie les statuts

**Résultats Attendus** :
- ✅ Toutes les livraisons gérées correctement
- ✅ Pas de confusion entre les livraisons
- ✅ Statuts corrects pour chaque livraison

## Tests de Performance

### Test P1 : Chargement de Nombreuses Livraisons

**Objectif** : Vérifier les performances avec beaucoup de données

**Étapes** :
1. Créer 50+ livraisons pour un coursier
2. Charger la liste
3. Filtrer par statut
4. Rechercher

**Résultats Attendus** :
- ✅ Chargement en moins de 2 secondes
- ✅ Filtrage instantané
- ✅ Pas de lag dans l'interface

### Test P2 : Mode Hors Ligne avec Synchronisation

**Objectif** : Vérifier la synchronisation de multiples actions

**Étapes** :
1. Mode hors ligne
2. Effectuer 10 actions (démarrages, confirmations)
3. Réactiver le réseau
4. Observer la synchronisation

**Résultats Attendus** :
- ✅ Toutes les actions synchronisées
- ✅ Pas de perte de données
- ✅ Synchronisation en moins de 5 secondes

## Tests de Sécurité

### Test S1 : Accès aux Livraisons d'Autres Coursiers

**Objectif** : Vérifier l'isolation des données

**Étapes** :
1. Se connecter comme coursier A
2. Noter les livraisons visibles
3. Se déconnecter
4. Se connecter comme coursier B
5. Vérifier les livraisons

**Résultats Attendus** :
- ✅ Chaque coursier voit uniquement ses livraisons
- ✅ Pas d'accès aux livraisons des autres

### Test S2 : Modification de Livraisons Non Assignées

**Objectif** : Vérifier les permissions

**Étapes** :
1. Tenter de modifier une livraison non assignée (via manipulation)

**Résultats Attendus** :
- ✅ Erreur de permission
- ✅ Modification refusée par Firebase

## Problèmes Connus et Limitations

### Limitations Actuelles

1. **Upload d'Images** : Les photos sont enregistrées localement mais pas encore uploadées vers Firebase Storage. Le chemin local est temporairement enregistré.

2. **Notifications Push** : Les notifications de nouvelles livraisons ne sont pas encore implémentées (Phase 13).

3. **Géolocalisation** : Le suivi GPS du coursier n'est pas implémenté dans cette phase.

### Améliorations Futures

1. **Firebase Storage** : Implémenter l'upload des photos vers Firebase Storage
2. **Compression d'Images** : Compresser les photos avant l'upload
3. **Signature Électronique** : Ajouter un widget de signature manuscrite
4. **Itinéraire Optimisé** : Suggérer l'ordre optimal des livraisons
5. **Navigation GPS** : Intégration avec Google Maps pour la navigation

## Checklist de Validation

### Fonctionnalités
- [ ] Liste des livraisons assignées
- [ ] Filtrage par statut
- [ ] Détails complets de la livraison
- [ ] Informations du destinataire
- [ ] Détails du colis
- [ ] Démarrage de tournée
- [ ] Confirmation de livraison
- [ ] Capture de photo de preuve
- [ ] Déclaration d'échec
- [ ] Sélection du motif d'échec
- [ ] Photo justificative d'échec
- [ ] Mode hors ligne
- [ ] Synchronisation automatique

### Interface Utilisateur
- [ ] Design cohérent avec le thème COREX
- [ ] Navigation intuitive
- [ ] Messages de feedback clairs
- [ ] Indicateurs de chargement
- [ ] États vides informatifs
- [ ] Responsive (mobile et desktop)

### Performance
- [ ] Chargement rapide
- [ ] Pas de lag
- [ ] Synchronisation efficace
- [ ] Gestion mémoire correcte

### Sécurité
- [ ] Isolation des données par coursier
- [ ] Permissions Firebase correctes
- [ ] Validation des données

## Commandes Utiles

### Lancer l'Application Desktop
```bash
cd corex_desktop
flutter run -d windows
```

### Lancer l'Application Mobile
```bash
cd corex_mobile
flutter run -d <device_id>
```

### Vérifier les Diagnostics
```bash
flutter doctor
```

### Nettoyer et Reconstruire
```bash
flutter clean
flutter pub get
flutter run
```

## Support et Dépannage

### Problème : Photos ne s'affichent pas
**Solution** : Vérifier les permissions caméra dans les paramètres de l'appareil

### Problème : Synchronisation ne fonctionne pas
**Solution** : Vérifier la connexion Firebase et les règles de sécurité

### Problème : Livraisons ne s'affichent pas
**Solution** : Vérifier que le coursier a des livraisons assignées dans Firebase

### Problème : Erreur de permission
**Solution** : Vérifier les règles Firestore pour la collection "livraisons"

## Conclusion

La Phase 7 est maintenant complète avec toutes les fonctionnalités essentielles pour les coursiers. Le système permet une gestion complète des livraisons avec support du mode hors ligne et une interface intuitive sur desktop et mobile.

**Prochaine Phase** : Phase 8 - Module Gestion Financière (Caisse)
