import 'package:get/get.dart';
import 'package:corex_shared/repositories/local_colis_repository.dart';

/// Utilitaire pour nettoyer le cache local en cas de problèmes de format
class CacheCleaner {
  /// Nettoie le cache local si des erreurs de format sont détectées
  static Future<void> cleanCacheIfNeeded() async {
    try {
      if (Get.isRegistered<LocalColisRepository>()) {
        final localRepo = Get.find<LocalColisRepository>();

        // Tenter de récupérer les données pour détecter les erreurs
        try {
          localRepo.getAllColis();
          print('✅ [CACHE_CLEANER] Cache local en bon état');
        } catch (e) {
          if (e.toString().contains('type cast') || e.toString().contains('subtype') || e.toString().contains('Timestamp')) {
            print('🧹 [CACHE_CLEANER] Erreur de format détectée, nettoyage du cache...');
            await localRepo.clearAllCache();
            print('✅ [CACHE_CLEANER] Cache nettoyé avec succès');
          } else {
            print('⚠️ [CACHE_CLEANER] Erreur non liée au format: $e');
          }
        }
      }
    } catch (e) {
      print('❌ [CACHE_CLEANER] Erreur lors du nettoyage: $e');
    }
  }

  /// Force le nettoyage du cache (pour debug)
  static Future<void> forceClearCache() async {
    try {
      if (Get.isRegistered<LocalColisRepository>()) {
        final localRepo = Get.find<LocalColisRepository>();
        await localRepo.clearAllCache();
        print('✅ [CACHE_CLEANER] Cache forcé nettoyé');
      }
    } catch (e) {
      print('❌ [CACHE_CLEANER] Erreur nettoyage forcé: $e');
    }
  }
}
