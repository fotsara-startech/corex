@echo off
echo ========================================
echo COREX - Creation du Package de Deploiement
echo ========================================
echo.

REM Verification que le build existe
if not exist "corex_desktop\build\web" (
    echo ERREUR: Le dossier build\web n'existe pas!
    echo Executez d'abord: flutter build web --release
    pause
    exit /b 1
)

echo Verification du contenu du build...
dir "corex_desktop\build\web" /b

echo.
echo Creation du package de deploiement...

REM Creer le dossier de deploiement
if exist "corex_deployment" rmdir /s /q "corex_deployment"
mkdir "corex_deployment"

echo Copie des fichiers...
xcopy "corex_desktop\build\web\*" "corex_deployment\" /s /e /h /y

echo.
echo ========================================
echo Package de deploiement cree avec succes!
echo ========================================
echo.
echo Dossier: corex_deployment\
echo.
echo Prochaines etapes:
echo 1. Compresser le dossier 'corex_deployment' en ZIP
echo 2. Uploader sur Namecheap via cPanel File Manager
echo 3. Extraire dans public_html/ (ou public_html/corex/)
echo 4. Ajouter votre domaine aux "Authorized domains" Firebase
echo.
echo Guide complet: DEPLOIEMENT_NAMECHEAP_FINAL.md
echo.
pause