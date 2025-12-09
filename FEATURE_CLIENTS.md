# Fonctionnalité : Gestion des Clients

## Vue d'ensemble

Cette fonctionnalité permet d'enregistrer et de réutiliser les informations des expéditeurs et destinataires pour accélérer le processus de collecte de colis.

## Composants créés

### 1. Modèle de données (`ClientModel`)
- **Fichier**: `corex_shared/lib/models/client_model.dart`
- **Champs**:
  - `id`: Identifiant unique
  - `nom`: Nom complet du client
  - `telephone`: Numéro de téléphone (clé de recherche)
  - `adresse`: Adresse complète
  - `ville`: Ville
  - `quartier`: Quartier (optionnel)
  - `type`: Type de client ('expediteur', 'destinataire', 'les_deux')
  - `agenceId`: Agence qui a créé ce client
  - `createdAt`: Date de création
  - `updatedAt`: Date de dernière modification

### 2. Service (`ClientService`)
- **Fichier**: `corex_shared/lib/services/client_service.dart`
- **Méthodes**:
  - `createClient()`: Créer un nouveau client
  - `updateClient()`: Mettre à jour un client
  - `getClientById()`: Récupérer un client par ID
  - `getClientsByAgence()`: Récupérer tous les clients d'une agence
  - `searchClientByPhone()`: Rechercher un client par téléphone
  - `searchClientsByName()`: Rechercher des clients par nom
  - `deleteClient()`: Supprimer un client
  - `watchClientsByAgence()`: Stream pour observer les changements

### 3. Controller (`ClientController`)
- **Fichier**: `corex_shared/lib/controllers/client_controller.dart`
- **Responsabilités**:
  - Gestion de l'état des clients
  - Chargement et mise en cache des clients
  - Interface entre l'UI et le service

### 4. Widget de sélection (`ClientSelector`)
- **Fichier**: `corex_desktop/lib/widgets/client_selector.dart`
- **Fonctionnalités**:
  - Recherche de client par téléphone
  - Auto-complétion des champs si client trouvé
  - Enregistrement automatique des nouveaux clients
  - Validation des champs
  - Indicateur visuel de client trouvé

### 5. Écran de gestion (`ClientsListScreen`)
- **Fichier**: `corex_desktop/lib/screens/clients/clients_list_screen.dart`
- **Fonctionnalités**:
  - Liste de tous les clients de l'agence
  - Recherche par nom, téléphone ou ville
  - Affichage des détails d'un client
  - Rafraîchissement de la liste

## Workflow d'utilisation

### Lors de la collecte d'un colis :

1. **Commercial entre le numéro de téléphone** de l'expéditeur
2. **Clique sur "Rechercher"**
3. **Deux scénarios possibles** :
   
   **A. Client existant trouvé** :
   - ✅ Les champs se remplissent automatiquement
   - ✅ Message de confirmation affiché
   - ✅ Icône verte de validation
   - Le commercial peut modifier les infos si nécessaire
   
   **B. Nouveau client** :
   - ℹ️ Message "Nouveau client" affiché
   - Le commercial remplit les champs manuellement
   - ✅ Le client est automatiquement enregistré pour la prochaine fois

4. **Même processus pour le destinataire**

### Gestion des clients (Admin) :

1. **Menu** → **Clients**
2. **Voir la liste** de tous les clients enregistrés
3. **Rechercher** un client spécifique
4. **Consulter les détails** d'un client

## Avantages

✅ **Gain de temps** : Plus besoin de ressaisir les informations des clients réguliers
✅ **Moins d'erreurs** : Les informations sont cohérentes d'une collecte à l'autre
✅ **Historique** : Possibilité de voir tous les clients enregistrés
✅ **Expérience utilisateur** : Interface intuitive avec feedback visuel
✅ **Scalabilité** : Base de données de clients qui s'enrichit automatiquement

## Base de données Firebase

### Collection : `clients`

```json
{
  "id": "uuid",
  "nom": "Jean Dupont",
  "telephone": "677123456",
  "adresse": "123 Rue de la Paix",
  "ville": "Douala",
  "quartier": "Akwa",
  "type": "les_deux",
  "agenceId": "agence-uuid",
  "createdAt": "2025-01-15T10:30:00Z",
  "updatedAt": "2025-01-15T10:30:00Z"
}
```

### Index recommandés :
- `agenceId` + `telephone` (pour la recherche rapide)
- `agenceId` + `updatedAt` (pour le tri)

## Améliorations futures possibles

1. **Statistiques** : Nombre de colis par client
2. **Favoris** : Marquer des clients comme favoris
3. **Modification** : Permettre la modification des infos client depuis la liste
4. **Export** : Exporter la liste des clients en CSV/Excel
5. **Fusion** : Fusionner des doublons de clients
6. **Notes** : Ajouter des notes sur les clients (préférences, instructions spéciales)

## Tests recommandés

- [ ] Recherche d'un client existant
- [ ] Création d'un nouveau client
- [ ] Modification des infos d'un client trouvé
- [ ] Recherche avec numéro invalide
- [ ] Affichage de la liste des clients
- [ ] Recherche dans la liste des clients
- [ ] Collecte de colis avec client existant
- [ ] Collecte de colis avec nouveau client
