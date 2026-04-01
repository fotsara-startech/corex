import 'package:get/get.dart';
import '../models/colis_model.dart';
import '../repositories/local_colis_repository.dart';
import 'firebase_service.dart';
import 'colis_service.dart';

/// Service de synchronisation pour gérer les données créées en mode offline
/// Utilise le repository local (Hive) comme source de vérité
class SyncService extends GetxService {
  final ColisService _colisService = Get.find<ColisService>();
  LocalColisRepository? _localRepo;

  final RxBool isSyncing = false.obs;
  final RxInt pendingSyncCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<LocalColisRepository>()) {
      _localRepo = Get.find<LocalColisRepository>();
      _updatePendingCount();
    }
  }

  void _updatePendingCount() {
    pendingSyncCount.value = _localRepo?.getPendingSyncCount() ?? 0;
  }

  /// Synchronise tous les colis en attente depuis le repository local
  Future<void> syncOfflineColis() async {
    if (isSyncing.value) {
      print('⚠️ [SYNC_SERVICE] Synchronisation déjà en cours');
      return;
    }

    if (_localRepo == null) {
      print('⚠️ [SYNC_SERVICE] Repository local non disponible');
      return;
    }

    isSyncing.value = true;
    print('🔄 [SYNC_SERVICE] Début de la synchronisation des colis offline...');

    try {
      // Récupérer tous les colis en attente de synchronisation depuis Hive
      final pendingColis = _localRepo!.getPendingSyncColis();
      pendingSyncCount.value = pendingColis.length;

      print('📦 [SYNC_SERVICE] ${pendingColis.length} colis à synchroniser');

      if (pendingColis.isEmpty) {
        print('✅ [SYNC_SERVICE] Aucun colis à synchroniser');
        isSyncing.value = false;
        return;
      }

      // Synchroniser chaque colis
      int successCount = 0;
      int errorCount = 0;

      for (final colis in pendingColis) {
        try {
          await _syncSingleColis(colis);
          successCount++;
          _updatePendingCount();
        } catch (e) {
          print('❌ [SYNC_SERVICE] Erreur sync colis ${colis.id}: $e');
          errorCount++;
        }
      }

      print('✅ [SYNC_SERVICE] Synchronisation terminée: $successCount réussis, $errorCount échecs');

      if (successCount > 0) {
        Get.snackbar(
          'Synchronisation',
          '$successCount colis synchronisé(s) avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('❌ [SYNC_SERVICE] Erreur synchronisation: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Synchronise un seul colis depuis le local vers Firebase
  Future<void> _syncSingleColis(ColisModel colis) async {
    print('🔄 [SYNC_SERVICE] Synchronisation colis ${colis.numeroSuivi}...');

    try {
      // Si le numéro contient "LOCAL", générer un numéro définitif
      String finalNumeroSuivi = colis.numeroSuivi;

      if (colis.numeroSuivi.contains('LOCAL')) {
        finalNumeroSuivi = await _colisService.generateNumeroSuivi();
        print('📦 [SYNC_SERVICE] Nouveau numéro: $finalNumeroSuivi');

        // Mettre à jour le colis localement avec le nouveau numéro
        final updatedColis = colis.copyWith(
          numeroSuivi: finalNumeroSuivi,
          historique: [
            ...colis.historique,
            HistoriqueStatut(
              statut: colis.statut,
              date: DateTime.now(),
              userId: 'system',
              commentaire: 'Synchronisation: numéro local ${colis.numeroSuivi} remplacé par $finalNumeroSuivi',
            ),
          ],
        );

        // Sauvegarder dans Firebase
        await FirebaseService.colis.doc(colis.id).set(updatedColis.toFirestore());

        // Mettre à jour localement
        await _localRepo!.updateColis(colis.id, updatedColis);
      } else {
        // Juste synchroniser tel quel
        await FirebaseService.colis.doc(colis.id).set(colis.toFirestore());
      }

      // Retirer de la file d'attente
      await _localRepo!.removePendingSync(colis.id);

      print('✅ [SYNC_SERVICE] Colis ${colis.id} synchronisé: ${colis.numeroSuivi} → $finalNumeroSuivi');
    } catch (e) {
      print('❌ [SYNC_SERVICE] Erreur sync colis ${colis.id}: $e');
      rethrow;
    }
  }

  /// Compte le nombre de colis en attente de synchronisation
  int countPendingSyncColis() {
    final count = _localRepo?.getPendingSyncCount() ?? 0;
    pendingSyncCount.value = count;
    return count;
  }
}
