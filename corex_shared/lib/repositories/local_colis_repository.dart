import 'package:hive/hive.dart';
import 'package:get/get.dart';
import '../models/colis_model.dart';

/// Repository local pour les colis utilisant Hive
/// Garantit que les données ne sont jamais perdues, même hors ligne
class LocalColisRepository extends GetxService {
  static const String _boxName = 'colis_box';
  static const String _counterBoxName = 'counters_box';
  static const String _pendingSyncBoxName = 'pending_sync_box';

  Box<ColisModel>? _colisBox;
  Box<int>? _counterBox;
  Box<String>? _pendingSyncBox;

  /// Initialise Hive et ouvre les boxes
  Future<void> initialize() async {
    print('📦 [LOCAL_REPO] Initialisation de Hive...');

    try {
      _colisBox = await Hive.openBox<ColisModel>(_boxName);
      _counterBox = await Hive.openBox<int>(_counterBoxName);
      _pendingSyncBox = await Hive.openBox<String>(_pendingSyncBoxName);

      print('✅ [LOCAL_REPO] Hive initialisé avec succès');
      print('📊 [LOCAL_REPO] ${_colisBox!.length} colis en cache local');
      print('🔄 [LOCAL_REPO] ${_pendingSyncBox!.length} colis en attente de sync');
    } catch (e) {
      print('❌ [LOCAL_REPO] Erreur initialisation Hive: $e');

      // Si c'est une erreur de format, nettoyer le cache
      if (e.toString().contains('type cast') || e.toString().contains('subtype')) {
        print('🧹 [LOCAL_REPO] Détection d\'erreur de format, nettoyage du cache...');
        await _clearCorruptedCache();

        // Réessayer l'initialisation
        _colisBox = await Hive.openBox<ColisModel>(_boxName);
        _counterBox = await Hive.openBox<int>(_counterBoxName);
        _pendingSyncBox = await Hive.openBox<String>(_pendingSyncBoxName);

        print('✅ [LOCAL_REPO] Cache nettoyé et réinitialisé avec succès');
      } else {
        rethrow;
      }
    }
  }

  /// Nettoie manuellement tout le cache Hive (méthode publique)
  Future<void> clearAllCache() async {
    print('🧹 [LOCAL_REPO] Nettoyage manuel du cache...');
    await _clearCorruptedCache();
    await initialize();
    print('✅ [LOCAL_REPO] Cache nettoyé et réinitialisé');
  }

  /// Nettoie le cache corrompu
  Future<void> _clearCorruptedCache() async {
    try {
      // Fermer et supprimer les boxes corrompues
      if (Hive.isBoxOpen(_boxName)) {
        await Hive.box(_boxName).close();
      }
      if (Hive.isBoxOpen(_counterBoxName)) {
        await Hive.box(_counterBoxName).close();
      }
      if (Hive.isBoxOpen(_pendingSyncBoxName)) {
        await Hive.box(_pendingSyncBoxName).close();
      }

      // Supprimer les fichiers de cache
      await Hive.deleteBoxFromDisk(_boxName);
      await Hive.deleteBoxFromDisk(_counterBoxName);
      await Hive.deleteBoxFromDisk(_pendingSyncBoxName);

      print('🧹 [LOCAL_REPO] Cache Hive nettoyé');
    } catch (e) {
      print('⚠️ [LOCAL_REPO] Erreur lors du nettoyage: $e');
    }
  }

  /// Génère un numéro de suivi local séquentiel
  String generateLocalNumeroSuivi() {
    final year = DateTime.now().year;
    final counterKey = 'colis_$year';

    // Récupérer le compteur actuel
    int counter = _counterBox?.get(counterKey, defaultValue: 0) ?? 0;

    // Incrémenter
    counter++;

    // Sauvegarder
    _counterBox?.put(counterKey, counter);

    final numeroSuivi = 'COL-$year-LOCAL${counter.toString().padLeft(6, '0')}';
    print('📦 [LOCAL_REPO] Numéro local généré: $numeroSuivi');
    return numeroSuivi;
  }

  /// Sauvegarde un colis localement
  Future<void> saveColis(ColisModel colis) async {
    try {
      print('💾 [LOCAL_REPO] Sauvegarde locale: ${colis.numeroSuivi}');
      await _colisBox?.put(colis.id, colis);
      print('✅ [LOCAL_REPO] Colis sauvegardé localement');
    } catch (e) {
      print('❌ [LOCAL_REPO] Erreur sauvegarde: $e');
      rethrow;
    }
  }

  /// Marque un colis comme en attente de synchronisation
  Future<void> markPendingSync(String colisId) async {
    try {
      await _pendingSyncBox?.put(colisId, colisId);
      print('🔄 [LOCAL_REPO] Colis $colisId marqué pour sync');
    } catch (e) {
      print('❌ [LOCAL_REPO] Erreur marquage sync: $e');
    }
  }

  /// Retire un colis de la liste d'attente de synchronisation
  Future<void> removePendingSync(String colisId) async {
    try {
      await _pendingSyncBox?.delete(colisId);
      print('✅ [LOCAL_REPO] Colis $colisId retiré de la file de sync');
    } catch (e) {
      print('❌ [LOCAL_REPO] Erreur retrait sync: $e');
    }
  }

  /// Récupère tous les colis en attente de synchronisation
  List<ColisModel> getPendingSyncColis() {
    try {
      final pendingIds = _pendingSyncBox?.values.toList() ?? [];
      final colis = <ColisModel>[];

      for (final id in pendingIds) {
        final c = _colisBox?.get(id);
        if (c != null) {
          colis.add(c);
        }
      }

      print('🔄 [LOCAL_REPO] ${colis.length} colis en attente de sync');
      return colis;
    } catch (e) {
      print('❌ [LOCAL_REPO] Erreur récupération pending: $e');
      return [];
    }
  }

  /// Récupère un colis par son ID
  ColisModel? getColisById(String colisId) {
    return _colisBox?.get(colisId);
  }

  /// Récupère tous les colis locaux
  List<ColisModel> getAllColis() {
    return _colisBox?.values.toList() ?? [];
  }

  /// Récupère les colis par agence
  List<ColisModel> getColisByAgence(String agenceId) {
    return _colisBox?.values.where((c) => c.agenceCorexId == agenceId).toList() ?? [];
  }

  /// Récupère les colis par commercial
  List<ColisModel> getColisByCommercial(String commercialId) {
    return _colisBox?.values.where((c) => c.commercialId == commercialId).toList() ?? [];
  }

  /// Récupère les colis par statut
  List<ColisModel> getColisByStatut(String statut) {
    return _colisBox?.values.where((c) => c.statut == statut).toList() ?? [];
  }

  /// Met à jour un colis
  Future<void> updateColis(String colisId, ColisModel colis) async {
    try {
      await _colisBox?.put(colisId, colis);
      print('✅ [LOCAL_REPO] Colis $colisId mis à jour localement');
    } catch (e) {
      print('❌ [LOCAL_REPO] Erreur mise à jour: $e');
      rethrow;
    }
  }

  /// Supprime un colis
  Future<void> deleteColis(String colisId) async {
    try {
      await _colisBox?.delete(colisId);
      await _pendingSyncBox?.delete(colisId);
      print('✅ [LOCAL_REPO] Colis $colisId supprimé localement');
    } catch (e) {
      print('❌ [LOCAL_REPO] Erreur suppression: $e');
      rethrow;
    }
  }

  /// Compte les colis en attente de synchronisation
  int getPendingSyncCount() {
    return _pendingSyncBox?.length ?? 0;
  }

  /// Vérifie si un colis est en attente de synchronisation
  bool isPendingSync(String colisId) {
    return _pendingSyncBox?.containsKey(colisId) ?? false;
  }

  /// Nettoie les anciennes données (optionnel)
  Future<void> clearOldData({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final allColis = getAllColis();
      int deletedCount = 0;

      for (final colis in allColis) {
        // Ne supprimer que les colis livrés et non en attente de sync
        if ((colis.statut == 'livre' || colis.statut == 'retire') && colis.dateLivraison != null && colis.dateLivraison!.isBefore(cutoffDate) && !isPendingSync(colis.id)) {
          await deleteColis(colis.id);
          deletedCount++;
        }
      }

      print('🧹 [LOCAL_REPO] $deletedCount anciens colis supprimés');
    } catch (e) {
      print('❌ [LOCAL_REPO] Erreur nettoyage: $e');
    }
  }
}
