# 🚀 Guide de Démarrage Rapide - COREX

## ✅ Phase 0 Complétée

L'infrastructure de base est maintenant en place et prête à être utilisée !

## 📋 Avant de Commencer

Vous devez créer un premier utilisateur admin dans Firebase pour pouvoir vous connecter.

### Créer le Premier Utilisateur Admin

1. **Aller sur Firebase Console**
   - Ouvrez https://console.firebase.google.com
   - Sélectionnez le projet `corex-a1c1e`

2. **Créer un utilisateur dans Authentication**
   - Allez dans `Authentication` > `Users`
   - Cliquez sur `Add user`
   - Email : `admin@corex.cm` (ou votre email)
   - Mot de passe : Choisissez un mot de passe sécurisé
   - Copiez l'UID généré (vous en aurez besoin)

3. **Créer le document utilisateur dans Firestore**
   - Allez dans `Firestore Database`
   - Créez une collection `users`
   - Créez un document avec l'UID copié précédemment
   - Ajoutez les champs suivants :
   
   ```
   email: "admin@corex.cm"
   nom: "Admin"
   prenom: "COREX"
   telephone: "677123456"
   role: "admin"
   agenceId: null
   isActive: true
   createdAt: [Timestamp actuel]
   lastLogin: null
   ```

## 🖥️ Lancer l'Application Desktop

```bash
cd corex_desktop
flutter run -d windows
```

**Identifiants de connexion :**
- Email : `admin@corex.cm` (ou celui que vous avez créé)
- Mot de passe : Celui que vous avez défini

## 📱 Lancer l'Application Mobile

```bash
cd corex_mobile
flutter run
```

**Note :** L'application mobile est réservée au PDG (rôle admin uniquement).

## 🎯 Que Faire Ensuite ?

### 1. Tester la Connexion
- Lancez l'application desktop
- Connectez-vous avec vos identifiants admin
- Vérifiez que vous arrivez sur l'écran d'accueil

### 2. Vérifier le Mode Hors Ligne
- Connectez-vous
- Coupez votre connexion internet
- L'application devrait continuer à fonctionner
- Reconnectez-vous : les données se synchronisent automatiquement

### 3. Prêt pour la Phase 1
Une fois que tout fonctionne, vous êtes prêt à commencer la Phase 1 :
- Gestion complète des utilisateurs
- Système de permissions
- Interface d'administration

## 🔧 Commandes Utiles

### Vérifier que tout compile
```bash
# Desktop
cd corex_desktop
flutter analyze

# Mobile
cd corex_mobile
flutter analyze
```

### Nettoyer et reconstruire
```bash
flutter clean
flutter pub get
```

### Voir les logs Firebase
```bash
flutter run --verbose
```

## 📊 Structure Firebase Actuelle

### Collections Firestore
- `users` : Utilisateurs du système
- `agences` : Agences COREX (à créer)
- `colis` : Colis (à créer)
- `livraisons` : Livraisons (à créer)
- `transactions` : Transactions financières (à créer)
- `zones` : Zones géographiques (à créer)
- `agencesTransport` : Agences de transport (à créer)
- `counters` : Compteurs pour numéros de suivi (à créer)

## ❓ Problèmes Courants

### "User not found in database"
➡️ Vous avez créé l'utilisateur dans Authentication mais pas dans Firestore. Suivez l'étape 3 ci-dessus.

### "Account disabled"
➡️ Vérifiez que `isActive: true` dans le document Firestore.

### "Firebase not initialized"
➡️ Vérifiez que les fichiers `firebase_options.dart` existent dans les dossiers lib/.

### Erreur de compilation
➡️ Exécutez `flutter clean` puis `flutter pub get` puis réessayez.

## 📞 Prochaines Étapes

Consultez `.kiro/specs/corex/tasks.md` pour voir le plan complet d'implémentation.

La Phase 1 ajoutera :
- Interface de gestion des utilisateurs
- Création/modification/suppression d'utilisateurs
- Gestion des rôles et permissions
- Réinitialisation de mot de passe

---

**Bon développement ! 🚀**
