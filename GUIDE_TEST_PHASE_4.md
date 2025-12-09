# Guide de Test - Phase 4 : Enregistrement de Colis

## Prérequis

1. Application COREX Desktop lancée
2. Connexion Firebase active
3. Au moins un utilisateur avec le rôle "agent" ou "gestionnaire"
4. Au moins un colis en statut "collecte" (créé via l'interface commercial)

## Scénario de Test Complet

### Étape 1 : Préparation

1. **Créer un colis de test (en tant que commercial)**
   - Se connecter avec un compte commercial
   - Aller dans "Collecter un colis"
   - Remplir toutes les informations :
     - Expéditeur : Jean Dupont, +237 690 000 001, Douala
     - Destinataire : Marie Martin, +237 690 000 002, Yaoundé, Bastos
     - Contenu : Documents, Poids : 2 kg
     - Tarif : 5000 FCFA, Payé
   - Enregistrer le colis
   - **Résultat attendu** : Message de succès, colis créé avec statut "collecte"

2. **Se déconnecter et se reconnecter en tant qu'agent**
   - Cliquer sur le bouton de déconnexion
   - Se connecter avec un compte agent ou gestionnaire

### Étape 2 : Accès à l'Interface d'Enregistrement

1. **Ouvrir le menu**
   - Cliquer sur l'icône du menu (hamburger) en haut à gauche
   - **Résultat attendu** : Le drawer s'ouvre

2. **Naviguer vers l'enregistrement**
   - Dans la section "OPÉRATIONS", cliquer sur "Enregistrer des colis"
   - **Résultat attendu** : L'écran "Enregistrement des Colis" s'affiche

### Étape 3 : Liste des Colis à Enregistrer

1. **Vérifier l'affichage**
   - **Résultat attendu** :
     - Barre de recherche en haut
     - Statistique "À enregistrer : 1" (ou plus)
     - Carte du colis créé précédemment
     - Badge orange "À ENREGISTRER"

2. **Vérifier les informations affichées**
   - **Résultat attendu** :
     - Date de collecte visible
     - Nom et téléphone de l'expéditeur
     - Nom, ville et téléphone du destinataire
     - Contenu, poids et tarif
     - Bouton "ENREGISTRER CE COLIS"

3. **Tester la recherche**
   - Taper "Jean" dans la barre de recherche
   - **Résultat attendu** : Le colis de Jean Dupont apparaît
   - Taper "Marie" dans la barre de recherche
   - **Résultat attendu** : Le colis pour Marie Martin apparaît
   - Taper "690 000 001" dans la barre de recherche
   - **Résultat attendu** : Le colis apparaît
   - Effacer la recherche
   - **Résultat attendu** : Tous les colis réapparaissent

### Étape 4 : Détails du Colis

1. **Ouvrir les détails**
   - Cliquer sur le bouton "ENREGISTRER CE COLIS"
   - **Résultat attendu** : L'écran de détails s'ouvre

2. **Vérifier l'affichage des détails**
   - **Résultat attendu** :
     - Carte de statut en haut avec "EN ATTENTE D'ENREGISTREMENT" (orange)
     - Section "Expéditeur" avec toutes les infos
     - Section "Destinataire" avec toutes les infos
     - Section "Détails du Colis"
     - Section "Informations Financières"
     - Section "Dates"
     - Bouton vert "ENREGISTRER ET GÉNÉRER LES DOCUMENTS"
     - Bouton "RETOUR"

3. **Vérifier les informations**
   - Toutes les informations saisies doivent être présentes et correctes

### Étape 5 : Enregistrement du Colis

1. **Lancer l'enregistrement**
   - Cliquer sur "ENREGISTRER ET GÉNÉRER LES DOCUMENTS"
   - **Résultat attendu** :
     - Le bouton affiche "ENREGISTREMENT..." avec un spinner
     - Le bouton est désactivé pendant le traitement

2. **Attendre la fin du traitement**
   - **Résultat attendu** (après quelques secondes) :
     - Message de succès avec le numéro de suivi (ex: "COL-2025-000001")
     - Deux fichiers PDF s'ouvrent automatiquement :
       1. Reçu de collecte
       2. Bordereau d'expédition
     - Retour automatique à l'écran de liste

3. **Vérifier la liste mise à jour**
   - **Résultat attendu** :
     - Le colis n'apparaît plus dans la liste
     - Statistique "À enregistrer : 0"
     - Message "Aucun colis à enregistrer"

### Étape 6 : Vérification des Documents PDF

#### Reçu de Collecte

1. **Vérifier l'en-tête**
   - Logo COREX en vert
   - Titre "REÇU DE COLLECTE"
   - Date du jour

2. **Vérifier le contenu**
   - Numéro de suivi en évidence (ex: COL-2025-000001)
   - Section EXPÉDITEUR complète
   - Section DESTINATAIRE complète
   - Section DÉTAILS DU COLIS
   - Section INFORMATIONS FINANCIÈRES
   - Dates de collecte et d'enregistrement

3. **Vérifier le design**
   - Couleur verte COREX (#2E7D32)
   - Mise en page professionnelle
   - Pied de page avec coordonnées

#### Bordereau d'Expédition

1. **Vérifier l'en-tête**
   - Logo COREX
   - Titre "BORDEREAU D'EXPÉDITION"

2. **Vérifier le numéro de suivi**
   - Grand format avec fond vert
   - Bien visible et lisible

3. **Vérifier le contenu**
   - Colonne "DE" avec infos expéditeur
   - Colonne "À" avec infos destinataire
   - Encadré vert avec détails du colis
   - Mode de livraison en évidence
   - Zones de signature (expéditeur et destinataire)

4. **Vérifier le design**
   - Couleurs COREX
   - Mise en page claire
   - Prêt à imprimer

### Étape 7 : Vérification dans Firebase

1. **Ouvrir Firebase Console**
   - Aller dans Firestore Database
   - Collection "colis"
   - Trouver le colis enregistré

2. **Vérifier les champs**
   - `statut` : "enregistre"
   - `numeroSuivi` : "COL-2025-000001" (ou suivant)
   - `dateEnregistrement` : Date et heure actuelles
   - `historique` : Doit contenir 2 entrées :
     1. Statut "collecte" (création)
     2. Statut "enregistre" (enregistrement)

3. **Vérifier le compteur**
   - Collection "counters"
   - Document "colis_2025"
   - Champ `count` : 1 (ou plus)

### Étape 8 : Vérification des Fichiers

1. **Localiser les fichiers**
   - Ouvrir l'Explorateur Windows
   - Aller dans "Documents"
   - Dossier "COREX"
   - Sous-dossier "Documents"

2. **Vérifier les fichiers**
   - **Résultat attendu** :
     - `Recu_Collecte_COL-2025-000001.pdf`
     - `Bordereau_COL-2025-000001.pdf`

## Test du Mode Offline

### Étape 1 : Préparation

1. **Créer un nouveau colis** (en tant que commercial)
2. **Se reconnecter en tant qu'agent**

### Étape 2 : Désactiver la Connexion

1. **Désactiver le WiFi ou débrancher le câble réseau**
2. **Attendre quelques secondes**

### Étape 3 : Enregistrer en Mode Offline

1. **Aller dans "Enregistrer des colis"**
   - **Résultat attendu** : Le colis apparaît (cache local)

2. **Enregistrer le colis**
   - Cliquer sur "ENREGISTRER ET GÉNÉRER LES DOCUMENTS"
   - **Résultat attendu** :
     - Numéro temporaire généré (ex: COL-2025-TEMP1732636800000)
     - Message de succès
     - Documents PDF générés

### Étape 4 : Réactiver la Connexion

1. **Réactiver le WiFi ou rebrancher le câble**
2. **Attendre la synchronisation automatique**
3. **Vérifier dans Firebase**
   - Le colis doit être synchronisé
   - Le numéro temporaire doit être remplacé par un numéro définitif

## Test des Permissions

### Test 1 : Agent

1. **Se connecter en tant qu'agent**
2. **Ouvrir le menu**
   - **Résultat attendu** : "Enregistrer des colis" est visible

### Test 2 : Gestionnaire

1. **Se connecter en tant que gestionnaire**
2. **Ouvrir le menu**
   - **Résultat attendu** : "Enregistrer des colis" est visible

### Test 3 : Commercial

1. **Se connecter en tant que commercial**
2. **Ouvrir le menu**
   - **Résultat attendu** : "Enregistrer des colis" n'est PAS visible

### Test 4 : Coursier

1. **Se connecter en tant que coursier**
2. **Ouvrir le menu**
   - **Résultat attendu** : "Enregistrer des colis" n'est PAS visible

## Test de Charge

### Enregistrement Multiple

1. **Créer 10 colis** (en tant que commercial)
2. **Se connecter en tant qu'agent**
3. **Aller dans "Enregistrer des colis"**
   - **Résultat attendu** : Statistique "À enregistrer : 10"
4. **Enregistrer tous les colis un par un**
   - **Résultat attendu** :
     - Numéros de suivi séquentiels (001, 002, 003, etc.)
     - Pas de doublons
     - Tous les documents générés correctement

## Problèmes Connus et Solutions

### Problème 1 : Les PDF ne s'ouvrent pas automatiquement

**Solution** :
- Vérifier que le package `open_file` est installé
- Vérifier les permissions Windows
- Ouvrir manuellement depuis Documents/COREX/Documents

### Problème 2 : Erreur "Timeout" lors de l'enregistrement

**Solution** :
- Vérifier la connexion internet
- Le colis est sauvegardé localement
- Il sera synchronisé automatiquement au retour de connexion

### Problème 3 : Le menu "Enregistrer des colis" n'apparaît pas

**Solution** :
- Vérifier le rôle de l'utilisateur (doit être agent, gestionnaire ou admin)
- Se déconnecter et se reconnecter

### Problème 4 : Numéros de suivi en double

**Solution** :
- Vérifier que le compteur Firebase est bien configuré
- Vérifier les règles de sécurité Firestore
- En cas de problème, réinitialiser le compteur

## Checklist de Validation

- [ ] L'écran d'enregistrement s'affiche correctement
- [ ] La recherche fonctionne
- [ ] Les détails du colis s'affichent correctement
- [ ] L'enregistrement fonctionne
- [ ] Le numéro de suivi est généré correctement
- [ ] Le statut passe à "enregistre"
- [ ] L'historique est mis à jour
- [ ] Le reçu de collecte est généré
- [ ] Le bordereau d'expédition est généré
- [ ] Les PDF s'ouvrent automatiquement
- [ ] Les fichiers sont sauvegardés dans Documents/COREX/Documents
- [ ] Le mode offline fonctionne
- [ ] Les permissions sont respectées
- [ ] L'enregistrement multiple fonctionne
- [ ] Pas de doublons de numéros de suivi

## Conclusion

Si tous les tests passent, la Phase 4 est validée et prête pour la production. Vous pouvez passer à la Phase 5 : Module Suivi et Gestion des Statuts.

---

**Note** : Ce guide doit être suivi dans l'ordre pour garantir une validation complète de toutes les fonctionnalités.
