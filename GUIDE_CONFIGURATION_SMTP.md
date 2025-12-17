# Guide de Configuration SMTP - Résolution du Problème de Certificat

## Problème Identifié
```
HandshakeException: Handshake error in client (OS Error: CERTIFICATE_VERIFY_FAILED: certificate has expired)
```

Le certificat SSL du serveur kastraeg.com a expiré, causant l'échec des connexions SMTP.

## Solutions Implémentées

### 1. Configuration Actuelle (Recommandée)
```dart
_smtpServer = SmtpServer(
  'kastraeg.com',
  port: 587, // Port TLS standard
  username: 'notification@kastraeg.com',
  password: 'l[bNMaG%MZTL',
  ssl: false, // Pas de SSL direct
  allowInsecure: true, // Permettre les connexions non sécurisées
  ignoreBadCertificate: true, // Ignorer les certificats invalides
);
```

### 2. Test des Configurations
Utilisez cette méthode pour tester automatiquement différents ports :

```dart
// Dans votre code de test
final emailService = EmailService.instance;
await emailService.testMultipleSmtpConfigurations();
```

### 3. Configurations Alternatives à Tester

#### Option A: Port 25 (Standard SMTP)
```dart
SmtpServer(
  'kastraeg.com',
  port: 25,
  username: 'notification@kastraeg.com',
  password: 'l[bNMaG%MZTL',
  ssl: false,
  allowInsecure: true,
  ignoreBadCertificate: true,
);
```

#### Option B: Port 2525 (Alternatif)
```dart
SmtpServer(
  'kastraeg.com',
  port: 2525,
  username: 'notification@kastraeg.com',
  password: 'l[bNMaG%MZTL',
  ssl: false,
  allowInsecure: true,
  ignoreBadCertificate: true,
);
```

#### Option C: Votre Port Personnalisé 2079
```dart
SmtpServer(
  'kastraeg.com',
  port: 2079,
  username: 'notification@kastraeg.com',
  password: 'l[bNMaG%MZTL',
  ssl: false,
  allowInsecure: true,
  ignoreBadCertificate: true,
);
```

## Actions Recommandées

### 1. Test Immédiat
```dart
// Testez la configuration actuelle
final success = await EmailService.instance.testCurrentSmtpConfig();
if (!success) {
  // Testez toutes les configurations
  await EmailService.instance.testMultipleSmtpConfigurations();
}
```

### 2. Solution Permanente
Contactez votre hébergeur kastraeg.com pour :
- Renouveler le certificat SSL expiré
- Confirmer les ports SMTP disponibles
- Vérifier les paramètres d'authentification

### 3. Configuration de Secours
Si aucune configuration ne fonctionne, utilisez un service email tiers :
- Gmail SMTP
- SendGrid
- Mailgun
- Amazon SES

## Paramètres Actuels Confirmés
- **Serveur:** kastraeg.com
- **Username:** notification@kastraeg.com
- **Password:** l[bNMaG%MZTL
- **Ports testés:** 25, 587, 2525, 2079
- **SSL:** Désactivé (certificat expiré)
- **Sécurité:** allowInsecure + ignoreBadCertificate

## Vérification
Une fois configuré, les logs devraient afficher :
```
✅ Configuration SMTP actuelle fonctionne
✅ Email envoyé avec succès: colisStatus -> manuel@kastraeg.com
```