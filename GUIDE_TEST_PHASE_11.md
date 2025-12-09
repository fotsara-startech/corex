# Guide de Test - Phase 11: Module Service de Courses

## Prérequis
- Application COREX Desktop lancée
- Connexion Firebase active
- Au moins un utilisateur de chaque rôle créé:
  - Admin ou Gestionnaire
  - Commercial
  - Coursier
- Au moins un client créé dans le système

## Test 1: Création de Course (Commercial/Gestionnaire)

### Étapes
1. Se connecter en tant que Commercial ou Gestionnaire
2. Ouvrir le menu latéral
3. Cliquer sur "Service de Courses"
4. Cliquer sur le bouton FAB "Nouvelle Course"

### Vérifications
- ✅ Le formulaire de création s'affiche
- ✅ La liste des clients est chargée dans le dropdown
- ✅ Tous les champs sont présents:
  - Client (dropdown)
  - Lieu
  - Tâche
  - Instructions détaillées
  - Montant estimé
  - Commission (%)

### Actions
1. Sélectionner un client
2. Remplir le lieu: "Marché central"
3. Remplir la tâche: "Acheter des fournitures de bureau"
4. Remplir les instructions: "Acheter 10 ramettes de papier A4, 5 stylos bleus, 3 agrafeuses"
5. Saisir le montant estimé: 15000
6. Vérifier que la commission s'affiche: 1500 FCFA (10%)
7. Modifier la commission à 15%
8. Vérifier que la commission s'affiche: 2250 FCFA
9. Cliquer sur "Créer la Course"

### Résultats Attendus
- ✅ Message de succès affiché
- ✅ Commission affichée dans le message
- ✅ Retour à l'écran de liste
- ✅ La nouvelle course apparaît dans la liste avec statut "En Attente"

## Test 2: Attribution de Course (Gestionnaire)

### Étapes
1. Se connecter en tant que Gestionnaire
2. Aller dans "Service de Courses" → "Suivi des courses"
3. Identifier une course avec statut "En Attente"
4. Cliquer sur la carte de la course
5. Cliquer sur "Attribuer"

### Vérifications
- ✅ L'écran d'attribution s'affiche
- ✅ Les détails de la course sont affichés
- ✅ La liste des coursiers actifs est chargée
- ✅ Seuls les coursiers actifs sont dans la liste

### Actions
1. Sélectionner un coursier dans la liste
2. Cliquer sur "Attribuer"

### Résultats Attendus
- ✅ Message de succès affiché avec le nom du coursier
- ✅ Retour à l'écran de suivi
- ✅ Le statut de la course passe à "En Cours"
- ✅ Le nom du coursier est affiché sur la carte

## Test 3: Suivi des Courses (Gestionnaire)

### Étapes
1. Se connecter en tant que Gestionnaire
2. Aller dans "Service de Courses" → "Suivi des courses"

### Vérifications Statistiques
- ✅ Carte "Total" affiche le nombre total de courses
- ✅ Carte "En Attente" affiche le nombre de courses en attente
- ✅ Carte "En Cours" affiche le nombre de courses en cours
- ✅ Carte "Terminées" affiche le nombre de courses terminées

### Test des Filtres
1. **Filtre par statut:**
   - Sélectionner "En Attente" → Seules les courses en attente s'affichent
   - Sélectionner "En Cours" → Seules les courses en cours s'affichent
   - Sélectionner "Terminées" → Seules les courses terminées s'affichent
   - Sélectionner "Tous" → Toutes les courses s'affichent

2. **Filtre par coursier:**
   - Sélectionner un coursier → Seules ses courses s'affichent
   - Sélectionner "Tous" → Toutes les courses s'affichent

3. **Combinaison de filtres:**
   - Sélectionner "En Cours" + un coursier spécifique
   - ✅ Seules les courses en cours de ce coursier s'affichent

### Résultats Attendus
- ✅ Les filtres fonctionnent correctement
- ✅ Les statistiques sont mises à jour en temps réel
- ✅ Les cartes affichent toutes les informations nécessaires

## Test 4: Interface Coursier - Démarrage

### Étapes
1. Se connecter en tant que Coursier
2. Ouvrir le menu latéral
3. Cliquer sur "Mes Courses"

### Vérifications
- ✅ L'écran "Mes Courses" s'affiche
- ✅ Seules les courses assignées au coursier connecté sont affichées
- ✅ Les statistiques personnalisées s'affichent:
  - Total
  - En Cours
  - Terminées

### Actions - Démarrer une Course
1. Identifier une course avec statut "En Cours" (pas encore démarrée)
2. Vérifier que le bouton "Démarrer la course" est affiché
3. Cliquer sur "Démarrer la course"
4. Confirmer dans la boîte de dialogue

### Résultats Attendus
- ✅ Message de succès affiché
- ✅ Le bouton "Démarrer" disparaît
- ✅ Le bouton "Terminer la course" apparaît
- ✅ La date de début est affichée sur la carte

## Test 5: Interface Coursier - Terminer

### Étapes
1. Toujours connecté en tant que Coursier
2. Dans "Mes Courses", identifier une course démarrée
3. Cliquer sur "Terminer la course"

### Vérifications
- ✅ Une boîte de dialogue s'affiche
- ✅ Le nom de la course est affiché
- ✅ Un champ "Montant réel" est présent
- ✅ Le montant estimé est pré-rempli
- ✅ Une note indique que l'upload des justificatifs sera disponible prochainement

### Actions
1. Modifier le montant réel: 18000 (au lieu de 15000)
2. Cliquer sur "Terminer"

### Résultats Attendus
- ✅ Message de succès affiché avec le montant
- ✅ Le statut de la course passe à "Terminée"
- ✅ Le montant réel est affiché sur la carte
- ✅ La date de fin est affichée
- ✅ Les boutons d'action disparaissent

## Test 6: Détails de Course

### Étapes
1. Se connecter en tant que Gestionnaire
2. Aller dans "Service de Courses" → "Suivi des courses"
3. Cliquer sur une course terminée

### Vérifications
- ✅ L'écran de détails s'affiche
- ✅ Le statut est affiché en haut (badge coloré)
- ✅ Toutes les sections sont présentes:
  - Client (nom, téléphone)
  - Détails de la Course (lieu, tâche, instructions)
  - Tarification (montant estimé, commission, montant réel)
  - Coursier (nom, dates)
  - Dates (création)

### Vérifications Spécifiques
- ✅ Le montant estimé est affiché: 15000 FCFA
- ✅ La commission est affichée: 2250 FCFA (15%)
- ✅ Le montant réel est affiché: 18000 FCFA
- ✅ Toutes les dates sont au bon format: dd/MM/yyyy HH:mm

### Actions
1. Vérifier que le bouton "Enregistrer le Paiement" est affiché
2. Cliquer sur le bouton

## Test 7: Enregistrement du Paiement

### Vérifications Écran de Paiement
- ✅ L'écran de paiement s'affiche
- ✅ Les détails de la course sont affichés
- ✅ Les détails financiers sont affichés:
  - Montant estimé: 15000 FCFA (en gris)
  - Montant réel: 18000 FCFA (en bleu)
  - Commission COREX (15%): 2700 FCFA (en vert)
  - MONTANT TOTAL: 18000 FCFA (en gras)

### Vérifications Validation
- ✅ Une section "Validation du Paiement" est affichée
- ✅ Une checklist est présente:
  - ✅ Le montant a été vérifié
  - ✅ Les justificatifs ont été validés
  - ✅ Une transaction financière sera créée automatiquement
  - ✅ La course sera marquée comme payée

### Actions
1. Vérifier tous les montants
2. Cliquer sur "Enregistrer le Paiement"
3. Confirmer dans la boîte de dialogue

### Résultats Attendus
- ✅ Message de succès affiché avec le montant
- ✅ Retour à l'écran de détails
- ✅ Le bouton "Enregistrer le Paiement" disparaît (ou est désactivé)

## Test 8: Vérification de la Transaction

### Étapes
1. Toujours connecté en tant que Gestionnaire
2. Aller dans "Caisse"
3. Aller dans "Historique des transactions"

### Vérifications
- ✅ Une nouvelle transaction est présente
- ✅ Type: Recette
- ✅ Catégorie: Courses
- ✅ Montant: 18000 FCFA
- ✅ Description: "Paiement course - Acheter des fournitures de bureau"
- ✅ Référence: "COURSE-{id}"
- ✅ Date: Date du jour

### Vérifications Solde
- ✅ Le solde de la caisse a augmenté de 18000 FCFA
- ✅ Les statistiques "Recettes du jour" incluent ce montant

## Test 9: Statistiques Globales

### Étapes
1. Créer plusieurs courses avec différents statuts
2. Aller dans "Service de Courses" → "Suivi des courses"

### Vérifications
- ✅ Total des courses = nombre total créé
- ✅ En Attente = nombre de courses non attribuées
- ✅ En Cours = nombre de courses attribuées mais non terminées
- ✅ Terminées = nombre de courses terminées

### Test Commission Totale
1. Noter les montants réels de toutes les courses terminées
2. Calculer manuellement: Σ(montantReel × commissionPourcentage / 100)
3. Comparer avec la carte "Commission"
- ✅ Le montant affiché correspond au calcul manuel

## Test 10: Permissions par Rôle

### Test Commercial
1. Se connecter en tant que Commercial
2. Vérifier les accès:
   - ✅ Peut créer des courses
   - ✅ Peut voir les courses de son agence
   - ✅ Peut voir les détails
   - ❌ Ne peut PAS attribuer de courses
   - ❌ Ne peut PAS enregistrer de paiements

### Test Coursier
1. Se connecter en tant que Coursier
2. Vérifier les accès:
   - ✅ Voit uniquement "Mes Courses" dans le menu
   - ✅ Voit uniquement ses courses assignées
   - ✅ Peut démarrer ses courses
   - ✅ Peut terminer ses courses
   - ❌ Ne voit PAS les courses des autres coursiers
   - ❌ Ne peut PAS créer de courses
   - ❌ Ne peut PAS enregistrer de paiements

### Test Gestionnaire
1. Se connecter en tant que Gestionnaire
2. Vérifier les accès:
   - ✅ Peut créer des courses
   - ✅ Peut attribuer des courses
   - ✅ Peut suivre toutes les courses de l'agence
   - ✅ Peut enregistrer des paiements
   - ✅ Voit toutes les statistiques

### Test Admin
1. Se connecter en tant qu'Admin
2. Vérifier les accès:
   - ✅ Toutes les permissions du Gestionnaire
   - ✅ Peut voir les courses de toutes les agences

## Test 11: Mode Hors Ligne (Optionnel)

### Étapes
1. Se connecter en tant que Coursier
2. Aller dans "Mes Courses"
3. Désactiver la connexion Internet
4. Essayer de démarrer une course

### Résultats Attendus
- ✅ L'indicateur de connexion passe au rouge
- ✅ Les données en cache sont affichées
- ⚠️ Les modifications seront synchronisées au retour de connexion

## Test 12: Validation des Formulaires

### Test Création de Course
1. Essayer de créer une course sans sélectionner de client
   - ✅ Message d'erreur: "Veuillez sélectionner un client"

2. Essayer de créer une course sans lieu
   - ✅ Message d'erreur: "Veuillez saisir le lieu"

3. Essayer de créer une course sans tâche
   - ✅ Message d'erreur: "Veuillez saisir la tâche"

4. Essayer de créer une course sans instructions
   - ✅ Message d'erreur: "Veuillez saisir les instructions"

5. Essayer de créer une course sans montant
   - ✅ Message d'erreur: "Veuillez saisir le montant"

6. Essayer de créer une course avec un montant invalide (texte)
   - ✅ Message d'erreur: "Montant invalide"

7. Essayer de créer une course avec une commission > 100%
   - ✅ Message d'erreur: "Commission invalide (0-100)"

### Test Terminer Course
1. Essayer de terminer une course sans montant
   - ✅ Message d'erreur: "Montant invalide"

2. Essayer de terminer une course avec un montant négatif
   - ✅ Message d'erreur: "Montant invalide"

## Checklist Finale

### Fonctionnalités
- ✅ Création de course avec calcul automatique de commission
- ✅ Attribution de course à un coursier
- ✅ Suivi des courses avec filtres multiples
- ✅ Interface coursier pour démarrer/terminer
- ✅ Enregistrement du paiement avec transaction automatique
- ✅ Statistiques en temps réel
- ✅ Permissions par rôle respectées

### Interface Utilisateur
- ✅ Tous les écrans s'affichent correctement
- ✅ Les formulaires sont intuitifs
- ✅ Les messages de feedback sont clairs
- ✅ Les couleurs et icônes sont cohérentes
- ✅ La navigation est fluide

### Données
- ✅ Les courses sont enregistrées dans Firestore
- ✅ Les transactions sont créées automatiquement
- ✅ Les statuts sont mis à jour correctement
- ✅ Les dates sont enregistrées correctement
- ✅ Les montants sont calculés correctement

### Performance
- ✅ Les listes se chargent rapidement
- ✅ Les filtres réagissent instantanément
- ✅ Pas de lag lors de la navigation
- ✅ Les statistiques se mettent à jour en temps réel

## Bugs Connus / Limitations

### ⏸️ Upload des Justificatifs
- **Statut:** En stand-by
- **Impact:** Les coursiers ne peuvent pas uploader de photos de reçus
- **Workaround:** Saisir le montant réel manuellement
- **Prévu:** Prochaine mise à jour

### ⏸️ Notifications
- **Statut:** À implémenter (Phase 13)
- **Impact:** Pas de notification au coursier lors de l'attribution
- **Workaround:** Le coursier doit vérifier "Mes Courses" régulièrement
- **Prévu:** Phase 13 - Notifications et Emails

## Conclusion

Si tous les tests passent avec succès, la Phase 11 - Module Service de Courses est validée et prête pour la production.

**Prochaines étapes:**
- Implémenter l'upload des justificatifs
- Ajouter les notifications (Phase 13)
- Passer à la Phase 12 - Module Retour de Colis
