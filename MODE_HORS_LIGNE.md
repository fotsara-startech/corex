# Mode Hors Ligne - COREX

## Vue d'ensemble

Le mode hors ligne permet aux utilisateurs de continuer à utiliser l'application même sans connexion Internet. Cette fonctionnalité est particulièrement importante pour les commerciaux et coursiers qui peuvent se trouver dans des zones avec une connexion limitée.

## Implémentation actuelle

### Desktop (Windows)

Pour la version Desktop, la persistance Firebase est **désactivée** car elle cause des problèmes de connexion sur Windows. Cependant, nous avons implémenté :

#### 1. Indicateur de connexion
- **Widget** : `ConnectionIndicator`
- **Emplacement** : AppBar du HomeScreen et écran de collecte
- **Fonctionnalité** :
  - Vérifie la connexion toutes les 30 secondes
  - Affiche un badge orange "Hors ligne" si déconnecté
  - Bouton de rafraîchissement pour vérifier manuellement
  - Disparaît automatiquement quand la connexion est rétablie

#### 2. Gestion des erreurs
- Messages d'erreur clairs en cas de perte de connexion
- Logs détaillés pour le débogage
- Continuation de l'exécution quand possible

### Mobile (Android/iOS) - À venir

Pour la version mobile, la persistance Firebase sera **activée** automatiquement :

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,  // Activé pour mobile
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

#### Fonctionnalités prévues :

1. **Cache local**
   - Toutes les données récentes sont mises en cache
   - Accès aux données même hors ligne
   - Taille de cache illimitée

2. **Synchronisation automatique**
   - Les modifications sont enregistrées localement
   - Synchronisation automatique au retour de connexion
   - Gestion des conflits de données

3. **Collecte hors ligne**
   - Possibilité de collecter des colis sans connexion
   - Génération de numéros de suivi temporaires
   - Upload automatique à la reconnexion

4. **Indicateurs visuels**
   - Badge "Hors ligne" dans l'AppBar
   - Icône de synchronisation pendant l'upload
   - Compteur de données en attente de synchronisation

## Configuration par plateforme

### Windows Desktop

```dart
// main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: false, // Désactivé pour Windows
);
```

**Raison** : La persistance Firebase sur Windows Desktop cause des problèmes de connexion et des crashes avec l'erreur `abort()`.

### Android/iOS Mobile

```dart
// main.dart (mobile)
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,  // Activé pour mobile
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

**Avantages** :
- Fonctionne parfaitement sur mobile
- Pas de problèmes de stabilité
- Expérience utilisateur optimale

## Utilisation

### Pour les utilisateurs Desktop

1. **Vérifier la connexion** : Regarder l'indicateur dans l'AppBar
2. **En cas de déconnexion** : 
   - Un badge orange "Hors ligne" apparaît
   - Cliquer sur l'icône de rafraîchissement pour revérifier
   - Attendre le rétablissement de la connexion
3. **Recommandation** : Éviter de collecter des colis sans connexion

### Pour les utilisateurs Mobile (futur)

1. **Collecte hors ligne** :
   - Collecter normalement même sans connexion
   - Les données sont sauvegardées localement
   - Un indicateur montre les données en attente

2. **Synchronisation** :
   - Automatique dès que la connexion revient
   - Notification de succès après synchronisation
   - Possibilité de forcer la synchronisation

3. **Gestion des conflits** :
   - Les données locales ont priorité
   - Résolution automatique des conflits simples
   - Alerte en cas de conflit complexe

## Tests

### Tests Desktop

- [x] Indicateur de connexion fonctionne
- [x] Détection de perte de connexion
- [x] Rafraîchissement manuel
- [x] Messages d'erreur appropriés

### Tests Mobile (à faire)

- [ ] Collecte complète hors ligne
- [ ] Synchronisation automatique
- [ ] Gestion des conflits
- [ ] Performance du cache
- [ ] Taille du cache
- [ ] Nettoyage du cache

## Limitations actuelles

### Desktop
- ❌ Pas de cache local
- ❌ Impossible de travailler hors ligne
- ✅ Détection de connexion
- ✅ Messages d'erreur clairs

### Mobile (futur)
- ✅ Cache local complet
- ✅ Travail hors ligne possible
- ✅ Synchronisation automatique
- ✅ Gestion des conflits

## Améliorations futures

1. **Desktop** :
   - Implémenter un cache SQLite local
   - Queue de synchronisation manuelle
   - Export des données en attente

2. **Mobile** :
   - Compression des données en cache
   - Priorisation de la synchronisation
   - Mode "économie de données"
   - Statistiques de synchronisation

3. **Général** :
   - Logs de synchronisation
   - Rapport d'erreurs détaillé
   - Dashboard de statut de connexion

## Dépannage

### "Hors ligne" affiché alors que connecté

1. Cliquer sur l'icône de rafraîchissement
2. Vérifier la connexion Internet
3. Redémarrer l'application
4. Vérifier les règles Firebase

### Données non synchronisées (Mobile)

1. Vérifier l'indicateur de synchronisation
2. Forcer la synchronisation manuellement
3. Vérifier les logs de l'application
4. Contacter le support si le problème persiste

## Références

- [Firebase Offline Persistence](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- [Flutter Connectivity](https://pub.dev/packages/connectivity_plus)
- [GetX State Management](https://pub.dev/packages/get)
