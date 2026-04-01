# Guide de Mise à Jour du Favicon COREX

## Problème Résolu
Le logo Flutter par défaut apparaissait dans l'onglet du navigateur au lieu du logo COREX.

## Solution Implémentée

### 1. Script Automatique
Un script batch `update_favicon.bat` a été créé pour automatiser le remplacement du favicon.

**Utilisation:**
```bash
.\update_favicon.bat
```

**Ce que fait le script:**
- ✅ Copie le logo COREX vers `corex_desktop/web/favicon.png`
- ✅ Remplace toutes les icônes PWA dans `corex_desktop/web/icons/`
- ✅ Met à jour le dossier de déploiement `corex_deployment/`
- ✅ Vérifie que tout est bien installé

### 2. Fichiers Mis à Jour

#### Favicon Principal
- `corex_desktop/web/favicon.png` → Logo COREX

#### Icônes PWA (Progressive Web App)
- `corex_desktop/web/icons/Icon-192.png` → Logo COREX 192x192
- `corex_desktop/web/icons/Icon-512.png` → Logo COREX 512x512
- `corex_desktop/web/icons/Icon-maskable-192.png` → Logo COREX maskable 192x192
- `corex_desktop/web/icons/Icon-maskable-512.png` → Logo COREX maskable 512x512

#### Déploiement
- `corex_deployment/favicon.png`
- `corex_deployment/icons/*` → Toutes les icônes

### 3. Configuration HTML
Le fichier `corex_desktop/web/index.html` contient déjà la bonne configuration:
```html
<!-- Favicon -->
<link rel="icon" type="image/png" href="favicon.png"/>

<!-- iOS meta tags & icons -->
<meta name="apple-mobile-web-app-title" content="COREX">
<link rel="apple-touch-icon" href="icons/Icon-192.png">
```

## Étapes Après Mise à Jour

### Option 1: Rebuild Complet (Recommandé)
```bash
cd corex_desktop
flutter build web --release
```

### Option 2: Mode Développement
```bash
cd corex_desktop
flutter run -d chrome
```

### Option 3: Serveur Local
Si vous utilisez un serveur local, redémarrez-le après avoir exécuté le script.

## Voir le Nouveau Favicon

### Dans le Navigateur
1. Ouvrez l'application web
2. Videz le cache du navigateur:
   - **Chrome/Edge:** `Ctrl + Shift + R` ou `Ctrl + F5`
   - **Firefox:** `Ctrl + Shift + R`
   - **Safari:** `Cmd + Option + R`

3. Rechargez la page

### Vérification
- ✅ L'onglet du navigateur doit afficher le logo COREX vert
- ✅ Les favoris doivent utiliser le logo COREX
- ✅ Sur mobile, l'icône de l'app doit être le logo COREX

## Problèmes Courants

### Le favicon ne change pas
**Cause:** Cache du navigateur
**Solution:** 
1. Videz complètement le cache (Ctrl+Shift+Delete)
2. Fermez et rouvrez le navigateur
3. Ouvrez en navigation privée pour tester

### Le favicon est flou
**Cause:** Le logo source n'est pas optimisé pour les petites tailles
**Solution:** Le logo COREX est déjà en haute résolution, il devrait être net

### Erreur lors de l'exécution du script
**Cause:** Chemin du logo incorrect
**Solution:** Vérifiez que `corex_desktop/assets/img/LOGO COREX.png` existe

## Maintenance Future

### Changer le Logo
1. Remplacez `corex_desktop/assets/img/LOGO COREX.png` par le nouveau logo
2. Exécutez `.\update_favicon.bat`
3. Rebuild l'application

### Avant Chaque Déploiement
Exécutez toujours le script avant de builder pour le déploiement:
```bash
.\update_favicon.bat
cd corex_desktop
flutter build web --release
```

## Fichiers Concernés
- ✅ `update_favicon.bat` - Script de mise à jour automatique
- ✅ `corex_desktop/web/favicon.png` - Favicon principal
- ✅ `corex_desktop/web/icons/*.png` - Icônes PWA
- ✅ `corex_desktop/web/index.html` - Configuration HTML
- ✅ `corex_desktop/web/manifest.json` - Manifest PWA
- ✅ `corex_deployment/*` - Fichiers de déploiement

## Résultat Final
Le logo COREX vert apparaît maintenant:
- ✅ Dans l'onglet du navigateur
- ✅ Dans les favoris
- ✅ Sur l'écran d'accueil mobile (PWA)
- ✅ Dans la barre des tâches Windows
- ✅ Dans le gestionnaire d'applications

---
**Date de création:** 24 février 2026
**Statut:** ✅ Implémenté et testé
