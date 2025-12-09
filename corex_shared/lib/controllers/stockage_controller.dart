import 'package:get/get.dart';
import '../models/depot_model.dart';
import '../models/mouvement_stock_model.dart';
import '../models/facture_stockage_model.dart';
import '../models/client_model.dart';
import '../services/stockage_service.dart';
import '../services/client_service.dart';
import 'auth_controller.dart';

class StockageController extends GetxController {
  final StockageService _stockageService = Get.find<StockageService>();
  final ClientService _clientService = Get.find<ClientService>();

  final RxList<ClientModel> clientsStockeurs = <ClientModel>[].obs;
  final RxList<DepotModel> depotsList = <DepotModel>[].obs;
  final RxList<MouvementStockModel> mouvementsList = <MouvementStockModel>[].obs;
  final RxList<FactureStockageModel> facturesList = <FactureStockageModel>[].obs;

  final RxBool isLoading = false.obs;
  final Rx<ClientModel?> selectedClient = Rx<ClientModel?>(null);
  final Rx<DepotModel?> selectedDepot = Rx<DepotModel?>(null);

  @override
  void onInit() {
    super.onInit();
    // Ne pas charger automatiquement car l'utilisateur n'est pas encore connecté
    // Les écrans appelleront loadClientsStockeurs() et loadDepots() quand nécessaire
    print('📦 [STOCKAGE_CONTROLLER] Contrôleur initialisé (chargement différé)');
  }

  // ========== CLIENTS STOCKEURS ==========

  Future<void> loadClientsStockeurs() async {
    print('🔄 [STOCKAGE_CONTROLLER] Début chargement clients stockeurs...');
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null) {
        print('❌ [STOCKAGE_CONTROLLER] Utilisateur non connecté');
        return;
      }

      if (user.agenceId == null) {
        print('❌ [STOCKAGE_CONTROLLER] AgenceId null pour l\'utilisateur ${user.id}');
        return;
      }

      print('📍 [STOCKAGE_CONTROLLER] AgenceId: ${user.agenceId}');

      // Charger les dépôts d'abord pour obtenir les IDs des clients
      print('🔍 [STOCKAGE_CONTROLLER] Chargement des dépôts...');
      final depots = await _stockageService.getDepotsListByAgence(user.agenceId!);
      print('📦 [STOCKAGE_CONTROLLER] ${depots.length} dépôts trouvés');

      if (depots.isEmpty) {
        print('⚠️ [STOCKAGE_CONTROLLER] Aucun dépôt trouvé pour cette agence');
        clientsStockeurs.value = [];
        return;
      }

      // Extraire les IDs uniques des clients qui ont des dépôts
      final clientIds = depots.map((d) => d.clientId).toSet().toList();
      print('👥 [STOCKAGE_CONTROLLER] ${clientIds.length} clients uniques trouvés: $clientIds');

      if (clientIds.isEmpty) {
        print('⚠️ [STOCKAGE_CONTROLLER] Aucun clientId dans les dépôts');
        clientsStockeurs.value = [];
        return;
      }

      // Charger les informations des clients
      final clients = <ClientModel>[];
      for (final clientId in clientIds) {
        print('🔍 [STOCKAGE_CONTROLLER] Chargement client: $clientId');
        final client = await _clientService.getClientById(clientId);
        if (client != null) {
          print('✅ [STOCKAGE_CONTROLLER] Client trouvé: ${client.nom} (${client.id})');
          clients.add(client);
        } else {
          print('❌ [STOCKAGE_CONTROLLER] Client $clientId introuvable en base');
        }
      }

      print('📊 [STOCKAGE_CONTROLLER] Total clients chargés: ${clients.length}');

      // Trier par nom
      clients.sort((a, b) => a.nom.compareTo(b.nom));
      clientsStockeurs.value = clients;

      print('✅ [STOCKAGE_CONTROLLER] ${clients.length} clients stockeurs chargés et affichés');
    } catch (e, stackTrace) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur chargement clients: $e');
      print('📍 [STACKTRACE] $stackTrace');
      Get.snackbar('Erreur', 'Impossible de charger les clients: $e');
    } finally {
      isLoading.value = false;
      print('🏁 [STOCKAGE_CONTROLLER] Fin chargement (isLoading: ${isLoading.value})');
    }
  }

  Future<bool> createClientStockeur(ClientModel client) async {
    try {
      final clientId = await _clientService.createClient(client);
      // Créer une nouvelle instance avec l'ID retourné
      final newClient = ClientModel(
        id: clientId,
        nom: client.nom,
        telephone: client.telephone,
        adresse: client.adresse,
        ville: client.ville,
        quartier: client.quartier,
        type: client.type,
        agenceId: client.agenceId,
        createdAt: client.createdAt,
        updatedAt: client.updatedAt,
      );
      // Ajouter immédiatement le client à la liste locale
      clientsStockeurs.insert(0, newClient);
      Get.snackbar('Succès', 'Client stockeur enregistré');
      return true;
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur création client: $e');
      Get.snackbar('Erreur', 'Impossible de créer le client');
      return false;
    }
  }

  Future<ClientModel?> searchClientByPhone(String telephone) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) return null;

      return await _clientService.searchClientByPhone(telephone, user.agenceId!);
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur recherche: $e');
      return null;
    }
  }

  // ========== DÉPÔTS ==========

  Future<void> loadDepots() async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) return;

      _stockageService.getDepotsByAgence(user.agenceId!).listen((depots) {
        depotsList.value = depots;
      });
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur chargement dépôts: $e');
      Get.snackbar('Erreur', 'Impossible de charger les dépôts');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDepotsByClient(String clientId) async {
    try {
      _stockageService.getDepotsByClient(clientId).listen((depots) {
        depotsList.value = depots;
      });
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur chargement dépôts client: $e');
    }
  }

  Future<bool> createDepot(DepotModel depot) async {
    try {
      await _stockageService.createDepot(depot);
      Get.snackbar('Succès', 'Dépôt enregistré avec succès');
      return true;
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur création dépôt: $e');
      Get.snackbar('Erreur', 'Impossible d\'enregistrer le dépôt');
      return false;
    }
  }

  Future<bool> updateDepot(String depotId, Map<String, dynamic> data) async {
    try {
      await _stockageService.updateDepot(depotId, data);
      Get.snackbar('Succès', 'Dépôt mis à jour');
      return true;
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur mise à jour dépôt: $e');
      Get.snackbar('Erreur', 'Impossible de mettre à jour le dépôt');
      return false;
    }
  }

  void selectDepot(DepotModel depot) {
    selectedDepot.value = depot;
    loadMouvementsByDepot(depot.id);
  }

  Future<void> reloadSelectedDepot() async {
    if (selectedDepot.value == null) return;

    try {
      final depot = await _stockageService.getDepot(selectedDepot.value!.id);
      if (depot != null) {
        selectedDepot.value = depot;
        print('✅ [STOCKAGE_CONTROLLER] Dépôt rechargé avec nouvelles quantités');
      }
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur rechargement dépôt: $e');
    }
  }

  // ========== MOUVEMENTS ==========

  Future<void> loadMouvementsByDepot(String depotId) async {
    try {
      _stockageService.getMouvementsByDepot(depotId).listen((mouvements) {
        mouvementsList.value = mouvements;
      });
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur chargement mouvements: $e');
    }
  }

  Future<void> loadMouvementsByClient(String clientId) async {
    try {
      _stockageService.getMouvementsByClient(clientId).listen((mouvements) {
        mouvementsList.value = mouvements;
      });
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur chargement mouvements client: $e');
    }
  }

  Future<bool> createRetrait(
    String depotId,
    String clientId,
    List<ProduitMouvement> produits,
    String? notes,
  ) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return false;
      }

      await _stockageService.createRetrait(
        depotId,
        clientId,
        user.agenceId!,
        produits,
        user.id,
        notes,
      );

      // Recharger le dépôt pour avoir les quantités à jour
      await reloadSelectedDepot();

      Get.snackbar('Succès', 'Retrait enregistré avec succès');
      return true;
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur création retrait: $e');
      Get.snackbar('Erreur', 'Impossible d\'enregistrer le retrait');
      return false;
    }
  }

  // ========== FACTURES ==========

  Future<void> loadFactures() async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) return;

      _stockageService.getFacturesByAgence(user.agenceId!).listen((factures) {
        facturesList.value = factures;
      });
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur chargement factures: $e');
    }
  }

  Future<void> loadFacturesByClient(String clientId) async {
    try {
      _stockageService.getFacturesByClient(clientId).listen((factures) {
        facturesList.value = factures;
      });
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur chargement factures client: $e');
    }
  }

  Future<bool> generateFactureMensuelle(
    String clientId,
    List<String> depotIds,
    DateTime periodeDebut,
    DateTime periodeFin,
    double montantTotal,
    String? notes,
  ) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user == null || user.agenceId == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return false;
      }

      final numeroFacture = await _stockageService.generateNumeroFacture();

      final facture = FactureStockageModel(
        id: '',
        numeroFacture: numeroFacture,
        clientId: clientId,
        agenceId: user.agenceId!,
        depotIds: depotIds,
        periodeDebut: periodeDebut,
        periodeFin: periodeFin,
        montantTotal: montantTotal,
        statut: 'impayee',
        dateEmission: DateTime.now(),
        userId: user.id,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _stockageService.createFacture(facture);
      Get.snackbar('Succès', 'Facture générée: $numeroFacture');
      return true;
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur génération facture: $e');
      Get.snackbar('Erreur', 'Impossible de générer la facture');
      return false;
    }
  }

  Future<bool> marquerFacturePayee(
    String factureId,
    String transactionId,
  ) async {
    try {
      await _stockageService.updateFacture(factureId, {
        'statut': 'payee',
        'datePaiement': DateTime.now(),
        'transactionId': transactionId,
      });

      Get.snackbar('Succès', 'Facture marquée comme payée');
      return true;
    } catch (e) {
      print('❌ [STOCKAGE_CONTROLLER] Erreur paiement facture: $e');
      Get.snackbar('Erreur', 'Impossible de marquer la facture comme payée');
      return false;
    }
  }

  List<DepotModel> getDepotsActifs() {
    return depotsList.where((depot) {
      // Un dépôt est actif s'il a au moins un produit avec quantité > 0
      return depot.produits.any((p) => p.quantite > 0);
    }).toList();
  }

  double getTotalStockageClient(String clientId) {
    final depotsClient = depotsList.where((d) => d.clientId == clientId).toList();
    return depotsClient.fold(0.0, (sum, depot) => sum + depot.tarifMensuel);
  }
}
