# Améliorations - Enregistrement des Colis

## Date: 3 Mars 2026

## Modifications effectuées

### 1. Ajout du champ "Valeur déclarée" du colis

#### Modèle de données (ColisModel)
- Ajout du champ `valeurDeclaree` (double?, optionnel)
- Mise à jour des méthodes `fromFirestore()`, `toFirestore()` et `copyWith()`

#### Formulaire de collecte (NouvelleCollecteScreen)
- Ajout d'un champ de saisie pour la valeur déclarée
- Champ optionnel avec validation du format numérique
- Label: "Valeur déclarée (FCFA) - Optionnel"
- Helper text: "Valeur estimée du contenu du colis"
- Icône: `Icons.monetization_on`

### 2. Poids du colis rendu optionnel

#### Modèle de données
- Le champ `poids` est maintenant de type `double?` (nullable)
- Changement de `required this.poids` à `this.poids`

#### Formulaire de collecte
- Le champ poids n'est plus obligatoire
- Label mis à jour: "Poids (kg) - Optionnel"
- Helper text ajouté: "Laissez vide si non pesé"
- Validation: accepte les valeurs vides, valide uniquement le format si rempli

#### Affichage
- Tous les écrans d'affichage ont été mis à jour pour gérer le poids optionnel
- Affichage conditionnel: "Non pesé" si le poids est null
- Utilisation de `if (colis.poids != null)` pour l'affichage conditionnel

### 3. Fichiers modifiés

#### Modèle et services
- `corex_shared/lib/models/colis_model.dart` - Modèle de données
- `corex_shared/lib/services/ticket_service.dart` - Service de génération de tickets
- `corex_shared/lib/services/ticket_service_simple.dart`
- `corex_shared/lib/services/ticket_service_optimized.dart`
- `corex_shared/lib/services/ticket_service_fixed.dart`
- `corex_shared/lib/services/ticket_print_service.dart`

#### Écrans Desktop
- `corex_desktop/lib/screens/agent/nouvelle_collecte_screen.dart` - Formulaire de collecte
- `corex_desktop/lib/screens/agent/enregistrement_colis_screen.dart` - Liste des colis à enregistrer
- `corex_desktop/lib/screens/agent/colis_details_screen.dart` - Détails du colis
- `corex_desktop/lib/screens/suivi/details_colis_screen.dart` - Suivi des colis
- `corex_desktop/lib/screens/retours/creer_retour_screen.dart` - Création de retours
- `corex_desktop/lib/screens/client/historique_client_screen.dart` - Historique client
- `corex_desktop/lib/screens/coursier/details_livraison_screen.dart` - Détails livraison coursier
- `corex_desktop/lib/screens/livraisons/attribution_livraison_screen.dart` - Attribution livraison
- `corex_desktop/lib/screens/livraisons/suivi_livraisons_screen.dart` - Suivi livraisons
- `corex_desktop/lib/services/pdf_service.dart` - Génération PDF

#### Écrans Mobile
- `corex_mobile/lib/screens/coursier/details_livraison_screen.dart`
- `corex_mobile/lib/screens/suivi/details_colis_screen.dart`

### 4. Affichage de la valeur déclarée

La valeur déclarée est maintenant affichée dans:
- Les tickets d'enregistrement (HTML et texte)
- Les écrans de détails du colis
- Les écrans de suivi
- Les documents PDF
- L'historique client
- Les écrans coursier

Format d'affichage: `Valeur déclarée: XXXXX FCFA`

### 5. Gestion du poids optionnel

#### Dans les formulaires
- Le champ poids peut être laissé vide
- Aucune erreur de validation si vide
- Validation du format numérique uniquement si rempli

#### Dans l'affichage
- Si poids null: affiche "Non pesé"
- Si poids présent: affiche "X.X kg"
- Affichage conditionnel dans tous les écrans

#### Dans les tickets
- HTML: affiche "Non pesé" si null
- Texte: affiche "Non pesé" si null
- PDF: n'affiche pas la ligne si null

### 6. Compatibilité

#### Données existantes
- Les colis existants sans valeur déclarée: champ null (pas d'affichage)
- Les colis existants avec poids: continuent de s'afficher normalement
- Aucune migration de données nécessaire

#### Nouveaux colis
- Valeur déclarée: optionnelle, peut être null
- Poids: optionnel, peut être null
- Tous les autres champs: inchangés

## Impact sur l'utilisation

### Pour les agents
1. Lors de la collecte, ils peuvent maintenant:
   - Saisir la valeur déclarée du colis (optionnel)
   - Laisser le poids vide si le colis n'est pas pesé
   
2. Les informations s'affichent correctement:
   - "Non pesé" si pas de poids
   - Valeur déclarée visible si renseignée

### Pour les clients
- Meilleure traçabilité avec la valeur déclarée
- Information claire si le colis n'a pas été pesé

### Pour les coursiers
- Visibilité sur la valeur du colis pour une meilleure gestion
- Information de poids optionnelle

## Tests recommandés

1. Créer un colis avec valeur déclarée et poids
2. Créer un colis avec valeur déclarée sans poids
3. Créer un colis sans valeur déclarée avec poids
4. Créer un colis sans valeur déclarée ni poids
5. Vérifier l'affichage dans tous les écrans
6. Générer un ticket pour chaque cas
7. Générer un PDF pour chaque cas
8. Vérifier la compatibilité avec les colis existants

## Notes techniques

- Le champ `valeurDeclaree` est stocké en FCFA (double)
- Le champ `poids` est stocké en kg (double)
- Les deux champs sont nullable dans Firestore
- Aucun index Firestore supplémentaire requis
- Les règles de sécurité Firestore restent inchangées
