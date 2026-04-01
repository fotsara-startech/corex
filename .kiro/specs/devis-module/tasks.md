# Plan d'implémentation : Module Devis

## Vue d'ensemble

Implémentation du module Devis en Flutter/Dart suivant le pattern établi du projet COREX :
`Model → Service (Firestore) → Controller (GetX) → Screens (Flutter Desktop)`.
Le langage d'implémentation est **Dart / Flutter**.

## Tâches

- [x] 1. Créer DevisModel et LigneDevis
  - [x] 1.1 Implémenter `LigneDevis` et `DevisModel` dans `corex_shared/lib/models/devis_model.dart`
    - Définir `LigneDevis` avec `designation`, `quantite`, `prixUnitaire`, `total` (calculé)
    - Définir `DevisModel` avec tous les champs du design : `id`, `numeroDevis`, `clientNom`, `clientTelephone`, `agenceId`, `userId`, `lignes`, `montantTotal`, `statut`, `dateCreation`, `dateModification`, `dateValidation`, `transactionId`, `factureId`, `notes`
    - Implémenter `fromFirestore(DocumentSnapshot)`, `toFirestore()`, `copyWith()`
    - Implémenter `LigneDevis.fromMap()` et `toMap()` pour la sérialisation des sous-documents
    - _Requirements: 1.2, 1.3, 7.1_

  - [ ]* 1.2 Écrire le test de propriété P2 — Round-trip sérialisation DevisModel
    - **Propriété 2 : Round-trip sérialisation DevisModel**
    - **Valide : Requirements 1.2**
    - Fichier : `corex_shared/test/models/devis_model_test.dart`
    - Générer des `DevisModel` aléatoires, sérialiser via `toFirestore()`, désérialiser via `fromFirestore()`, comparer tous les champs

  - [ ]* 1.3 Écrire le test de propriété P3 — Calcul du total d'une ligne
    - **Propriété 3 : total ligne = quantite × prixUnitaire**
    - **Valide : Requirements 1.3, 1.4**
    - Fichier : `corex_shared/test/models/devis_model_test.dart`
    - Générer des paires `(quantite, prixUnitaire)` positives, vérifier `total == q × p` et `montantTotal == sum(totaux)`

- [x] 2. Créer DevisService
  - [x] 2.1 Implémenter `DevisService` dans `corex_shared/lib/services/devis_service.dart`
    - Implémenter `generateNumeroDevis()` : transaction Firestore sur `counters/devis`, format `DEV-YYYY-MM-XXXXXX`, fallback UUID en cas d'erreur
    - Implémenter `createDevis(DevisModel)` → `Future<String>` (retourne l'id Firestore)
    - Implémenter `updateDevis(String id, Map<String, dynamic>)` → `Future<void>`
    - Implémenter `deleteDevis(String id)` → `Future<void>`
    - Implémenter `getDevisByAgence(String agenceId)` → `Stream<List<DevisModel>>` trié par `dateCreation` desc
    - Implémenter `getDevisById(String id)` → `Future<DevisModel?>`
    - Suivre le même pattern que `StockageService` (logs `print`, `rethrow` sur erreur)
    - _Requirements: 1.1, 2.3, 7.1, 7.2, 7.3_

  - [ ]* 2.2 Écrire le test de propriété P1 — Format du numéro de devis
    - **Propriété 1 : Format DEV-YYYY-MM-XXXXXX**
    - **Valide : Requirements 1.1, 7.1**
    - Fichier : `corex_shared/test/services/devis_service_test.dart`
    - Vérifier que le numéro généré correspond au regex `DEV-\d{4}-\d{2}-\d{6}`

  - [ ]* 2.3 Écrire le test de propriété P7 — Suppression round-trip
    - **Propriété 7 : Après deleteDevis(id), getDevisById(id) retourne null**
    - **Valide : Requirements 2.3, 2.5**
    - Fichier : `corex_shared/test/services/devis_service_test.dart`

  - [ ]* 2.4 Écrire le test de propriété P16 — Unicité des numéros de devis
    - **Propriété 16 : Tous les numéros générés séquentiellement sont distincts**
    - **Valide : Requirements 7.2**
    - Fichier : `corex_shared/test/services/devis_service_test.dart`

- [ ] 3. Checkpoint — Vérifier les tests du modèle et du service
  - S'assurer que tous les tests passent, poser des questions si nécessaire.

- [x] 4. Créer DevisController
  - [x] 4.1 Implémenter `DevisController` dans `corex_shared/lib/controllers/devis_controller.dart`
    - Déclarer les observables : `devisList`, `filteredList`, `isLoading`, `selectedStatut`, `currentDevis`
    - Implémenter `onInit()` : récupérer `agenceId` depuis `AuthController`, appeler `loadDevis()`
    - Implémenter `loadDevis()` : souscrire au stream `DevisService.getDevisByAgence()`
    - Implémenter `createDevis(DevisModel)` : valider (clientNom non vide, lignes non vides), générer numéro, créer via service, snackbar succès/erreur
    - Implémenter `updateDevis(String id, Map)` : vérifier statut `brouillon`/`envoye`, bloquer si `valide`/`converti`
    - Implémenter `deleteDevis(String id)` : vérifier statut autorisé, supprimer, retirer de la liste
    - Implémenter `setFiltreStatut(String)` : mettre à jour `selectedStatut` et `filteredList`
    - Suivre le pattern try/catch/snackbar de `StockageController`
    - _Requirements: 1.4, 1.5, 1.6, 1.7, 2.1, 2.2, 2.4, 2.5, 6.1, 6.2, 6.3, 6.4_

  - [x] 4.2 Implémenter `validerDevis(DevisModel)` dans `DevisController`
    - Créer une `TransactionModel` de type `recette` avec `categorieRecette: 'devis'`, `montant: devis.montantTotal`, `reference: devis.numeroDevis`
    - Appeler `TransactionService.createTransaction()`
    - En cas de succès : appeler `DevisService.updateDevis()` avec `statut: 'valide'`, `transactionId`, `dateValidation`
    - En cas d'échec de la transaction : ne pas modifier le statut, afficher snackbar d'erreur (rollback)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 4.3 Implémenter `convertirEnFacture(DevisModel)` dans `DevisController`
    - Créer une `FactureStockageModel` pré-remplie avec `clientNom`, `montantTotal`, `numeroDevis` comme référence
    - Appeler `StockageService.createFacture()` pour persister la facture
    - Mettre à jour le devis avec `statut: 'converti'` et `factureId`
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [x] 4.4 Implémenter `genererPdf(DevisModel)` dans `DevisController`
    - Générer un PDF avec `pdf` + `printing` (même pattern que `_genererPdf` dans `FacturesStockageScreen`)
    - Contenu : en-tête COREX (couleur `#2E7D32`), numéro devis, date, client (nom, téléphone), tableau des lignes (désignation, quantité, prix unitaire, total), montant total, statut
    - Méthode `imprimerDevis()` : appeler `Printing.layoutPdf()`
    - Méthode `exporterPdf()` : appeler `Printing.sharePdf()` avec nom `Devis_[numeroDevis].pdf`
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [ ]* 4.5 Écrire le test de propriété P4 — Validation avant sauvegarde
    - **Propriété 4 : clientNom vide ou lignes vides → création rejetée**
    - **Valide : Requirements 1.5, 1.6**
    - Fichier : `corex_shared/test/controllers/devis_controller_test.dart`

  - [ ]* 4.6 Écrire le test de propriété P5 — Statut initial brouillon
    - **Propriété 5 : Tout devis créé avec succès a statut == 'brouillon'**
    - **Valide : Requirements 1.7**
    - Fichier : `corex_shared/test/controllers/devis_controller_test.dart`

  - [ ]* 4.7 Écrire le test de propriété P6 — Permissions selon statut
    - **Propriété 6 : Modification/suppression autorisées seulement pour brouillon/envoye**
    - **Valide : Requirements 2.1, 2.2, 2.4**
    - Fichier : `corex_shared/test/controllers/devis_controller_test.dart`

  - [ ]* 4.8 Écrire le test de propriété P8 — Validation complète
    - **Propriété 8 : Après validation → statut valide + transaction recette + transactionId non-null + dateValidation non-null**
    - **Valide : Requirements 3.1, 3.2, 3.3, 3.5**
    - Fichier : `corex_shared/test/controllers/devis_controller_test.dart`

  - [ ]* 4.9 Écrire le test de propriété P14 — Tri par date décroissante
    - **Propriété 14 : La liste chargée est triée par dateCreation décroissante**
    - **Valide : Requirements 6.1**
    - Fichier : `corex_shared/test/controllers/devis_controller_test.dart`

  - [ ]* 4.10 Écrire le test de propriété P15 — Filtrage par statut
    - **Propriété 15 : filteredList contient uniquement des devis avec statut == filtre sélectionné**
    - **Valide : Requirements 6.2, 6.5**
    - Fichier : `corex_shared/test/controllers/devis_controller_test.dart`

- [ ] 5. Checkpoint — Vérifier les tests du controller
  - S'assurer que tous les tests passent, poser des questions si nécessaire.

- [-] 6. Créer DevisListScreen
  - [x] 6.1 Implémenter `DevisListScreen` dans `corex_desktop/lib/screens/devis/devis_list_screen.dart`
    - Appeler `DevisController.loadDevis()` dans `initState` ou via `onInit` du controller
    - Afficher les chips de filtre : Tous / Brouillon / Envoyé / Validé / Refusé / Converti (même style que `_FiltreBtn` dans `FacturesStockageScreen`)
    - Afficher un `ListView` de cartes avec : numéro devis, nom client, montant total, statut (chip coloré), date de création
    - Afficher un `CircularProgressIndicator` pendant `isLoading`
    - Afficher un état vide avec bouton "Créer un devis" si `filteredList` est vide
    - FAB pour créer un nouveau devis → naviguer vers `DevisFormScreen`
    - Tap sur une carte → naviguer vers `DevisDetailScreen`
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [-] 7. Créer DevisFormScreen
  - [x] 7.1 Implémenter `DevisFormScreen` dans `corex_desktop/lib/screens/devis/devis_form_screen.dart`
    - Accepter un `DevisModel?` optionnel en paramètre (null = création, non-null = édition)
    - Champs : `clientNom` (TextFormField), `clientTelephone` (TextFormField), `notes` (TextFormField optionnel)
    - Section lignes : `ListView` de widgets de ligne avec `designation`, `quantite`, `prixUnitaire`
    - Recalculer `total` de chaque ligne et `montantTotal` en temps réel à chaque modification (via `onChanged`)
    - Bouton "Ajouter une ligne" pour insérer une nouvelle `LigneDevis` vide
    - Bouton de suppression sur chaque ligne
    - Validation avant sauvegarde : `clientNom` non vide, au moins une ligne, `quantite` > 0, `prixUnitaire` >= 0
    - Bouton "Enregistrer" → appeler `DevisController.createDevis()` ou `updateDevis()` selon le mode
    - _Requirements: 1.1, 1.3, 1.4, 1.5, 1.6, 2.1_

- [-] 8. Créer DevisDetailScreen
  - [x] 8.1 Implémenter `DevisDetailScreen` dans `corex_desktop/lib/screens/devis/devis_detail_screen.dart`
    - Accepter un `DevisModel` en paramètre
    - Afficher : numéro devis, date de création, nom client, téléphone, statut (chip coloré), notes
    - Afficher un tableau des lignes (désignation, quantité, prix unitaire, total)
    - Afficher le montant total en évidence
    - Actions contextuelles selon statut :
      - `brouillon`/`envoye` → boutons Modifier (→ `DevisFormScreen`), Supprimer, Valider
      - `valide` → boutons Convertir en facture, Imprimer PDF, Exporter PDF
      - `converti` → afficher référence `factureId`, boutons Imprimer PDF, Exporter PDF
      - `refuse` → boutons Imprimer PDF, Exporter PDF (lecture seule)
    - Appeler les méthodes correspondantes du `DevisController`
    - _Requirements: 2.1, 2.2, 2.4, 3.5, 4.3, 4.4, 5.1, 5.3_

  - [ ]* 8.2 Écrire le test de propriété P11 — Conversion uniquement depuis statut valide
    - **Propriété 11 : Le bouton Convertir est désactivé si statut != 'valide'**
    - **Valide : Requirements 4.4**
    - Fichier : `corex_shared/test/controllers/devis_controller_test.dart`

- [x] 9. Intégration dans main.dart et home_screen.dart
  - [x] 9.1 Enregistrer `DevisService` et `DevisController` dans `corex_desktop/lib/main.dart`
    - Ajouter dans `_initializeServices()` après `StockageService` :
      ```dart
      await _safeInitialize('DevisService', () async => Get.put(DevisService(), permanent: true));
      await _safeInitialize('DevisController', () async => Get.put(DevisController(), permanent: true));
      ```
    - Ajouter l'import de `DevisService` et `DevisController` depuis `corex_shared`
    - Ajouter la route `/devis` dans `getPages` : `GetPage(name: '/devis', page: () => const DevisListScreen())`
    - Ajouter l'import de `DevisListScreen`
    - _Requirements: 6.1_

  - [x] 9.2 Ajouter l'entrée "Devis" dans le drawer de `corex_desktop/lib/screens/home/home_screen.dart`
    - Ajouter un `ListTile` dans la section OPÉRATIONS (visible pour `gestionnaire`, `admin`, `commercial`)
    - Icône : `Icons.request_quote`, titre : `'Devis'`
    - Navigation : `Get.toNamed('/devis')`
    - Ajouter l'import de `DevisListScreen` si navigation directe utilisée
    - _Requirements: 6.1, 6.3_

- [ ] 10. Checkpoint final — Vérifier l'intégration complète
  - S'assurer que tous les tests passent, que la navigation fonctionne, poser des questions si nécessaire.

## Notes

- Les tâches marquées `*` sont optionnelles et peuvent être ignorées pour un MVP rapide
- Chaque tâche référence les requirements pour la traçabilité
- Les tests de propriétés utilisent la bibliothèque `fast_check` (Dart)
- Le pattern PDF suit exactement `_genererPdf()` dans `FacturesStockageScreen`
- Le pattern de gestion d'erreurs suit `StockageController` (try/catch/snackbar/print)
- `DevisService` doit être exporté depuis `corex_shared/lib/corex_shared.dart`
