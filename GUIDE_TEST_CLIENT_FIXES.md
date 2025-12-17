# Guide de Test - Corrections Clients

## Tests à effectuer après les corrections

### 1. Test de l'erreur KeyDownEvent

**Objectif :** Vérifier que l'erreur KeyDownEvent n'apparaît plus

**Procédure :**
1. Ouvrir l'écran de collecte de colis
2. Aller à l'étape "Expéditeur"
3. Saisir un numéro de téléphone rapidement
4. Cliquer plusieurs fois sur "Rechercher" rapidement
5. Utiliser les touches du clavier (Volume, etc.) pendant la recherche

**Résultat attendu :**
- Aucune exception KeyDownEvent dans la console
- L'interface reste réactive
- Pas de blocage de l'application

### 2. Test de l'affichage en double

**Objectif :** Vérifier qu'il n'y a plus de doublons dans les résultats

**Procédure :**
1. Créer un client avec le numéro : `6 12 34 56 78`
2. Rechercher avec différents formats :
   - `612345678`
   - `6 12 34 56 78`
   - `6-12-34-56-78`
   - `(6) 12 34 56 78`
3. Vérifier les résultats de recherche

**Résultat attendu :**
- Un seul client trouvé pour tous les formats
- Pas de doublons dans l'affichage
- Informations correctement remplies

### 3. Test du champ email

**Objectif :** Vérifier que le champ email fonctionne correctement

**Procédure :**
1. **Création d'un nouveau client avec email :**
   - Aller à l'écran de collecte
   - Saisir un nouveau numéro de téléphone
   - Cliquer "Rechercher" → "Nouveau client"
   - Remplir tous les champs y compris l'email
   - Valider la collecte

2. **Recherche d'un client existant avec email :**
   - Rechercher le client créé précédemment
   - Vérifier que l'email est bien rempli automatiquement

3. **Validation email :**
   - Tester avec un email invalide : `test@`
   - Tester avec un email valide : `test@example.com`
   - Laisser le champ vide (optionnel)

**Résultat attendu :**
- Le champ email apparaît dans l'interface
- La validation fonctionne correctement
- L'email est sauvegardé et récupéré
- Les notifications peuvent utiliser l'email

### 4. Test de performance

**Objectif :** Vérifier que les recherches sont fluides

**Procédure :**
1. Effectuer plusieurs recherches consécutives
2. Changer de numéro pendant une recherche en cours
3. Naviguer entre les étapes pendant une recherche

**Résultat attendu :**
- Pas de blocage de l'interface
- Recherches rapides et fluides
- Annulation correcte des recherches en cours

### 5. Test de migration des données

**Objectif :** Vérifier que les clients existants fonctionnent toujours

**Procédure :**
1. Rechercher des clients créés avant la mise à jour
2. Vérifier qu'ils s'affichent correctement
3. Modifier un client existant pour ajouter un email
4. Sauvegarder et rechercher à nouveau

**Résultat attendu :**
- Les anciens clients fonctionnent normalement
- Le champ email est vide pour les anciens clients
- Possibilité d'ajouter un email aux clients existants

## Checklist de validation

- [ ] Aucune erreur KeyDownEvent dans la console
- [ ] Pas de doublons dans les résultats de recherche
- [ ] Le champ email apparaît dans l'interface
- [ ] La validation email fonctionne
- [ ] Les emails sont sauvegardés en base
- [ ] Les emails sont récupérés lors des recherches
- [ ] Les recherches sont fluides et rapides
- [ ] Les clients existants fonctionnent toujours
- [ ] Possibilité d'ajouter des emails aux clients existants

## En cas de problème

### Si l'erreur KeyDownEvent persiste :
1. Vérifier que toutes les modifications sont appliquées
2. Redémarrer l'application complètement
3. Vérifier les logs pour d'autres erreurs

### Si les doublons persistent :
1. Vérifier la normalisation des numéros
2. Contrôler les index Firestore
3. Vérifier la logique de recherche

### Si le champ email ne fonctionne pas :
1. Vérifier que le modèle ClientModel est mis à jour
2. Contrôler les règles Firestore
3. Vérifier les validateurs

## Notifications email

Après validation des corrections, tester l'envoi de notifications :

1. **Configuration du service email :**
   - Vérifier la configuration SMTP
   - Tester l'envoi d'un email simple

2. **Notifications automatiques :**
   - Collecter un colis avec email expéditeur
   - Vérifier l'envoi de la confirmation
   - Tester les notifications de changement de statut

3. **Gestion des erreurs :**
   - Tester avec un email invalide
   - Vérifier les logs d'erreur
   - Confirmer que l'application continue de fonctionner