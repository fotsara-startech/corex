import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:corex_shared/corex_shared.dart';

/// Widget affichant l'état de synchronisation et permettant la synchronisation manuelle
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = Get.find<SyncService>();
    final connectivityService = Get.find<ConnectivityService>();

    return Obx(() {
      final isOnline = connectivityService.isConnected.value;
      final isSyncing = syncService.isSyncing.value;
      final pendingCount = syncService.pendingSyncCount.value;

      // Si pas de colis en attente, ne rien afficher
      if (pendingCount == 0 && !isSyncing) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Tooltip(
          message: isSyncing
              ? 'Synchronisation en cours...'
              : isOnline
                  ? '$pendingCount colis en attente de synchronisation. Cliquez pour synchroniser.'
                  : '$pendingCount colis en attente. Connexion requise pour synchroniser.',
          child: InkWell(
            onTap: isOnline && !isSyncing
                ? () async {
                    await syncService.syncOfflineColis();
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSyncing
                    ? Colors.blue.shade100
                    : isOnline
                        ? Colors.orange.shade100
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSyncing
                      ? Colors.blue
                      : isOnline
                          ? Colors.orange
                          : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSyncing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  else
                    Icon(
                      isOnline ? Icons.sync : Icons.sync_disabled,
                      size: 16,
                      color: isOnline ? Colors.orange : Colors.grey,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    isSyncing ? 'Sync...' : '$pendingCount à sync',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSyncing
                          ? Colors.blue.shade900
                          : isOnline
                              ? Colors.orange.shade900
                              : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
