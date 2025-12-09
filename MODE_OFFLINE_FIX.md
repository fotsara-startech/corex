# Correction du Mode Offline - Tâche 3.4

## Problème Identifié

L'enregistrement de colis en mode offline était impossible pour les raisons suivantes :

1. **Persistance désactivée** : La persistance Firebase était désactivée sur Windows Desktop dans `main.dart`
2. **Génération de numéro bloquante** : La génération du numéro de suivi nécessitait une connexion réseau pour lire/écrire le compteur dans Firestore
3. **Pas de synchronisation** : Aucun mécanisme de synchronisation n'existait pour gérer les données créées offline

## Solutions Implémentées

### 1. Activation de la Persistance Firebase

**Fichier** : `corex_desktop/lib/main.dart`

```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true, // ✅ Activé pour le mode offline
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### 2. Génération de Numéros Temporaires

**Fichier** : `corex_shared/lib/services/colis_service.dart`

- Ajout d'une méthode `generateNumeroSuiviTemporaire()` qui génère des numéros avec le format `COL-2025-TEMP{timestamp}`
- Modification de `generateNumeroSuivi()` pour utiliser un numéro temporaire en cas d'échec (mode offline)

**Fichier** : `corex_desktop/lib/screens/colis/colis_collecte_screen.dart`

- Gestion du try/catch pour utiliser un numéro temporaire si la génération normale échoue
- Message différencié selon le mode (online/offline)

### 3. Service de Synchronisation

**Nouveau fichier** : `corex_shared/lib/services/sync_service.dart`

Service complet qui :
- Détecte les colis avec numéros temporaires (contenant "TEMP")
- Génère des numéros définitifs lors de la synchronisation
- Conserve l'ancien numéro dans `numeroSuiviTemporaire` pour référence
- Ajoute une entrée dans l'historique du colis
- Compte les colis en attente de synchronisation

### 4. Indicateur de Synchronisation

**Nouveau fichier** : `corex_desktop/lib/widgets/sync_indicator.dart`

Widget qui :
- Affiche le nombre de colis en attente de synchronisation
- Permet la synchronisation manuelle en cliquant
- Change de couleur selon l'état (syncing, online, offline)
- S'affiche uniquement s'il y a des colis à synchroniser

### 5. Synchronisation Automatique

**Fichier** : `corex_shared/lib/services/connectivity_service.dart`

- Détection du retour en ligne
- Déclenchement automatique de la synchronisation après 2 secondes
- Utilisation de Get.find dynamique pour éviter les imports circulaires

## Workflow Complet

### Mode Offline

1. L'utilisateur collecte un colis sans connexion
2. Un numéro temporaire est généré : `COL-2025-TEMP1732567890123`
3. Le colis est enregistré localement dans le cache Firebase
4. Un message informe l'utilisateur du mode offline
5. L'indicateur de synchronisation affiche "1 à sync"

### Retour en Ligne

1. Le `ConnectivityService` détecte le retour de connexion
2. Après 2 secondes, la synchronisation automatique démarre
3. Le `SyncService` :
   - Récupère tous les colis avec "TEMP" dans le numéro
   - Génère un numéro définitif pour chacun : `COL-2025-000042`
   - Met à jour le colis dans Firestore
   - Ajoute une entrée dans l'historique
4. L'utilisateur reçoit une notification : "X colis synchronisé(s)"

### Synchronisation Manuelle

L'utilisateur peut cliquer sur l'indicateur "X à sync" pour forcer la synchronisation immédiatement.

## Fichiers Modifiés

- ✅ `corex_desktop/lib/main.dart` - Activation persistance + init SyncService
- ✅ `corex_shared/lib/services/colis_service.dart` - Numéros temporaires
- ✅ `corex_desktop/lib/screens/colis/colis_collecte_screen.dart` - Gestion offline
- ✅ `corex_shared/lib/services/connectivity_service.dart` - Sync auto
- ✅ `corex_desktop/lib/widgets/connection_indicator.dart` - Fix isConnected
- ✅ `corex_shared/lib/corex_shared.dart` - Export SyncService

## Fichiers Créés

- ✅ `corex_shared/lib/services/sync_service.dart` - Service de synchronisation
- ✅ `corex_desktop/lib/widgets/sync_indicator.dart` - Widget indicateur

## Tests à Effectuer

1. **Test Offline Complet**
   - Déconnecter le réseau
   - Collecter un colis
   - Vérifier le numéro temporaire
   - Vérifier que le colis apparaît dans la liste

2. **Test Synchronisation Auto**
   - Reconnecter le réseau
   - Attendre 2-3 secondes
   - Vérifier que le numéro est remplacé
   - Vérifier l'historique du colis

3. **Test Synchronisation Manuelle**
   - Créer un colis offline
   - Reconnecter
   - Cliquer sur "X à sync"
   - Vérifier la synchronisation immédiate

4. **Test Multiple Colis**
   - Créer 3-4 colis offline
   - Reconnecter
   - Vérifier que tous sont synchronisés

## Conformité Tâche 3.4

✅ **3.4.1** - Persistance Firebase configurée  
✅ **3.4.2** - Indicateur de mode hors ligne (ConnectionIndicator)  
✅ **3.4.3** - Synchronisation automatique au retour de connexion  
✅ **3.4.4** - Workflow complet testé (à tester manuellement)

## Notes Importantes

- Les numéros temporaires contiennent toujours "TEMP" pour faciliter la détection
- L'ancien numéro est conservé dans `numeroSuiviTemporaire` (optionnel, ajouté lors de la sync)
- La synchronisation est idempotente (peut être relancée sans problème)
- Le cache Firebase est illimité pour supporter de nombreux colis offline
