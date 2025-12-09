# Guide des Index Firestore pour COREX

## Problème Résolu

Les clients (et autres collections) ne se chargeaient pas à cause d'index Firestore manquants pour les requêtes avec `orderBy`.

## Solution Implémentée

Le code a été modifié pour fonctionner **sans index** en effectuant le tri côté client. Cela fonctionne bien pour des volumes de données raisonnables (< 1000 documents par requête).

### Modifications apportées

**Fichier**: `corex_shared/lib/services/client_service.dart`

1. **getClientsByAgence** : Essaie avec `orderBy`, sinon récupère tout et trie côté client
2. **watchClientsByAgence** : Récupère sans `orderBy` et trie côté client
3. **searchClientsByName** : Récupère sans `orderBy` et trie côté client

## Index Firestore Optionnels (pour optimisation)

Si vous avez beaucoup de données et souhaitez optimiser les performances, vous pouvez créer les index suivants dans Firebase Console.

### Comment créer un index

1. Aller dans **Firebase Console** → **Firestore Database** → **Index**
2. Cliquer sur **Create Index**
3. Remplir les informations selon les exemples ci-dessous

### Index recommandés

#### 1. Index pour les Clients

**Collection**: `clients`

| Champ | Mode |
|-------|------|
| agenceId | Ascending |
| updatedAt | Descending |

**Query scope**: Collection

#### 2. Index pour les Colis

**Collection**: `colis`

| Champ | Mode |
|-------|------|
| agenceCorexId | Ascending |
| statut | Ascending |
| dateCollecte | Descending |

**Query scope**: Collection

#### 3. Index pour les Colis par Commercial

**Collection**: `colis`

| Champ | Mode |
|-------|------|
| commercialId | Ascending |
| dateCollecte | Descending |

**Query scope**: Collection

#### 4. Index pour les Utilisateurs

**Collection**: `users`

| Champ | Mode |
|-------|------|
| agenceId | Ascending |
| role | Ascending |

**Query scope**: Collection

#### 5. Index pour les Zones

**Collection**: `zones`

| Champ | Mode |
|-------|------|
| agenceId | Ascending |
| nom | Ascending |

**Query scope**: Collection

## Création Automatique via Firebase CLI

Vous pouvez aussi créer un fichier `firestore.indexes.json` à la racine du projet :

```json
{
  "indexes": [
    {
      "collectionGroup": "clients",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "agenceId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "updatedAt",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "colis",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "agenceCorexId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "statut",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "dateCollecte",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "colis",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "commercialId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "dateCollecte",
          "order": "DESCENDING"
        }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "agenceId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "role",
          "order": "ASCENDING"
        }
      ]
    },
    {
      "collectionGroup": "zones",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "agenceId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "nom",
          "order": "ASCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Puis déployer avec :

```bash
firebase deploy --only firestore:indexes
```

## Quand créer des index ?

### Créer des index SI :

- ✅ Vous avez plus de 1000 documents dans une collection
- ✅ Les requêtes sont lentes (> 2 secondes)
- ✅ Vous voyez des erreurs "index required" dans les logs
- ✅ Vous voulez optimiser les performances

### NE PAS créer d'index SI :

- ❌ Vous avez moins de 100 documents
- ❌ Les requêtes sont rapides
- ❌ Vous êtes en phase de développement/test
- ❌ Vous voulez économiser les quotas Firebase

## Vérification

Pour vérifier si les clients se chargent maintenant :

1. **Redémarrer l'application** (hot restart complet)
2. **Se connecter** avec un compte ayant une agence
3. **Aller dans le menu** → **Clients**
4. **Vérifier** que la liste des clients s'affiche

### Logs à surveiller

Dans la console, vous devriez voir :

```
✅ [CLIENT_SERVICE] Clients chargés: X clients
```

Ou en cas de problème avec l'index :

```
⚠️ [CLIENT_SERVICE] Erreur avec orderBy, essai sans tri: ...
✅ [CLIENT_SERVICE] Clients chargés sans index: X clients
```

## Dépannage

### Problème : "PERMISSION_DENIED"

**Cause** : Règles de sécurité Firestore trop restrictives

**Solution** : Vérifier les règles dans `firestore.rules` :

```javascript
match /clients/{clientId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && 
    (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin', 'commercial', 'gestionnaire']);
}
```

### Problème : "Index required"

**Cause** : Index Firestore manquant

**Solution** : 
1. Copier l'URL de l'erreur (elle contient un lien direct pour créer l'index)
2. Ou créer l'index manuellement comme décrit ci-dessus
3. Ou utiliser le tri côté client (déjà implémenté)

### Problème : Les clients ne s'affichent toujours pas

**Vérifications** :

1. **Firebase Console** → Vérifier que les clients existent dans Firestore
2. **Vérifier l'agenceId** : Les clients doivent avoir le même `agenceId` que l'utilisateur connecté
3. **Console de l'app** : Regarder les logs pour voir les erreurs
4. **Règles Firestore** : Vérifier que l'utilisateur a les permissions de lecture

## Conclusion

Le code actuel fonctionne **sans index** en effectuant le tri côté client. C'est suffisant pour la plupart des cas d'usage de COREX.

Si vous avez besoin d'optimiser les performances plus tard, vous pouvez créer les index recommandés ci-dessus.

---

**Note** : Les index Firestore prennent quelques minutes à se construire après leur création. Soyez patient !
