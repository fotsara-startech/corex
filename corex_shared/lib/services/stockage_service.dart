import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/depot_model.dart';
import '../models/mouvement_stock_model.dart';
import '../models/facture_stockage_model.dart';

class StockageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== DÉPÔTS ==========

  Future<String> createDepot(DepotModel depot) async {
    try {
      final docRef = await _firestore.collection('depots').add(depot.toFirestore());

      // Créer un mouvement de dépôt
      final mouvement = MouvementStockModel(
        id: '',
        depotId: docRef.id,
        clientId: depot.clientId,
        agenceId: depot.agenceId,
        type: 'depot',
        produits: depot.produits
            .map((p) => ProduitMouvement(
                  nom: p.nom,
                  quantite: p.quantite,
                  unite: p.unite,
                ))
            .toList(),
        dateMouvement: depot.dateDepot,
        userId: depot.userId,
        notes: 'Dépôt initial',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('mouvements_stock').add(mouvement.toFirestore());

      print('✅ [STOCKAGE_SERVICE] Dépôt créé: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur création dépôt: $e');
      rethrow;
    }
  }

  Future<void> updateDepot(String depotId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('depots').doc(depotId).update(data);
      print('✅ [STOCKAGE_SERVICE] Dépôt mis à jour: $depotId');
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur mise à jour dépôt: $e');
      rethrow;
    }
  }

  Future<DepotModel?> getDepot(String depotId) async {
    try {
      final doc = await _firestore.collection('depots').doc(depotId).get();
      if (!doc.exists) return null;
      return DepotModel.fromFirestore(doc);
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur récupération dépôt: $e');
      return null;
    }
  }

  Future<List<DepotModel>> getDepotsListByAgence(String agenceId) async {
    try {
      print('🔍 [STOCKAGE_SERVICE] Recherche dépôts pour agenceId: $agenceId');
      final snapshot = await _firestore.collection('depots').where('agenceId', isEqualTo: agenceId).get();

      print('📦 [STOCKAGE_SERVICE] ${snapshot.docs.length} documents trouvés');

      final depots = snapshot.docs.map((doc) {
        print('📄 [STOCKAGE_SERVICE] Dépôt: ${doc.id}, clientId: ${doc.data()['clientId']}');
        return DepotModel.fromFirestore(doc);
      }).toList();

      print('✅ [STOCKAGE_SERVICE] ${depots.length} dépôts convertis');
      return depots;
    } catch (e, stackTrace) {
      print('❌ [STOCKAGE_SERVICE] Erreur récupération dépôts: $e');
      print('📍 [STACKTRACE] $stackTrace');
      return [];
    }
  }

  Stream<List<DepotModel>> getDepotsByAgence(String agenceId) {
    return _firestore
        .collection('depots')
        .where('agenceId', isEqualTo: agenceId)
        .orderBy('dateDepot', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DepotModel.fromFirestore(doc)).toList());
  }

  Future<void> deleteDepot(String depotId) async {
    try {
      await _firestore.collection('depots').doc(depotId).delete();
      print('✅ [STOCKAGE_SERVICE] Dépôt supprimé: $depotId');
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur suppression dépôt: $e');
      rethrow;
    }
  }

  Future<void> deleteMouvement(String mouvementId) async {
    try {
      await _firestore.collection('mouvements_stock').doc(mouvementId).delete();
      print('✅ [STOCKAGE_SERVICE] Mouvement supprimé: $mouvementId');
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur suppression mouvement: $e');
      rethrow;
    }
  }

  Stream<List<DepotModel>> getDepotsByClient(String clientId) {
    return _firestore
        .collection('depots')
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateDepot', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => DepotModel.fromFirestore(doc)).toList());
  }

  // ========== MOUVEMENTS ==========

  Future<void> createRetrait(
    String depotId,
    String clientId,
    String agenceId,
    List<ProduitMouvement> produits,
    String userId,
    String? notes,
  ) async {
    try {
      // Récupérer le dépôt actuel AVANT de créer le mouvement
      final depot = await getDepot(depotId);
      if (depot == null) {
        throw Exception('Dépôt introuvable');
      }

      // Vérifier les quantités disponibles
      for (final retrait in produits) {
        final produitDepot = depot.produits.firstWhere(
          (p) => p.nom == retrait.nom,
          orElse: () => throw Exception('Produit ${retrait.nom} introuvable dans le dépôt'),
        );

        if (produitDepot.quantite < retrait.quantite) {
          throw Exception('Quantité insuffisante pour ${retrait.nom}: '
              'disponible ${produitDepot.quantite} ${produitDepot.unite}, '
              'demandé ${retrait.quantite} ${retrait.unite}');
        }
      }

      // Mettre à jour les quantités dans le dépôt EN PREMIER
      final produitsUpdated = depot.produits.map((p) {
        final retrait = produits.firstWhere(
          (r) => r.nom == p.nom,
          orElse: () => ProduitMouvement(nom: '', quantite: 0, unite: ''),
        );

        if (retrait.nom.isNotEmpty) {
          final nouvelleQuantite = p.quantite - retrait.quantite;
          return p.copyWith(quantite: nouvelleQuantite);
        }
        return p;
      }).toList();

      await updateDepot(depotId, {
        'produits': produitsUpdated.map((p) => p.toMap()).toList(),
      });

      // Créer le mouvement de retrait APRÈS la mise à jour
      final mouvement = MouvementStockModel(
        id: '',
        depotId: depotId,
        clientId: clientId,
        agenceId: agenceId,
        type: 'retrait',
        produits: produits,
        dateMouvement: DateTime.now(),
        userId: userId,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('mouvements_stock').add(mouvement.toFirestore());

      print('✅ [STOCKAGE_SERVICE] Retrait enregistré et quantités mises à jour');
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur création retrait: $e');
      rethrow;
    }
  }

  Stream<List<MouvementStockModel>> getMouvementsByDepot(String depotId) {
    return _firestore
        .collection('mouvements_stock')
        .where('depotId', isEqualTo: depotId)
        .orderBy('dateMouvement', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MouvementStockModel.fromFirestore(doc)).toList());
  }

  Stream<List<MouvementStockModel>> getMouvementsByClient(String clientId) {
    return _firestore
        .collection('mouvements_stock')
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateMouvement', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MouvementStockModel.fromFirestore(doc)).toList());
  }

  // ========== FACTURES ==========

  Future<String> generateNumeroFacture() async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month.toString().padLeft(2, '0');

      final counterDoc = _firestore.collection('counters').doc('facture_stockage');

      return await _firestore.runTransaction<String>((transaction) async {
        final snapshot = await transaction.get(counterDoc);

        int counter = 1;
        if (snapshot.exists) {
          counter = (snapshot.data()?['count'] ?? 0) + 1;
        }

        transaction.set(counterDoc, {'count': counter}, SetOptions(merge: true));

        return 'FACT-$year-$month-${counter.toString().padLeft(6, '0')}';
      });
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur génération numéro facture: $e');
      rethrow;
    }
  }

  Future<String> createFacture(FactureStockageModel facture) async {
    try {
      final docRef = await _firestore.collection('factures_stockage').add(facture.toFirestore());
      print('✅ [STOCKAGE_SERVICE] Facture créée: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur création facture: $e');
      rethrow;
    }
  }

  Future<void> updateFacture(String factureId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _firestore.collection('factures_stockage').doc(factureId).update(data);
      print('✅ [STOCKAGE_SERVICE] Facture mise à jour: $factureId');
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur mise à jour facture: $e');
      rethrow;
    }
  }

  Future<FactureStockageModel?> getFacture(String factureId) async {
    try {
      final doc = await _firestore.collection('factures_stockage').doc(factureId).get();
      if (!doc.exists) return null;
      return FactureStockageModel.fromFirestore(doc);
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur récupération facture: $e');
      return null;
    }
  }

  Stream<List<FactureStockageModel>> getFacturesByClient(String clientId) {
    return _firestore
        .collection('factures_stockage')
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateEmission', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FactureStockageModel.fromFirestore(doc)).toList());
  }

  Stream<List<FactureStockageModel>> getFacturesByAgence(String agenceId) {
    return _firestore
        .collection('factures_stockage')
        .where('agenceId', isEqualTo: agenceId)
        .orderBy('dateEmission', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FactureStockageModel.fromFirestore(doc)).toList());
  }

  Future<List<FactureStockageModel>> getFacturesImpayees(String agenceId) async {
    try {
      final snapshot = await _firestore.collection('factures_stockage').where('agenceId', isEqualTo: agenceId).where('statut', isEqualTo: 'impayee').orderBy('dateEmission', descending: true).get();

      return snapshot.docs.map((doc) => FactureStockageModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ [STOCKAGE_SERVICE] Erreur récupération factures impayées: $e');
      return [];
    }
  }
}
