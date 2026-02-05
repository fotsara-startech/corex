@echo off
echo 🚀 Demarrage de COREX en mode developpement web...

REM Nettoyer le cache Flutter
echo 🧹 Nettoyage du cache...
flutter clean

REM Récupérer les dépendances
echo 📦 Installation des dependances...
flutter pub get

REM Attendre un peu pour s'assurer que tout est prêt
timeout /t 2 /nobreak > nul

REM Démarrer en mode web avec hot reload
echo 🌐 Demarrage du serveur web...
flutter run -d web-server --web-port=8080 --web-hostname=localhost --dart-define=FLUTTER_WEB_USE_SKIA=true

pause