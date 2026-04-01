@echo off
echo ========================================
echo    COREX - Compilation Web
echo ========================================
echo.

cd corex_desktop

echo [1/6] Nettoyage des fichiers de build precedents...
if exist build\web rmdir /s /q build\web
flutter clean

echo.
echo [2/6] Recuperation des dependances...
flutter pub get

echo.
echo [3/6] Verification de la configuration web...
flutter doctor

echo.
echo [4/6] Compilation en mode release pour le web...
flutter build web --release --web-renderer html --base-href /

echo.
echo [5/6] Optimisation des fichiers...
cd build\web
echo Taille des fichiers principaux:
dir /s *.js *.html *.css

echo.
echo [6/6] Preparation pour l'upload...
echo.
echo ========================================
echo    COMPILATION TERMINEE !
echo ========================================
echo.
echo Fichiers generes dans: corex_desktop\build\web\
echo.
echo PROCHAINES ETAPES:
echo 1. Compresser le dossier build\web\ en ZIP
echo 2. Se connecter au cPanel de Namecheap
echo 3. Aller dans File Manager
echo 4. Naviguer vers public_html/
echo 5. Uploader et extraire le fichier ZIP
echo 6. Configurer les variables d'environnement Firebase
echo.
echo Appuyez sur une touche pour continuer...
pause > nul