# Guide de Test - Phase 5 : Module Suivi et Gestion des Statuts

## Objectif

Ce guide vous permet de tester toutes les fonctionnalités du module de suivi et de gestion des statuts des colis implémentées dans la Phase 5.

## Prérequis

1. ✅ Phase 0 complétée (Configuration et Infrastructure)
2. ✅ Phase 1 complétée (Authentification et Gestion des Utilisateurs)
3. ✅ Phase 2 complétée (Gestion des Agences et Configuration)
4. ✅ Phase 3 complétée (Module Expédition de Colis)
5. ✅ Phase 4 complétée (Module Enregistrement de Colis)
6. ✅ Avoir des colis avec différents statuts dans la base de données
7. ✅ Avoir des utilisateurs avec différents rôles

## Préparation des Données de Test

### 1. Créer des Colis de Test

Avant de tester le module de suivi, assurez-vous d'avoir des colis avec différents statuts :

**Via l'interface Commercial (Phase 3):**
1. Connectez-vous en tant que Commercial
2. Collectez plusieurs colis (statut: `collecte`)

**Via l'interface Agent (Phase 4):**
1. Connectez-vous en tant que Agent
2. Enregistrez certains colis (statut: `enregistre`)

**Statuts à créer manuellement (via Firebase Console ou l'interface):**
- `enTransit` - Colis en transit
- `arriveDestination` - Colis arrivé à destination
- `enCoursLivraison` - Colis en cours de livraison
- `livre` - Colis livré
- `retire` - Colis retiré
- `echec` - Échec de livraison
- `retour` - Colis en retour

## Tests Fonctionnels

### Test 1: Accès au Module de Suivi

**Objectif:** Vérifier que tous les rôles peuvent accéder au module de suivi

**Étapes:**
1. Lancez l'application desktop: `cd corex_desktop && flutter run -d windows`
2. Connectez-vous avec différents rôles
3. Cliquez sur le menu hamburger (☰)
4. Cliquez sur "Suivi des colis"

**Résultat attendu:**
- ✅ L'écran de suivi s'ouvre
- ✅ La liste des colis s'affiche selon les permissions du rôle
- ✅ PDG voit tous les colis
- ✅ Admin/Gestionnaire/Agent voient les colis de leur agence
- ✅ Commercial voit uniquement ses colis
- ✅ Coursier voit uniquement les colis qui lui sont assignés

---

### Test 2: Recherche par Numéro de Suivi

**Objectif:** Vérifier la recherche par numéro de suivi

**Étapes:**
1. Ouvrez l'écran de suivi
2. Notez un numéro de suivi d'un colis (ex: COL-2025-000001)
3. Tapez le numéro complet dans la barre de recherche
4. Tapez seulement une partie du numéro (ex: "000001")

**Résultat attendu:**
- ✅ La recherche filtre en temps réel
- ✅ Le colis correspondant s'affiche
- ✅ La recherche partielle fonctionne
- ✅ La recherche est insensible à la casse

---

### Test 3: Recherche par Nom

**Objectif:** Vérifier la recherche par nom d'expéditeur et destinataire

**Étapes:**
1. Tapez le nom d'un expéditeur dans la barre de recherche
2. Effacez et tapez le nom d'un destinataire
3. Tapez seulement une partie du nom

**Résultat attendu:**
- ✅ Les colis avec l'expéditeur correspondant s'affichent
- ✅ Les colis avec le destinataire correspondant s'affichent
- ✅ La recherche partielle fonctionne
- ✅ La recherche est insensible à la casse

---

### Test 4: Recherche par Téléphone

**Objectif:** Vérifier la recherche par numéro de téléphone

**Étapes:**
1. Tapez un numéro de téléphone d'expéditeur
2. Tapez un numéro de téléphone de destinataire
3. Tapez seulement une partie du numéro

**Résultat attendu:**
- ✅ Les colis correspondants s'affichent
- ✅ La recherche partielle fonctionne

---

### Test 5: Filtre par Statut

**Objectif:** Vérifier le filtrage par statut

**Étapes:**
1. Cliquez sur le dropdown "Tous les statuts"
2. Sélectionnez "Collecté"
3. Vérifiez que seuls les colis avec statut "collecte" s'affichent
4. Changez pour "Enregistré"
5. Testez tous les statuts disponibles

**Résultat attendu:**
- ✅ Le filtre s'applique immédiatement
- ✅ Seuls les colis du statut sélectionné s'affichent
- ✅ Le compteur de colis est correct
- ✅ "Tous les statuts" affiche tous les colis

---

### Test 6: Filtre par Date

**Objectif:** Vérifier le filtrage par période

**Étapes:**
1. Cliquez sur "Date début"
2. Sélectionnez une date dans le calendrier
3. Vérifiez que seuls les colis collectés après cette date s'affichent
4. Cliquez sur "Date fin"
5. Sélectionnez une date
6. Vérifiez que seuls les colis dans la période s'affichent

**Résultat attendu:**
- ✅ Le calendrier s'ouvre
- ✅ Le filtre s'applique correctement
- ✅ Les colis hors période sont masqués
- ✅ La combinaison date début + date fin fonctionne

---

### Test 7: Combinaison de Filtres

**Objectif:** Vérifier que plusieurs filtres peuvent être combinés

**Étapes:**
1. Tapez un nom dans la recherche
2. Sélectionnez un statut
3. Ajoutez un filtre de date
4. Vérifiez que tous les filtres s'appliquent ensemble

**Résultat attendu:**
- ✅ Tous les filtres s'appliquent simultanément
- ✅ Seuls les colis correspondant à TOUS les critères s'affichent
- ✅ Le compteur est correct

---

### Test 8: Réinitialisation des Filtres

**Objectif:** Vérifier la réinitialisation des filtres

**Étapes:**
1. Appliquez plusieurs filtres (recherche, statut, date)
2. Cliquez sur l'icône "Réinitialiser les filtres" (⟲)

**Résultat attendu:**
- ✅ Tous les filtres sont réinitialisés
- ✅ La barre de recherche est vidée
- ✅ Le statut revient à "Tous"
- ✅ Les dates sont effacées
- ✅ Tous les colis s'affichent à nouveau

---

### Test 9: Affichage des Détails du Colis

**Objectif:** Vérifier l'affichage complet des détails

**Étapes:**
1. Cliquez sur un colis dans la liste
2. Vérifiez toutes les sections affichées

**Résultat attendu:**
- ✅ Header coloré avec numéro de suivi et statut
- ✅ Section Expéditeur (nom, téléphone, adresse)
- ✅ Section Destinataire (nom, téléphone, adresse, ville, quartier)
- ✅ Section Détails du Colis (contenu, poids, dimensions, mode de livraison)
- ✅ Section Informations Financières (montant, statut paiement, date paiement)
- ✅ Section Dates Importantes (collecte, enregistrement, livraison)
- ✅ Section Historique des Statuts

---

### Test 10: Historique des Statuts (Desktop)

**Objectif:** Vérifier l'affichage de l'historique avec timeline

**Étapes:**
1. Ouvrez les détails d'un colis avec plusieurs changements de statut
2. Scrollez jusqu'à la section "Historique des Statuts"
3. Vérifiez la timeline verticale

**Résultat attendu:**
- ✅ Timeline verticale avec indicateurs colorés
- ✅ Chaque statut affiché avec sa couleur
- ✅ Date et heure de chaque changement
- ✅ Commentaires affichés s'ils existent
- ✅ Ordre chronologique (du plus ancien au plus récent)

---

### Test 11: Mise à Jour du Statut - Transitions Valides

**Objectif:** Vérifier la validation du workflow des statuts

**Étapes:**
1. Ouvrez les détails d'un colis avec statut "collecte"
2. Cliquez sur l'icône d'édition (✏️) dans l'AppBar
3. Vérifiez les statuts disponibles dans le dropdown

**Résultat attendu:**
- ✅ Dialogue "Modifier le Statut" s'ouvre
- ✅ Statut actuel affiché
- ✅ Seuls les statuts valides sont proposés:
  - Pour "collecte": enregistre, annule
  - Pour "enregistre": enTransit, annule
  - Pour "enTransit": arriveDestination, retour
  - Pour "arriveDestination": enCoursLivraison, retire, retour
  - Pour "enCoursLivraison": livre, echec, retour
  - Pour "echec": enCoursLivraison, retour
  - Pour "retour": enTransit
  - Pour "livre" ou "retire": aucun (statuts finaux)

---

### Test 12: Mise à Jour du Statut - Avec Commentaire

**Objectif:** Vérifier l'ajout de commentaire lors du changement de statut

**Étapes:**
1. Ouvrez le dialogue de modification de statut
2. Sélectionnez un nouveau statut
3. Tapez un commentaire (ex: "Colis vérifié et conforme")
4. Cliquez sur "Confirmer"
5. Attendez la confirmation
6. Vérifiez l'historique

**Résultat attendu:**
- ✅ Message de succès affiché
- ✅ Statut mis à jour dans le header
- ✅ Nouvel élément ajouté à l'historique
- ✅ Commentaire visible dans l'historique
- ✅ Date et heure actuelles enregistrées

---

### Test 13: Mise à Jour du Statut - Sans Commentaire

**Objectif:** Vérifier que le commentaire est optionnel

**Étapes:**
1. Ouvrez le dialogue de modification de statut
2. Sélectionnez un nouveau statut
3. Laissez le champ commentaire vide
4. Cliquez sur "Confirmer"

**Résultat attendu:**
- ✅ Mise à jour réussie
- ✅ Pas de commentaire dans l'historique
- ✅ Autres informations enregistrées correctement

---

### Test 14: Mise à Jour du Statut - Dates Automatiques

**Objectif:** Vérifier la mise à jour automatique des dates

**Étapes:**
1. Changez un colis de "collecte" à "enregistre"
2. Vérifiez la section "Dates Importantes"
3. Changez un colis vers "livre" ou "retire"
4. Vérifiez à nouveau les dates

**Résultat attendu:**
- ✅ Passage à "enregistre": dateEnregistrement ajoutée
- ✅ Passage à "livre" ou "retire": dateLivraison ajoutée
- ✅ Dates affichées au format "dd/MM/yyyy à HH:mm"

---

### Test 15: Couleurs des Statuts

**Objectif:** Vérifier la cohérence des couleurs

**Étapes:**
1. Parcourez la liste des colis
2. Ouvrez les détails de plusieurs colis
3. Vérifiez les couleurs dans l'historique

**Résultat attendu:**
- ✅ Collecté: Orange
- ✅ Enregistré: Vert
- ✅ En Transit: Bleu
- ✅ Arrivé à Destination: Violet
- ✅ En Cours de Livraison: Orange foncé
- ✅ Livré: Vert
- ✅ Retiré: Vert
- ✅ Échec: Rouge
- ✅ Retour: Orange rouge
- ✅ Annulé: Gris

---

### Test 16: Permissions - PDG

**Objectif:** Vérifier les permissions du PDG

**Étapes:**
1. Connectez-vous en tant que PDG
2. Ouvrez le module de suivi
3. Vérifiez les colis affichés
4. Modifiez un statut

**Résultat attendu:**
- ✅ Tous les colis de toutes les agences visibles
- ✅ Peut modifier les statuts
- ✅ Tous les filtres disponibles

---

### Test 17: Permissions - Admin/Gestionnaire

**Objectif:** Vérifier les permissions Admin/Gestionnaire

**Étapes:**
1. Connectez-vous en tant qu'Admin ou Gestionnaire
2. Ouvrez le module de suivi
3. Vérifiez les colis affichés

**Résultat attendu:**
- ✅ Seuls les colis de leur agence visibles
- ✅ Peut modifier les statuts
- ✅ Filtres par commercial et coursier disponibles

---

### Test 18: Permissions - Commercial

**Objectif:** Vérifier les permissions Commercial

**Étapes:**
1. Connectez-vous en tant que Commercial
2. Ouvrez le module de suivi
3. Vérifiez les colis affichés
4. Tentez de modifier un statut

**Résultat attendu:**
- ✅ Seuls ses propres colis collectés visibles
- ✅ Peut consulter les détails
- ✅ Peut voir l'historique
- ✅ Peut modifier les statuts (selon les règles métier)

---

### Test 19: Permissions - Coursier

**Objectif:** Vérifier les permissions Coursier

**Étapes:**
1. Connectez-vous en tant que Coursier
2. Ouvrez le module de suivi
3. Vérifiez les colis affichés

**Résultat attendu:**
- ✅ Seuls les colis qui lui sont assignés visibles
- ✅ Peut consulter les détails
- ✅ Peut modifier les statuts de livraison

---

### Test 20: Actualisation des Données

**Objectif:** Vérifier le rafraîchissement des données

**Étapes:**
1. Ouvrez le module de suivi
2. Cliquez sur l'icône d'actualisation (🔄)
3. Attendez le chargement

**Résultat attendu:**
- ✅ Indicateur de chargement affiché
- ✅ Données rechargées depuis Firebase
- ✅ Liste mise à jour
- ✅ Filtres réappliqués

---

### Test 21: Interface Mobile (Bonus)

**Objectif:** Vérifier l'interface mobile

**Étapes:**
1. Lancez l'application mobile (si disponible)
2. Accédez au module de suivi
3. Testez la recherche et les filtres
4. Ouvrez les détails d'un colis

**Résultat attendu:**
- ✅ Interface adaptée au mobile
- ✅ Chips horizontaux pour les statuts
- ✅ Cartes compactes pour les colis
- ✅ Détails optimisés pour petit écran
- ✅ Historique avec cartes colorées (pas de timeline)

---

### Test 22: Performance

**Objectif:** Vérifier les performances avec beaucoup de colis

**Étapes:**
1. Créez ou importez au moins 50 colis
2. Ouvrez le module de suivi
3. Testez la recherche et les filtres
4. Scrollez dans la liste

**Résultat attendu:**
- ✅ Chargement rapide (< 2 secondes)
- ✅ Recherche réactive (temps réel)
- ✅ Scroll fluide
- ✅ Pas de lag lors du filtrage

---

### Test 23: Mode Hors Ligne (Lecture)

**Objectif:** Vérifier la consultation en mode hors ligne

**Étapes:**
1. Ouvrez le module de suivi avec connexion
2. Consultez quelques colis
3. Désactivez la connexion Internet
4. Actualisez la page
5. Consultez les colis

**Résultat attendu:**
- ✅ Les colis en cache s'affichent
- ✅ Détails consultables
- ✅ Historique visible
- ✅ Indicateur de mode hors ligne affiché

---

### Test 24: Mode Hors Ligne (Modification)

**Objectif:** Vérifier la modification en mode hors ligne

**Étapes:**
1. Désactivez la connexion Internet
2. Tentez de modifier un statut
3. Réactivez la connexion

**Résultat attendu:**
- ✅ Modification enregistrée localement (si implémenté)
- ✅ OU message d'erreur explicite
- ✅ Synchronisation automatique au retour de connexion

---

## Bugs Connus et Limitations

### Limitations Actuelles

1. **Pagination:** Pas de pagination pour l'instant. Toutes les données sont chargées en une fois.
2. **Recherche serveur:** La recherche est effectuée côté client. Pour de très grandes quantités, envisager une recherche côté serveur.
3. **Notifications:** Pas de notifications push lors des changements de statut (Phase 13).

### Bugs à Surveiller

1. Vérifier que les transitions de statut invalides sont bien bloquées
2. Vérifier que l'historique est toujours dans le bon ordre
3. Vérifier que les dates sont correctement formatées selon le fuseau horaire

## Checklist de Validation

Avant de passer à la Phase 6, vérifiez que:

- [ ] Tous les tests fonctionnels passent
- [ ] Les permissions sont correctement appliquées
- [ ] L'interface desktop est fonctionnelle
- [ ] L'interface mobile est fonctionnelle (si applicable)
- [ ] Les couleurs des statuts sont cohérentes
- [ ] L'historique s'affiche correctement
- [ ] Les transitions de statut sont validées
- [ ] Les commentaires sont enregistrés
- [ ] Les dates sont mises à jour automatiquement
- [ ] La recherche fonctionne pour tous les critères
- [ ] Les filtres s'appliquent correctement
- [ ] Le mode hors ligne fonctionne (lecture)
- [ ] Les performances sont acceptables

## Prochaine Phase

Une fois tous les tests validés, vous pouvez passer à:

**Phase 6 - Module Livraison à Domicile (Gestionnaire)**

Cette phase implémentera:
- Attribution des livraisons aux coursiers
- Création de fiches de livraison
- Suivi des livraisons par le gestionnaire

---

**Bonne chance pour les tests ! 🚀**
