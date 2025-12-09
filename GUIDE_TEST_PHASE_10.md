# Guide de Test - Phase 10 : Module Stockage de Marchandises

## Prérequis

- Application COREX Desktop lancée
- Compte utilisateur avec rôle **Gestionnaire** ou **Admin**
- Firebase configuré et accessible

## Scénario de Test Complet

### 1. Création d'un Client Stockeur

**Objectif:** Créer un nouveau client qui utilisera le service de stockage

**Étapes:**
1. Se connecter avec un compte Gestionnaire ou Admin
2. Ouvrir le menu latéral (drawer)
3. Cliquer sur "Stockage" → "Clients stockeurs"
4. Cliquer sur le bouton "+" en haut à droite
5. Remplir le formulaire:
   - Téléphone: `+237 690 123 456`
   - Cliquer sur l'icône de recherche (devrait ne rien trouver)
   - Nom: `Entreprise ABC`
   - Adresse: `123 Rue du Commerce`
   - Ville: `Douala`
   - Quartier: `Akwa`
6. Cliquer sur "Enregistrer"

**Résultat attendu:**
- ✅ Message de succès "Client stockeur enregistré"
- ✅ Retour à la liste des clients
- ✅ Le nouveau client apparaît dans la liste

### 2. Enregistrement d'un Dépôt

**Objectif:** Enregistrer un dépôt de marchandises pour le client

**Étapes:**
1. Dans la liste des clients stockeurs, cliquer sur "Entreprise ABC"
2. Cliquer sur le bouton "+" (Nouveau dépôt)
3. Remplir le formulaire:
   - Emplacement: `Zone A, Étagère 3`
   - Type de tarif: `Tarif global`
   - Tarif mensuel: `50000` FCFA
4. Ajouter des produits:
   - Cliquer sur "+" dans la section Produits
   - Produit 1:
     - Nom: `Cartons de vêtements`
     - Description: `Vêtements d'hiver`
     - Quantité: `50`
     - Unité: `Cartons`
   - Cliquer sur "Ajouter"
   - Ajouter un deuxième produit:
     - Nom: `Sacs de riz`
     - Description: `Riz importé`
     - Quantité: `100`
     - Unité: `Sacs`
   - Cliquer sur "Ajouter"
5. Notes: `Premier dépôt du client`
6. Cliquer sur "Enregistrer"

**Résultat attendu:**
- ✅ Message "Dépôt enregistré avec succès"
- ✅ Retour à l'écran du client
- ✅ Le dépôt apparaît dans l'onglet "Dépôts"
- ✅ Statut "Actif" affiché
- ✅ Un mouvement de type "Dépôt" apparaît dans l'onglet "Mouvements"

### 3. Consultation de l'Inventaire

**Objectif:** Vérifier les détails du dépôt et l'inventaire

**Étapes:**
1. Dans l'onglet "Dépôts", cliquer sur le dépôt créé
2. Vérifier les informations affichées:
   - Date de dépôt
   - Emplacement
   - Tarif mensuel
   - Liste des produits avec quantités

**Résultat attendu:**
- ✅ Toutes les informations sont correctement affichées
- ✅ Les 2 produits sont listés avec leurs quantités
- ✅ L'historique montre le mouvement de dépôt initial

### 4. Retrait Partiel de Produits

**Objectif:** Effectuer un retrait partiel de marchandises

**Étapes:**
1. Dans l'écran de détails du dépôt, cliquer sur l'icône "-" (Retrait)
2. Saisir les quantités à retirer:
   - Cartons de vêtements: `10`
   - Sacs de riz: `20`
3. Notes: `Retrait pour livraison client`
4. Cliquer sur "Enregistrer"

**Résultat attendu:**
- ✅ Message "Retrait enregistré avec succès"
- ✅ Les quantités sont mises à jour:
  - Cartons de vêtements: 40 (50 - 10)
  - Sacs de riz: 80 (100 - 20)
- ✅ Un nouveau mouvement de type "Retrait" apparaît dans l'historique
- ✅ Le dépôt reste "Actif" (quantités > 0)

### 5. Génération d'une Facture Mensuelle

**Objectif:** Créer une facture pour le stockage du mois

**Étapes:**
1. Retourner au menu principal
2. Cliquer sur "Stockage" → "Factures de stockage"
3. Cliquer sur le bouton "+" (Générer une facture)
4. Remplir le formulaire:
   - Client: Sélectionner `Entreprise ABC`
   - Période début: Premier jour du mois en cours
   - Période fin: Dernier jour du mois en cours
   - Cocher le dépôt créé
5. Notes: `Facture mensuelle - Mois de [mois actuel]`
6. Vérifier que le montant total affiché est `50000 FCFA`
7. Cliquer sur "Générer"

**Résultat attendu:**
- ✅ Message "Facture générée: FACT-YYYY-MM-XXXXXX"
- ✅ Retour à la liste des factures
- ✅ La nouvelle facture apparaît avec statut "Impayée"
- ✅ Le numéro de facture suit le format FACT-YYYY-MM-XXXXXX

### 6. Consultation de la Facture

**Objectif:** Vérifier les détails de la facture générée

**Étapes:**
1. Dans la liste des factures, cliquer sur la facture créée pour l'étendre
2. Vérifier les informations:
   - Numéro de facture
   - Date d'émission
   - Période de facturation
   - Montant total
   - Statut

**Résultat attendu:**
- ✅ Toutes les informations sont correctes
- ✅ Le bouton "Marquer payée" est visible
- ✅ Le bouton "PDF" est visible (fonctionnalité à implémenter)

### 7. Paiement de la Facture

**Objectif:** Marquer la facture comme payée

**Étapes:**
1. Cliquer sur "Marquer payée"
2. Dans la boîte de dialogue:
   - Vérifier le numéro de facture et le montant
   - Laisser "Créer une transaction financière" coché
3. Cliquer sur "Confirmer"

**Résultat attendu:**
- ✅ Message "Facture marquée comme payée"
- ✅ Le statut de la facture passe à "Payée"
- ✅ La date de paiement est enregistrée
- ✅ Le chip affiche "Payée" en vert
- ✅ Le bouton "Marquer payée" disparaît

### 8. Vérification dans l'Onglet Factures du Client

**Objectif:** Vérifier que la facture apparaît dans l'historique du client

**Étapes:**
1. Retourner à "Clients stockeurs"
2. Cliquer sur "Entreprise ABC"
3. Aller dans l'onglet "Factures"

**Résultat attendu:**
- ✅ La facture créée apparaît dans la liste
- ✅ Le statut "Payée" est affiché
- ✅ Toutes les informations sont correctes

### 9. Test de Retrait Total

**Objectif:** Vider complètement un dépôt

**Étapes:**
1. Retourner dans l'onglet "Dépôts" du client
2. Cliquer sur le dépôt
3. Cliquer sur l'icône "-" (Retrait)
4. Retirer toutes les quantités restantes:
   - Cartons de vêtements: `40`
   - Sacs de riz: `80`
5. Notes: `Retrait total - Fin de stockage`
6. Cliquer sur "Enregistrer"

**Résultat attendu:**
- ✅ Les quantités passent à 0
- ✅ Le statut du dépôt passe à "Vide"
- ✅ Le chip "Vide" apparaît en gris
- ✅ L'historique montre le retrait total

### 10. Test avec Tarif par Produit

**Objectif:** Créer un dépôt avec tarification par produit

**Étapes:**
1. Créer un nouveau dépôt pour le même client
2. Choisir "Tarif par produit"
3. Ajouter un produit:
   - Nom: `Équipements électroniques`
   - Quantité: `20`
   - Unité: `Pièces`
   - Tarif unitaire: `2000` FCFA
4. Ajouter un deuxième produit:
   - Nom: `Meubles`
   - Quantité: `10`
   - Unité: `Pièces`
   - Tarif unitaire: `5000` FCFA
5. Enregistrer

**Résultat attendu:**
- ✅ Le dépôt est créé
- ✅ Chaque produit affiche son tarif unitaire
- ✅ Le tarif mensuel total est calculé automatiquement

## Tests de Validation

### Validation des Quantités

**Test:** Essayer de retirer plus que la quantité disponible

**Étapes:**
1. Ouvrir un dépôt avec des produits
2. Tenter de retirer une quantité supérieure à celle en stock
3. Essayer de valider

**Résultat attendu:**
- ✅ Message d'erreur "Max: [quantité disponible]"
- ✅ Le formulaire ne se valide pas

### Validation des Champs Obligatoires

**Test:** Essayer de créer un dépôt sans remplir tous les champs

**Étapes:**
1. Ouvrir le formulaire de création de dépôt
2. Laisser des champs vides
3. Essayer de valider

**Résultat attendu:**
- ✅ Messages d'erreur sur les champs requis
- ✅ Le formulaire ne se valide pas

### Validation des Produits

**Test:** Essayer de créer un dépôt sans produits

**Étapes:**
1. Remplir le formulaire de dépôt
2. Ne pas ajouter de produits
3. Essayer de valider

**Résultat attendu:**
- ✅ Message "Ajoutez au moins un produit"
- ✅ Le dépôt n'est pas créé

## Tests de Recherche et Filtrage

### Recherche de Client

**Test:** Rechercher un client par téléphone existant

**Étapes:**
1. Créer un nouveau client stockeur
2. Créer un autre client avec un téléphone différent
3. Dans le formulaire de création, saisir le téléphone du premier client
4. Cliquer sur rechercher

**Résultat attendu:**
- ✅ Les informations du client sont pré-remplies
- ✅ Message "Client trouvé"

### Filtrage des Factures

**Test:** Filtrer les factures par statut

**Étapes:**
1. Créer plusieurs factures (payées et impayées)
2. Utiliser les filtres "Toutes", "Impayées", "Payées"

**Résultat attendu:**
- ✅ Les factures sont filtrées correctement selon le statut sélectionné

## Tests d'Intégration Firebase

### Synchronisation en Temps Réel

**Test:** Vérifier la synchronisation des données

**Étapes:**
1. Ouvrir l'application sur deux fenêtres (ou deux machines)
2. Créer un dépôt sur la première fenêtre
3. Observer la deuxième fenêtre

**Résultat attendu:**
- ✅ Le nouveau dépôt apparaît automatiquement sur la deuxième fenêtre
- ✅ Les mises à jour sont synchronisées en temps réel

### Persistance des Données

**Test:** Vérifier que les données sont sauvegardées

**Étapes:**
1. Créer plusieurs dépôts et factures
2. Fermer l'application
3. Rouvrir l'application
4. Naviguer vers les écrans de stockage

**Résultat attendu:**
- ✅ Toutes les données sont présentes
- ✅ Aucune perte d'information

## Vérification dans Firebase Console

### Collections à Vérifier

1. **depots**
   - Vérifier la structure des documents
   - Vérifier les produits (array)
   - Vérifier les timestamps

2. **mouvements_stock**
   - Vérifier les mouvements de type "depot"
   - Vérifier les mouvements de type "retrait"
   - Vérifier les références (depotId, clientId)

3. **factures_stockage**
   - Vérifier les numéros de facture
   - Vérifier les statuts
   - Vérifier les montants

4. **counters/facture_stockage**
   - Vérifier que le compteur s'incrémente

## Checklist Finale

- [ ] Création de client stockeur fonctionne
- [ ] Recherche de client par téléphone fonctionne
- [ ] Enregistrement de dépôt avec tarif global fonctionne
- [ ] Enregistrement de dépôt avec tarif par produit fonctionne
- [ ] Ajout de plusieurs produits fonctionne
- [ ] Affichage de l'inventaire est correct
- [ ] Retrait partiel met à jour les quantités
- [ ] Retrait total change le statut en "Vide"
- [ ] Historique des mouvements est complet
- [ ] Génération de facture fonctionne
- [ ] Numérotation automatique des factures fonctionne
- [ ] Calcul du montant total est correct
- [ ] Marquage de facture comme payée fonctionne
- [ ] Factures apparaissent dans l'historique du client
- [ ] Validations des formulaires fonctionnent
- [ ] Navigation entre écrans est fluide
- [ ] Permissions (Gestionnaire/Admin) sont respectées
- [ ] Synchronisation Firebase fonctionne
- [ ] Aucune erreur dans la console

## Problèmes Connus / Limitations

1. **Génération de PDF** - Non implémentée (à faire dans Phase 13)
2. **Envoi d'emails** - Non implémenté (à faire dans Phase 13)
3. **Génération automatique de factures** - Nécessite Cloud Functions
4. **Photos des produits** - Upload non implémenté

## Conclusion

Si tous les tests passent, la Phase 10 est fonctionnelle et prête pour la production. Les fonctionnalités optionnelles (PDF, emails) peuvent être ajoutées dans les phases suivantes.
