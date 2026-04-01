# Intégration du Logo COREX

## Modifications Effectuées

### 1. Configuration des Assets

**Fichier** : `corex_desktop/pubspec.yaml`

Ajout de la déclaration des assets :
```yaml
flutter:
  uses-material-design: true
  
  # Assets
  assets:
    - assets/img/
    - assets/img/LOGO COREX.png
```

### 2. Widget Réutilisable CorexLogo

**Fichier** : `corex_desktop/lib/widgets/corex_logo.dart`

Création d'un widget réutilisable pour afficher le logo COREX avec :
- Support de dimensions personnalisables (`width`, `height`)
- Option pour afficher le texte "COREX" à côté du logo (`showText`)
- Couleur de texte personnalisable (`textColor`)
- Fallback automatique si l'image ne charge pas (affiche un cercle vert avec "C")

**Utilisation** :
```dart
// Logo seul
CorexLogo(height: 40)

// Logo avec texte
CorexLogo(
  height: 40,
  showText: true,
  textColor: Colors.white,
)
```

### 3. Écran de Login

**Fichier** : `corex_desktop/lib/screens/auth/login_screen.dart`

Remplacement du logo texte par l'image :
- Taille responsive (120x120 sur mobile, 150x150 sur desktop)
- Fallback vers le logo texte si l'image ne charge pas
- Padding de 8px autour de l'image

### 4. AppBar du HomeScreen

**Fichier** : `corex_desktop/lib/screens/home/home_screen.dart`

Remplacement du titre texte par le logo :
- Logo de 40px de hauteur
- Affichage du texte "COREX" à côté
- Couleur blanche pour le texte

## Emplacements du Logo

Le logo est maintenant visible dans :

1. **Écran de connexion** : Logo principal centré (150x150px)
2. **AppBar** : Logo avec texte dans la barre de navigation (40px)
3. **Fallback** : Cercle vert avec "C" si l'image ne charge pas

## Structure des Fichiers

```
corex_desktop/
├── assets/
│   └── img/
│       └── LOGO COREX.png          # Logo source
├── lib/
│   ├── widgets/
│   │   └── corex_logo.dart         # Widget réutilisable
│   └── screens/
│       ├── auth/
│       │   └── login_screen.dart   # Logo dans l'écran de login
│       └── home/
│           └── home_screen.dart    # Logo dans l'AppBar
└── pubspec.yaml                     # Déclaration des assets
```

## Avantages de Cette Approche

✅ **Réutilisable** : Le widget `CorexLogo` peut être utilisé partout dans l'app
✅ **Responsive** : S'adapte automatiquement à la taille de l'écran
✅ **Robuste** : Fallback automatique si l'image ne charge pas
✅ **Personnalisable** : Taille, texte et couleur configurables
✅ **Cohérent** : Même logo partout dans l'application

## Utilisation dans d'Autres Écrans

Pour utiliser le logo dans un nouvel écran :

```dart
// 1. Importer le widget
import '../../widgets/corex_logo.dart';

// 2. Utiliser le widget
CorexLogo(
  height: 50,           // Taille optionnelle
  showText: true,       // Afficher "COREX" à côté
  textColor: Colors.green, // Couleur du texte
)
```

## Prochaines Étapes Possibles

1. **Favicon Web** : Utiliser le logo comme favicon pour la version web
2. **Icône d'Application** : Générer les icônes d'app pour Windows/Android
3. **Splash Screen** : Ajouter le logo dans l'écran de démarrage
4. **Notifications** : Utiliser le logo dans les notifications
5. **PDF/Exports** : Inclure le logo dans les documents générés

## Notes Techniques

- **Format** : PNG avec transparence
- **Emplacement** : `assets/img/LOGO COREX.png`
- **Chargement** : Asynchrone avec `Image.asset()`
- **Cache** : Automatiquement géré par Flutter
- **Performance** : Optimisé pour le web et desktop

---

**Date** : 24 février 2026
**Statut** : ✅ Implémenté
**Impact** : Le logo COREX est maintenant visible dans toute l'application
