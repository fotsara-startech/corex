# Guide de Test - Phase 13 : Notifications et Emails

## Vue d'Ensemble

La Phase 13 implémente le système complet de notifications et d'emails pour COREX, incluant :
- Service d'envoi d'emails avec templates HTML
- Notifications automatiques pour les changements de statut
- Système d'alertes avec différents niveaux de sévérité
- Interface de gestion des notifications et préférences

## Fonctionnalités Implémentées

### 1. Service d'Emails (EmailService)
- ✅ Configuration SMTP avec support Gmail et serveurs personnalisés
- ✅ File d'attente d'emails avec retry automatique
- ✅ Templates HTML professionnels pour tous les types d'emails
- ✅ Support des pièces jointes (PDF, images)
- ✅ Logging des succès et échecs d'envoi

### 2. Service de Notifications (NotificationService)
- ✅ Notifications automatiques de changement de statut de colis
- ✅ Notifications d'arrivée à destination
- ✅ Notifications d'attribution de livraison aux coursiers
- ✅ Notifications d'échec de livraison
- ✅ Notifications de facturation mensuelle
- ✅ Gestion des préférences utilisateur

### 3. Service d'Alertes (AlertService)
- ✅ Surveillance automatique des seuils (stocks, crédits, retards)
- ✅ Alertes avec 4 niveaux de sévérité (low, medium, high, critical)
- ✅ Notifications ciblées selon les rôles utilisateur
- ✅ Gestion du cycle de vie des alertes (création, lecture, résolution)

### 4. Interface Utilisateur
- ✅ Écran de gestion des notifications et alertes
- ✅ Statistiques des alertes actives
- ✅ Configuration des préférences de notification
- ✅ Actions administrateur pour créer des alertes manuelles

## Tests à Effectuer

### Test 1 : Configuration du Service d'Emails

**Objectif :** Vérifier que le service d'emails est correctement configuré

**Étapes :**
1. Ouvrir le fichier `corex_shared/lib/services/email_service.dart`
2. Modifier la configuration SMTP dans `_initializeEmailConfig()` :
   ```dart
   // Pour Gmail (exemple)
   _smtpServer = gmail('votre-email@gmail.com', 'mot-de-passe-app');
   _fromEmail = 'votre-email@gmail.com';
   _fromName = 'COREX - Notifications';
   ```
3. Redémarrer l'application

**Résultat attendu :**
- Aucune erreur au démarrage
- Service d'emails initialisé avec succès

### Test 2 : Notifications de Changement de Statut

**Objectif :** Tester les notifications automatiques lors des changements de statut

**Prérequis :**
- Avoir configuré le service d'emails
- Avoir des colis avec des emails d'expéditeur/destinataire

**Étapes :**
1. Se connecter en tant qu'Agent
2. Aller dans "Suivi des Colis"
3. Sélectionner un colis en statut "collecte"
4. Changer le statut vers "enregistre"
5. Vérifier les logs dans la console

**Résultat attendu :**
- Message de confirmation du changement de statut
- Log "✅ Notifications de changement de statut envoyées"
- Email envoyé à l'expéditeur (si configuré)

### Test 3 : Notifications d'Arrivée à Destination

**Objectif :** Tester les notifications spéciales d'arrivée

**Étapes :**
1. Prendre un colis en statut "enTransit"
2. Changer le statut vers "arriveDestination"
3. Vérifier les logs

**Résultat attendu :**
- Notification de changement de statut
- Notification spéciale d'arrivée envoyée au destinataire
- Log "✅ Notification d'arrivée envoyée"

### Test 4 : Notifications d'Attribution de Livraison

**Objectif :** Tester les notifications aux coursiers

**Étapes :**
1. Se connecter en tant que Gestionnaire
2. Aller dans "Livraisons"
3. Attribuer une livraison à un coursier
4. Utiliser la nouvelle méthode `createLivraisonWithNotification`

**Résultat attendu :**
- Livraison créée avec succès
- Email envoyé au coursier avec les détails
- Log "✅ Notification d'attribution envoyée"

### Test 5 : Interface de Gestion des Notifications

**Objectif :** Tester l'écran de notifications

**Étapes :**
1. Naviguer vers `/notifications` dans l'application
2. Vérifier l'affichage des statistiques
3. Tester les préférences de notification
4. Créer une alerte manuelle (si admin/PDG)

**Résultat attendu :**
- Écran s'affiche correctement
- Statistiques des alertes visibles
- Préférences modifiables
- Alertes créées avec succès

### Test 6 : Système d'Alertes Automatiques

**Objectif :** Tester la surveillance automatique

**Étapes :**
1. Attendre 1 heure après le démarrage de l'application
2. Vérifier les logs de surveillance
3. Créer des conditions d'alerte (optionnel)

**Résultat attendu :**
- Logs "🔍 Vérification des..." toutes les heures
- Alertes créées si conditions remplies
- Notifications envoyées selon la sévérité

## Configuration Recommandée pour les Tests

### Configuration Gmail (Exemple)

1. **Activer l'authentification à 2 facteurs** sur votre compte Gmail
2. **Générer un mot de passe d'application** :
   - Aller dans Paramètres Google > Sécurité
   - Mots de passe des applications
   - Générer un nouveau mot de passe pour "COREX"
3. **Utiliser ce mot de passe** dans la configuration :
   ```dart
   _smtpServer = gmail('votre-email@gmail.com', 'mot-de-passe-app-16-caracteres');
   ```

### Configuration Serveur SMTP Personnalisé

```dart
_smtpServer = SmtpServer(
  'smtp.votre-domaine.com',
  port: 587,
  username: 'notifications@votre-domaine.com',
  password: 'votre_mot_de_passe',
  ssl: false,
  allowInsecure: false,
);
```

## Dépannage

### Problème : Emails non envoyés

**Solutions :**
1. Vérifier la configuration SMTP
2. Vérifier la connexion internet
3. Contrôler les logs d'erreur dans la console
4. Tester avec un autre fournisseur d'email

### Problème : Notifications non déclenchées

**Solutions :**
1. Vérifier que les services sont bien initialisés
2. Contrôler que les emails sont renseignés dans les modèles
3. Vérifier les préférences de notification
4. Redémarrer l'application

### Problème : Alertes non affichées

**Solutions :**
1. Vérifier les permissions utilisateur
2. Actualiser la page des notifications
3. Contrôler les logs du service d'alertes

## Améliorations Futures

### Phase 13.4 : Notifications Push (Mobile)
- Intégration Firebase Cloud Messaging
- Notifications push pour l'application mobile
- Badges de notification sur l'icône

### Phase 13.5 : Templates Personnalisables
- Interface d'édition des templates d'emails
- Personnalisation par agence
- Prévisualisation des emails

### Phase 13.6 : Rapports de Notifications
- Statistiques d'envoi d'emails
- Taux d'ouverture et de lecture
- Historique des notifications

## Validation de la Phase 13

La Phase 13 est considérée comme **COMPLÈTE** quand :

- ✅ Service d'emails configuré et fonctionnel
- ✅ Notifications automatiques opérationnelles
- ✅ Système d'alertes actif
- ✅ Interface de gestion accessible
- ✅ Tests de bout en bout réussis
- ✅ Configuration documentée

## Notes Importantes

1. **Sécurité :** Ne jamais commiter les credentials SMTP dans le code
2. **Performance :** La file d'attente évite les blocages lors de l'envoi
3. **Fiabilité :** Le système de retry garantit la livraison des emails
4. **Évolutivité :** L'architecture permet d'ajouter facilement de nouveaux types de notifications

## Prochaine Étape

Une fois la Phase 13 validée, passer à la **Phase 14 : Sécurité et Traçabilité** qui implémentera :
- Système de logging avancé
- Renforcement de la sécurité Firebase
- Interface d'audit pour les administrateurs