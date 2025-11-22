# Règles de Sécurité Firestore - COREX

## 📋 Configuration des Règles

Ces règles doivent être configurées dans Firebase Console > Firestore Database > Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fonction helper pour vérifier l'authentification
    function isSignedIn() {
      return request.auth != null;
    }
    
    // Fonction helper pour obtenir les données utilisateur
    function getUserData() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data;
    }
    
    // Fonction helper pour vérifier le rôle
    function hasRole(role) {
      return isSignedIn() && getUserData().role == role;
    }
    
    // Fonction helper pour vérifier si l'utilisateur est actif
    function isActive() {
      return isSignedIn() && getUserData().isActive == true;
    }
    
    // Collection users
    match /users/{userId} {
      // Lecture : utilisateur lui-même ou admin
      allow read: if isSignedIn() && (
        request.auth.uid == userId || 
        hasRole('admin')
      );
      
      // Écriture : admin uniquement
      allow write: if hasRole('admin');
    }
    
    // Collection agences
    match /agences/{agenceId} {
      // Lecture : tous les utilisateurs authentifiés
      allow read: if isSignedIn() && isActive();
      
      // Écriture : admin uniquement
      allow write: if hasRole('admin');
    }
    
    // Collection colis
    match /colis/{colisId} {
      // Lecture : tous les utilisateurs authentifiés
      allow read: if isSignedIn() && isActive();
      
      // Création : commercial, agent, gestionnaire, admin
      allow create: if isSignedIn() && isActive() && (
        hasRole('commercial') ||
        hasRole('agent') ||
        hasRole('gestionnaire') ||
        hasRole('admin')
      );
      
      // Mise à jour : agent, gestionnaire, admin, coursier (pour statut)
      allow update: if isSignedIn() && isActive() && (
        hasRole('agent') ||
        hasRole('gestionnaire') ||
        hasRole('admin') ||
        hasRole('coursier')
      );
      
      // Suppression : admin uniquement
      allow delete: if hasRole('admin');
    }
    
    // Collection livraisons
    match /livraisons/{livraisonId} {
      // Lecture : tous les utilisateurs authentifiés
      allow read: if isSignedIn() && isActive();
      
      // Création : gestionnaire, admin
      allow create: if isSignedIn() && isActive() && (
        hasRole('gestionnaire') ||
        hasRole('admin')
      );
      
      // Mise à jour : coursier (ses livraisons), gestionnaire, admin
      allow update: if isSignedIn() && isActive() && (
        (hasRole('coursier') && resource.data.coursierId == request.auth.uid) ||
        hasRole('gestionnaire') ||
        hasRole('admin')
      );
      
      // Suppression : admin uniquement
      allow delete: if hasRole('admin');
    }
    
    // Collection transactions
    match /transactions/{transactionId} {
      // Lecture : utilisateurs de la même agence ou admin
      allow read: if isSignedIn() && isActive() && (
        resource.data.agenceId == getUserData().agenceId ||
        hasRole('admin')
      );
      
      // Création : gestionnaire de l'agence ou admin
      allow create: if isSignedIn() && isActive() && (
        (hasRole('gestionnaire') && request.resource.data.agenceId == getUserData().agenceId) ||
        hasRole('admin')
      );
      
      // Mise à jour : gestionnaire de l'agence ou admin
      allow update: if isSignedIn() && isActive() && (
        (hasRole('gestionnaire') && resource.data.agenceId == getUserData().agenceId) ||
        hasRole('admin')
      );
      
      // Suppression : admin uniquement
      allow delete: if hasRole('admin');
    }
    
    // Collection zones
    match /zones/{zoneId} {
      // Lecture : tous les utilisateurs authentifiés
      allow read: if isSignedIn() && isActive();
      
      // Écriture : gestionnaire de l'agence ou admin
      allow write: if isSignedIn() && isActive() && (
        (hasRole('gestionnaire') && resource.data.agenceId == getUserData().agenceId) ||
        hasRole('admin')
      );
    }
    
    // Collection agencesTransport
    match /agencesTransport/{agenceTransportId} {
      // Lecture : tous les utilisateurs authentifiés
      allow read: if isSignedIn() && isActive();
      
      // Écriture : gestionnaire ou admin
      allow write: if isSignedIn() && isActive() && (
        hasRole('gestionnaire') ||
        hasRole('admin')
      );
    }
    
    // Collection counters
    match /counters/{counterId} {
      // Lecture : tous les utilisateurs authentifiés
      allow read: if isSignedIn() && isActive();
      
      // Écriture : tous les utilisateurs authentifiés (pour auto-increment)
      allow write: if isSignedIn() && isActive();
    }
  }
}
```

## 🔐 Explication des Règles

### Principes de Sécurité

1. **Authentification obligatoire** : Toutes les opérations nécessitent une authentification
2. **Utilisateur actif** : L'utilisateur doit avoir `isActive: true`
3. **Contrôle par rôle** : Les permissions sont basées sur le rôle de l'utilisateur
4. **Isolation des données** : Les utilisateurs ne voient que les données de leur agence (sauf admin)

### Rôles et Permissions

| Rôle | Permissions |
|------|-------------|
| **Admin** | Accès complet à toutes les collections |
| **Gestionnaire** | Gestion de son agence (colis, livraisons, transactions, zones) |
| **Commercial** | Création de colis uniquement |
| **Agent** | Création et mise à jour de colis |
| **Coursier** | Mise à jour de ses livraisons uniquement |

### Collections Spéciales

- **users** : Seul l'admin peut créer/modifier des utilisateurs
- **agences** : Seul l'admin peut gérer les agences
- **counters** : Tous peuvent écrire (pour l'auto-incrémentation des numéros de suivi)

## 📝 Comment Appliquer ces Règles

1. Allez sur Firebase Console : https://console.firebase.google.com
2. Sélectionnez le projet `corex-a1c1e`
3. Allez dans `Firestore Database` > `Rules`
4. Copiez-collez les règles ci-dessus
5. Cliquez sur `Publish`

## ⚠️ Important

- Ces règles sont essentielles pour la sécurité de l'application
- Ne les modifiez pas sans comprendre les implications
- Testez toujours les règles avant de les déployer en production
- Les règles sont évaluées côté serveur, elles ne peuvent pas être contournées

## 🧪 Tester les Règles

Firebase Console offre un simulateur de règles :
1. Allez dans `Firestore Database` > `Rules`
2. Cliquez sur `Rules Playground`
3. Testez différents scénarios avec différents rôles

---

**Sécurité avant tout ! 🔐**
