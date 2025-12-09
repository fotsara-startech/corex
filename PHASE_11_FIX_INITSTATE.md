# Fix: setState() called during build - Phase 11

## Problème Identifié

### Erreur
```
[ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: 
setState() or markNeedsBuild() called during build.
This Obx widget cannot be marked as needing to build because the framework 
is already in the process of building widgets.
```

### Cause
Dans les écrans suivants, `loadCourses()` était appelé directement dans `initState()`:
- `suivi_courses_screen.dart`
- `mes_courses_screen.dart`
- `courses_list_screen.dart`

Le problème est que `loadCourses()` met à jour des observables GetX (`isLoading.value`, `coursesList.value`), ce qui déclenche un rebuild pendant que le widget est déjà en train de se construire.

### Code Problématique
```dart
@override
void initState() {
  super.initState();
  _courseController.loadCourses(); // ❌ Appel direct
}
```

## Solution Appliquée

### Utilisation de `addPostFrameCallback`
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _courseController.loadCourses(); // ✅ Appel après le build
  });
}
```

### Explication
`WidgetsBinding.instance.addPostFrameCallback()` permet d'exécuter du code **après** que le premier frame ait été construit. Cela évite de modifier l'état pendant la construction du widget.

## Fichiers Modifiés

### 1. suivi_courses_screen.dart
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _courseController.loadCourses();
    _userController.loadUsers();
  });
}
```

### 2. mes_courses_screen.dart
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _courseController.loadCourses();
  });
}
```

### 3. courses_list_screen.dart
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _courseController.loadCourses();
  });
}
```

## Alternatives Considérées

### Alternative 1: Future.microtask
```dart
@override
void initState() {
  super.initState();
  Future.microtask(() => _courseController.loadCourses());
}
```
**Raison du rejet:** Moins explicite que `addPostFrameCallback`

### Alternative 2: ever() de GetX
```dart
@override
void initState() {
  super.initState();
  ever(_courseController.coursesList, (_) {
    // Réagir aux changements
  });
}
```
**Raison du rejet:** Ne résout pas le problème du chargement initial

### Alternative 3: Modifier le Controller
```dart
class CourseController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    loadCourses(); // Charger automatiquement
  }
}
```
**Raison du rejet:** Le controller est partagé entre plusieurs écrans, le chargement automatique n'est pas toujours souhaitable

## Bonnes Pratiques

### ✅ À Faire
1. Utiliser `addPostFrameCallback` pour les appels qui modifient l'état dans `initState()`
2. Utiliser `Future.delayed(Duration.zero)` comme alternative simple
3. Charger les données dans `onInit()` du controller si elles sont toujours nécessaires

### ❌ À Éviter
1. Appeler directement des méthodes qui modifient des observables dans `initState()`
2. Utiliser `setState()` dans `initState()` sans callback
3. Modifier l'état pendant le build

## Pattern Recommandé pour GetX

### Pour les Écrans
```dart
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  final MyController _controller = Get.find<MyController>();

  @override
  void initState() {
    super.initState();
    // Option 1: PostFrameCallback (recommandé)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadData();
    });
    
    // Option 2: Future.microtask
    // Future.microtask(() => _controller.loadData());
    
    // Option 3: Future.delayed
    // Future.delayed(Duration.zero, () => _controller.loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return CircularProgressIndicator();
      }
      return ListView(...);
    });
  }
}
```

### Pour les Controllers
```dart
class MyController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<MyModel> items = <MyModel>[].obs;

  // Option 1: Chargement manuel (recommandé pour écrans multiples)
  Future<void> loadData() async {
    isLoading.value = true;
    try {
      items.value = await _service.getData();
    } finally {
      isLoading.value = false;
    }
  }

  // Option 2: Chargement automatique (si toujours nécessaire)
  @override
  void onInit() {
    super.onInit();
    loadData();
  }
}
```

## Tests de Validation

### Test 1: Suivi des Courses
1. Se connecter en tant que Gestionnaire
2. Aller dans "Service de Courses" → "Suivi des courses"
3. ✅ L'écran se charge sans erreur
4. ✅ Les courses s'affichent correctement
5. ✅ Les statistiques sont mises à jour

### Test 2: Mes Courses (Coursier)
1. Se connecter en tant que Coursier
2. Aller dans "Mes Courses"
3. ✅ L'écran se charge sans erreur
4. ✅ Les courses du coursier s'affichent
5. ✅ Les statistiques sont correctes

### Test 3: Liste des Courses
1. Se connecter en tant que Commercial
2. Aller dans "Service de Courses"
3. ✅ L'écran se charge sans erreur
4. ✅ Les courses s'affichent
5. ✅ Le bouton FAB est visible

## Impact

### Avant le Fix
- ❌ Erreur runtime lors de l'ouverture des écrans
- ❌ Application crash possible
- ❌ Expérience utilisateur dégradée

### Après le Fix
- ✅ Aucune erreur
- ✅ Chargement fluide des données
- ✅ Expérience utilisateur optimale

## Conclusion

Le fix a été appliqué avec succès sur tous les écrans concernés. L'utilisation de `addPostFrameCallback` est maintenant le pattern standard pour charger des données dans `initState()` qui modifient des observables GetX.

**Statut:** ✅ RÉSOLU
**Date:** 9 décembre 2025
**Impact:** Aucun changement fonctionnel, seulement correction d'erreur runtime
