# Guide de Déploiement COREX sur Namecheap

## Étapes de Compilation

### 1. Préparation de l'environnement
```bash
# Vérifier Flutter
flutter doctor

# Nettoyer le projet
cd corex_desktop
flutter clean
flutter pub get
```

### 2. Compilation pour le web
```bash
# Compilation optimisée pour production
flutter build web --release --web-renderer html --base-href /

# Alternative avec base-href personnalisé (si sous-dossier)
flutter build web --release --web-renderer html --base-href /corex/
```

### 3. Vérification des fichiers générés
Les fichiers seront dans `corex_desktop/build/web/` :
- `index.html` - Page principale
- `main.dart.js` - Code Dart compilé
- `flutter_service_worker.js` - Service worker
- `manifest.json` - Configuration PWA
- `assets/` - Ressources (images, fonts, etc.)
- `icons/` - Icônes de l'application

## Déploiement sur Namecheap

### 1. Accès au cPanel
1. Connectez-vous à votre compte Namecheap
2. Allez dans "Hosting List"
3. Cliquez sur "Manage" pour votre domaine
4. Ouvrez le cPanel

### 2. Upload des fichiers
1. Dans cPanel, ouvrez "File Manager"
2. Naviguez vers `public_html/`
3. **Option A - Dossier racine :**
   - Uploadez tout le contenu de `build/web/` directement dans `public_html/`
4. **Option B - Sous-dossier :**
   - Créez un dossier `corex/` dans `public_html/`
   - Uploadez le contenu dans `public_html/corex/`

### 3. Configuration des permissions
```bash
# Permissions recommandées
Dossiers : 755
Fichiers : 644
```

### 4. Configuration du serveur web

#### Fichier .htaccess (à créer dans public_html/)
```apache
# Redirection pour SPA (Single Page Application)
<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # Handle Angular and other HTML5 mode routing
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^.*$ /index.html [L]
    
    # Cache static assets
    <FilesMatch "\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 month"
        Header append Cache-Control "public"
    </FilesMatch>
    
    # Compress files
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/plain
        AddOutputFilterByType DEFLATE text/html
        AddOutputFilterByType DEFLATE text/xml
        AddOutputFilterByType DEFLATE text/css
        AddOutputFilterByType DEFLATE application/xml
        AddOutputFilterByType DEFLATE application/xhtml+xml
        AddOutputFilterByType DEFLATE application/rss+xml
        AddOutputFilterByType DEFLATE application/javascript
        AddOutputFilterByType DEFLATE application/x-javascript
    </IfModule>
</IfModule>

# Security headers
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
```

## Configuration Firebase

### 1. Domaine autorisé
Dans la console Firebase :
1. Allez dans "Authentication" > "Settings" > "Authorized domains"
2. Ajoutez votre domaine : `votredomaine.com`
3. Si sous-dossier : `votredomaine.com/corex`

### 2. Variables d'environnement
Les clés Firebase sont déjà configurées dans `firebase_options.dart` :
- Project ID: `corex-a1c1e`
- Auth Domain: `corex-a1c1e.firebaseapp.com`
- API Key: `AIzaSyCM_Y0Uwg7pxcfUjNO5EySaWFrCx_R6-jo`

## Test du déploiement

### 1. Vérifications de base
- [ ] Page d'accueil se charge : `https://votredomaine.com`
- [ ] Connexion Firebase fonctionne
- [ ] Authentification possible
- [ ] Navigation entre pages

### 2. Tests de performance
```bash
# Outils de test
- Google PageSpeed Insights
- GTmetrix
- Lighthouse (dans Chrome DevTools)
```

### 3. Tests de compatibilité
- [ ] Chrome/Edge
- [ ] Firefox
- [ ] Safari
- [ ] Mobile (responsive)

## Optimisations post-déploiement

### 1. Performance
```bash
# Activer la compression GZIP dans cPanel
# Configurer le cache des ressources statiques
# Optimiser les images si nécessaire
```

### 2. SEO (optionnel)
```html
<!-- Ajouter dans index.html -->
<meta name="description" content="COREX - Système de gestion logistique">
<meta name="keywords" content="logistique, transport, gestion, colis">
<meta property="og:title" content="COREX">
<meta property="og:description" content="Système de gestion logistique">
```

### 3. Monitoring
- Configurer Google Analytics (optionnel)
- Surveiller les erreurs dans la console Firebase
- Vérifier les logs d'accès cPanel

## Dépannage

### Problèmes courants

#### 1. Page blanche
- Vérifier les erreurs dans la console du navigateur
- S'assurer que tous les fichiers sont uploadés
- Vérifier les permissions des fichiers

#### 2. Erreurs Firebase
- Vérifier que le domaine est autorisé
- Contrôler les clés API
- Vérifier la connectivité réseau

#### 3. Erreurs de routing
- S'assurer que le fichier .htaccess est présent
- Vérifier la configuration du serveur web

#### 4. Ressources non trouvées
- Vérifier le base-href dans la compilation
- S'assurer que les chemins sont corrects

## Commandes utiles

### Compilation avec options
```bash
# Debug (plus rapide, plus gros)
flutter build web --debug

# Profile (compromis)
flutter build web --profile

# Release (optimisé, plus lent à compiler)
flutter build web --release

# Avec base-href personnalisé
flutter build web --release --base-href /mon-app/

# Avec renderer spécifique
flutter build web --release --web-renderer canvaskit
flutter build web --release --web-renderer html
```

### Vérification locale
```bash
# Serveur local pour tester
cd build/web
python -m http.server 8000
# Puis ouvrir http://localhost:8000
```

## Maintenance

### Mises à jour
1. Modifier le code source
2. Recompiler : `flutter build web --release`
3. Uploader les nouveaux fichiers
4. Vider le cache du navigateur

### Sauvegarde
- Sauvegarder régulièrement le code source
- Exporter la base de données Firebase
- Sauvegarder les fichiers web via cPanel

---

**Note importante :** Assurez-vous que votre plan d'hébergement Namecheap supporte les applications web modernes et les redirections .htaccess.