@echo off
echo ========================================
echo  COREX - Mise a jour du Favicon
echo ========================================
echo.

REM Chemins
set LOGO_SOURCE=corex_desktop\assets\img\LOGO COREX.png
set WEB_FOLDER=corex_desktop\web
set ICONS_FOLDER=%WEB_FOLDER%\icons
set DEPLOYMENT_FOLDER=corex_deployment

echo [1/5] Verification du logo source...
if not exist "%LOGO_SOURCE%" (
    echo ERREUR: Logo source introuvable: %LOGO_SOURCE%
    pause
    exit /b 1
)
echo    OK - Logo trouve

echo.
echo [2/5] Copie du favicon principal...
copy /Y "%LOGO_SOURCE%" "%WEB_FOLDER%\favicon.png"
if errorlevel 1 (
    echo ERREUR: Impossible de copier le favicon
    pause
    exit /b 1
)
echo    OK - favicon.png copie

echo.
echo [3/5] Copie des icones PWA...
copy /Y "%LOGO_SOURCE%" "%ICONS_FOLDER%\Icon-192.png"
copy /Y "%LOGO_SOURCE%" "%ICONS_FOLDER%\Icon-512.png"
copy /Y "%LOGO_SOURCE%" "%ICONS_FOLDER%\Icon-maskable-192.png"
copy /Y "%LOGO_SOURCE%" "%ICONS_FOLDER%\Icon-maskable-512.png"
echo    OK - Icones PWA copiees

echo.
echo [4/5] Mise a jour du dossier de deploiement...
if exist "%DEPLOYMENT_FOLDER%" (
    copy /Y "%LOGO_SOURCE%" "%DEPLOYMENT_FOLDER%\favicon.png"
    if exist "%DEPLOYMENT_FOLDER%\icons" (
        copy /Y "%LOGO_SOURCE%" "%DEPLOYMENT_FOLDER%\icons\Icon-192.png"
        copy /Y "%LOGO_SOURCE%" "%DEPLOYMENT_FOLDER%\icons\Icon-512.png"
        copy /Y "%LOGO_SOURCE%" "%DEPLOYMENT_FOLDER%\icons\Icon-maskable-192.png"
        copy /Y "%LOGO_SOURCE%" "%DEPLOYMENT_FOLDER%\icons\Icon-maskable-512.png"
        echo    OK - Deploiement mis a jour
    ) else (
        echo    ATTENTION - Dossier icons de deploiement introuvable
    )
) else (
    echo    INFO - Dossier de deploiement introuvable (normal si pas encore build)
)

echo.
echo [5/5] Verification...
if exist "%WEB_FOLDER%\favicon.png" (
    echo    OK - Favicon installe avec succes
) else (
    echo    ERREUR - Favicon non installe
    pause
    exit /b 1
)

echo.
echo ========================================
echo  SUCCES - Favicon mis a jour!
echo ========================================
echo.
echo PROCHAINES ETAPES:
echo 1. Rebuild l'application web:
echo    cd corex_desktop
echo    flutter build web --release
echo.
echo 2. Ou lancez le serveur de dev:
echo    cd corex_desktop
echo    flutter run -d chrome
echo.
echo 3. Videz le cache du navigateur (Ctrl+Shift+R)
echo    pour voir le nouveau favicon
echo.
pause
