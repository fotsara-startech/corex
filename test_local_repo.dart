import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:corex_shared/corex_shared.dart';

/// Test simple pour vérifier l'initialisation du LocalColisRepository
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 [TEST] Début du test LocalColisRepository...');

  try {
    // Initialiser Hive
    await Hive.initFlutter('test');

    // Enregistrer les adaptateurs
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ColisModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HistoriqueStatutAdapter());
    }

    print('✅ [TEST] Hive initialisé');

    // Initialiser le repository
    final localRepo = LocalColisRepository();
    await localRepo.initialize();
    Get.put(localRepo, permanent: true);

    print('✅ [TEST] LocalColisRepository initialisé');

    // Tester la génération de numéro
    final numeroSuivi = localRepo.generateLocalNumeroSuivi();
    print('✅ [TEST] Numéro généré: $numeroSuivi');

    // Vérifier que Get.find fonctionne
    final repoFromGet = Get.find<LocalColisRepository>();
    final numeroSuivi2 = repoFromGet.generateLocalNumeroSuivi();
    print('✅ [TEST] Numéro via Get.find: $numeroSuivi2');

    print('🎉 [TEST] Tous les tests passés !');
  } catch (e) {
    print('❌ [TEST] Erreur: $e');
  }
}
