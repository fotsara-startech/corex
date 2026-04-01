# Document de Requirements — Module Devis

## Introduction

Ce module permet aux agents COREX de créer, gérer et exporter des devis commerciaux pour les clients. Un devis est composé de lignes de détail (désignation, quantité, prix unitaire) avec calcul automatique des totaux. Une fois validé, le devis génère une transaction financière en caisse. Le devis peut également être converti en facture.

## Glossaire

- **Devis** : Document commercial présentant une offre de prix à un client, composé de lignes de détail et d'un total calculé.
- **DevisModel** : Modèle de données représentant un devis dans Firestore.
- **LigneDevis** : Ligne de détail d'un devis contenant une désignation, une quantité, un prix unitaire et un total calculé.
- **DevisService** : Service Firestore responsable des opérations CRUD sur les devis.
- **DevisController** : Contrôleur GetX gérant l'état réactif des devis.
- **TransactionService** : Service existant responsable de l'enregistrement des transactions financières en caisse.
- **TransactionModel** : Modèle existant représentant une transaction financière (recette ou dépense).
- **ClientModel** : Modèle existant représentant un client avec nom, téléphone, adresse.
- **Agent** : Utilisateur authentifié de l'application COREX Desktop ayant accès au module devis.
- **Statut_Devis** : État du devis parmi : `brouillon`, `envoye`, `valide`, `refuse`, `converti`.

---

## Requirements

### Requirement 1 : Création d'un devis

**User Story :** En tant qu'agent, je veux créer un devis avec des lignes de détail pour un client, afin de lui soumettre une offre commerciale.

#### Acceptance Criteria

1. WHEN l'agent soumet le formulaire de création, THE DevisService SHALL enregistrer le devis dans Firestore avec un numéro unique au format `DEV-YYYY-MM-XXXXXX`.
2. THE DevisModel SHALL contenir les champs : `id`, `numeroDevis`, `clientNom`, `clientTelephone`, `agenceId`, `userId`, `lignes`, `montantTotal`, `statut`, `dateCreation`, `dateModification`, `notes`.
3. THE LigneDevis SHALL contenir les champs : `designation`, `quantite`, `prixUnitaire`, `total` (calculé automatiquement comme `quantite × prixUnitaire`).
4. WHEN l'agent modifie la quantité ou le prix unitaire d'une ligne, THE DevisController SHALL recalculer automatiquement le total de la ligne et le montant total du devis.
5. THE DevisController SHALL exiger au minimum une ligne de détail et un nom de client non vide avant de permettre la sauvegarde.
6. IF le nom du client est vide ou si aucune ligne n'est présente, THEN THE DevisController SHALL afficher un message d'erreur de validation.
7. WHEN un devis est créé avec succès, THE DevisController SHALL initialiser son statut à `brouillon`.

---

### Requirement 2 : Modification et suppression d'un devis

**User Story :** En tant qu'agent, je veux modifier ou supprimer un devis existant, afin de corriger des erreurs ou annuler une offre.

#### Acceptance Criteria

1. WHEN l'agent ouvre un devis en statut `brouillon` ou `envoye`, THE DevisController SHALL permettre la modification de toutes les lignes et des informations client.
2. WHILE le statut du devis est `valide` ou `converti`, THE DevisController SHALL empêcher toute modification des lignes et afficher un message indiquant que le devis est verrouillé.
3. WHEN l'agent confirme la suppression d'un devis, THE DevisService SHALL supprimer le document Firestore correspondant.
4. WHILE le statut du devis est `valide` ou `converti`, THE DevisController SHALL désactiver le bouton de suppression.
5. WHEN un devis est supprimé avec succès, THE DevisController SHALL retirer le devis de la liste réactive et afficher une confirmation.

---

### Requirement 3 : Validation d'un devis et création de transaction

**User Story :** En tant qu'agent, je veux valider un devis accepté par le client, afin d'enregistrer automatiquement la recette en caisse.

#### Acceptance Criteria

1. WHEN l'agent valide un devis, THE DevisService SHALL mettre à jour le statut du devis à `valide` et enregistrer la date de validation.
2. WHEN l'agent valide un devis, THE TransactionService SHALL créer une transaction de type `recette` avec `categorieRecette` égale à `devis`, le montant total du devis, et la référence du numéro de devis.
3. WHEN la transaction est créée avec succès, THE DevisService SHALL enregistrer l'identifiant de la transaction dans le champ `transactionId` du devis.
4. IF la création de la transaction échoue, THEN THE DevisController SHALL afficher un message d'erreur et annuler la mise à jour du statut du devis.
5. WHILE un devis est en statut `valide`, THE DevisController SHALL afficher le montant et la date de validation dans la fiche du devis.

---

### Requirement 4 : Conversion d'un devis en facture

**User Story :** En tant qu'agent, je veux convertir un devis validé en facture, afin de formaliser la transaction commerciale.

#### Acceptance Criteria

1. WHEN l'agent déclenche la conversion d'un devis en statut `valide`, THE DevisController SHALL créer une `FactureStockageModel` pré-remplie avec les informations du devis (client, montant, référence).
2. WHEN la conversion est effectuée, THE DevisService SHALL mettre à jour le statut du devis à `converti` et enregistrer l'identifiant de la facture générée dans le champ `factureId`.
3. WHILE un devis est en statut `converti`, THE DevisController SHALL afficher un lien ou une référence vers la facture associée.
4. IF le devis n'est pas en statut `valide`, THEN THE DevisController SHALL désactiver l'action de conversion et afficher un message explicatif.

---

### Requirement 5 : Export et impression PDF du devis

**User Story :** En tant qu'agent, je veux exporter ou imprimer un devis en PDF, afin de le transmettre au client.

#### Acceptance Criteria

1. WHEN l'agent déclenche l'impression, THE DevisController SHALL générer un document PDF contenant : le numéro de devis, la date, les informations client (nom, téléphone), le tableau des lignes (désignation, quantité, prix unitaire, total), le montant total, et le statut.
2. THE DevisController SHALL utiliser la bibliothèque `pdf` et `printing` existantes dans le projet pour la génération et l'impression.
3. WHEN l'agent déclenche l'export PDF, THE DevisController SHALL proposer le téléchargement du fichier nommé `Devis_[numeroDevis].pdf`.
4. THE DevisController SHALL inclure l'en-tête COREX (nom, couleur verte `#2E7D32`) dans le PDF généré, cohérent avec le style des factures existantes.
5. IF la génération du PDF échoue, THEN THE DevisController SHALL afficher un message d'erreur à l'agent.

---

### Requirement 6 : Liste et filtrage des devis

**User Story :** En tant qu'agent, je veux consulter la liste des devis avec des filtres par statut, afin de suivre l'avancement des offres commerciales.

#### Acceptance Criteria

1. THE DevisController SHALL charger la liste des devis de l'agence courante depuis Firestore, triés par date de création décroissante.
2. WHEN l'agent sélectionne un filtre de statut, THE DevisController SHALL afficher uniquement les devis correspondant au statut sélectionné.
3. THE DevisController SHALL proposer les filtres suivants : `Tous`, `Brouillon`, `Envoyé`, `Validé`, `Refusé`, `Converti`.
4. WHILE la liste des devis est en cours de chargement, THE DevisController SHALL afficher un indicateur de chargement.
5. IF aucun devis ne correspond au filtre sélectionné, THEN THE DevisController SHALL afficher un message `Aucun devis` avec un bouton de création.

---

### Requirement 7 : Numérotation automatique des devis

**User Story :** En tant qu'agent, je veux que chaque devis reçoive un numéro unique et séquentiel, afin d'assurer la traçabilité des offres.

#### Acceptance Criteria

1. WHEN un nouveau devis est créé, THE DevisService SHALL générer un numéro unique au format `DEV-YYYY-MM-XXXXXX` où `YYYY-MM` est l'année et le mois courants et `XXXXXX` est un compteur séquentiel à 6 chiffres.
2. THE DevisService SHALL utiliser le mécanisme de compteur Firestore existant (collection `counters`) pour garantir l'unicité du numéro de devis.
3. IF la génération du numéro échoue, THEN THE DevisService SHALL utiliser un identifiant UUID comme numéro de secours et journaliser l'erreur.
