import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectivityService extends GetxService {
  final RxBool isConnected = true.obs;
  bool _wasOffline = false;

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  void _startMonitoring() {
    // Vérifier la connexion toutes les 30 secondes
    Future.delayed(const Duration(seconds: 30), () {
      _checkConnection();
      _startMonitoring();
    });
  }

  Future<void> _checkConnection() async {
    try {
      // Tenter une requête simple pour vérifier la connexion
      await FirebaseFirestore.instance.collection('_test').limit(1).get(const GetOptions(source: Source.server));

      if (!isConnected.value) {
        print('🌐 [CONNECTIVITY] Connexion rétablie');
        isConnected.value = true;

        // Déclencher la synchronisation automatique si on revient en ligne
        if (_wasOffline) {
          _wasOffline = false;
          _triggerAutoSync();
        }
      }
    } catch (e) {
      if (isConnected.value) {
        print('📡 [CONNECTIVITY] Connexion perdue - Mode offline activé');
        isConnected.value = false;
        _wasOffline = true;
      }
    }
  }

  void _triggerAutoSync() {
    print('🔄 [CONNECTIVITY] Déclenchement de la synchronisation automatique...');

    // Attendre un peu pour laisser la connexion se stabiliser
    Future.delayed(const Duration(seconds: 2), () {
      try {
        // Utiliser Get.find de manière dynamique pour éviter l'import circulaire
        final syncService = Get.find(tag: 'SyncService');
        if (syncService != null) {
          // Appeler la méthode via réflexion dynamique
          (syncService as dynamic).syncOfflineColis();
        }
      } catch (e) {
        print('⚠️ [CONNECTIVITY] Erreur lors de la synchronisation auto: $e');
      }
    });
  }

  Future<bool> checkConnectionNow() async {
    await _checkConnection();
    return isConnected.value;
  }
}
