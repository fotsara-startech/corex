# Guide de Test - Phase 9: Module Rapports et Tableaux de Bord

## Prérequis

Avant de commencer les tests, assurez-vous que:
- ✅ Les phases 0 à 8 sont complétées et fonctionnelles
- ✅ Firebase est configuré avec des données de test
- ✅ Au moins 2 agences sont créées
- ✅ Des utilisateurs de différents rôles existent (PDG, commercial, coursier)
- ✅ Des colis, livraisons et transactions existent dans la base de données
- ✅ L'application mobile est compilée et déployée

## Données de Test Recommandées

### Agences
- Agence Douala (avec 2 commerciaux, 2 coursiers)
- Agence Yaoundé (avec 1 commercial, 1 coursier)

### Colis
- Au moins 10 colis par agence
- Différents statuts (collecte, enregistre, enTransit, livre)
- Répartis sur plusieurs jours/semaines

### Transactions
- Recettes: paiements de colis, livraisons
- Dépenses: salaires, loyer, carburant
- Réparties sur plusieurs jours/semaines

### Livraisons
- Au moins 5 livraisons par coursier
- Statuts variés (enAttente, enCours, livree, echec)

## Tests du Dashboard Global (Tâche 9.1)

### Test 1: Accès au Dashboard (PDG)

**Objectif:** Vérifier que le PDG peut accéder au dashboard

**Étapes:**
1. Se connecter avec un compte PDG
2. Sur l'écran d'accueil, cliquer sur "Tableau de Bord"
3. Vérifier que l'écran du dashboard s'affiche

**Résultat attendu:**
- ✅ Le dashboard s'affiche avec les cartes de statistiques
- ✅ Les graphiques sont visibles
- ✅ Le sélecteur de période est présent

### Test 2: Statistiques Globales

**Objectif:** Vérifier l'affichage des KPI globaux

**Étapes:**
1. Sur le dashboard, observer les cartes de statistiques
2. Vérifier les valeurs affichées:
   - CA Global
   - Nombre de Colis
   - Nombre de Livraisons

**Résultat attendu:**
- ✅ Les valeurs correspondent aux données dans Firebase
- ✅ Le CA est calculé correctement (somme des recettes)
- ✅ Les nombres de colis et livraisons sont corrects

### Test 3: Changement de Période

**Objectif:** Vérifier le fonctionnement du sélecteur de période

**Étapes:**
1. Cliquer sur "Aujourd'hui"
2. Observer les statistiques
3. Cliquer sur "Semaine"
4. Observer les changements
5. Tester "Mois" et "Année"

**Résultat attendu:**
- ✅ Les statistiques se mettent à jour selon la période
- ✅ Les graphiques changent (nombre de points, labels)
- ✅ Le bouton sélectionné est mis en surbrillance (vert)
- ✅ Un indicateur de chargement s'affiche pendant le calcul

### Test 4: Graphique Évolution du CA

**Objectif:** Vérifier le graphique d'évolution du CA

**Étapes:**
1. Observer le graphique "Évolution du CA"
2. Vérifier les axes (X: périodes, Y: montants)
3. Changer de période et observer les changements

**Résultat attendu:**
- ✅ Le graphique affiche une courbe verte
- ✅ Les labels des axes sont corrects
- ✅ Les valeurs correspondent aux transactions
- ✅ La courbe est lissée (isCurved: true)

### Test 5: Graphiques Colis et Livraisons

**Objectif:** Vérifier les graphiques en barres

**Étapes:**
1. Observer le graphique "Évolution des Colis"
2. Observer le graphique "Évolution des Livraisons"
3. Vérifier les couleurs (bleu pour colis, orange pour livraisons)

**Résultat attendu:**
- ✅ Les barres sont affichées correctement
- ✅ Les hauteurs correspondent aux nombres
- ✅ Les couleurs sont correctes

### Test 6: Répartition par Statut

**Objectif:** Vérifier la répartition des colis par statut

**Étapes:**
1. Observer la section "Répartition par Statut"
2. Vérifier les barres de progression
3. Vérifier les pourcentages

**Résultat attendu:**
- ✅ Tous les statuts sont affichés
- ✅ Les barres de progression sont proportionnelles
- ✅ Les pourcentages totalisent 100%
- ✅ Les couleurs correspondent aux statuts

### Test 7: Rafraîchissement

**Objectif:** Vérifier le rafraîchissement des données

**Étapes:**
1. Cliquer sur l'icône de rafraîchissement dans l'AppBar
2. Observer le chargement
3. Tirer vers le bas pour rafraîchir (pull-to-refresh)

**Résultat attendu:**
- ✅ Un indicateur de chargement s'affiche
- ✅ Les données sont rechargées
- ✅ Le pull-to-refresh fonctionne

### Test 8: Accès Restreint (Non-PDG)

**Objectif:** Vérifier que les autres rôles voient leurs données d'agence

**Étapes:**
1. Se déconnecter
2. Se connecter avec un compte commercial ou gestionnaire
3. Vérifier si le bouton "Tableau de Bord" est visible
4. Si visible, vérifier que seules les données de l'agence sont affichées

**Résultat attendu:**
- ✅ Le bouton peut être masqué pour les non-PDG (selon implémentation)
- ✅ Si accessible, seules les données de l'agence sont affichées

## Tests des Rapports Financiers (Tâche 9.2)

### Test 9: Accès aux Rapports Financiers

**Objectif:** Vérifier l'accès à l'écran de rapports financiers

**Étapes:**
1. Sur le dashboard, cliquer sur l'icône "assessment" dans l'AppBar
2. Vérifier que l'écran "Rapports Financiers" s'affiche

**Résultat attendu:**
- ✅ L'écran s'affiche correctement
- ✅ Le sélecteur de période est présent
- ✅ Le bilan consolidé est affiché

### Test 10: Bilan Consolidé

**Objectif:** Vérifier le calcul du bilan consolidé

**Étapes:**
1. Observer la carte "Bilan Consolidé"
2. Vérifier les valeurs:
   - Recettes (vert)
   - Dépenses (rouge)
   - Solde (vert si positif, rouge si négatif)

**Résultat attendu:**
- ✅ Les valeurs correspondent à la somme de toutes les agences
- ✅ Le solde = recettes - dépenses
- ✅ Les couleurs sont correctes

### Test 11: Top 5 Agences

**Objectif:** Vérifier l'affichage du top 5 des agences

**Étapes:**
1. Observer la carte "Top 5 Agences par CA"
2. Vérifier l'ordre (décroissant par CA)
3. Vérifier les médailles (or, argent, bronze)

**Résultat attendu:**
- ✅ Les agences sont triées par CA décroissant
- ✅ Les médailles sont affichées (1: or, 2: argent, 3: bronze)
- ✅ Les montants sont corrects

### Test 12: Détail par Agence

**Objectif:** Vérifier l'expansion des détails par agence

**Étapes:**
1. Observer la carte "Bilan par Agence"
2. Cliquer sur une agence pour l'étendre
3. Vérifier les détails (recettes, dépenses, solde)

**Résultat attendu:**
- ✅ L'agence s'étend pour afficher les détails
- ✅ Les valeurs sont correctes
- ✅ Le solde est coloré (vert/rouge)

### Test 13: Sélection de Période Personnalisée

**Objectif:** Vérifier la sélection de dates personnalisées

**Étapes:**
1. Cliquer sur "Date début"
2. Sélectionner une date (ex: il y a 30 jours)
3. Cliquer sur "Date fin"
4. Sélectionner une date (ex: aujourd'hui)
5. Observer les changements

**Résultat attendu:**
- ✅ Le date picker s'affiche
- ✅ Les dates sont mises à jour
- ✅ Les statistiques sont recalculées
- ✅ Un indicateur de chargement s'affiche

### Test 14: Export PDF Rapport Financier

**Objectif:** Vérifier la génération du PDF

**Étapes:**
1. Cliquer sur l'icône PDF dans l'AppBar
2. Attendre la génération
3. Vérifier le PDF généré

**Résultat attendu:**
- ✅ Le PDF est généré sans erreur
- ✅ Le PDF contient:
   - En-tête COREX avec période
   - Bilan consolidé
   - Tableau par agence
   - Pied de page avec date
- ✅ Le design est professionnel
- ✅ Les couleurs COREX sont présentes

## Tests des Rapports par Agence (Tâche 9.3)

### Test 15: Accès au Rapport par Agence

**Objectif:** Vérifier l'accès à l'écran de rapport par agence

**Étapes:**
1. Sur le dashboard, cliquer sur "Rapport par Agence"
2. Vérifier que l'écran s'affiche

**Résultat attendu:**
- ✅ L'écran s'affiche correctement
- ✅ Le sélecteur d'agence est présent
- ✅ Une agence est sélectionnée par défaut

### Test 16: Sélection d'Agence

**Objectif:** Vérifier le changement d'agence

**Étapes:**
1. Cliquer sur le dropdown d'agence
2. Sélectionner une autre agence
3. Observer les changements

**Résultat attendu:**
- ✅ La liste des agences s'affiche
- ✅ L'agence sélectionnée change
- ✅ Les statistiques sont recalculées
- ✅ Un indicateur de chargement s'affiche

### Test 17: Statistiques de l'Agence

**Objectif:** Vérifier les statistiques globales de l'agence

**Étapes:**
1. Observer les cartes de statistiques:
   - CA
   - Colis
   - Livraisons

**Résultat attendu:**
- ✅ Les valeurs correspondent à l'agence sélectionnée
- ✅ Les couleurs sont correctes (vert, bleu, orange)

### Test 18: Graphique Évolution CA Agence

**Objectif:** Vérifier le graphique d'évolution du CA

**Étapes:**
1. Observer le graphique "Évolution du CA"
2. Changer de période
3. Changer d'agence

**Résultat attendu:**
- ✅ Le graphique affiche les données de l'agence
- ✅ La courbe change selon la période
- ✅ La courbe change selon l'agence

### Test 19: Performance des Commerciaux

**Objectif:** Vérifier les statistiques des commerciaux

**Étapes:**
1. Observer la carte "Performance des Commerciaux"
2. Vérifier les données:
   - Nom du commercial
   - Nombre de colis
   - CA généré

**Résultat attendu:**
- ✅ Tous les commerciaux de l'agence sont listés
- ✅ Les données sont correctes
- ✅ Le tri est par CA décroissant
- ✅ Si aucun commercial, afficher "Aucun commercial"

### Test 20: Performance des Coursiers

**Objectif:** Vérifier les statistiques des coursiers

**Étapes:**
1. Observer la carte "Performance des Coursiers"
2. Vérifier les données:
   - Nom du coursier
   - Nombre de livraisons
   - Nombre de livraisons réussies
   - Taux de réussite

**Résultat attendu:**
- ✅ Tous les coursiers de l'agence sont listés
- ✅ Les données sont correctes
- ✅ Le taux de réussite est calculé correctement
- ✅ Le tri est par nombre de livraisons décroissant
- ✅ La couleur du taux change (vert si ≥80%, orange sinon)
- ✅ Si aucun coursier, afficher "Aucun coursier"

### Test 21: Export PDF Rapport Agence

**Objectif:** Vérifier la génération du PDF

**Étapes:**
1. Cliquer sur l'icône PDF dans l'AppBar
2. Attendre la génération
3. Vérifier le PDF généré

**Résultat attendu:**
- ✅ Le PDF est généré sans erreur
- ✅ Le PDF contient:
   - En-tête COREX avec nom d'agence et période
   - Statistiques globales
   - Tableau des commerciaux
   - Tableau des coursiers
   - Pied de page avec date
- ✅ Le design est professionnel
- ✅ Les couleurs COREX sont présentes

## Tests d'Export (Tâche 9.4)

### Test 22: Format PDF - Mise en Page

**Objectif:** Vérifier la qualité du PDF généré

**Étapes:**
1. Générer un PDF (rapport financier ou agence)
2. Ouvrir le PDF
3. Vérifier:
   - Marges
   - Alignement
   - Polices
   - Couleurs
   - Tableaux

**Résultat attendu:**
- ✅ Les marges sont correctes (32 points)
- ✅ Le texte est aligné correctement
- ✅ Les polices sont lisibles
- ✅ Les couleurs COREX sont présentes (vert #2E7D32)
- ✅ Les tableaux sont bien formatés

### Test 23: Nom du Fichier PDF

**Objectif:** Vérifier le nom du fichier généré

**Étapes:**
1. Générer un PDF
2. Vérifier le nom du fichier proposé

**Résultat attendu:**
- ✅ Rapport financier: `rapport_financier_DD_MM_YYYY.pdf`
- ✅ Rapport agence: `rapport_agence_[NomAgence]_DD_MM_YYYY.pdf`

### Test 24: Partage du PDF

**Objectif:** Vérifier le partage du fichier

**Étapes:**
1. Générer un PDF
2. Utiliser la fonction de partage du système
3. Partager via email, WhatsApp, etc.

**Résultat attendu:**
- ✅ Le dialogue de partage s'affiche
- ✅ Le fichier peut être partagé
- ✅ Le fichier est reçu correctement

## Tests de Performance

### Test 25: Temps de Chargement

**Objectif:** Vérifier les performances de chargement

**Étapes:**
1. Mesurer le temps de chargement du dashboard
2. Mesurer le temps de changement de période
3. Mesurer le temps de génération de PDF

**Résultat attendu:**
- ✅ Dashboard: < 3 secondes
- ✅ Changement de période: < 2 secondes
- ✅ Génération PDF: < 5 secondes

### Test 26: Grandes Quantités de Données

**Objectif:** Vérifier le comportement avec beaucoup de données

**Étapes:**
1. Créer 100+ colis
2. Créer 50+ transactions
3. Charger le dashboard
4. Générer un PDF

**Résultat attendu:**
- ✅ Le dashboard se charge sans erreur
- ✅ Les graphiques s'affichent correctement
- ✅ Le PDF est généré sans erreur
- ✅ Pas de ralentissement majeur

## Tests d'Erreurs

### Test 27: Aucune Donnée

**Objectif:** Vérifier le comportement sans données

**Étapes:**
1. Créer une nouvelle agence sans données
2. Sélectionner cette agence dans le rapport
3. Observer l'affichage

**Résultat attendu:**
- ✅ Message "Aucune donnée" affiché
- ✅ Pas d'erreur
- ✅ Les graphiques affichent un message approprié

### Test 28: Erreur de Connexion

**Objectif:** Vérifier le comportement hors ligne

**Étapes:**
1. Désactiver la connexion internet
2. Essayer de charger le dashboard
3. Observer le comportement

**Résultat attendu:**
- ✅ Message d'erreur approprié
- ✅ Possibilité de réessayer
- ✅ Pas de crash de l'application

### Test 29: Période Invalide

**Objectif:** Vérifier la validation des dates

**Étapes:**
1. Essayer de sélectionner une date de fin avant la date de début
2. Observer le comportement

**Résultat attendu:**
- ✅ La sélection est empêchée ou corrigée
- ✅ Message d'erreur si nécessaire

## Checklist Finale

### Fonctionnalités
- [ ] Dashboard global accessible (PDG)
- [ ] Statistiques globales correctes
- [ ] Sélecteur de période fonctionnel
- [ ] Graphiques d'évolution affichés
- [ ] Répartition par statut correcte
- [ ] Rapports financiers consolidés
- [ ] Top 5 agences affiché
- [ ] Détail par agence fonctionnel
- [ ] Rapport par agence accessible
- [ ] Sélection d'agence fonctionnelle
- [ ] Performance commerciaux affichée
- [ ] Performance coursiers affichée
- [ ] Export PDF rapport financier
- [ ] Export PDF rapport agence
- [ ] Design professionnel des PDF

### Performance
- [ ] Chargement rapide (< 3s)
- [ ] Pas de ralentissement
- [ ] Gestion des grandes quantités de données

### Erreurs
- [ ] Gestion des données vides
- [ ] Gestion des erreurs de connexion
- [ ] Validation des dates

### UX
- [ ] Navigation intuitive
- [ ] Indicateurs de chargement
- [ ] Messages d'erreur clairs
- [ ] Pull-to-refresh fonctionnel
- [ ] Boutons bien placés

## Problèmes Connus et Solutions

### Problème 1: Graphiques ne s'affichent pas
**Solution:** Vérifier que `fl_chart` est bien installé et que les données ne sont pas vides

### Problème 2: PDF ne se génère pas
**Solution:** Vérifier que `pdf` et `printing` sont bien installés dans `corex_shared`

### Problème 3: Statistiques incorrectes
**Solution:** Vérifier les filtres de période et les calculs dans les controllers

### Problème 4: Lenteur de chargement
**Solution:** Optimiser les requêtes Firebase, utiliser des index composites

## Conclusion

Une fois tous les tests passés avec succès, la Phase 9 est complète et prête pour la production. Le PDG dispose maintenant d'outils puissants pour suivre les performances de l'entreprise et prendre des décisions éclairées.
