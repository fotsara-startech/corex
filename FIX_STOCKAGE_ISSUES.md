# Corrections des Problèmes de Stockage

## Problèmes Identifiés et Résolus

### 1. Les clients stockeurs n'apparaissent pas au démarrage

**Problème :** Après l'enregistrement d'un nouveau client stockeur, il fallait effectuer une recherche pour le visualiser dans la liste. Au redémarrage de l'application, aucun client n'apparaissait même si des dépôts existaient en base de données.

**Cause Racine :** 
- La méthode `loadClientsStockeurs()` chargeait TOUS les clients de l'agence
- Si les clients avaient été créés via le module de livraison (et non via le module de stockage), ils n'étaient pas affichés
- Aucune corrélation entre les clients affichés et les dépôts existants

**Solution Complète :**

1. **Modification de `client_service.dart`** :
   - Changé le type de retour de `Future<void>` à `Future<String>`
   - Retourne maintenant l'ID du document créé par Firestore

2. **Modification de `stockage_service.dart`** :
   - Ajout de la méthode `getDepotsListByAgence()` qui retourne une liste (pas un Stream)
   - Permet de récupérer tous les dépôts de manière synchrone

3. **Modification de `stockage_controller.dart`** :
   - **Nouvelle logique de chargement** :
     1. Charge d'abord tous les dépôts de l'agence
     2. Extrait les IDs uniques des clients qui ont des dépôts
     3. Charge les informations complètes de chaque client
     4. Trie les clients par nom
   - Pour la création : ajoute immédiatement le client en tête de liste
   - **Résultat** : Seuls les clients ayant des dépôts sont affichés

### 2. Les quantités ne sont pas mises à jour après un retrait

**Problème :** Lors d'un retrait, les quantités n'étaient pas mises à jour directement, ce qui permettait de faire des retraits avec des quantités négatives.

**Cause :**
- L'ordre des opérations était incorrect (mouvement créé avant la mise à jour du stock)
- Aucune vérification des quantités disponibles avant le retrait
- Pas de validation pour éviter les quantités négatives

**Solution dans `stockage_service.dart`** :

1. **Vérification préalable** :
   - Récupération du dépôt AVANT toute opération
   - Vérification que chaque produit existe dans le dépôt
   - Validation que la quantité demandée est disponible
   - Message d'erreur explicite si quantité insuffisante

2. **Ordre des opérations corrigé** :
   - ✅ Récupération du dépôt
   - ✅ Vérification des quantités disponibles
   - ✅ Mise à jour des quantités dans le dépôt (EN PREMIER)
   - ✅ Création du mouvement de retrait (EN SECOND)

3. **Calcul des nouvelles quantités** :
   ```dart
   final nouvelleQuantite = p.quantite - retrait.quantite;
   return p.copyWith(quantite: nouvelleQuantite);
   ```

4. **Gestion des erreurs** :
   - Exception levée si le dépôt n'existe pas
   - Exception levée si le produit n'existe pas
   - Exception levée si la quantité est insuffisante
   - Messages d'erreur détaillés avec les quantités disponibles et demandées

## Avantages des Corrections

### Pour le Problème 1 :
- ✅ Expérience utilisateur améliorée (pas besoin de rechercher)
- ✅ Feedback immédiat après la création
- ✅ Liste toujours à jour

### Pour le Problème 2 :
- ✅ Impossible d'avoir des quantités négatives
- ✅ Validation en temps réel des stocks disponibles
- ✅ Messages d'erreur clairs et informatifs
- ✅ Intégrité des données garantie
- ✅ Mise à jour immédiate dans l'interface (grâce aux Streams Firestore)

## Cause Technique du Problème d'Affichage

**Problème de timing** :
- Le `StockageController.onInit()` était appelé au démarrage de l'app
- À ce moment, l'utilisateur n'était PAS encore connecté
- `loadClientsStockeurs()` échouait silencieusement (user == null)
- Quand l'utilisateur naviguait vers l'écran après connexion, aucun rechargement n'était déclenché

**Solution** :
- Retirer le chargement automatique du `onInit()`
- Charger les données dans le `initState()` de l'écran
- Utiliser `WidgetsBinding.instance.addPostFrameCallback()` pour garantir que le widget est monté
- Les données sont maintenant chargées APRÈS la connexion

## Fichiers Modifiés

1. `corex_shared/lib/services/client_service.dart`
   - Méthode `createClient()` retourne maintenant l'ID
   - Logs ajoutés pour le débogage

2. `corex_shared/lib/controllers/stockage_controller.dart`
   - Méthode `createClientStockeur()` met à jour la liste locale
   - Méthode `loadClientsStockeurs()` avec nouvelle logique (charge clients ayant des dépôts)
   - `onInit()` ne charge plus automatiquement (chargement différé)
   - Logs détaillés ajoutés

3. `corex_shared/lib/services/stockage_service.dart`
   - Méthode `createRetrait()` avec validation et ordre correct des opérations
   - Nouvelle méthode `getDepotsListByAgence()` pour récupération synchrone
   - Logs ajoutés

4. `corex_desktop/lib/screens/stockage/clients_stockeurs_screen.dart`
   - Changé de `StatelessWidget` à `StatefulWidget`
   - Ajout de `initState()` qui charge les clients après le montage du widget
   - Garantit que les données sont chargées quand l'utilisateur est connecté

5. `corex_desktop/lib/screens/stockage/create_depot_screen.dart`
   - Fix du bug de parsing du tarif (bonus)

## Problème 3 : Quantités non mises à jour après retrait et dialog ne se ferme pas

**Problème** : Après un retrait, les quantités affichées ne changeaient pas et le dialog restait ouvert.

**Causes** :
1. L'écran affichait le `depot` passé en paramètre (statique), pas les données réactives du contrôleur
2. Aucun rechargement du dépôt après le retrait
3. Le dialog se fermait uniquement si `success == true`, mais les erreurs n'étaient pas visibles

**Solution** :

1. **Modification de `depot_details_screen.dart`** :
   - Changé de `StatelessWidget` à `StatefulWidget`
   - Dans `initState()`, appel de `controller.selectDepot()` pour stocker le dépôt actuel
   - Utilisation de `Obx()` pour observer les changements du `selectedDepot`
   - L'écran affiche maintenant `controller.selectedDepot.value` au lieu du paramètre statique
   - Les quantités se mettent à jour automatiquement quand le dépôt change

2. **Modification de `stockage_controller.dart`** :
   - Nouvelle méthode `reloadSelectedDepot()` qui recharge le dépôt depuis Firestore
   - Dans `createRetrait()`, appel de `reloadSelectedDepot()` après le retrait
   - Les nouvelles quantités sont récupérées et l'interface se met à jour automatiquement

**Résultat** :
- ✅ Les quantités sont mises à jour en temps réel après un retrait
- ✅ Le dialog se ferme automatiquement après succès
- ✅ Les erreurs sont affichées clairement (quantité insuffisante, etc.)
- ✅ L'historique des mouvements se met à jour automatiquement

## Tests Recommandés

### Test 1 : Création de client
1. Créer un nouveau client stockeur
2. Vérifier qu'il apparaît immédiatement dans la liste
3. Vérifier qu'il est en première position

### Test 2 : Retrait avec quantité suffisante
1. Créer un dépôt avec 10 unités d'un produit
2. Effectuer un retrait de 3 unités
3. Vérifier que la quantité passe à 7 immédiatement
4. Vérifier que le mouvement est enregistré

### Test 3 : Retrait avec quantité insuffisante
1. Créer un dépôt avec 5 unités d'un produit
2. Tenter un retrait de 10 unités
3. Vérifier qu'une erreur est affichée
4. Vérifier que la quantité reste à 5
5. Vérifier qu'aucun mouvement n'est créé

### Test 4 : Retrait de produit inexistant
1. Créer un dépôt avec le produit A
2. Tenter un retrait du produit B
3. Vérifier qu'une erreur est affichée
