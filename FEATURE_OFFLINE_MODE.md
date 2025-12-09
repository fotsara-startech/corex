# Fonctionnalité : Mode Hors Ligne

## Vue d'ensemble

Cette fonctionnalité permet de détecter l'état de connexion et d'informer l'utilisateur lorsqu'il est hors ligne.

## Composants créés

### 1. Service de connectivité (`ConnectivityService`)
- **Fichier**: `corex_shared/lib/services/connectivity_service.dart`
- **Fonctionnalités**:
  - Détection automatique de l'état de connexion
  - Vérification périodique toutes les 30 secondes
  - Observable `isOnline` pour réactivité UI
  - Observable `isSyncing` pour indiquer la synchronisation
  - Méthode `checkConnectionNow()` pour vérification manuelle

### 2. Widget indicateur de connexion (`ConnectionIndicator`)
- **Fichier**: `corex_desktop/lib/widgets/connection_indicator.dart`
- **Affichage**:
  - **En ligne** : Badge vert avec icône cloud_done
  - **Hors ligne** : Badge rouge avec icône cloud_off
  - **Synchronisation** : Badge orange avec spinner

### 3. Intégration dans l'UI
- Indicateur ajouté dans l'AppBar du HomeScreen
- Visible en permanence pour informer l'utilisateur
- Mise à jour automatique en temps réel

## Fonctionnement

### Détection de connexion
```dart
// Vérification via une requête Firestore
await FirebaseFirestore.instance
    .collection('_test')
    .limit(1)
    .get(const GetOptions(source: Source.server));
```

### Monitoring automatique
- Vérification toutes les 30 secondes
- Mise à jour automatique de l'état
- Logs dans la console pour débogage

## Limitations Windows Desktop

Sur Windows Desktop, la persistance Firebase est **désactivée** car elle cause des problèmes de connexion :

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: false, // Désactivé pour Windows
);
```

### Conséquences :
- ❌ Pas de cache local automatique
- ❌ Pas de synchronisation automatique hors ligne
- ✅ Détection de l'état de connexion fonctionnelle
- ✅ Feedback visuel à l'utilisateur

## Utilisation

### Dans n'importe quel écran :

```dart
// Importer le widget
import '../../widgets/connection_indicator.dart';

// Ajouter dans l'AppBar
appBar: AppBar(
  title: const Text('Mon Écran'),
  actions: const [
    ConnectionIndicator(),
    SizedBox(width: 16),
  ],
),
```

### Vérifier l'état programmatiquement :

```dart
final connectivityService = Get.find<ConnectivityService>();

// Vérifier l'état actuel
if (connectivityService.isOnline.value) {
  // En ligne
} else {
  // Hors ligne
}

// Vérifier maintenant
final isOnline = await connectivityService.checkConnectionNow();
```

### Réagir aux changements :

```dart
Obx(() {
  if (connectivityService.isOnline.value) {
    return Text('Connecté');
  } else {
    return Text('Déconnecté');
  }
})
```

## Mode hors ligne sur Mobile

Sur les applications mobiles (Android/iOS), la persistance Firebase sera **activée** :

```dart
// Dans corex_mobile/lib/main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true, // Activé pour mobile
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### Avantages mobile :
- ✅ Cache local automatique
- ✅ Synchronisation automatique au retour de connexion
- ✅ Collecte de colis hors ligne
- ✅ Consultation des données en cache

## Tests recommandés

### Desktop :
- [ ] Vérifier l'affichage de l'indicateur
- [ ] Couper la connexion internet
- [ ] Vérifier que l'indicateur passe en rouge
- [ ] Rétablir la connexion
- [ ] Vérifier que l'indicateur repasse en vert

### Mobile (futur) :
- [ ] Collecter un colis hors ligne
- [ ] Vérifier le stockage en cache
- [ ] Rétablir la connexion
- [ ] Vérifier la synchronisation automatique

## Améliorations futures

1. **Queue de synchronisation** : Stocker les actions hors ligne et les rejouer
2. **Indicateur de données en attente** : Afficher le nombre d'éléments à synchroniser
3. **Retry automatique** : Réessayer les opérations échouées
4. **Notification** : Alerter l'utilisateur lors de la perte/reprise de connexion
5. **Mode avion** : Détecter spécifiquement le mode avion
6. **Qualité de connexion** : Indiquer la qualité (3G, 4G, WiFi, etc.)

## Notes techniques

- Le service utilise GetX pour la réactivité
- La vérification se fait via une requête Firestore légère
- Le service est initialisé au démarrage de l'application
- L'état est persisté pendant toute la session
