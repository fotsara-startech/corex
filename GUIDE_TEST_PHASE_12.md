# Guide de Test - Phase 12 : Module Retour de Colis

## Prérequis

- Application COREX Desktop lancée
- Connexion avec un compte Gestionnaire ou Admin
- Au moins un colis existant dans le système
- Au moins un coursier actif

## Test 1 : Création d'un retour

### Étapes
1. Se connecter en tant que Gestionnaire ou Commercial
2. Ouvrir le menu latéral (drawer)
3. Cliquer sur "Retours de Colis"
4. Cliquer sur le bouton "Créer un Retour"
5. Saisir un numéro de suivi existant (ex: COL-2025-000001)
6. Cliquer sur "Rechercher"

### Résultats attendus
- ✅ Le colis est trouvé et affiché
- ✅ Les informations expéditeur et destinataire sont affichées
- ✅ Un message de confirmation apparaît

### Test de l'inversion
7. Vérifier que dans la section "Expéditeur (deviendra destinataire du retour)":
   - Les informations correspondent au destinataire du colis initial
8. Vérifier que dans la section "Destinataire (deviendra expéditeur du retour)":
   - Les informations correspondent à l'expéditeur du colis initial

### Résultats attendus
- ✅ L'inversion est correcte
- ✅ Toutes les informations sont présentes

### Création du retour
9. Saisir un commentaire optionnel (ex: "Client refuse le colis")
10. Cliquer sur "Créer le Retour"

### Résultats attendus
- ✅ Message de succès avec le numéro de suivi du retour (RET-2025-XXXXXX)
- ✅ Retour à la liste des retours
- ✅ Le nouveau retour apparaît dans la liste

## Test 2 : Vérification du lien bidirectionnel

### Étapes
1. Noter le numéro de suivi du retour créé
2. Aller dans "Suivi des colis"
3. Rechercher le colis initial
4. Ouvrir les détails du colis

### Résultats attendus
- ✅ Le colis initial contient une référence au retour
- ✅ Le retourId est présent dans les données

### Vérification inverse
5. Retourner dans "Retours de Colis"
6. Cliquer sur "Détails" du retour créé

### Résultats attendus
- ✅ Le retour affiche les informations du colis initial
- ✅ Le numéro du colis initial est affiché

## Test 3 : Filtrage par statut

### Étapes
1. Dans la liste des retours
2. Utiliser le filtre "Filtrer par statut"
3. Sélectionner "Collecté"

### Résultats attendus
- ✅ Seuls les retours avec statut "collecte" sont affichés
- ✅ Le retour créé précédemment apparaît

### Test des autres statuts
4. Tester les autres statuts:
   - Enregistré
   - En Transit
   - Arrivé
   - En Livraison
   - Livré

### Résultats attendus
- ✅ Le filtrage fonctionne correctement
- ✅ Les retours sont filtrés selon leur statut

## Test 4 : Affichage des retours dans le suivi

### Étapes
1. Aller dans "Suivi des colis"
2. Observer la barre de filtres
3. Localiser le switch "Afficher les retours"
4. Activer le switch

### Résultats attendus
- ✅ Le switch est visible dans la barre de filtres
- ✅ Par défaut, le switch est désactivé (retours masqués)
- ✅ Quand activé, les retours apparaissent dans la liste
- ✅ Les retours sont identifiables (icône ou badge)

### Mise à jour des statuts
5. Avec le switch activé, trouver un retour
6. Cliquer sur le retour pour voir les détails
7. Mettre à jour le statut (ex: collecte → enregistre)

### Résultats attendus
- ✅ Le statut du retour est mis à jour
- ✅ L'historique est enregistré
- ✅ Le retour reste visible dans la liste

## Test 5 : Attribution à un coursier

### Prérequis
- Avoir un retour avec statut "arriveDestination"
- (Si nécessaire, mettre à jour manuellement le statut dans Firebase)

### Étapes
1. Dans la liste des retours
2. Trouver un retour avec statut "Arrivé"
3. Cliquer sur l'icône "Attribuer" (icône personne+)
4. Sélectionner un coursier dans la liste
5. Cliquer sur "Attribuer"

### Résultats attendus
- ✅ Message de succès
- ✅ Le statut du retour passe à "En Livraison"
- ✅ Le coursier est assigné au retour
- ✅ L'historique est mis à jour

## Test 6 : Affichage des détails

### Étapes
1. Dans la liste des retours
2. Cliquer sur l'icône "Détails" (œil) d'un retour
3. Observer la fenêtre de détails

### Résultats attendus
- ✅ Numéro de suivi du retour affiché
- ✅ Statut actuel affiché
- ✅ Date de collecte affichée
- ✅ Informations du colis initial affichées
- ✅ Informations expéditeur complètes
- ✅ Informations destinataire complètes
- ✅ Détails du colis (contenu, poids, tarif)
- ✅ Commentaire affiché si présent

## Test 7 : Codes couleur des statuts

### Étapes
1. Observer les puces de statut dans la liste

### Résultats attendus
- ✅ Collecté = Orange
- ✅ Enregistré = Bleu
- ✅ En Transit = Violet
- ✅ Arrivé = Turquoise
- ✅ En Livraison = Indigo
- ✅ Livré = Vert

## Test 8 : Génération du numéro de suivi

### Étapes
1. Créer plusieurs retours successifs
2. Noter les numéros de suivi générés

### Résultats attendus
- ✅ Format: RET-YYYY-XXXXXX (ex: RET-2025-000001)
- ✅ Les numéros sont séquentiels
- ✅ Pas de doublons
- ✅ L'année correspond à l'année actuelle

## Test 9 : Validation des erreurs

### Test 9.1 : Numéro de suivi invalide
1. Créer un retour
2. Saisir un numéro de suivi inexistant
3. Cliquer sur "Rechercher"

### Résultats attendus
- ✅ Message d'erreur: "Aucun colis trouvé avec ce numéro de suivi"

### Test 9.2 : Champ vide
1. Créer un retour
2. Laisser le champ numéro de suivi vide
3. Cliquer sur "Rechercher"

### Résultats attendus
- ✅ Message d'erreur: "Veuillez saisir un numéro de suivi"

### Test 9.3 : Création sans recherche
1. Créer un retour
2. Cliquer directement sur "Créer le Retour" sans rechercher
3. (Le bouton ne devrait pas être visible)

### Résultats attendus
- ✅ Le bouton "Créer le Retour" n'apparaît que si un colis est trouvé

## Test 10 : Permissions d'accès

### Test 10.1 : Gestionnaire
1. Se connecter en tant que Gestionnaire
2. Vérifier l'accès au menu "Retours de Colis"

### Résultats attendus
- ✅ Menu visible et accessible

### Test 10.2 : Commercial
1. Se connecter en tant que Commercial
2. Vérifier l'accès au menu "Retours de Colis"

### Résultats attendus
- ✅ Menu visible et accessible

### Test 10.3 : Admin
1. Se connecter en tant que Admin
2. Vérifier l'accès au menu "Retours de Colis"

### Résultats attendus
- ✅ Menu visible et accessible

### Test 10.4 : Coursier
1. Se connecter en tant que Coursier
2. Vérifier l'accès au menu "Retours de Colis"

### Résultats attendus
- ✅ Menu non visible (pas d'accès)

## Test 11 : Actualisation

### Étapes
1. Dans la liste des retours
2. Cliquer sur l'icône "Actualiser" dans l'AppBar

### Résultats attendus
- ✅ La liste se recharge
- ✅ Indicateur de chargement affiché
- ✅ Données à jour affichées

## Checklist finale

- [ ] Création de retour fonctionne
- [ ] Numéro de suivi généré correctement (RET-YYYY-XXXXXX)
- [ ] Inversion expéditeur/destinataire correcte
- [ ] Lien bidirectionnel colis/retour fonctionnel
- [ ] Filtrage par statut opérationnel
- [ ] Attribution à un coursier fonctionne
- [ ] Affichage des détails complet
- [ ] Codes couleur corrects
- [ ] Validation des erreurs appropriée
- [ ] Permissions d'accès respectées
- [ ] Actualisation fonctionnelle

## Notes

- Les retours utilisent le même workflow que les colis normaux
- Le statut "retourne" est ajouté au colis initial quand le retour est livré
- Les retours peuvent être suivis comme des colis normaux dans "Suivi des colis"
- Le compteur de retours est indépendant du compteur de colis

## Problèmes connus

Aucun problème connu pour le moment.

## Prochaines étapes

Après validation de la Phase 12, passer à la Phase 13 : Notifications et Emails.
